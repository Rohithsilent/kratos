"""
KRATOS AI — Firebase Authentication & Security.

Provides:
- Firebase ID token verification via firebase-admin SDK
- FastAPI dependency `get_current_user` — attach to any route that needs auth
- Optional: skip auth in DEBUG mode for local development
"""
from __future__ import annotations

import os
from typing import Optional

from fastapi import Depends, HTTPException, WebSocket, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from loguru import logger

# ── Firebase Admin SDK ────────────────────────────────────────────────────────
try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth, credentials

    _SERVICE_ACCOUNT = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or os.getenv(
        "FIREBASE_SERVICE_ACCOUNT_PATH", "firebase-service-account.json"
    )
    _PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")

    if not firebase_admin._apps:
        try:
            cred = credentials.Certificate(_SERVICE_ACCOUNT)
            options = {"projectId": _PROJECT_ID} if _PROJECT_ID else {}
            firebase_admin.initialize_app(cred, options)
            logger.info("Firebase Admin SDK initialised from {}", _SERVICE_ACCOUNT)
        except Exception as exc:
            # Fallback: use Application Default Credentials (GCP environments)
            try:
                options = {"projectId": _PROJECT_ID} if _PROJECT_ID else {}
                firebase_admin.initialize_app(options=options if options else None)
                logger.info("Firebase Admin SDK initialised via Application Default Credentials")
            except Exception:
                logger.warning(
                    "Firebase Admin SDK could not be initialised: {}. "
                    "Auth will be DISABLED — do not run in production!",
                    exc,
                )

    _firebase_available = True
except ImportError:
    logger.error("firebase-admin not installed. Auth is disabled.")
    _firebase_available = False


# ── Token extractor ───────────────────────────────────────────────────────────
_bearer = HTTPBearer(auto_error=False)

DEBUG_MODE = os.getenv("DEBUG", "false").lower() == "true"


class AuthenticatedUser:
    """Minimal verified user identity extracted from Firebase token."""

    def __init__(self, uid: str, email: Optional[str] = None) -> None:
        self.uid = uid
        self.email = email

    def __repr__(self) -> str:
        return f"<AuthenticatedUser uid={self.uid}>"


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer),
) -> AuthenticatedUser:
    """
    FastAPI dependency — verifies Firebase ID token from Authorization header.

    Usage:
        @router.get("/protected")
        async def protected(user: AuthenticatedUser = Depends(get_current_user)):
            return {"uid": user.uid}

    In DEBUG mode, a missing/invalid token returns a stub user for local dev.
    """
    if DEBUG_MODE:
        # Development shortcut — accept any token or no token
        uid = "dev-user"
        if credentials:
            uid = credentials.credentials[:28] or "dev-user"
        logger.debug("Auth bypassed in DEBUG mode | uid={}", uid)
        return AuthenticatedUser(uid=uid)

    if not _firebase_available:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable.",
        )

    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header. Expected: Bearer <Firebase ID Token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        decoded = firebase_auth.verify_id_token(token, check_revoked=True)
        uid = decoded["uid"]
        email = decoded.get("email")
        logger.debug("Token verified | uid={}", uid)
        return AuthenticatedUser(uid=uid, email=email)
    except firebase_auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked. Please sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except firebase_auth.InvalidIdTokenError as exc:
        logger.warning("Invalid Firebase token: {}", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as exc:
        logger.error("Token verification failed: {}", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not verify credentials.",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def verify_websocket_token(websocket: WebSocket) -> Optional[AuthenticatedUser]:
    """
    Verify Firebase token for WebSocket connections.

    Flutter should pass the token as a query param:
        wss://api.example.com/ws/chat/{user_id}?token=<Firebase ID Token>

    Returns:
        AuthenticatedUser if token is valid, None otherwise.
    """
    if DEBUG_MODE:
        return AuthenticatedUser(uid=websocket.path_params.get("user_id", "dev-user"))

    token = websocket.query_params.get("token")
    if not token:
        return None

    try:
        decoded = firebase_auth.verify_id_token(token, check_revoked=True)
        return AuthenticatedUser(uid=decoded["uid"], email=decoded.get("email"))
    except Exception as exc:
        logger.warning("WebSocket token verification failed: {}", exc)
        return None

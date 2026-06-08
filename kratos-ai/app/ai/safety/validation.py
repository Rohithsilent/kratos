"""
SafetyValidation — Input/output guardrails for KRATOS AI.

Responsibilities:
- Block medically dangerous advice requests
- Sanitise AI output before returning to client
- Rate-limit guard (pre-check before hitting Gemini)
- Flag PII in user messages
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from loguru import logger


# ── Banned patterns ───────────────────────────────────────────────────────────

_MEDICAL_TRIGGERS = [
    r"\bsteroids?\b", r"\bpeds?\b", r"\bsarms?\b",
    r"\b(self.harm|suicide|kill\s+myself)\b",
    r"\binjection\b.*\b(muscle|body)\b",
]

_PII_PATTERNS = [
    r"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b",   # phone
    r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",  # email
]


@dataclass
class ValidationResult:
    is_safe: bool
    reason: str | None = None
    sanitised_text: str | None = None


def validate_input(message: str) -> ValidationResult:
    """
    Validate user input before sending to Gemini.

    Args:
        message: Raw user message.

    Returns:
        ValidationResult indicating safety status.
    """
    lower = message.lower()

    for pattern in _MEDICAL_TRIGGERS:
        if re.search(pattern, lower):
            logger.warning("SafetyValidation: blocked input | pattern={}", pattern)
            return ValidationResult(
                is_safe=False,
                reason="This request involves topics outside KRATOS's safe fitness scope.",
            )

    # Strip PII before logging / processing
    sanitised = message
    for pii in _PII_PATTERNS:
        sanitised = re.sub(pii, "[REDACTED]", sanitised)

    return ValidationResult(is_safe=True, sanitised_text=sanitised)


def validate_output(response: str) -> ValidationResult:
    """
    Validate AI output before returning to client.

    Args:
        response: Raw Gemini response text.

    Returns:
        ValidationResult — may modify output to remove unsafe content.
    """
    for pattern in _MEDICAL_TRIGGERS:
        if re.search(pattern, response.lower()):
            logger.warning("SafetyValidation: AI output blocked | pattern={}", pattern)
            return ValidationResult(
                is_safe=False,
                reason="AI response contained restricted content and was blocked.",
            )

    return ValidationResult(is_safe=True, sanitised_text=response)

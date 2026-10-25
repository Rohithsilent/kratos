# Deploy KRATOS AI with Azure for Students

This guide deploys only `kratos-ai`, the FastAPI/Gemini backend used by chat,
nutrition, meals, and WebSockets. The Razorpay webhook server remains the
separate `backend/` service; keep its HTTPS URL in the Flutter build define.

## Architecture and cost guardrails

Use one resource group in a nearby region that offers all three services:

```text
Flutter app ──HTTPS/WSS──> Azure Container Apps (0–1 replicas)
                                  │
                                  └──TLS──> Azure Database for PostgreSQL Flexible Server

GitHub Actions ──OIDC──> Azure Container Registry ──> Container Apps
```

Start with one Container App replica maximum, 0.5 vCPU and 1 GiB memory. Set
minimum replicas to `0` if cold starts are acceptable, or `1` if fast initial
chat/WebSocket connection matters more than cost. Do **not** create Azure Cache
for Redis at this stage: the backend has a bounded in-memory cache and local
rate limiter fallback.

Azure for Students credit and free-service allowances change, so check the
offer page before creating paid resources. A budget alerts you; it does not
stop services automatically. Delete the resource group when you no longer need
the deployment.

## Values to decide before starting

Choose unique lowercase names:

- `RESOURCE_GROUP`, for example `rg-kratos-prod`
- `LOCATION`, for example `centralindia` (use a region where Container Apps,
  ACR, and PostgreSQL are available)
- `ACR_NAME`, for example `kratosacr12345`
- `POSTGRES_SERVER`, for example `kratospg12345`
- `CONTAINER_APP_ENV`, for example `cae-kratos-prod`
- `CONTAINER_APP_NAME`, for example `kratos-ai`

Keep these **secret** values ready, but never commit them:

- PostgreSQL administrator password
- Gemini API key
- entire Firebase service-account JSON for the existing Firebase project

If `assets/.env` ever held a real Gemini key, rotate that key in Google AI
Studio. The Flutter release no longer bundles that file or any Gemini key.

## 1. Select the Azure for Students subscription and set a budget

In the Azure portal, confirm that **Azure for Students** is the active
subscription. Go to **Cost Management + Billing → Budgets**, create a monthly
budget for this resource group, and configure alerts at 50%, 75%, and 90%.

## 2. Create the resource group and registry

Install Azure CLI, sign in, and select the student subscription:

```bash
az login
az account set --subscription "Azure for Students"
az group create --name <RESOURCE_GROUP> --location <LOCATION>
az acr create --resource-group <RESOURCE_GROUP> --name <ACR_NAME> --sku Basic
```

`Basic` is sufficient for this single image repository. Record the registry
login server:

```bash
az acr show --resource-group <RESOURCE_GROUP> --name <ACR_NAME> --query loginServer -o tsv
```

## 3. Create PostgreSQL with TLS enabled

In the portal choose **Create a resource → Azure Database for PostgreSQL
flexible server**. Use the same resource group and region, PostgreSQL 16,
**Burstable B1ms**, 32 GiB storage, no high availability, and a strong unique
administrator password. Create a database named `kratos_ai`.

For the initial low-cost public-network deployment, add the PostgreSQL firewall
rule **Allow Azure services and resources to access this server**. This permits
Azure-hosted resources to connect; it does not expose the database username or
password. For a higher-security later phase, move the app and database into a
VNet/private endpoint.

Record the server hostname, which ends in
`.postgres.database.azure.com`. The app sets `POSTGRES_SSL=true`; do not turn
this off in Azure.

## 4. Build the container image

This build runs in Azure Container Registry, so Docker is not required locally:

```bash
az acr build \
  --registry <ACR_NAME> \
  --image kratos-ai:initial \
  --file kratos-ai/Dockerfile \
  kratos-ai
```

## 5. Create Container Apps environment and the app

Install the extension and create an environment:

```bash
az extension add --name containerapp --upgrade
az containerapp env create \
  --resource-group <RESOURCE_GROUP> \
  --name <CONTAINER_APP_ENV> \
  --location <LOCATION>
```

In the Azure portal, create a **Container App** in that environment. Select the
`kratos-ai:initial` image in your ACR and configure:

- Ingress: **External**, target port `8000`, transport **HTTP**.
- Scaling: minimum replicas `0` (or `1` for faster first requests), maximum
  replicas `1`.
- Resources: `0.5` vCPU and `1 GiB` memory.
- Probes: readiness and liveness use `GET /health` on port `8000`.
- Registry authentication: assign the Container App system-managed identity the
  **AcrPull** role on the registry, then select that identity for the registry.

Create these Container App secrets exactly as named:

```text
postgres-password              <PostgreSQL admin password>
gemini-api-key                 <Gemini API key>
firebase-service-account-json  <complete Firebase service-account JSON>
```

Then add these environment variables. Use a secret reference for the three
marked values:

```text
ENVIRONMENT=production
DEBUG=false
POSTGRES_HOST=<POSTGRES_SERVER>.postgres.database.azure.com
POSTGRES_PORT=5432
POSTGRES_DB=kratos_ai
POSTGRES_USER=<PostgreSQL admin username>
POSTGRES_PASSWORD=secretref:postgres-password
POSTGRES_SSL=true
GEMINI_API_KEY=secretref:gemini-api-key
FIREBASE_SERVICE_ACCOUNT_JSON=secretref:firebase-service-account-json
REDIS_URL=redis://localhost:6379/0
RUN_MIGRATIONS_ON_START=true
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=5
ALLOWED_ORIGINS=[]
```

For Flutter Web, replace the final value with a JSON array containing its exact
HTTPS origin, for example `["https://app.example.com"]`. Native Android/iOS
clients do not need a browser CORS origin.

After saving, open the Container App revision logs. It must show an Alembic
migration run, a PostgreSQL connection verification, and no Firebase warning.
Copy the application URL, then verify:

```bash
curl -fsS https://<CONTAINER_APP_FQDN>/health
```

The response must show `postgres: healthy`.

## 6. Configure GitHub Actions continuous deployment

Create an Entra application/service principal with a GitHub OIDC federated
credential scoped to this repository's `main` branch. Assign it **Contributor**
on this resource group. In GitHub, add these repository secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

Add these repository variables:

```text
AZURE_RESOURCE_GROUP
AZURE_ACR_NAME
AZURE_CONTAINER_APP_NAME
```

The committed workflow `.github/workflows/deploy-kratos-ai.yml` then builds in
ACR and deploys an image tagged with the immutable Git commit SHA every time
`main` changes under `kratos-ai/`. The Container App applies Alembic migrations
before accepting traffic.

## 7. Build the Flutter release against production URLs

Build without `assets/.env`. Pass only public values with Dart defines:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<CONTAINER_APP_FQDN> \
  --dart-define=RAZORPAY_BACKEND_URL=https://<YOUR_EXISTING_RAZORPAY_BACKEND> \
  --dart-define=RAZORPAY_KEY_ID=<RAZORPAY_PUBLIC_KEY_ID> \
  --dart-define=RAZORPAY_PLAN_PRO_MONTHLY=<PLAN_ID> \
  --dart-define=RAZORPAY_PLAN_PRO_YEARLY=<PLAN_ID> \
  --dart-define=RAZORPAY_PLAN_PREMIUM_MONTHLY=<PLAN_ID> \
  --dart-define=RAZORPAY_PLAN_PREMIUM_YEARLY=<PLAN_ID>
```

Never pass `GEMINI_API_KEY`, Razorpay key secret, webhook secret, PostgreSQL
password, or Firebase service-account JSON to a Flutter build.

## 8. Production acceptance checklist

- `GET /health` returns HTTP 200.
- Firebase-authenticated REST chat, chat WebSocket, and nutrition WebSocket all
  work through the public HTTPS/WSS URL.
- A meal write and read persists after a revision restart.
- A 5 MB + 1 byte image upload returns HTTP 413.
- Razorpay webhook is still configured to the separate payment backend and a
  test subscription updates Firestore once.
- Azure budget alerts are visible and the database/server password is stored
  only in Container Apps secrets.

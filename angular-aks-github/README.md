# Angular + AKS + GitHub Actions Starter

This starter project shows a **beginner-friendly** end-to-end setup for:

- Angular web application
- Docker image build
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)
- Helm deployment
- GitHub Actions parameterized deployment
- GitHub Environments and variables
- SonarQube integration
- Gitleaks integration
- Trivy integration
- Support for both:
  - **OIDC** (recommended, requires Microsoft Entra setup)
  - **Service Principal Secret** (practical fallback if you do not have Entra access)

---

## 1. Project structure

```text
.
├── .github/workflows/
│   ├── ci-security.yml
│   └── deploy-aks.yml
├── helm/angular-aks/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-delphi.yaml
│   └── templates/
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── scripts/
│   ├── create-azure-resources.sh
│   └── create-service-principal.sh
├── src/
│   ├── app/app.component.ts
│   ├── index.html
│   ├── main.ts
│   └── styles.css
├── .dockerignore
├── .gitignore
├── Dockerfile
├── angular.json
├── nginx.conf
├── package.json
├── sonar-project.properties
├── tsconfig.app.json
└── tsconfig.json
```

---

## 2. How the flow works

1. Developer pushes code to GitHub.
2. `ci-security.yml` runs:
   - Angular build
   - Gitleaks secret scan
   - Trivy filesystem scan
   - SonarQube analysis (if enabled)
3. `deploy-aks.yml` is started manually with parameters.
4. Workflow authenticates to Azure using:
   - `oidc`, or
   - `spn-secret`
5. Workflow builds Docker image and pushes it to ACR.
6. Workflow connects to AKS.
7. Workflow deploys the app using Helm.
8. AKS exposes the Angular app through a Kubernetes Service.

---

## 3. Important reality about OIDC in your case

If you **do not have Microsoft Entra access**, you usually **cannot create the app registration / federated credential by yourself**.

That means:

- You **can still implement the pipeline now** using **Service Principal Secret** mode.
- Later, when your Azure admin helps, you can switch to **OIDC** without changing the repo structure much.

So the practical plan is:

- **Now:** use `auth_mode = spn-secret`
- **Later:** switch to `auth_mode = oidc`

---

## 4. Prerequisites

You need these tools on your laptop (or use Azure Cloud Shell):

- Azure CLI
- Docker Desktop / Docker Engine
- kubectl
- Helm
- Git
- GitHub repository
- Azure subscription

---

## 5. Azure setup (Delphi environment)

In this sample, **Delphi** is treated as your deployment environment name.

Suggested naming:

- Resource Group: `rg-delphi-aks-demo`
- ACR: `acrdelphiaksdemo001`
- AKS: `aks-delphi-demo`
- Namespace: `angular-delphi`
- GitHub Environment: `delphi`

### Step 5.1 - Login to Azure

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### Step 5.2 - Create the resource group

```bash
az group create \
  --name rg-delphi-aks-demo \
  --location centralindia
```

### Step 5.3 - Create Azure Container Registry

```bash
az acr create \
  --resource-group rg-delphi-aks-demo \
  --name acrdelphiaksdemo001 \
  --sku Basic
```

### Step 5.4 - Create AKS and attach ACR

```bash
az aks create \
  --resource-group rg-delphi-aks-demo \
  --name aks-delphi-demo \
  --node-count 2 \
  --node-vm-size Standard_DS2_v2 \
  --generate-ssh-keys \
  --attach-acr acrdelphiaksdemo001
```

### Step 5.5 - Connect kubectl to AKS

```bash
az aks get-credentials \
  --resource-group rg-delphi-aks-demo \
  --name aks-delphi-demo \
  --overwrite-existing
```

### Step 5.6 - Verify cluster access

```bash
kubectl get nodes
```

---

## 6. GitHub repository setup

### Step 6.1 - Push this code to your GitHub repo

```bash
git init
git branch -M main
git remote add origin https://github.com/<your-org-or-user>/<your-repo>.git
git add .
git commit -m "Initial Angular AKS GitHub Actions starter"
git push -u origin main
```

### Step 6.2 - Enable GitHub Actions

In GitHub:

- Open repository
- Go to **Settings > Actions > General**
- Allow GitHub Actions if disabled

### Step 6.3 - Create GitHub environment

In GitHub:

- Go to **Settings > Environments**
- Create environment: `delphi`

Optional beginner-safe protections:

- Required reviewers = 1
- Deployment branches = `main`

---

## 7. GitHub variables and secrets

### 7.1 Repository or environment variables

Create these under:

- **Settings > Secrets and variables > Actions > Variables**
- or under environment `delphi`

Recommended variables:

| Name | Example |
|---|---|
| `AZURE_LOCATION` | `centralindia` |
| `ACR_NAME` | `acrdelphiaksdemo001` |
| `ACR_LOGIN_SERVER` | `acrdelphiaksdemo001.azurecr.io` |
| `AKS_RESOURCE_GROUP` | `rg-delphi-aks-demo` |
| `AKS_CLUSTER_NAME` | `aks-delphi-demo` |
| `IMAGE_REPOSITORY` | `angular-aks-app` |
| `HELM_CHART_PATH` | `./helm/angular-aks` |
| `SONAR_ENABLED` | `false` or `true` |
| `SONAR_HOST_URL` | `https://sonarqube.example.com` |

### 7.2 Secrets for Service Principal Secret mode

Create these secrets:

| Secret | Description |
|---|---|
| `AZURE_CREDENTIALS` | JSON consumed by the deploy workflow for Azure and AKS settings |

Example value for `AZURE_CREDENTIALS`:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "resourceGroup": "rg-delphi-aks-demo",
  "aksClusterName": "aks-delphi-demo",
  "aksNamespace": "angular-delphi",
  "acrName": "acrdelphiaksdemo001",
  "acrLoginServer": "acrdelphiaksdemo001.azurecr.io",
  "helmReleaseName": "angular-delphi",
  "imageName": "angular-aks-app"
}
```

`acrLoginServer` is optional in the deploy workflow. When present, the workflow validates it against the real login server returned by Azure and uses the Azure-resolved value.

### 7.3 Secrets for OIDC mode

Create these secrets:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App registration / workload identity client ID |
| `AZURE_TENANT_ID` | Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

### 7.4 Secrets for SonarQube

| Secret | Description |
|---|---|
| `SONAR_TOKEN` | SonarQube token |

If you use self-hosted SonarQube Server, store `SONAR_HOST_URL` as a variable.

---

## 8. Service Principal Secret mode (recommended for your current access level)

If you **do not have Entra access**, ask your Azure admin to run the script in:

```text
scripts/create-service-principal.sh
```

That script creates a service principal and then assigns:

- `AcrPush` on ACR
- `Azure Kubernetes Service Cluster Admin Role` on the AKS cluster

After that, the admin gives you the JSON for `AZURE_CREDENTIALS`.

Then your GitHub workflow can deploy without OIDC.

### Deploy using Service Principal Secret

Go to GitHub:

- **Actions > Deploy Angular to AKS**
- Click **Run workflow**
- Use:
  - `environment_name = delphi`
  - `auth_mode = spn-secret`
  - `namespace = angular-delphi`
  - `replica_count = 2`

---

## 9. OIDC mode (for later, when admin support is available)

OIDC is more secure because GitHub does not store a long-lived Azure secret.

### Admin-side OIDC setup summary

Your Azure admin needs to do this:

1. Create or identify an app registration / service principal.
2. Assign required Azure roles.
3. Add a **Federated Credential** for GitHub Actions.
4. Give you:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

### Deploy using OIDC

Use the same GitHub workflow with:

- `auth_mode = oidc`

---

## 10. SonarQube setup

### Option A - easiest
Use an existing SonarQube server from your organization.

### Option B - self-hosted later
You can host SonarQube separately, but that is outside this starter repo.

### Minimum SonarQube steps

1. Create a project in SonarQube.
2. Generate a token.
3. Add GitHub secret:
   - `SONAR_TOKEN`
4. Add variable:
   - `SONAR_HOST_URL`
5. Set variable:
   - `SONAR_ENABLED = true`

---

## 11. Run locally

### Step 11.1 - Install packages

```bash
npm install
```

### Step 11.2 - Run Angular app

```bash
npm start
```

Open:

```text
http://localhost:4200
```

### Step 11.3 - Build production output

```bash
npm run build
```

---

## 12. Run Docker locally

### Build image

```bash
docker build -t angular-aks-app:local .
```

### Run container

```bash
docker run -d -p 8080:80 angular-aks-app:local
```

Open:

```text
http://localhost:8080
```

---

## 13. Manual Helm deployment from laptop

If you want to test deployment manually before GitHub Actions:

```bash
helm upgrade --install angular-delphi ./helm/angular-aks \
  --namespace angular-delphi \
  --create-namespace \
  --set image.repository=acrdelphiaksdemo001.azurecr.io/angular-aks-app \
  --set image.tag=local \
  --set replicaCount=2 \
  -f ./helm/angular-aks/values-delphi.yaml
```

Check status:

```bash
kubectl get all -n angular-delphi
kubectl get svc -n angular-delphi
```

---

## 14. How to get the application URL

Because the Helm chart uses a `LoadBalancer` service by default:

```bash
kubectl get svc -n angular-delphi
```

Look for the **EXTERNAL-IP** column.

Open:

```text
http://<EXTERNAL-IP>
```

---

## 15. Common beginner issues

### Problem: OIDC fails
Cause:
- No federated credential
- Wrong client / tenant / subscription values
- Missing `id-token: write` permission in workflow

Fix:
- Use `spn-secret` first
- Ask admin to configure OIDC later

### Problem: AKS deployment fails after login
Cause:
- Service principal has no AKS access

Fix:
- Ask admin to assign `Azure Kubernetes Service Cluster Admin Role` on the AKS cluster

### Problem: Docker push fails
Cause:
- Service principal has no ACR push rights

Fix:
- Ask admin to assign `AcrPush` role on ACR

### Problem: SonarQube step fails
Cause:
- Token missing
- Wrong `SONAR_HOST_URL`
- Project not created in SonarQube

Fix:
- Temporarily set `SONAR_ENABLED = false`

### Problem: Service external IP is pending
Cause:
- Azure LoadBalancer provisioning not finished yet

Fix:
- Wait a little and run:

```bash
kubectl get svc -n angular-delphi -w
```

---

## 16. Recommended learning order

If you are a beginner, do it in this order:

1. Run Angular locally
2. Build Docker image locally
3. Create ACR
4. Create AKS
5. Connect kubectl to AKS
6. Push image to ACR manually
7. Deploy with Helm manually
8. Add GitHub variables/secrets
9. Run GitHub deploy workflow with `spn-secret`
10. Enable SonarQube
11. Later upgrade to OIDC

---

## 17. First successful demo target

Your first goal should be only this:

- GitHub repo has code
- GitHub workflow runs successfully
- Docker image is pushed to ACR
- Helm deploys to AKS
- App opens through the AKS public IP

Once that works, harden it later.

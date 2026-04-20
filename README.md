# 10Alytics DevOps Assessment

A complete CI/CD pipeline deploying a Python Flask application to Azure
using GitHub Actions and Terraform.

## Architecture

Developer Push → GitHub → GitHub Actions (CI)
→ Lint + Test → Terraform Apply
→ Azure App Service + Azure SQL DB
→ Deploy Flask App → Health Check

## Stack

| Tool | Purpose |
|---|---|
| GitHub Actions | CI/CD pipeline automation |
| Terraform | Infrastructure as Code |
| Azure App Service | Managed Python hosting |
| Azure SQL Database | Managed relational database |
| Flask | Lightweight Python web framework |

## Repository Structure
10alytics-devops-assessment/
├── .github/workflows/
│   ├── terraform-plan.yml   # Runs on PRs — validates infra changes
│   └── deploy-app.yml       # Runs on main push — full deploy
├── terraform/
│   ├── main.tf              # Core infrastructure
│   ├── variables.tf         # Input variables
│   ├── backend.tf           # Remote state configuration
│   └── outputs.tf           # App URL and name exports
├── app/
│   ├── app.py               # Flask application
│   ├── requirements.txt     # Python dependencies
│   └── tests/
│       └── test_app.py      # Pytest test suite
└── README.md

## Required GitHub Secrets

| Secret | Purpose |
|---|---|
| `AZURE_USERNAME` | Azure account email |
| `AZURE_PASSWORD` | Azure account password |
| `ARM_ACCESS_KEY` | Terraform state storage key |
| `DB_ADMIN` | SQL Server admin username |
| `DB_PASSWORD` | SQL Server admin password |
| `AZURE_WEBAPP_PUBLISH_PROFILE` | App Service publish profile XML |

## Pipeline Flow

1. **Lint and test** — flake8 + pytest run on every push to main
2. **Provision** — Terraform provisions App Service and SQL DB
3. **Deploy** — App package deployed via publish profile
4. **Verify** — Health endpoint polled until 200 OK

## Setup Instructions

### 1. Provision Terraform state storage (once only)

```bash
az group create --name rg-tfstate --location francecentral
az storage account create \
  --name tfstate10alytics \
  --resource-group rg-tfstate \
  --location francecentral \
  --sku Standard_LRS
az storage container create \
  --name tfstate \
  --account-name tfstate10alytics
```

### 2. Add GitHub Secrets

Add all secrets listed above under Settings → Secrets and variables → Actions.

### 3. Push to main

```bash
git add .
git commit -m "Initial pipeline setup"
git push origin main
```

### 4. Add publish profile (after first deploy)

- Go to Azure Portal → App Service → Get publish profile
- Copy the XML content
- Add as `AZURE_WEBAPP_PUBLISH_PROFILE` secret in GitHub

## Verify Deployment

```bash
curl https://<app-url>/health
```

Expected response:

```json
{
  "status": "ok",
  "checks": { "database": "configured" },
  "environment": "dev"
}
```

## Security Decisions

- No secrets stored in code — all injected via GitHub Secrets
- HTTPS enforced on App Service
- SQL firewall allows Azure services only
- Terraform state stored remotely with access key auth
- Tests must pass before infrastructure is touched
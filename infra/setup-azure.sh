#!/usr/bin/env bash
# One-time Azure setup for the demo: resource group, Container Apps environment,
# two apps (staging + production) and a GitHub OIDC identity (no stored secrets).
#
# Prerequisites: Azure CLI logged in (az login) to a subscription you own, and
# permission to create app registrations in your Entra ID tenant.
#
# Usage:  GITHUB_REPO=<owner>/<repo> bash infra/setup-azure.sh
#
# NOTE: written against the az CLI docs but not run against a live subscription
# by the author. Read it first and expect to adjust names/locations.
# Cost: Container Apps can scale to zero; still delete the resource group when done:
#   az group delete --name "$RG" --yes
set -euo pipefail

: "${GITHUB_REPO:?set GITHUB_REPO=<owner>/<repo>}"
LOCATION="${LOCATION:-centralindia}"
RG="${RG:-rg-two-click-demo}"
ENV_NAME="${ENV_NAME:-cae-two-click-demo}"
APP="${APP:-twoclick}"
PLACEHOLDER_IMAGE="${PLACEHOLDER_IMAGE:-mcr.microsoft.com/k8se/quickstart:latest}"

az extension add --name containerapp --upgrade --only-show-errors
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

az group create --name "$RG" --location "$LOCATION" >/dev/null
az containerapp env create --name "$ENV_NAME" --resource-group "$RG" --location "$LOCATION" >/dev/null

for STAGE in staging production; do
  az containerapp create \
    --name "${APP}-${STAGE}" \
    --resource-group "$RG" \
    --environment "$ENV_NAME" \
    --image "$PLACEHOLDER_IMAGE" \
    --target-port 8000 \
    --ingress external \
    --min-replicas 0 --max-replicas 1 \
    --env-vars "APP_ENV=${STAGE}" >/dev/null
done

# GitHub -> Azure login through OIDC federation (no client secret to leak)
APP_ID="$(az ad app create --display-name "gh-${APP}-deployer" --query appId -o tsv)"
az ad sp create --id "$APP_ID" >/dev/null
SUB_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

# Least privilege: Contributor on this one resource group only
az role assignment create \
  --assignee "$APP_ID" --role Contributor \
  --scope "/subscriptions/${SUB_ID}/resourceGroups/${RG}" >/dev/null

for ENVIRONMENT in staging production; do
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"gh-${ENVIRONMENT}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_REPO}:environment:${ENVIRONMENT}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" >/dev/null
done

cat <<EOF

Done. In GitHub: Settings -> Secrets and variables -> Actions -> Variables, add:
  AZURE_DEPLOY          true
  AZURE_CLIENT_ID       ${APP_ID}
  AZURE_TENANT_ID       ${TENANT_ID}
  AZURE_SUBSCRIPTION_ID ${SUB_ID}
  AZURE_RESOURCE_GROUP  ${RG}
  APP_NAME              ${APP}

Then: Settings -> Environments -> create 'staging' and 'production';
on 'production' enable "Required reviewers" and add yourself.
EOF

#!/usr/bin/env bash
set -euo pipefail

# This script should be run by an Azure admin or a user with permission
# to create service principals and assign Azure RBAC roles.

SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"
RESOURCE_GROUP="rg-delphi-aks-demo"
AKS_NAME="aks-delphi-demo"
ACR_NAME="acrdelphiaksdemo001"
SP_NAME="gh-angular-aks-delphi-$(date +%s)"

az login
az account set --subscription "$SUBSCRIPTION_ID"

AKS_ID=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --query id -o tsv)
ACR_ID=$(az acr show --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --query id -o tsv)

SP_JSON=$(az ad sp create-for-rbac --name "$SP_NAME" --skip-assignment)
APP_ID=$(echo "$SP_JSON" | jq -r '.appId')
PASSWORD=$(echo "$SP_JSON" | jq -r '.password')
TENANT_ID=$(echo "$SP_JSON" | jq -r '.tenant')

az role assignment create \
  --assignee "$APP_ID" \
  --role AcrPush \
  --scope "$ACR_ID"

az role assignment create \
  --assignee "$APP_ID" \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --scope "$AKS_ID"

cat <<JSON
{
  "clientId": "$APP_ID",
  "clientSecret": "$PASSWORD",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}
JSON

# #!/usr/bin/env bash
# set -euo pipefail

# # Update these values before running.
# SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"
# LOCATION="centralindia"
# RESOURCE_GROUP="rg-delphi-aks-demo"
# ACR_NAME="acrdelphiaksdemo001"
# AKS_NAME="aks-delphi-demo"

# az login
# az account set --subscription "$SUBSCRIPTION_ID"

# az group create \
#   --name "$RESOURCE_GROUP" \
#   --location "$LOCATION"

# az acr create \
#   --resource-group "$RESOURCE_GROUP" \
#   --name "$ACR_NAME" \
#   --sku Basic

# az aks create \
#   --resource-group "$RESOURCE_GROUP" \
#   --name "$AKS_NAME" \
#   --node-count 2 \
#   --node-vm-size Standard_DS2_v2 \
#   --generate-ssh-keys \
#   --attach-acr "$ACR_NAME"

# az aks get-credentials \
#   --resource-group "$RESOURCE_GROUP" \
#   --name "$AKS_NAME" \
#   --overwrite-existing

# kubectl get nodes

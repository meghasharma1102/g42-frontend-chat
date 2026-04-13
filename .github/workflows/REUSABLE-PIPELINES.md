# Reusable Pipeline Guide

This repository now contains two reusable workflows:

- `reusable-ci-security.yml`
- `reusable-deploy-aks.yml`

## Why `actions/setup-node@v4` is not a folder in your repo

- `actions/setup-node@v4` is an official action from GitHub Marketplace.
- It is downloaded at runtime by GitHub Actions.
- So you will not see it as a local folder in your repository.
- You can still see it in workflow logs as a step when the workflow runs.

The reusable workflow files are now configured with both:

- `workflow_call` (for sharing/reuse)
- `workflow_dispatch` (so they appear and can be run manually from the Actions tab)

If you want a local folder action example, this repo now includes:

- `.github/actions/setup-node-wrapper/action.yml`

Usage inside a workflow step:

```yaml
- name: Setup Node via local wrapper
  uses: ./.github/actions/setup-node-wrapper
  with:
    node-version: '20'
```

## Use in another repository

Create workflow files in the target repository and call these reusable workflows by reference:

```yaml
name: Shared CI Security

on:
  workflow_dispatch:

jobs:
  validate:
    uses: <ORG_OR_USER>/g42-frontend-chat/.github/workflows/reusable-ci-security.yml@main
    with:
      project_directory: .
      node_version: '20'
      enable_sonar: true
      runner_labels: '["self-hosted","Linux","X64"]'
    secrets: inherit
```

```yaml
name: Shared Deploy to AKS

on:
  workflow_dispatch:
    inputs:
      image_tag:
        description: Docker image tag
        required: true
        default: v1
        type: string
      replica_count:
        description: Pod replicas
        required: true
        default: '1'
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    uses: <ORG_OR_USER>/g42-frontend-chat/.github/workflows/reusable-deploy-aks.yml@main
    with:
      project_directory: .
      environment_name: dev
      image_tag: ${{ inputs.image_tag }}
      replica_count: ${{ inputs.replica_count }}
      helm_chart_path: ./helm/angular-aks
      helm_values_file: ./helm/angular-aks/values.yaml
      enable_sonar: false
      runner_labels: '["self-hosted","Linux","X64"]'
    secrets: inherit
```

## Required secrets for deploy workflow

- `AZURE_CREDENTIALS` (JSON with `clientId`, `tenantId`, `subscriptionId`, `resourceGroup`, `aksClusterName`, `aksNamespace`, `acrName`, `acrLoginServer`, `helmReleaseName`, `imageName`)
- `SONAR_TOKEN` and `SONAR_HOST_URL` only when `enable_sonar: true`

# Getting started with terraform

## Set up Terraform to access Azure

```Azure CLI

az account show --query "{subscriptionId:id, tenantId:id}"

```

## Export SUBSCRIPTION_ID as environemnt variable

```bash

EXPORT SUBSCRIPTION_ID=<<replace with subscription id>>

```

## Create Service principle to work with Terraform

```Azure CLI

az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"

```


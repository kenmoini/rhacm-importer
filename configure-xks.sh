#!/bin/bash

# This script is used to configure an xKS cluster (EKS, GKE, AKS, etc.) for use 
#  with Red Hat Advanced Cluster Management for Kubernetes.
# All that is required is a pull secret for images from the Red Hat Registry, 
#  which can be obtained from https://console.redhat.com/openshift/downloads

# This script assumes that:
# 1. The Pull Secret is stored in a file called rh-pull-secret.json that is 
#    stored in the same directory as where this is being executed.
#    Otherwise, you can point it to a different location by setting the
#    RH_PULL_SECRET_FILE environment variable.

# 2. You are already authenticated to an xKS cluster and have kubectl.
#    Super simple via their Web Consoles.

export RH_PULL_SECRET_FILE=${RH_PULL_SECRET_FILE:-rh-pull-secret.json}

# Detect the current kubernetes context
export KUBE_CONTEXT=$(kubectl config current-context)
echo "Detected Kubernetes context: $KUBE_CONTEXT"

# Prompt to continue or not
read -p "Continue? (y/N) " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "\nExiting"
    exit 1
fi

echo -e "\nStarting to configure the cluster for ACM..."

# Create namespaces
echo -e "\nCreating namespaces..."
for NS in rhacm-connector open-cluster-management-agent open-cluster-management-agent-addon open-cluster-management-addon-observability open-cluster-management-agent-observability
do
    kubectl create namespace $NS
done

# Create needed Service Accounts
echo -e "\nCreating service accounts..."
kubectl create serviceaccount rhacm-connector -n rhacm-connector
kubectl create serviceaccount klusterlet -n open-cluster-management-agent
kubectl create serviceaccount klusterlet-work-sa -n open-cluster-management-agent
kubectl create serviceaccount klusterlet-registration-sa -n open-cluster-management-agent
kubectl create serviceaccount endpoint-observability-operator-sa -n open-cluster-management-addon-observability
kubectl create serviceaccount cluster-proxy -n open-cluster-management-agent-addon

# Create Image Pull Secret
echo -e "\nCreating image pull secret..."
for NS in open-cluster-management-agent open-cluster-management-agent-addon open-cluster-management-addon-observability open-cluster-management-agent-observability
do
    kubectl create secret docker-registry open-cluster-management-image-pull-credentials --from-file=.dockerconfigjson=${RH_PULL_SECRET_FILE} -n $NS
done

# Patch Service Accounts to use Image Pull Secret
echo -e "\nPatching service accounts to use image pull secret..."
kubectl patch serviceaccount default -n open-cluster-management-agent --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'
kubectl patch serviceaccount klusterlet -n open-cluster-management-agent --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'
kubectl patch serviceaccount klusterlet-registration-sa -n open-cluster-management-agent --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'
kubectl patch serviceaccount klusterlet-work-sa -n open-cluster-management-agent --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'
kubectl patch serviceaccount default -n open-cluster-management-addon-observability --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'
kubectl patch serviceaccount default -n open-cluster-management-agent --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'
kubectl patch serviceaccount default -n open-cluster-management-agent --type "json" -p '[{"op":"add","path":"/imagePullSecrets","value":[{"name": "open-cluster-management-image-pull-credentials"}]}]'

# Apply the ClusterRoleBinding for the rhacm-connector SA
echo -e "\nCreating rhacm-importer ClusterRoleBinding..."
kubectl create clusterrolebinding rhacm-connector-binding --clusterrole=cluster-admin --serviceaccount=rhacm-connector:rhacm-connector

# Get the Cluster API Endpoint
API_ENDPOINT=$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")

# Create a Token Secret
echo -e "\nCreating token secret..."
kubectl apply -n rhacm-connector -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: rhacm-connector-token
  annotations:
    kubernetes.io/service-account.name: rhacm-connector
type: kubernetes.io/service-account-token
EOF

# Get the ServiceAccount token for the rhacm-connector SA
echo -e "\nGetting rhacm-connector SA token...\n"
SA_TOKEN=$(kubectl -n rhacm-connector get secret rhacm-connector-token -o jsonpath='{.data.token}' | base64 -d)

echo -e "\nAPI Server: $API_ENDPOINT"
echo -e "\nToken: $SA_TOKEN"

echo -e "\nDone!"
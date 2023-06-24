#!/bin/bash

# This script will remove all of the resources created by RHACM on a cluster.
# NOTE: It will not remove it as a ManagedCluster on the management hub cluster that RHACM is running on.

export KUBE_CONTEXT=$(kubectl config current-context)
echo "Detected Kubernetes context: $KUBE_CONTEXT"

# Prompt to continue or not
read -p "Continue? (y/N) " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "\nExiting"
    exit 1
fi

echo -e "\nStarting to remove RHACM resources from the cluster..."

echo -e "\nDeleting namespaces..."
for NS in rhacm-connector open-cluster-management-agent open-cluster-management-agent-addon open-cluster-management-addon-observability open-cluster-management-agent-observability
do
    kubectl delete namespace $NS
done

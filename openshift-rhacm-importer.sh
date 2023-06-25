#!/bin/bash

# This script simply uses openshift-rhacm-importer.yaml to create the resources
#  on an OpenShift cluster to be imported into Red Hat Advanced Cluster Management for Kubernetes
#  and then returns the API Endpoint and ServiceAccount Token that can be used to import the cluster.

# Check to see if we're logged into a cluster
LOGIN_CHECK=$(oc whoami 2>&1 | grep "error" | wc -l)

if [[ $LOGIN_CHECK -ne 0 ]]
then
    echo "Please login to an OpenShift cluster before running this script."
    exit 1
fi

# Get the API Endpoint
API_ENDPOINT=$(oc whoami --show-server)

# Apply the openshift-rhacm-importer.yaml file
echo "Creating import resources..."
oc apply -f openshift-rhacm-importer.yaml

SA_TOKEN=$(oc -n kube-system get secret $(kubectl -n kube-system get serviceaccount/mcm-cluster-importer -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)

echo -e "\nDone!  Use the following to import the cluster into Red Hat Advanced Cluster Management for Kubernetes:"

echo -e "\nAPI Endpoint: $API_ENDPOINT"
echo -e "\nToken:\n\n"
echo $SA_TOKEN

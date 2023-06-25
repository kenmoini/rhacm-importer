#!/bin/bash

# This script is used to create a GKE cluster for use with Red Hat Advanced Cluster Management for Kubernetes.

export GCP_PROJECT=${GCP_PROJECT:-SET-A-PROJECT-NAME}
export GKE_CLUSTER_NAME=${GKE_CLUSTER_NAME:-my-gke-cluster}
export GKE_CLUSTER_REGION=${GKE_CLUSTER_REGION:-us-central1}
export GKE_CLUSTER_LOCATION=${GKE_CLUSTER_LOCATION:-us-central1-c}
export GKE_CLUSTER_NODE_COUNT=${GKE_CLUSTER_NODE_COUNT:-3}
export GKE_CLUSTER_NODE_TYPE=${GKE_CLUSTER_NODE_TYPE:-e2-standard-8}
export GKE_VPC_NAME=${GKE_VPC_NAME:-gke-vpc}

if [[ $GCP_PROJECT == "SET-A-PROJECT-NAME" ]]
then
    echo "Please set the GCP_PROJECT environment variable to the name of your GCP project."
    exit 1
fi

# Enable the GKE API
echo "Enabling the GKE API..."
gcloud services enable container.googleapis.com

# Create a VPC if it does not exist
VPC_CHECK=$(gcloud compute networks list | grep "NAME: ${GKE_VPC_NAME}" | wc -l)
if [[ $VPC_CHECK -eq 0 ]]
then
    echo "Creating VPC..."
    gcloud compute networks create ${GKE_VPC_NAME} --project=${GCP_PROJECT} --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional
else
    echo "VPC already exists..."
fi

# Create the GKE cluster if it does not exist
CLUSTER_CHECK=$(gcloud container clusters list | grep "${GKE_CLUSTER_NAME}" | wc -l)
if [[ $CLUSTER_CHECK -eq 0 ]]
then
    echo "Creating GKE cluster..."

    gcloud beta container --project "${GCP_PROJECT}" clusters create "${GKE_CLUSTER_NAME}" \
      --zone "${GKE_CLUSTER_LOCATION}" --cluster-version "1.25.8-gke.1000" --release-channel "regular" \
      --node-locations "${GKE_CLUSTER_LOCATION}" --machine-type "${GKE_CLUSTER_NODE_TYPE}" --num-nodes "${GKE_CLUSTER_NODE_COUNT}" \
      --network "projects/${GCP_PROJECT}/global/networks/${GKE_VPC_NAME}" \
      --subnetwork "projects/${GCP_PROJECT}/regions/${GKE_CLUSTER_REGION}/subnetworks/${GKE_VPC_NAME}" \
      --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" \
      --metadata disable-legacy-endpoints=true --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM \
      --default-max-pods-per-node "110" --security-posture=standard --workload-vulnerability-scanning=disabled \
      --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
      --enable-ip-alias --no-enable-intra-node-visibility \
      --no-enable-master-authorized-networks --enable-autoupgrade --enable-autorepair \
      --no-enable-managed-prometheus --enable-shielded-nodes --no-enable-basic-auth \
      --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
      --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append"
else
    echo "GKE cluster already exists..."
    exit 1
fi
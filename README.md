# RHACM Importer

This repository has a few helpful scripts that can be used to connect an OpenShift or other xKS (EKS, AKS, GKE, etc) cluster to Red Hat Advanced Cluster Management for Kubernetes.

The primary script, `configure-xks.sh` will configure an active Kubernetes context with all the needed Namespaces, ServiceAccounts, and Image Pull Secrets needed to connect to RHACM.  All that is required is the creation of a JSON file holding your Red Hat Registry Pull Secret.

There are additional scripts such as `create-gke-cluster.sh` that can be used to quickly create a GKE cluster for testing with RHACM.  There is also a `openshift-rhacm-importer.sh` and paired `openshift-rhacm-importer.yaml` files that can be applied to any Red Hat OpenShift cluster to quickly and easily import an OpenShift cluster into RHACM via an API/Token combination.

## Prerequisites

1. A Kubernetes/OpenShift Cluster or few
2. A Red Hat Registry Image Pull Secret: https://console.redhat.com/openshift/downloads

## Usage - configure-xks.sh

Assuming you're running this out of a Cloud Shell, all that you need to do is authenticate to an xKS cluster, create a file for the Image Pull Secret, and run the script:

1. Log into your Cloud Shell, or use your terminal if it's configured to connect to your xKS cluster
2. Authenticate to your xKS cluster
3. Create the Image Pull Secret file in your current directory `rh-pull-secret.json`
4. Run the script: `curl -sSL https://raw.githubusercontent.com/kenmoini/rhacm-importer/main/configure-xks.sh | bash -`

If you placed the Red Hat Registry Pull Secret in an alternative location, you can export the `RH_PULL_SECRET_FILE` environmental variable defining that path before running the script: `export RH_PULL_SECRET_FILE="/path/to/pull-secret.json`

## Usage - openshift-rhacm-importer.sh

If you're importing an existing OpenShift cluster into RHACM you can do so by running some huge copy/paste commaned that fails on most shells, paste in a kubeadmin file, or point it to an API endpoint with a Token to access it - `openshift-rhacm-importer.{sh,yaml}` help you do that last one.

Applying the YAML will create all the resources needed to do an API/Token import, but running the Bash script will apply the YAML and give you the API endpoint and Token as output.

```bash
# Log into the cluster
oc login ...

# Run the script while online
curl -sSL https://raw.githubusercontent.com/kenmoini/rhacm-importer/main/openshift-rhacm-importer.sh | bash -

# Or if needing to do it "offline"

# Clone the repo
git clone https://github.com/kenmoini/rhacm-importer.git

# Run the script
./rhacm-importer/openshift-rhacm-importer.sh offline
```

## Usage - Create GKE Cluster

In case you need a quick GKE cluster to test this against, you can run a script to create a GKE cluster.

```bash
# Export the GCP project name
export GCP_PROJECT="YOUR_PROJECT_NAME"

# Run the creation script - compatible with RHDP GKE Open Environments
curl -sSL https://raw.githubusercontent.com/kenmoini/rhacm-importer/main/create-gke-cluster.sh | bash -
```

There are some additional variables that can be set to alter the behavior of the script before running it:

```bash
# Below are the defaults set in the script

export GCP_PROJECT="SET-A-PROJECT-NAME"
export GKE_VPC_NAME="gke-vpc"
export GKE_CLUSTER_NAME="my-gke-cluster"
export GKE_CLUSTER_REGION="us-central1"
export GKE_CLUSTER_LOCATION="us-central1-c"
export GKE_CLUSTER_NODE_COUNT="3"
export GKE_CLUSTER_NODE_TYPE="e2-standard-8"
```

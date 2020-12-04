#!/usr/bin/env bash

set -eo pipefail

kindVersion=$(kind version);

if [[ $kindVersion =~ "v0.9." ]]
then
   echo "KinD version is ${kindVersion}"
else
  echo "Please make sure you are using KinD v0.9.0 or update the node_image"
  exit 0
fi

REPLY=continue
KIND_EXIST="$(kind get clusters -q | grep knative || true)"
if [[ ${KIND_EXIST} ]] ; then
 read -p "Knative Cluster kind-knative already installed, delete and re-create? N/y: " REPLY </dev/tty
fi
if [ "$REPLY" == "Y" ] || [ "$REPLY" == "y" ]; then
  kind delete cluster --name knative
elif [ "$REPLY" == "N" ] || [ "$REPLY" == "n" ] || [ -z "$REPLY" ]; then
  echo "Installation skipped"
  exit 0
fi

KIND_CLUSTER=$(mktemp)
cat <<EOF | kind create cluster --name knative --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.19.4
  extraPortMappings:
  - containerPort: 31080 # expose port 31380 of the node to port 80 on the host, later to be use by kourier ingress
    hostPort: 80
EOF
echo "Waiting on cluster to be ready"
sleep 10
until kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kube-system
do
   kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kube-system
done

#!/usr/bin/env bash

set -eo pipefail

kindVersion=$(kind version);
K8S_VERSION=${k8sVersion:-v1.20.2@sha256:15d3b5c4f521a84896ed1ead1b14e4774d02202d5c65ab68f30eeaf310a3b1a7}

if [[ $kindVersion =~ "v0.10." ]]
then
   echo "KinD version is ${kindVersion}"
else
  echo "Please make sure you are using KinD v0.10.x, download from https://github.com/kubernetes-sigs/kind/releases"
  exit 1
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
  image: kindest/node:${K8S_VERSION}
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

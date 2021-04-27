#!/usr/bin/env bash

set -eo pipefail

kindVersion=$(kind version);
K8S_VERSION=${k8sVersion:-v1.20.2@sha256:15d3b5c4f521a84896ed1ead1b14e4774d02202d5c65ab68f30eeaf310a3b1a7}
CLUSTER_NAME=${KIND_CLUSTER_NAME:-knative}

echo "KinD version is ${kindVersion}"
if [[ ! $kindVersion =~ "v0.10." ]]; then
  echo "WARNING: Please make sure you are using KinD version v0.10.x, download from https://github.com/kubernetes-sigs/kind/releases"
  echo "For example if using brew, run: brew upgrade kind"
  read -p "Do you want to continue on your own risk? Y/n: " REPLYKIND </dev/tty
  if [ "$REPLYKIND" == "Y" ] || [ "$REPLYKIND" == "y" ] || [ -z "$REPLYKIND" ]; then
    echo "You are very brave..."
    sleep 2
  elif [ "$REPLYKIND" == "N" ] || [ "$REPLYKIND" == "n" ]; then
    echo "Installation stopped, please upgrade kind and run again"
    exit 0
  fi
fi

REPLY=continue
KIND_EXIST="$(kind get clusters -q | grep ${CLUSTER_NAME} || true)"
if [[ ${KIND_EXIST} ]] ; then
 read -p "Knative Cluster kind-${CLUSTER_NAME} already installed, delete and re-create? N/y: " REPLY </dev/tty
fi
if [ "$REPLY" == "Y" ] || [ "$REPLY" == "y" ]; then
  kind delete cluster --name ${CLUSTER_NAME}
elif [ "$REPLY" == "N" ] || [ "$REPLY" == "n" ] || [ -z "$REPLY" ]; then
  echo "Installation skipped"
  exit 0
fi

KIND_CLUSTER=$(mktemp)
cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:${K8S_VERSION}
  extraPortMappings:
  - containerPort: 31080 # expose port 31380 of the node to port 80 on the host, later to be use by kourier ingress
    listenAddress: 127.0.0.1
    hostPort: 80
EOF
echo "Waiting on cluster to be ready"
sleep 10
until kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kube-system
do
   kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kube-system
done

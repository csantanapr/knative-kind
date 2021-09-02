#!/usr/bin/env bash

set -eo pipefail

kindVersion=$(kind version);
K8S_VERSION=${k8sVersion:-v1.21.1@sha256:69860bda5563ac81e3c0057d654b5253219618a22ec3a346306239bba8cfa1a6}
CLUSTER_NAME=${KIND_CLUSTER_NAME:-knative}
KIND_VERSION=${KIND_VERSION:-v0.11}

echo "KinD version is ${kindVersion}"
if [[ ! $kindVersion =~ "${KIND_VERSION}." ]]; then
  echo "WARNING: Please make sure you are using KinD version ${KIND_VERSION}.x, download from https://github.com/kubernetes-sigs/kind/releases"
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
cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --wait 120s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:${K8S_VERSION}
  extraPortMappings:
  - containerPort: 31080 # expose port 31380 of the node to port 80 on the host, later to be use by kourier or contour ingress
    listenAddress: 127.0.0.1
    hostPort: 80
EOF

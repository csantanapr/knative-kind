#!/usr/bin/env bash

set -e

REPLY=continue
if kubectl cluster-info --context kind-knative &>/dev/null; then
 read -p "Knative Cluster kind-knative already installed, delete and re-create? N/y: " REPLY </dev/tty
fi
if [ "$REPLY" == "Y" ] || [ "$REPLY" == "y" ]; then
  kind delete cluster --name knative
elif [ "$REPLY" == "N" ] || [ "$REPLY" == "n" ] || [ -z "$REPLY" ]; then
  echo "Installation skipped"
  exit 0
fi

KIND_CLUSTER=$(mktemp)
curl -sLo $KIND_CLUSTER https://raw.githubusercontent.com/csantanapr/knative-kind/master/kind/clusterconfig.yaml
kind create cluster --name knative --config $KIND_CLUSTER
kubectl cluster-info --context kind-knative
echo "Waiting on cluster to be ready"
until kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kube-system
do
   kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kube-system
done

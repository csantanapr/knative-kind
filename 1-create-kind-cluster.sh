#!/usr/bin/env bash

set -xeu

CLUSTER_NAME=${CLUSTER_NAME:=knative}

kind delete cluster --name ${CLUSTER_NAME}

kind create cluster --image kindest/node:v1.16.1 --name ${CLUSTER_NAME} --config kind-config.yaml

export KUBECONFIG="$(kind get kubeconfig-path --name="${CLUSTER_NAME}")"

kubectl cluster-info

sleep 30

kubectl get nodes
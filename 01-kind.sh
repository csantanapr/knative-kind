#!/usr/bin/env bash

kind delete cluster --name knative || true
KIND_CLUSTER=$(mktemp)
curl -sLo $KIND_CLUSTER https://raw.githubusercontent.com/csantanapr/knative-kind/master/kind/clusterconfig.yaml
kind create cluster --name knative --config $KIND_CLUSTER
kubectl cluster-info --context kind-knative
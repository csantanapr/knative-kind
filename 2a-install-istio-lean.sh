#!/usr/bin/env bash

set -xeu

# Using private branch to use latest 1.2.2 and nodeport set to 32000
kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.2.2/third_party/istio-1.2.2/istio-crds.yaml
sleep 5
kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.2.2/third_party/istio-1.2.2/istio-lean-nodeport-32000.yaml

kubectl get pods -n istio-system

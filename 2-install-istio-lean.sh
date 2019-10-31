#!/usr/bin/env bash

set -xeu

# Using private branch to use latest 1.3.3 and nodeport set to 32000
kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.3.3/third_party/istio-1.3.3/istio-crds.yaml

sleep 10

kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.3.3/third_party/istio-1.3.3/istio-lean-nodeport-32000.yaml

sleep 60

kubectl get pods -n istio-system

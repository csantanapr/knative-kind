#!/usr/bin/env bash

set -xeu

# Using private branch to use latest 1.3.3 and nodeport set to 32000
kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.3.3/third_party/istio-1.3.3/istio-crds.yaml

sleep 5

# some stupid reason some CRDS race condition running twice
set +e
kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.3.3/third_party/istio-1.3.3/istio-nodeport-32000.yaml
set -e
sleep 5
kubectl apply -f https://raw.githubusercontent.com/csantanapr/knative-serving/istio-1.3.3/third_party/istio-1.3.3/istio-nodeport-32000.yaml

kubectl get pods -n istio-system

sleep 30

kubectl get pods -n istio-system
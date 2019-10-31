#!/usr/bin/env bash

set -xeu

KNATIVE_VERSION=${KNATIVE_VERSION:="0.10.0"}


kubectl apply --selector knative.dev/crd-install=true \
  --filename https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml
sleep 10

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml
sleep 10

# sample event display function
kubectl apply --filename  https://github.com/knative/eventing-contrib/releases/download/v0.10.0/event-display.yaml

# github event source type
kubectl apply --filename  https://github.com/knative/eventing-contrib/releases/download/v0.10.0/github.yaml

sleep 20
kubectl get pods --namespace knative-eventing

kubectl label namespace default knative-eventing-injection=enabled

sleep 10

kubectl --namespace default get Broker default

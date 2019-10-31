#!/usr/bin/env bash

set -xeu

KNATIVE_VERSION=${KNATIVE_VERSION:="0.10.0"}

set +e
kubectl apply --filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving-crds.yaml
set -e
sleep 5
kubectl apply --filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving-crds.yaml
sleep 10

set +e
kubectl apply \
--selector networking.knative.dev/certificate-provider!=cert-manager \
--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving.yaml
sleep 5
set -e
kubectl apply \
--selector networking.knative.dev/certificate-provider!=cert-manager \
--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving.yaml

sleep 20
kubectl get pods --namespace knative-serving

DOMAIN="127.0.0.1.nip.io"
echo "Setting up local domain ${DOMAIN}"
kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"${DOMAIN}\": \"\"}}"

kubectl apply --filename hello-function.yaml

sleep 5

kubectl get ksvc

sleep 5

curl http://hello.default.127.0.0.1.nip.io

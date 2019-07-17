#!/usr/bin/env bash

set -xeu

KNATIVE_VERSION=${KNATIVE_VERSION:="0.7.1"}

# Minimal CRDs
kubectl apply \
--selector knative.dev/crd-install=true \
--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving.yaml

sleep 10

# Minimal knative serving
kubectl apply \
--selector networking.knative.dev/certificate-provider!=cert-manager \
--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving.yaml

sleep 10

DOMAIN="127.0.0.1.xip.io"
echo "Setting up local domain ${DOMAIN}"
kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"${DOMAIN}\": \"\"}}"

kubectl get pods --namespace knative-serving

kn service create hello --image gcr.io/knative-samples/helloworld-go

kn service list

curl http://hello.default.127.0.0.1.xip.io -v






# Whole enchilada CRDs
#kubectl apply \
#--selector knative.dev/crd-install=true \
#--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving.yaml \
#--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/monitoring.yaml

# Whole enchilada 
#kubectl apply  \
#--selector networking.knative.dev/certificate-provider!=cert-manager \
#--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/serving.yaml
#--filename https://github.com/knative/build/releases/download/v${KNATIVE_VERSION}/build.yaml \
#--filename https://github.com/knative/eventing/releases/download/v${KNATIVE_VERSION}/release.yaml \
#--filename https://github.com/knative/serving/releases/download/v${KNATIVE_VERSION}/monitoring.yaml
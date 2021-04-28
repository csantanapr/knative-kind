#!/usr/bin/env bash

set -eo pipefail

KNATIVE_EVENTING_VERSION=${KNATIVE_EVENTING_VERSION:-0.21.1}
NAMESPACE=${NAMESPACE:-default}
BROKER_NAME=${BROKER_NAME:example-broker}
set -u


n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-crds.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-core.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/in-memory-channel.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/mt-channel-broker.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing


kubectl apply -f - <<EOF
apiVersion: eventing.knative.dev/v1
kind: broker
metadata:
 name: ${BROKER_NAME}
 namespace: ${NAMESPACE}
EOF

sleep 3
kubectl get broker ${BROKER_NAME}
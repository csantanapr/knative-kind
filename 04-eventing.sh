#!/usr/bin/env bash

set -eo pipefail
set -u

KNATIVE_EVENTING_VERSION=${KNATIVE_EVENTING_VERSION:-0.23.0}
NAMESPACE=${NAMESPACE:-default}
BROKER_NAME=${BROKER_NAME:-example-broker}



n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-crds.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd > /dev/null

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-core.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing > /dev/null

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/in-memory-channel.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing > /dev/null

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/mt-channel-broker.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing > /dev/null


kubectl apply -f - <<EOF
apiVersion: eventing.knative.dev/v1
kind: broker
metadata:
 name: ${BROKER_NAME}
 namespace: ${NAMESPACE}
EOF

sleep 3
kubectl -n ${NAMESPACE} get broker ${BROKER_NAME}
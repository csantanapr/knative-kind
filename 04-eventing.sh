#!/usr/bin/env bash

set -eo pipefail
set -u


NAMESPACE=${NAMESPACE:-default}
BROKER_NAME=${BROKER_NAME:-example-broker}



n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-crds.yaml > /dev/null && break
  echo "Eventing CRDs failed to install on first try"
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd > /dev/null

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-core.yaml > /dev/null && break
  echo "Eventing Core failed to install on first try"
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing > /dev/null

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/eventing/latest/in-memory-channel.yaml > /dev/null && break
  echo "Eventing Memory Channel failed to install on first try"
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing > /dev/null

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://storage.googleapis.com/knative-nightly/eventing/latest/mt-channel-broker.yaml > /dev/null && break
  echo "Eventing MT Memory Broker failed to install on first try"
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

sleep 10
kubectl -n ${NAMESPACE} get broker ${BROKER_NAME}
#!/usr/bin/env bash

set -eo pipefail
set -u

KNATIVE_EVENTING_VERSION=${KNATIVE_EVENTING_VERSION:-0.24.1}
NAMESPACE=${NAMESPACE:-default}
BROKER_NAME=${BROKER_NAME:-example-broker}




n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-crds.yaml  && break
  echo "Eventing CRDs failed to install on first try"
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-core.yaml  && break
  echo "Eventing Core failed to install on first try"
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/in-memory-channel.yaml  && break
  echo "Eventing Memory Channel failed to install on first try"
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/mt-channel-broker.yaml  && break
  echo "Eventing MT Memory Broker failed to install on first try"
  n=$[$n+1]
  sleep 5
done
#kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing
sleep 30
kubectl get pods -A --show-labels
#kubectl describe pod -n knative-eventing


kubectl apply -f - <<EOF
apiVersion: eventing.knative.dev/v1
kind: broker
metadata:
 name: ${BROKER_NAME}
 namespace: ${NAMESPACE}
EOF

sleep 10
kubectl -n ${NAMESPACE} get broker ${BROKER_NAME}
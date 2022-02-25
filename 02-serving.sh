#!/usr/bin/env bash

set -eo pipefail
set -u

KNATIVE_VERSION=${KNATIVE_VERSION:-1.2.2}

n=0
set +e
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-crds.yaml > /dev/null && break
  echo "Serving CRDs failed to install on first try"
  n=$[$n+1]
  sleep 5
done
set -e
kubectl wait --for=condition=Established --all crd > /dev/null

n=0
set +e
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-core.yaml > /dev/null && break
  echo "Serving Core failed to install on first try"
  n=$[$n+1]
  sleep 5
done
set -e
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving > /dev/null



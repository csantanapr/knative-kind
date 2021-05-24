#!/usr/bin/env bash

set -eo pipefail
set -u

KNATIVE_NET_CONTOUR_VERSION=${KNATIVE_NET_CONTOUR_VERSION:-0.23.0}

## INSTALL CONTOUR
n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative-sandbox/net-contour/releases/download/v${KNATIVE_NET_CONTOUR_VERSION}/contour.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd > /dev/null
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n contour-internal > /dev/null
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n contour-external > /dev/null

## INSTALL NET CONTOUR
n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative-sandbox/net-contour/releases/download/v${KNATIVE_NET_CONTOUR_VERSION}/net-contour.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
# deployment for net-contour gets deployed to namespace knative-serving
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving > /dev/null

# Configure Knative to use this ingress
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"contour.ingress.networking.knative.dev"}}'


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: contour-ingress
  namespace: contour-external
  labels:
    networking.knative.dev/ingress-provider: contour
spec:
  type: NodePort
  selector:
    app: envoy
  ports:
    - name: http
      nodePort: 31080
      port: 80
      targetPort: 8080
EOF

#!/usr/bin/env bash

set -eo pipefail
set -u

KNATIVE_NET_KOURIER_VERSION=${KNATIVE_NET_KOURIER_VERSION:-0.23.0}

## INSTALL KOURIER
n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative-sandbox/net-kourier/releases/download/v$KNATIVE_NET_KOURIER_VERSION/kourier.yaml > /dev/null && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kourier-system > /dev/null
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving > /dev/null

# Configure Knative to use this ingress
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kourier-ingress
  namespace: kourier-system
  labels:
    networking.knative.dev/ingress-provider: kourier
spec:
  type: NodePort
  selector:
    app: 3scale-kourier-gateway
  ports:
    - name: http2
      nodePort: 31080
      port: 80
      targetPort: 8080
EOF

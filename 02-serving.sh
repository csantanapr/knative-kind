#!/usr/bin/env bash

set -eo pipefail

KNATIVE_VERSION=${KNATIVE_VERSION:-0.21.0}
KNATIVE_NET_KOURIER_VERSION=${KNATIVE_NET_KOURIER_VERSION:-0.21.0}
set -u
INGRESS_HOST="127.0.0.1"
KNATIVE_DOMAIN=$INGRESS_HOST.nip.io

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/serving/releases/download/v$KNATIVE_VERSION/serving-crds.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/serving/releases/download/v$KNATIVE_VERSION/serving-core.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving

n=0
until [ $n -ge 2 ]; do
  kubectl apply -f https://github.com/knative/net-kourier/releases/download/v$KNATIVE_NET_KOURIER_VERSION/kourier.yaml && break
  n=$[$n+1]
  sleep 5
done
kubectl wait --for=condition=Established --all crd

kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kourier-system
# deployment for net-kourier gets deployed to namespace knative-serving
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving

kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'


kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"

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

kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kourier-system
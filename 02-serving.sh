#!/usr/bin/env bash

set -ex
KNATIVE_VERSION=${KNATIVE_VERSION:-0.18.1}
KNATIVE_NET_KOURIER_VERSION=${KNATIVE_NET_KOURIER_VERSION:-0.18.0}
kubectl apply -f https://github.com/knative/serving/releases/download/v$KNATIVE_VERSION/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/v$KNATIVE_VERSION/serving-core.yaml
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving
kubectl apply -f https://github.com/knative/net-kourier/releases/download/v$KNATIVE_NET_KOURIER_VERSION/kourier.yaml
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n kourier-system
# deployment for net-kourier gets deployed to namespace knative-serving
kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-serving


INGRESS_HOST="127.0.0.1"

echo "The INGRESS_HOST is $INGRESS_HOST"
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'

KNATIVE_DOMAIN=$INGRESS_HOST.nip.io

echo "The KNATIVE_DOMAIN $INGRESS_HOST.nip.io"
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

cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: gcr.io/knative-samples/helloworld-go
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "Knative"
EOF
kubectl wait ksvc hello --all --timeout=-1s --for=condition=Ready
SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')
echo "The SERVICE_ULR is $SERVICE_URL"
curl $SERVICE_URL
#!/usr/bin/env bash

set -eo pipefail
set -u

cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/window: 10s
    spec:
      containers:
        - image: gcr.io/knative-samples/helloworld-go
          ports:
            - containerPort: 8080
          env:
            - name: TARGET
              value: "Knative"
EOF

echo "Downloading hello App container image..."
kubectl wait ksvc hello --all --timeout=-1s --for=condition=Ready > /dev/null
SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')
echo "The Knative Service hello endpoint is $SERVICE_URL"
curl $SERVICE_URL
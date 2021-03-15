#!/usr/bin/env bash

set -eo pipefail

KNATIVE_EVENTING_VERSION=${KNATIVE_EVENTING_VERSION:-0.21.1}
NAMESPACE=${NAMESPACE:-default}
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
 name: default
 namespace: $NAMESPACE
EOF

sleep 3
kubectl -n $NAMESPACE get broker default

kubectl -n $NAMESPACE apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-display
spec:
  replicas: 1
  selector:
    matchLabels: &labels
      app: hello-display
  template:
    metadata:
      labels: *labels
    spec:
      containers:
        - name: event-display
          image: gcr.io/knative-releases/knative.dev/eventing-contrib/cmd/event_display

---

kind: Service
apiVersion: v1
metadata:
  name: hello-display
spec:
  selector:
    app: hello-display
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOF

kubectl -n $NAMESPACE apply -f - << EOF
apiVersion: eventing.knative.dev/v1
kind: Trigger
metadata:
  name: hello-display
spec:
  broker: default
  filter:
    attributes:
      type: greeting
  subscriber:
    ref:
      apiVersion: v1
      kind: Service
      name: hello-display
EOF

kubectl -n $NAMESPACE apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: curl
  name: curl
spec:
  containers:
    # This could be any image that we can SSH into and has curl.
  - image: radial/busyboxplus:curl
    imagePullPolicy: IfNotPresent
    name: curl
    tty: true
EOF
kubectl wait -n $NAMESPACE pod curl --timeout=-1s --for=condition=Ready

kubectl -n $NAMESPACE exec curl -- curl -s -v  "http://broker-ingress.knative-eventing.svc.cluster.local/$NAMESPACE/default" \
  -X POST \
  -H "Ce-Id: say-hello" \
  -H "Ce-Specversion: 1.0" \
  -H "Ce-Type: greeting" \
  -H "Ce-Source: not-sendoff" \
  -H "Content-Type: application/json" \
  -d '{"msg":"Hello Knative!"}'

kubectl wait pod --timeout=-1s --for=condition=Ready -l app=hello-display -n $NAMESPACE

kubectl -n $NAMESPACE logs -l app=hello-display --tail=100


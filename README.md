# Setup Knative on Kind

Setup [Knative](https://knative.dev) on [Kind](https://kind.sigs.k8s.io/) (Kubernetes In Docker)

TLDR; `curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/demo.sh | sh`

>Updated and verified on 2020/12/03 with:
>- Knative Serving 0.19.0
>- Knative Kourier 0.19.1
>- Knative Eventing 0.19.2
>- Kind version 0.9.0
>- Kubernetes version 1.19.4


## Install Docker for Desktop
To use kind, you will also need to [install docker](https://docs.docker.com/install/).

Verify that docker engine and CLI is working:
```
docker version
```


## Create cluster with Kind

TLDR; `curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/01-kind.sh | sh`

1. Install or Upgrade [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) Linux, MacOS, or Windows. You can verify version with
    ```bash
    kind --version
    ```
1. Delete and create, start your cluster, we specify the config file above.A kind cluster config manifest is used to expose port `80` on the host to be later used by the Knative Kourier ingress. To use a different version of kubernetes check the image digest to use from the kind [release page](https://github.com/kubernetes-sigs/kind/releases)
    ```
    kind delete cluster --name knative || true
    ```
    ```yaml
    cat <<EOF | kind create cluster --name knative --config=-
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      image: kindest/node:v1.19.4
      extraPortMappings:
      - containerPort: 31080 # expose port 31380 of the node to port 80 on the host, later to be use by kourier ingress
        hostPort: 80
    EOF
    ```
1. Verify the versions of the client `kubectl` and the cluster api-server, and that you can connect to your cluster.
    ```bash
    kubectl cluster-info --context kind-knative
    ```

For more information installing or using kind checkout the docs https://kind.sigs.k8s.io/

## Install Knative Serving

TLDR; `curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/02-serving.sh | sh`

1. Select the version of Knative Serving to install
    ```bash
    export KNATIVE_VERSION="0.19.0"
    ```
1. Install Knative Serving in namespace `knative-serving`
    ```bash
    kubectl apply -f https://github.com/knative/serving/releases/download/v$KNATIVE_VERSION/serving-crds.yaml
    kubectl wait --for=condition=Established --all crd

    kubectl apply -f https://github.com/knative/serving/releases/download/v$KNATIVE_VERSION/serving-core.yaml

    kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-serving
    ```
1. Select the version of Knative Net Kurier to install
    ```bash
    export KNATIVE_NET_KOURIER_VERSION="0.19.1"
    ```

1. Install Knative Layer kourier in namespace `kourier-system`
    ```bash
    kubectl apply -f https://github.com/knative/net-kourier/releases/download/v$KNATIVE_NET_KOURIER_VERSION/kourier.yaml
    kubectl wait --for=condition=Established --all crd

    kubectl wait deployment --all --timeout=-1s --for=condition=Available -n kourier-system

    # deployment for net-kourier gets deployed to namespace knative-serving
    kubectl wait deployment --all --timeout=-1s --for=condition=Available -n knative-serving
    ```
1. Set the environment variable `EXTERNAL_IP` to External IP Address of the Worker Node
    ```bash
    EXTERNAL_IP="127.0.0.1"
    ```
2. Set the environment variable `KNATIVE_DOMAIN` as the DNS domain using `nip.io`
    ```bash
    KNATIVE_DOMAIN="$EXTERNAL_IP.nip.io"
    echo KNATIVE_DOMAIN=$KNATIVE_DOMAIN
    ```
    Double-check DNS is resolving
    ```bash
    dig $KNATIVE_DOMAIN
    ```
1. Configure DNS for Knative Serving
    ```bash
    kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"
    ```
1. Configure Kourier to listen for http port 80 on the node
    ```bash
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
    ```
1. Configure Knative to use Kourier
    ```bash
    kubectl patch configmap/config-network \
      --namespace knative-serving \
      --type merge \
      --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
    ```
1. Verify that Knative is Installed properly all pods should be in `Running` state and our `kourier-ingress` service configured.
    ```bash
    kubectl get pods -n knative-serving
    kubectl get pods -n kourier-system
    kubectl get svc  -n kourier-system
    ```


## Deploy Knative Serving Application

Deploy using [kn](https://github.com/knative/client)
```bash
kn service create hello \
--image gcr.io/knative-samples/helloworld-go \
--port 8080 \
--env TARGET=Knative
```

**Optional:** Deploy a Knative Service using the equivalent yaml manifest:
```bash
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
```

Wait for Knative Service to be Ready
```bash
kubectl wait ksvc hello --all --timeout=-1s --for=condition=Ready
```

Get the URL of the new Service
```bash
SERVICE_URL=$(kubectl get ksvc hello -o jsonpath='{.status.url}')
echo $SERVICE_URL
```

Test the App
```bash
curl $SERVICE_URL
```

The output should be:
```
Hello Knative!
```

Check the knative pods that scaled from zero
```
kubectl get pod -l serving.knative.dev/service=hello
```

The output should be:
```
NAME                                     READY   STATUS    RESTARTS   AGE
hello-r4vz7-deployment-c5d4b88f7-ks95l   2/2     Running   0          7s
```

Try the service `url` on your browser (command works on linux and macos)
```bash
open $SERVICE_URL
```

You can watch the pods and see how they scale down to zero after http traffic stops to the url
```
kubectl get pod -l serving.knative.dev/service=hello -w
```

The output should look like this:
```
NAME                                     READY   STATUS
hello-r4vz7-deployment-c5d4b88f7-ks95l   2/2     Running
hello-r4vz7-deployment-c5d4b88f7-ks95l   2/2     Terminating
hello-r4vz7-deployment-c5d4b88f7-ks95l   1/2     Terminating
hello-r4vz7-deployment-c5d4b88f7-ks95l   0/2     Terminating
```

Try to access the url again, and you will see a new pod running again.
```
NAME                                     READY   STATUS
hello-r4vz7-deployment-c5d4b88f7-rr8cd   0/2     Pending
hello-r4vz7-deployment-c5d4b88f7-rr8cd   0/2     ContainerCreating
hello-r4vz7-deployment-c5d4b88f7-rr8cd   1/2     Running
hello-r4vz7-deployment-c5d4b88f7-rr8cd   2/2     Running
```

Some people call this **Serverless** 🎉 🌮 🔥


## Install Knative Eventing

TLDR; `curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/03-eventing.sh | sh`

1. Select the version of Knative Eventing to install
    ```bash
    export KNATIVE_EVENTING_VERSION="0.19.2"
    ```
1. Install Knative Eventing in namespace `knative-eventing`
    ```bash
    kubectl apply --filename https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-crds.yaml
    kubectl wait --for=condition=Established --all crd

    kubectl apply --filename https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/eventing-core.yaml

    kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

    kubectl apply --filename https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/in-memory-channel.yaml

    kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

    kubectl apply --filename https://github.com/knative/eventing/releases/download/v$KNATIVE_EVENTING_VERSION/mt-channel-broker.yaml

    kubectl wait pod --timeout=-1s --for=condition=Ready -l '!job-name' -n knative-eventing

    ```

## Deploy Knative Eventing Application

- Set the example Namspace
    ```bash
    NAMESPACE=default
    ```

- Create a broker
    ```yaml
    kubectl apply -f - <<EOF
    apiVersion: eventing.knative.dev/v1
    kind: broker
    metadata:
      name: default
      namespace: $NAMESPACE
    EOF
    ```

- Verify broker
    ```bash
    kubectl -n $NAMESPACE get broker default
    ```

- Shoud print the address of the broker
    ```
    NAME      URL                                                                        AGE   READY   REASON
    default   http://broker-ingress.knative-eventing.svc.cluster.local/default/default   47s   True
    ```

- To deploy the `hello-display` consumer to your cluster, run the following command:
    ```yaml
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

    ```

- Create a trigger by entering the following command:
    ```yaml
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

    ```

- Create ` curl` Pod
    ```yaml
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
        resources: {}
        stdin: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        tty: true
    EOF

    ```

- Send a Cloud Event usnig `curl` pod created in the previous step.
    ```bash
    kubectl -n $NAMESPACE exec curl -- curl -s -v  "http://broker-ingress.knative-eventing.svc.cluster.local/$NAMESPACE/default" \
      -X POST \
      -H "Ce-Id: say-hello" \
      -H "Ce-Specversion: 1.0" \
      -H "Ce-Type: greeting" \
      -H "Ce-Source: not-sendoff" \
      -H "Content-Type: application/json" \
      -d '{"msg":"Hello Knative!"}'
    ```

- Verify the events were received
    ```bash
    kubectl -n $NAMESPACE logs -l app=hello-display --tail=100
    ```

- Successful events should look like this
    ```yaml
    Context Attributes,
      specversion: 1.0
      type: greeting
      source: not-sendoff
      id: say-hello
      datacontenttype: application/json
    Extensions,
      knativearrivaltime: 2020-11-06T18:29:10.448647713Z
      knativehistory: default-kne-trigger-kn-channel.default.svc.cluster.local
    Data,
      {
        "msg": "Hello Knative!"
      }
    ```


### Delete Cluster

- Delete the cluster `knative`
    ```
    kind delete cluster --name knative
    ```
If you have any issues with these instructions [open an new issue](https://github.com/csantanapr/knative-kind/issues/new) please 🙏🏻


# Setup [Knative](https://knative.dev) on [Kind](https://kind.sigs.k8s.io/) (Kubernetes In Docker)

>Updated and verified on 2020/07/18 with:
>- Knative version 0.16
>- Kind version 0.8.1
>- Kubernetes version 1.18.2


## Install Docker for Desktop
To use kind, you will also need to [install docker](https://docs.docker.com/install/).

Verify that docker engine and cli is working:
```
docker version
```


## Create cluster with Kind

1. Install [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) Linux, MacOS, or Windows. You can verify version with
    ```bash
    kind --version
    ```
1. A kind cluster manifest file [clusterconfig.yaml](./kind/clusterconfig.yaml) is already provided, you can customize it. We are exposing port `80` on they host to be later use by the Knative Kourier ingress. To use a different version of kubernetes check the image digest to use from the kind [release page](https://github.com/kubernetes-sigs/kind/releases)
    ```yaml
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      image: kindest/node:v1.18.2@sha256:7b27a6d0f2517ff88ba444025beae41491b016bc6af573ba467b70c5e8e0d85f
      extraPortMappings:
      - containerPort: 31080 # expose port 31380 of the node to port 80 on the host, later to be use by kourier ingress
        hostPort: 80
    ```
1. Create and start your cluster, we specify the config file above
    ```
    kind create cluster --name knative --config kind/clusterconfig.yaml
    ```
1. Verify the versions of the client `kubectl` and the cluster api-server, and that you can connect to your cluster.
    ```bash
    kubectl cluster-info --context kind-knative
    ```

## Install Knative Serving

1. Install Knative Serving in namespace `knative-serving`
    ```bash
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.16.0/serving-crds.yaml
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.16.0/serving-core.yaml
    kubectl wait deployment activator autoscaler controller webhook --for=condition=Available -n knative-serving 
    ```
1. Install Knative Layer kourier in namespace `kourier-system`
    ```
    kubectl apply -f https://github.com/knative/net-kourier/releases/download/v0.16.0/kourier.yaml
    kubectl wait deployment 3scale-kourier-control 3scale-kourier-gateway --for=condition=Available -n kourier-system 
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
    Double check DNS is resolving
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
    kubectl get svc  -n kourier-system kourier-ingress
    ```


## Deploy Knative Application

Deploy a Knative Service using the following yaml manifest:

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



Verify status of Knative Service until is Ready
```bash
kubectl get ksvc -w
```

Wait util column `READY` is `True` it might take a minute or two:
```
NAME    URL                                        LATESTCREATED   LATESTREADY   READY     REASON
hello   http://hello.default.10.107.1.152.nip.io   hello-r4vz7                   Unknown   RevisionMissing
hello   http://hello.default.10.107.1.152.nip.io   hello-r4vz7     hello-r4vz7   Unknown   RevisionMissing
hello   http://hello.default.10.107.1.152.nip.io   hello-r4vz7     hello-r4vz7   Unknown   IngressNotConfigured
hello   http://hello.default.10.107.1.152.nip.io   hello-r4vz7     hello-r4vz7   True  
```


Test the App
```bash
curl $(kubectl get ksvc hello -o jsonpath='{.status.url}')
```

Output should be:
```
Hello Knative!
```

Check the knative pods that scaled from zero
```
kubectl get pod -l serving.knative.dev/service=hello
```

Output should be:
```
NAME                                     READY   STATUS    RESTARTS   AGE
hello-r4vz7-deployment-c5d4b88f7-ks95l   2/2     Running   0          7s
```

Try the service `url` on your browser
```
open $(kubectl get ksvc hello -o jsonpath='{.status.url}')
```

You can watch the pods and see how they scale down to zero after http traffic stops to the url
```
kubectl get pod -l serving.knative.dev/service=hello -w
```

Output should look like this:
```
NAME                                     READY   STATUS
hello-r4vz7-deployment-c5d4b88f7-ks95l   2/2     Running
hello-r4vz7-deployment-c5d4b88f7-ks95l   2/2     Terminating
hello-r4vz7-deployment-c5d4b88f7-ks95l   1/2     Terminating
hello-r4vz7-deployment-c5d4b88f7-ks95l   0/2     Terminating
```

Try to access the url again, and you will see the new pods running again.
```
NAME                                     READY   STATUS
hello-r4vz7-deployment-c5d4b88f7-rr8cd   0/2     Pending
hello-r4vz7-deployment-c5d4b88f7-rr8cd   0/2     ContainerCreating
hello-r4vz7-deployment-c5d4b88f7-rr8cd   1/2     Running
hello-r4vz7-deployment-c5d4b88f7-rr8cd   2/2     Running
```

Some people call this **Serverless** 🎉 🌮 🔥


### Delete Cluster
Delete the cluster `knative`
```
kind delete cluster --name knative
```

If you have any issues with this instructions [open an new issue](https://github.com/csantanapr/knative-kind/issues/new) please 🙏🏻
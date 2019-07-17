Setup Knative on Kind (Kubernetes In Docker)

# TLDR
Install `kind` and `docker` with 6 CPUs and 8GB Mem.
```
./1-install_kind.sh  
./2a-install-istio-lean.sh
./3-install-knative-serving.sh
open http://hello.default.127.0.0.1.xip.io
```

# Install Docker for Desktop
To use kind, you will also need to [install docker](https://docs.docker.com/install/).

You need to increase the default CPU and Memory configuration in docker, go to preferences and increase it to 6 CPU (4 CPUs if only using istio-lean) and 8GB memory

Verify that docker engine and cli is working: 
```
docker version
```

# Install Kind
Follow the [kind install instructions](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) on the kind webstie to install kind CLI.
For example on OSX with the latest version of go `1.12.7` you can use this command to install:
```
GO111MODULE="on" go get sigs.k8s.io/kind@v0.4.0
```

Verify that `kind` is install:
```
kind version
```

## Create Kind Cluster

Create the cluster using a configuration file
```
kind create cluster --name knative --config kind-config.yaml
```
The process should take about 30 seconds if you already have the images cached and should look like this
```
Creating cluster "knative" ...
 ✓ Ensuring node image (kindest/node:v1.15.0) 🖼 
 ✓ Preparing nodes 📦 
 ✓ Creating kubeadm config 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Cluster creation complete. You can now use the cluster with:
export KUBECONFIG="$(kind get kubeconfig-path --name="knative")"
kubectl cluster-info
```

## Configure KUBECONFIG
When creating a kind cluster it will print how to set the environment `KUBECONFIG` to be use every time you want to interact with this specific cluster instance.
```
export KUBECONFIG="$(kind get kubeconfig-path --name="knative")"
```
Noticed the value of `knative` for the flag `--name` this is the name of the cluster.

Run this command on any new terminal before interacting with the cluster with the `kubectl` CLI or any other tool that calls the kubernetes API.

Verify that kubernetes API can be reach and cluster is running
```
kubectl cluster-info
kubectl get nodes
```


# Install Istio

## Install lean Istio 

Run the following script
```
./2a-install-istio-lean.sh
```

## Install full Istio
Only if you skipped istio lean and are planning to use traffic splitting that requires istio sidecards
```
./2a-install-istio-full.sh
```
# Install Knative Serving

Run the following script
```
./3-install-knative-serving.sh
```

Verify by creating a knative function
```
kn service create hello --image gcr.io/knative-samples/helloworld-go
```
Output
```
Service 'hello' successfully created in namespace 'default'.
Waiting for service 'hello' to become ready ... OK

Service URL:
http://hello.default.127.0.0.1.xip.io
```
For other knative samples images check https://console.cloud.google.com/gcr/images/knative-samples

To verify the status of your knative function
```
kn service list
```
Output
```
NAME    URL                                     GENERATION   AGE   CONDITIONS   READY   REASON
hello   http://hello.default.127.0.0.1.xip.io   1            43s   3 OK / 3     True    
```

Try to invoke your knative function
```
curl http://hello.default.127.0.0.1.xip.io
```

# Install Knative Eventing

TBD

# Clean up

Delete the cluster `knative`
```
kind delete cluster --name knative
```
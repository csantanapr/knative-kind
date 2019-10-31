Setup Knative on [Kind](https://kind.sigs.k8s.io/) (Kubernetes In Docker)

# TLDR
Install `kind` and `docker` configured with 4 CPUs and 8GB Mem.
```
./1-create-kind-cluster.sh 
./2-install-istio-lean.sh
./3-install-knative-serving.sh
open http://hello.default.127.0.0.1.nip.io
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
./1-create-kind-cluster.sh 
```
The process should take about 60 seconds if you already have the images cached and should look like this
```
Creating cluster "knative" ...
 ✓ Ensuring node image (kindest/node:v1.16.1) 🖼 
 ✓ Preparing nodes 📦 
 ✓ Creating kubeadm config 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Cluster creation complete. You can now use the cluster with:
export KUBECONFIG="$(kind get kubeconfig-path --name="knative")"
kubectl cluster-info
```

# Install Istio

## Install lean Istio 

Run the following script
```
./2-install-istio-lean.sh
```

## Install full Istio
Only if you skipped istio lean and are planning to use traffic splitting that requires istio sidecards
```
./2b-install-istio-full.sh
```
# Install Knative Serving

Run the following script
```
./3-install-knative-serving.sh
```

Try to invoke the knative function
```
curl http://hello.default.127.0.0.1.nip.io
```

# Install Knative Eventing

TODO

# Clean up

## Stop and Resume Cluster

Pause cluster
```
docker pause knative-control-plane
```
Resume
```
docker unpause knative-control-plane
```

## Delete Cluster
Delete the cluster `knative`
```
kind delete cluster --name knative
```
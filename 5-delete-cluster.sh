#!/usr/bin/env bash

set -xeu

CLUSTER_NAME=${CLUSTER_NAME:=knative}

kind delete cluster --name="${CLUSTER_NAME}"

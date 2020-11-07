#!/usr/bin/env bash

set -ex
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/01-kind.sh | sh
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/02-serving.sh | sh

#!/usr/bin/env bash

set -e
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/01-kind.sh | sh
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/02-serving.sh | sh
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/03-eventing.sh | sh

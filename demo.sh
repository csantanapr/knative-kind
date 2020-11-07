#!/usr/bin/env bash

set -e
STARTTIME=$(date +%s)
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/01-kind.sh | sh
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/02-serving.sh | sh
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/03-eventing.sh | sh
DURATION=$(($(date +%s) - $STARTTIME))
echo -e "\033[0;92m 🚀 Knative setup with samples took: $(($DURATION / 60))m$(($DURATION % 60))s \033[0m"
echo -e "\033[0;92m 🎉 Now have some fun with Serverless and Event Driven Apps \033[0m"
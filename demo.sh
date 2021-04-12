#!/usr/bin/env bash

set -eo pipefail

echo -e "\033[0;92m ✅ Checking dependencies... \033[0m"
STARTTIME=$(date +%s)
echo -e "🍿 Installing Knative Serving and Eventing ... \033[0m"
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/install.sh | bash
echo -e "🕹 Installing Knative Samples Apps... \033[0m"
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/03-serving-samples.sh | bash
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/05-eventing-samples.sh | bash
DURATION=$(($(date +%s) - $STARTTIME))
echo "kubectl get ksvc,broker,trigger"
kubectl -n default get ksvc,broker,trigger
echo -e "\033[0;92m 🚀 Knative setup with samples took: $(($DURATION / 60))m$(($DURATION % 60))s \033[0m"
echo -e "\033[0;92m 🎉 Now have some fun with Serverless and Event Driven Apps \033[0m"
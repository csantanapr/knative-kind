#!/usr/bin/env bash

set -eo pipefail

KNATIVE_NET=${KNATIVE_NET:-kourier}
KONK_BRANCH=${KONK_BRANCH:-knative-0.24}

echo -e "✅ Checking dependencies... \033[0m"
STARTTIME=$(date +%s)
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/${KONK_BRANCH}/01-kind.sh | bash
echo -e "🍿 Installing Knative Serving... \033[0m"
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/${KONK_BRANCH}/02-serving.sh | bash
echo -e "🔌 Installing Knative Serving Networking Layer ${KNATIVE_NET}... \033[0m"
if [[ "$KNATIVE_NET" == "kourier" ]]; then
    curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/${KONK_BRANCH}/02-kourier.sh | bash
else
    curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/${KONK_BRANCH}/02-contour.sh | bash
fi
# Setup Knative DOMAIN DNS
INGRESS_HOST="127.0.0.1"
KNATIVE_DOMAIN=$INGRESS_HOST.nip.io
kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"

echo -e "🔥 Installing Knative Eventing... \033[0m"
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/${KONK_BRANCH}/04-eventing.sh | bash
DURATION=$(($(date +%s) - $STARTTIME))
echo -e "\033[0;92m 🚀 Knative install took: $(($DURATION / 60))m$(($DURATION % 60))s \033[0m"
echo -e "\033[0;92m 🎉 Now have some fun with Serverless and Event Driven Apps \033[0m"

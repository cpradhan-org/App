#!/bin/bash

# Using kubesec v2.

scan_result=$(curl -sSX POST --data-binary @"kubernetes/development/secret.yaml" https://v2.kubesec.io/scan)
scan_message=$(curl -sSX POST --data-binary @"kubernetes/development/secret.yaml" https://v2.kubesec.io/scan | jq .[0].message -r )
scan_score=$(curl -sSX POST --data-binary @"kubernetes/development/secret.yaml" https://v2.kubesec.io/scan | jq .[0].score )


if [[ "$scan_score" -ge 5 ]]; then
  echo "Kubesec score is $scan_score"
  echo "Kubesec message is $scan_message"
else
  echo "Score is $scan_score, which is less than or equal to 5"
  echo "Scaning kubernetes resource has failed"
  exit 1;
fi;
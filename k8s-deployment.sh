#!/bin/bash

sed -i 's#image: chinmayapradhan/.*#image: ${imageName}#g' kubernetes/development/deployment.yaml
kubectl -n solar-system get deployment ${deploymentName} > /dev/null

if [[ $? -ne 0 ]]; then
    echo "deployment ${deploymentName} does not exists"
    kubectl -n solar-system apply -f kubernetes/development/deployment.yaml
else
    echo "deployment ${deploymentName} exists"
    kubectl -n solar-system set image deployment/${deploymentName} ${deploymentName}=${imageName} --record=true
fi
#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo 'please specify task to describe'
    exit 1
fi

TASK_NAME=$1
PROFILE=$2

if [ -z "$PROFILE" ]; then
    JSON=$(aws ecs describe-task-definition --task-definition ${TASK_NAME})
else
    JSON=$(aws ecs describe-task-definition --task-definition ${TASK_NAME} --profile ${PROFILE})
fi

#identify aws cli response code, if 0, all ok, anything else means error, and should exit.
if [ "$?" != 0 ]; then
    exit 1
fi

echo "Environment variables"
echo ${JSON} | jq '.taskDefinition.containerDefinitions[0].environment | sort_by(.name)'
echo "Image is:"
echo ${JSON} | jq '.taskDefinition.containerDefinitions[0].image'

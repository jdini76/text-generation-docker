#!/usr/bin/env bash

ARGS=("$@" --listen --api --listen-port 3001 --api-port 5001 --extensions api --trust-remote-code)

if [[ -f /text-gen-model ]];
then
  ARGS=("${ARGS[@]}" --model "$(</text-gen-model)")
fi

source ${OOBA_PATH}/bin/activate
cd /text-generation-webui
export PYTHONUNBUFFERED=1
export HF_HOME="/workspace"

if [[ ${HF_TOKEN} ]];
then
    export HF_TOKEN="${HF_TOKEN}"
fi

echo "Starting Oobabooba Text Generation UI: ${ARGS[@]}"
python3 server.py "${ARGS[@]}"

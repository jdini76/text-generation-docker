#!/usr/bin/env bash

# Arguments for the xtts server
ARGS=("$@" --deepspeed --listen)

# Check if there are any environment-specific configurations or tokens
if [[ -f /xtts-model ]];
then
  ARGS=("${ARGS[@]}" --model "$(</workspace/xtts-model)")
fi

# Activate the virtual environment
source ${XTTS_PATH}/bin/activate

# Change to the server's working directory
cd /xtts-api-server

# Set environment variables
export PYTHONUNBUFFERED=1
export HF_HOME="/workspace"

if [[ ${HF_TOKEN} ]];
then
    export HF_TOKEN="${HF_TOKEN}"
fi

# Print and start the server with the specified arguments
echo "Starting XTTS API Server: ${ARGS[@]}"
python -m xtts_api_server "${ARGS[@]}"

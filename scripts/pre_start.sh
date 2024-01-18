#!/usr/bin/env bash

export PYTHONUNBUFFERED=1

echo "Template version: ${TEMPLATE_VERSION}"

if [[ -e "/workspace/template_version" ]]; then
    EXISTING_VERSION=$(cat /workspace/template_version)
else
    EXISTING_VERSION="0.0.0"
fi

sync_apps() {
    # Sync venv to workspace to support Network volumes
    echo "Syncing venv to workspace, please wait..."
    rsync --remove-source-files -rlptDu /venv/ /workspace/venv/

    # Sync Oobabooga Text Generation Web UI to workspace to support Network volumes
    echo "Syncing Oobabooga Text Generation Web UI to workspace, please wait..."
    rsync --remove-source-files -rlptDu /text-generation-webui/ /workspace/text-generation-webui/

    echo "${TEMPLATE_VERSION}" > /workspace/template_version
}

fix_venvs() {
    # Fix the venv to make it work from /workspace
    echo "Fixing venv..."
    /fix_venv.sh /venv /workspace/venv
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs

        # Create directories
        mkdir -p /workspace/logs /workspace/tmp
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
fi

if [[ ${MODEL} ]];
then
    if [[ ! -e "/workspace/text-gen-model" ]];
    then
        echo "Downloading model (${MODEL}), this could take some time, please wait..."
        source /workspace/venv/bin/activate
        /workspace/text-generation-webui/fetch_model.py "${MODEL}" /workspace/text-generation-webui/models >> /workspace/logs/download-model.log 2>&1
        deactivate
    fi
fi

if [[ ${DISABLE_AUTOLAUNCH} ]];
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/text-generation-webui"
    echo "   deactivate && source /workspace/venv/bin/activate"
    echo "   ./start_textgen_server.sh"
else
    ARGS=()

    if [[ ${UI_ARGS} ]];
    then
    	  ARGS=("${ARGS[@]}" ${UI_ARGS})
    fi

    echo "Starting Oobabooga Text Generation Web UI"
    source /workspace/venv/bin/activate
    cd /workspace/text-generation-webui && nohup ./start_textgen_server.sh "${ARGS[@]}" > /workspace/logs/textgen.log 2>&1 &
    echo "Oobabooga Text Generation Web UI started"
    echo "Log file: /workspace/logs/textgen.log"
    deactivate
fi

echo "All services have been started"

#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="text-generation-webui"
export XTTS_APP="xtts-api-server"
DOCKER_IMAGE_VERSION_FILE="/workspace/docker_image_version"

echo "Template version: ${TEMPLATE_VERSION}"
echo "ooba venv: ${OOBA_PATH}"
echo "xtts venv: ${XTTS_PATH}"

if [[ -e ${DOCKER_IMAGE_VERSION_FILE} ]]; then
    EXISTING_VERSION=$(cat ${DOCKER_IMAGE_VERSION_FILE})
else
    EXISTING_VERSION="0.0.0"
fi

rsync_with_progress() {
    stdbuf -i0 -o0 -e0 rsync -au --info=progress2 "$@" | stdbuf -i0 -o0 -e0 tr '\r' '\n' | stdbuf -i0 -o0 -e0 grep -oP '\d+%|\d+.\d+[mMgG]' | tqdm --bar-format='{l_bar}{bar}' --total=100 --unit='%' > /dev/null
}

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync venv to workspace to support Network volumes
        echo "Syncing venv to workspace, please wait..."
        mkdir -p ${OOBA_PATH}
        rsync_with_progress --remove-source-files /venv/oobabooga ${OOBA_PATH}/

        # Sync text-generation-webui application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        rsync_with_progress --remove-source-files /${APP}/ /workspace/${APP}/

        # Sync xtts-api-server application to workspace to support Network volumes
        echo "Syncing ${XTTS_APP} to workspace, please wait..."
		mkdir -p ${XTTS_PATH}
		rsync_with_progress --remove-source-files /venv/xtts ${XTTS_PATH}/
		
		# Sync xtts application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        rsync_with_progress --remove-source-files /${XTTS_APP}/ /workspace/${XTTS_APP}/

        echo "${TEMPLATE_VERSION}" > ${DOCKER_IMAGE_VERSION_FILE}
        echo "${OOBA_PATH}" > "/workspace/${APP}/venv_path"
        echo "${XTTS_PATH}" > "/workspace/${XTTS_APP}/venv_path"
    fi
}

fix_venvs() {
    # Fix the venv to make it work from VENV_PATH
    echo "Fixing venv for OOBA..."
    /fix_venv.sh /venv/oobabooga ${OOBA_PATH}
	
	echo "Fixing venv for XTTS"
	/fix_venv.sh /venv/xtts ${XTTS_PATH}
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        #sync_apps
        #fix_venvs

        # Create directories
        mkdir -p /workspace/logs /workspace/tmp
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
else
    echo "Existing version is newer than the template version, not syncing!"
fi

if [[ ${MODEL} ]];
then
    if [[ ! -e "/workspace/text-gen-model" ]];
    then
        echo "Downloading model (${MODEL}), this could take some time, please wait..."
        source /venv/oobabooga/bin/activate
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
    echo "   ./start_textgen_server.sh"
else
    ARGS=()

    if [[ ${UI_ARGS} ]];
    then
        ARGS=("${ARGS[@]}" ${UI_ARGS})
    fi

    if [[ ${HF_TOKEN} ]];
    then
        export HF_TOKEN="${HF_TOKEN}"
    fi

    echo "Starting Oobabooga Text Generation Web UI"
	source ${OOBA_PATH}/bin/activate
    cd /text-generation-webui
    nohup ./start_textgen_server.sh "${ARGS[@]}" > /workspace/logs/textgen.log 2>&1 &
    echo "Oobabooga Text Generation Web UI started"
    echo "Log file: /workspace/logs/textgen.log"
	deactivate
fi

# Start XTTS API Server
echo "Starting XTTS API Server"
source ${XTTS_PATH}/bin/activate
cd /xtts-api-server
nohup ./start_xtts_server.sh > /workspace/logs/xtts.log 2>&1 &
echo "XTTS API Server started"
echo "Log file: /workspace/logs/xtts.log"
deactivate
echo "All services have been started"

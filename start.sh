#!/usr/bin/env bash
export VENV=/workspace/venv
export PYTHONUNBUFFERED=1

echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au --remove-source-files /venv/ /workspace/venv/
rm -rf /venv

# Sync text-generation-webui to workspace to support Network volumes
echo "Syncing text-generation-webui to workspace, please wait..."
rsync -au --remove-source-files /text-generation-webui/ /workspace/text-generation-webui/
rm -rf /text-generation-webui

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys
    chmod 700 -R ~/.ssh
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    cd /
    source ${VENV}/bin/activate
    nohup jupyter lab --allow-root \
        --no-browser \
        --port=8888 \
        --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} \
        --ServerApp.allow_origin=* \
        --ServerApp.preferred_dir=/workspace &
    echo "Jupyter Lab Started"
    deactivate
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/text-generation-webui"
    echo "   deactivate && source /workspace/venv/activate"
    echo "   ./start_chatbot_server.sh"
else
    mkdir -p /workspace/logs
    echo "Starting text-generation-webui"
    source ${VENV}/bin/activate
    cd /workspace/text-generation-webui && nohup ./start_chatbot_server.sh > /workspace/logs/textgen.log &
    echo "text-generation-webui started"
    echo "Log file: /workspace/logs/textgen.log"
    deactivate
fi

echo "All services have been started"

sleep infinity
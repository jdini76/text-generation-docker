#!/usr/bin/env bash
set -e

# Function to install oobabooga
install_oobabooga() {
    echo "Installing oobabooga..."
    
    # Create virtual env
    python3 -m venv ${OOBA_PATH}
    source ${OOBA_PATH}/bin/activate

    # Install torch
    pip3 install --upgrade pip
    pip3 install torch==${TORCH_VERSION} --index-url ${INDEX_URL}

    # Clone the git repo of Text Generation Web UI and set version
    git clone https://github.com/oobabooga/text-generation-webui /text-generation-webui
    cd /text-generation-webui
    git checkout ${OOBABOOGA_VERSION}

    # Install the dependencies for Text Generation Web UI
    # Including all extensions
    pip3 install -r requirements.txt
    bash -c 'for req in extensions/*/requirements.txt ; do pip3 install -r "$req" ; done'
    pip3 install -U safetensors>=0.4.1

    echo "/venv/oobabooga" > /text-generation-webui/venv_path
    deactivate
}

# Function to install xtts
install_xtts() {
    echo "Installing xtts..."

    # Create virtual env
    python3 -m venv ${XTTS_PATH}
    source ${XTTS_PATH}/bin/activate

    # Clone REPO
    git clone https://github.com/daswer123/xtts-api-server /xtts-api-server
	cd /xtts-api-server
    # Install deps
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install torch==${TORCH_VERSION} torchaudio==${TORCH_VERSION} --index-url ${INDEX_URL}

    echo "/venv/xtts" > /xtts-api-server/venv_path
    deactivate
}

# Check the argument
if [ "$1" == "oobabooga" ]; then
    install_oobabooga
elif [ "$1" == "xtts" ]; then
    install_xtts
else
    echo "Invalid argument. Please use 'oobabooga' or 'xtts'."
    exit 1
fi

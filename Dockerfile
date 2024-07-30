ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    PATH="/usr/local/cuda/bin:${PATH}"

# Install required packages, including dependencies for PyAudio and dos2unix
RUN apt-get update && \
    apt-get install -y dos2unix portaudio19-dev python3-pyaudio && \
    apt-get clean

# Set environment variables for torch installation
ARG INDEX_URL
ARG TORCH_VERSION
ARG OOBABOOGA_VERSION
ENV INDEX_URL=${INDEX_URL}
ENV TORCH_VERSION=${TORCH_VERSION}
ENV OOBABOOGA_VERSION=${OOBABOOGA_VERSION}

# Set the venv path
ARG OOBA_PATH
ENV OOBA_PATH=${OOBA_PATH}
ARG XTTS_PATH
ENV XTTS_PATH=${XTTS_PATH}

# Copy the install script and convert line endings
COPY --chmod=755 build/install.sh /install.sh
RUN dos2unix /install.sh

# Run the install script for oobabooga & xtts
RUN /install.sh oobabooga
RUN /install.sh xtts

# Clean up the install script
RUN rm /install.sh

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/api.html /usr/share/nginx/html/

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Copy startup script for Oobabooba Web UI
COPY --chmod=755 scripts/start_textgen_server.sh /text-generation-webui/
RUN dos2unix /text-generation-webui/start_textgen_server.sh

# Copy scripts to download models
COPY fetch_model.py /text-generation-webui/
COPY download_model.py /text-generation-webui/

# Copy the XTTS server start script
COPY --chmod=755 scripts/start_xtts_server.sh /xtts-api-server/
RUN dos2unix /xtts-api-server/start_xtts_server.sh

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Copy the main start script
COPY --chmod=755 scripts/* ./
RUN dos2unix /*

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]

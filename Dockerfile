ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    PATH="/usr/local/cuda/bin:${PATH}"

# Install required packages, including dos2unix
RUN apt-get update && \
    apt-get install -y dos2unix && \
    apt-get clean

# Install oobabooga
ARG INDEX_URL
ARG TORCH_VERSION
ARG OOBABOOGA_VERSION
ENV INDEX_URL=${INDEX_URL}
ENV TORCH_VERSION=${TORCH_VERSION}
ENV OOBABOOGA_VERSION=${OOBABOOGA_VERSION}

# Copy the install script and convert line endings
COPY --chmod=755 build/install.sh /install.sh
RUN dos2unix /install.sh

# Run the install script
RUN /install.sh && rm /install.sh

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/api.html /usr/share/nginx/html/

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Copy startup script for Oobabooba Web UI
COPY --chmod=755 scripts/start_textgen_server.sh /text-generation-webui/

# Copy scripts to download models
COPY fetch_model.py /text-generation-webui/
COPY download_model.py /text-generation-webui/

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]

variable "USERNAME" {
    default = "ashleykza"
}

variable "APP" {
    default = "oobabooga"
}

variable "RELEASE" {
    default = "1.16.0"
}

variable "CU_VERSION" {
    default = "121"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${USERNAME}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        BASE_IMAGE = "ashleykza/runpod-base:1.0.0-cuda12.1.1-torch2.2.1"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"
        TORCH_VERSION = "2.2.1+cu${CU_VERSION}"
        OOBABOOGA_COMMIT = "91a7370a655881c55274284509a546ffd644dc16"
        VENV_PATH = "/workspace/venvs/text-generation-webui"
    }
}
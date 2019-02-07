#!/usr/bin/env sh

set -eu

OS=$(. /etc/os-release; echo "$ID") && printf '\n\e[1;34m%-6s\e[m\n' "OS: ${OS}"

# Docker
sudo apt remove --yes docker docker-engine docker.io \
    && sudo apt update \
    && sudo apt --yes --no-install-recommends install \
        apt-transport-https \
        ca-certificates \
    && wget --quiet --output-document=- https://download.docker.com/linux/${OS}/gpg \
        | sudo apt-key add - \
    && sudo add-apt-repository \
        "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${OS} \
        $(lsb_release --codename --short) \
        stable" \
    && sudo apt update \
    && sudo apt --yes --no-install-recommends install docker-ce \
    && sudo usermod --append --groups docker "$USER" \
    && sudo systemctl enable docker \
    && printf '\n\e[1;92m%-6s\e[m\n\n' "Docker installed successfully"

printf '\e[1;92m%-6s\e[m\n\n' "Waiting for Docker to start..."
sleep 3

# Docker Compose
sudo apt install --yes jq curl \
    && VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r) \
    && printf '\n\e[1;92m%-6s\e[m\n' "Docker Compose install latest version ${VERSION}..." \
    && sudo wget \
        --output-document=/usr/local/bin/docker-compose \
        https://github.com/docker/compose/releases/download/${VERSION}/run.sh \
    && sudo chmod +x /usr/local/bin/docker-compose \
    && sudo wget \
        --output-document=/etc/bash_completion.d/docker-compose \
        "https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose" \
    && printf '\n\e[1;92m%-6s\e[m\n\n' "Docker Compose installed successfully"
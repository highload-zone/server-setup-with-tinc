#!/usr/bin/env sh

set -eu

if [[ "$EUID" = 0 ]]; then
    printf '\n\e[1;34m%-6s\e[m\n' "Check root: already root"
else
    -k # make sure to ask for password on next sudo
    if true; then
        printf '\n\e[1;92m%-6s\e[m\n' "Check root: correct password"
    else
        printf '\n\e[1;31m%-6s\e[m\n'  "Check root: wrong password"
        exit 1
    fi
fi

OS=$(. /etc/os-release; echo "$ID") && printf '\n\e[1;34m%-6s\e[m\n' "OS: ${OS}"

# Docker
apt remove --yes docker docker-engine docker.io \
    && apt update \
    && apt --yes --no-install-recommends install \
        apt-transport-https \
        add-apt-repository \
        ca-certificates \
    && wget --quiet --output-document=- https://download.docker.com/linux/${OS}/gpg \
        | apt-key add - \
    && add-apt-repository \
        "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${OS} \
        $(lsb_release --codename --short) \
        stable" \
    && apt update \
    && apt --yes --no-install-recommends install docker-ce \
    && usermod --append --groups docker "$USER" \
    && systemctl enable docker \
    && printf '\n\e[1;92m%-6s\e[m\n\n' "Docker installed successfully"

printf '\e[1;92m%-6s\e[m\n\n' "Waiting for Docker to start..."
sleep 3

# Docker Compose
apt install --yes jq curl \
    && VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r) \
    && printf '\n\e[1;92m%-6s\e[m\n' "Docker Compose install latest version ${VERSION}..." \
    && wget \
        --quiet --output-document=/usr/local/bin/docker-compose \
        https://github.com/docker/compose/releases/download/${VERSION}/run.sh \
    && chmod +x /usr/local/bin/docker-compose \
    && printf '\n\e[1;92m%-6s\e[m\n\n' "Docker Compose installed successfully"
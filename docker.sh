#!/usr/bin/env bash

if [[ "$EUID" = 0 ]]; then
    printf '\e[1;34m%-6s\e[m\n' "Check root: already root"
else
    -k # make sure to ask for password on next sudo
    if true; then
        printf '\e[1;92m%-6s\e[m\n' "Check root: correct password"
    else
        printf '\e[1;31m%-6s\e[m\n'  "Check root: wrong password"
        exit 1
    fi
fi

OS=$(. /etc/os-release; echo "$ID") && printf '\e[1;34m%-6s\e[m\n' "OS: ${OS}"

# Tools
apt-get -qq install mc htop curl git \
    && printf '\e[1;92m%-6s\e[m\n' "Available tools: mc, htop, curl, git"


# Swap
grep -q "swapfile" /etc/fstab

if [ $? -ne 0 ]; then
    swapsize=$(free --giga | grep Mem | awk '{print $2}')
    if [ $swapsize -gt 4 ]
    then
        swapsize=4
    else
        if [ $swapsize -eq 0 ]
        then
            swapsize=1
        fi
    fi
    echo 'swapfile not found. Adding swapfile.' \
    && fallocate -l ${swapsize}G /swapfile \
    && chmod 600 /swapfile \
    && mkswap /swapfile \
    && swapon /swapfile \
    && echo '/swapfile none swap defaults 0 0' >> /etc/fstab \
    && printf '\e[1;34m%-6s\e[m\n' "Swap ${swapsize}G created"
else
    printf '\e[1;92m%-6s\e[m\n' "Swap exists"
fi
cat /proc/swaps
cat /proc/meminfo | grep Swap

# Kernel tuning
grep -q "vm.swappiness=10" /etc/sysctl.d/99-sysctl.conf
if [ $? -ne 0 ]; then
    # sysctl
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.d/99-sysctl.conf
    echo 'fs.file-max=500000' | tee -a /etc/sysctl.d/99-sysctl.conf
    echo 'net.core.somaxconn = 65536' | tee -a /etc/sysctl.d/99-sysctl.conf
    # security limits
    echo '*         hard    nofile      32768' | tee -a /etc/security/limits.conf
    echo '*         soft    nofile      32768' | tee -a /etc/security/limits.conf
    echo 'root      hard    nofile      65536' | tee -a /etc/security/limits.conf
    echo 'root      soft    nofile      65536' | tee -a /etc/security/limits.conf
    sysctl -p && printf '\e[1;34m%-6s\e[m\n' "Sysctl configured"
else
    printf '\e[1;92m%-6s\e[m\n' "Sysctl configure exists"
fi

# Docker
apt-get -qq remove --yes docker docker-engine docker.io \
    && apt-get -qq update \
    && apt-get -qq --yes --no-install-recommends install \
        apt-transport-https \
        software-properties-common \
        gnupg2 \
        ca-certificates \
    && wget --quiet --output-document=- https://download.docker.com/linux/${OS}/gpg \
        | apt-key add - \
    && add-apt-repository \
        "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${OS} \
        $(lsb_release --codename --short) \
        stable" \
    && apt-get -qq update \
    && apt-get -qq --yes --no-install-recommends install docker-ce \
    && usermod --append --groups docker "$USER" \
    && systemctl enable docker \
    && printf '\n\e[1;92m%-6s\e[m\n\n' "Docker installed successfully"

printf '\e[1;92m%-6s\e[m\n' "Waiting for Docker to start..."
sleep 3

# Docker Compose
apt-get -qq install --yes jq curl \
    && VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r) \
    && printf '\n\e[1;92m%-6s\e[m\n' "Docker Compose install latest version ${VERSION}..." \
    && wget \
        --quiet --output-document=/usr/local/bin/docker-compose \
        https://github.com/docker/compose/releases/download/${VERSION}/run.sh \
    && chmod +x /usr/local/bin/docker-compose \
    && printf '\n\e[1;92m%-6s\e[m\n\n' "Docker Compose installed successfully"
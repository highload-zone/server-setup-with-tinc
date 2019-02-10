#!/usr/bin/env bash

# Env GIT='https://login:secret@github.com/user/repo.git'

# Default
NETWORK='vpn'
INTERFACE='tun0'
PRIVATE_IP='10.0.0.0'
COMPRESSION='0'

# Auto configure
PUBLIC_IP=$(curl -s http://api.ipify.org)
TINC_HOME=$(pwd -P)/tinc
NODE_NAME=$(hostname -s | sed -r 's/[^a-zA-Z0-9]+/_/g')

nextip() {
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo ${PRIVATE_IP} | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + $1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo ${NEXT_IP_HEX} | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
}

tinc() {
    docker run --rm --net=host --device=/dev/net/tun --cap-add NET_ADMIN --volume ${TINC_HOME}:/etc/tinc jenserat/tinc -n ${NETWORK} "$@"
}

 ### check if network exists
if [ ! -f ${TINC_HOME}/${NETWORK}/tinc.conf ]; then
    echo 'No Tinc Network Detected.. Installing..'
    mkdir -p ${TINC_HOME}/${NETWORK}/
    git clone ${GIT} ${TINC_HOME}/${NETWORK}/hosts

    if [ -f ${TINC_HOME}/${NETWORK}/hosts/${NODE_NAME} ]; then
        rm -rf ${TINC_HOME}/${NETWORK}/hosts/${NODE_NAME}
    fi

    tinc init ${NODE_NAME}

    # Declare public and private IPs in the host file, CONFIG/NET/hosts/HOST
    COUNT=$(ls -la ${TINC_HOME}/${NETWORK}/hosts/ | wc -l)
    PRIVATE_IP=$(nextip $COUNT+1)
    echo "Address = "${PUBLIC_IP} >> ${TINC_HOME}/${NETWORK}/hosts/${NODE_NAME}
    echo "Subnet = "${PRIVATE_IP}"/32" >> ${TINC_HOME}/${NETWORK}/hosts/${NODE_NAME}
    echo "Compression = "${COMPRESSION} >> ${TINC_HOME}/${NETWORK}/hosts/${NODE_NAME}
    #echo "Cipher = id-aes256-GCM" >> $TINC_HOME/$NETWORK/hosts/$NODE_NAME
    #echo "Digest = whirlpool" >> $TINC_HOME/$NETWORK/hosts/$NODE_NAME
    #echo "MACLength = 16" >> $TINC_HOME/$NETWORK/hosts/$NODE_NAME

    cd ${TINC_HOME}/${NETWORK}/hosts
    git config --global user.email ${NODE_NAME}"@docker"
    git config --global user.name ${NODE_NAME}

    git add .
    git commit -m "${NODE_NAME} ${PRIVATE_IP}"
    git push
fi

# Tweak the config to add our particular setup
tinc add AddressFamily ipv4
tinc add Device /dev/net/tun
tinc add Mode switch
tinc add Interface ${INTERFACE}
# ConnectTo random 3 hosts
for filename in $(shuf -n3 -e ${TINC_HOME}/${NETWORK}/hosts/*); do
    if [[ "$filename" != "$NODE_NAME" ]];
    then
        tinc add ConnectTo $(basename ${filename})
    fi
done

# Edit the tinc-up script
cat << EOF > ${TINC_HOME}/${NETWORK}/tinc-up
#!/bin/sh
ifconfig \$INTERFACE ${PRIVATE_IP} netmask 255.255.255.0
EOF

cat << EOF > ${TINC_HOME}/${NETWORK}/tinc-down
#!/bin/sh
ifconfig \$INTERFACE down
EOF

chmod +x ${TINC_HOME}/${NETWORK}/tinc-up
chmod +x ${TINC_HOME}/${NETWORK}/tinc-down

# Run
docker run -d --restart=always --name=tinc --net=host --device=/dev/net/tun --cap-add NET_ADMIN --volume ${TINC_HOME}:/etc/tinc jenserat/tinc -n ${NETWORK} start -D \
    && echo "Docker container started with name: tinc"

# Test connection
netstat -ntlpv | grep 655
ifconfig tun0
docker exec tinc tinc -n ${NETWORK} info ${NODE_NAME}
echo "----------------------------------------------------------------------------------------------------"
docker exec tinc tinc -n ${NETWORK} dump nodes
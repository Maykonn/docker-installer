#!/bin/bash

USERGROUPS_CHANGED=0

echo 'Checking dependencies:'

# Checking and installing Docker
if ! docker_loc="$(type -p "docker")" || [[ -z ${docker_loc} ]]; then
    read -rp "Docker is required but not found, do you want to install Docker now? [y/n]: " REPLY
    if [[ ${REPLY,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
        sudo apt-get update
        sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common

        echo $'\nInstalling Docker:'
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
           "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) \
           stable"

        sudo apt-get update
        sudo apt-get install docker-ce

        echo $'\nChecking Docker version:'
        docker -v
        echo $'\nChecking Docker installation:'
        sudo docker run hello-world
    fi
fi
echo $'Docker              -> OK'

# Checking and installing Docker Compose
if ! docker_compose_loc="$(type -p "docker-compose")" || [[ -z ${docker_compose_loc} ]]; then
    read -rp $'\nDocker Compose is required but not found, do you want to install Docker Compose now? [y/n]: ' REPLY
    if [[ ${REPLY,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
        echo $'\nInstalling Docker Compose:'
        curl -L https://github.com/docker/compose/releases/download/latest/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo $'\nChecking Docker Compose version:'
        docker-compose --version
    fi
fi
echo 'Docker Compose      -> OK'

# Adding the current user to the docker group
getent group "docker" &>/dev/null || sudo groupadd "docker" &>/dev/null # checking if group exists, if not, will be created
if ! groups ${USER} | grep &>/dev/null '\bdocker\b'; then
    read -rp 'The logged user ('${USER}') is not a member of the `docker` group, do you want to add now? [y/c]: ' REPLY

    [[ ${REPLY,,} =~ ^(n|no|c|)$ ]] && { echo "Canceled" && exit 1; }
    if [[ ${REPLY,,} =~ ^(y|yes)$ ]]; then
        echo "Adding user ${USER} to the docker group"
        sudo usermod -aG "docker" ${USER}
        echo 'User added to the docker group'
        USERGROUPS_CHANGED=1
    fi
fi

if [[ ${USERGROUPS_CHANGED} -eq 1 ]]; then
    echo 'User Groups         -> OK'
    echo 'You need to do logout/login again for changes to have effect'
    exit 1;
fi

echo $'User Groups         -> OK'
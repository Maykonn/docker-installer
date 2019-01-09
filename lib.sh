#!/usr/bin/env bash

check_requirements() {
    echo 'Checking requirements...'

    # Checking and installing Docker
    if ! docker_loc="$(type -p "docker")" || [[ -z ${docker_loc} ]]; then
        read -rp "Docker is required but not found, do you want to install Docker now? [y/n]: " ANSWER
        if [[ ${ANSWER,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
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

    # Checking and installing Docker Compose
    if ! docker_compose_loc="$(type -p "docker-compose")" || [[ -z ${docker_compose_loc} ]]; then
        read -rp $'\nDocker Compose is required but not found, do you want to install Docker Compose now? [y/n]: ' ANSWER
        if [[ ${ANSWER,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
            echo $'\nInstalling Docker Compose:'
            curl -L https://github.com/docker/compose/releases/download/latest/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose

            echo $'\nChecking Docker Compose version:'
            docker-compose --version
        fi
    fi

    echo 'Continuing the installation'
}

create_work_dir() {
    # Change the $REPAIRQ_LOCAL_PROJECTS_DIR var to $HOME_PATH plus the user given value or keep the default value if the given value is blank
    read -rp $'\nPath to your RepairQ local development directory (will be under '${HOME_PATH}').
If blank default will be assumed (e.g. type '${REPAIRQ_LOCAL_PROJECTS_DIR_SUFFIX}' if you want '${REPAIRQ_LOCAL_PROJECTS_DIR}'): ' WORKDIR

    if [[ ! -z ${WORKDIR} ]]; then
        REPAIRQ_LOCAL_PROJECTS_DIR=${HOME_PATH}${WORKDIR}
    fi

    # Creating the RepairQ work dir with the REPAIRQ_LOCAL_PROJECTS_DIR value (if not already exist)
    if [[ ! -d ${REPAIRQ_LOCAL_PROJECTS_DIR} ]]; then
        mkdir -p "$REPAIRQ_LOCAL_PROJECTS_DIR"
        echo $'\nDirectory created:'  ${REPAIRQ_LOCAL_PROJECTS_DIR}
    fi

    echo 'Local work dir for RepairQ is:' ${REPAIRQ_LOCAL_PROJECTS_DIR}

    # Removing the symbolic link to your RepairQ work directory (if already exists)
    if [[ -L ${REPAIRQ_LOCAL_SN} ]]; then
        rm ${REPAIRQ_LOCAL_SN}
    fi

    # Creating the symbolic link to your RepairQ work directory
    ln -s ${REPAIRQ_LOCAL_PROJECTS_DIR} ${REPAIRQ_LOCAL_SN}
    echo "Symbolic link to RepairQ work directory is [${REPAIRQ_LOCAL_SN}]"
}

clone_docker_repo() {
    REPAIRQ_DOCKER_DIR=${REPAIRQ_LOCAL_PROJECTS_DIR}/${REPAIRQ_DOCKER_DIR_SUFFIX}

    echo $'\nCreating the RepairQ-Docker('${REPAIRQ_DOCKER_REPOSITORY_URL}$') local project.'

    # The RepairQ-Docker directory already exists, asking the user how to proceed
    if [[ -d ${REPAIRQ_DOCKER_DIR} ]]; then
        while ! [[ "$REPLY" =~ ^(y|yes|n|no)$ ]]; do
            read -rp $'Directory '${REPAIRQ_DOCKER_DIR}' already exists, do you want to overwrite it? [y/n]: ' REPLY
        done

        [[ ${REPLY,,} =~ ^(n|no)$ ]] && { echo "Canceled" && exit 1; }
        if [[ ${REPLY,,} =~ ^(y|yes)$ ]]; then
            echo $'Removing the '${REPAIRQ_DOCKER_DIR}' dir'
            rm -rf ${REPAIRQ_DOCKER_DIR}
        fi
    fi

    mkdir -p "$REPAIRQ_DOCKER_DIR"
    echo $'\nDirectory created:'  ${REPAIRQ_DOCKER_DIR}

    if [[ ${REPAIRQ_DOCKER_GIT} -eq 1 ]]; then
        echo "Cloning ${REPAIRQ_DOCKER_REPOSITORY_URL} into ${REPAIRQ_DOCKER_DIR}"

        git clone ${REPAIRQ_DOCKER_REPOSITORY_URL} ${REPAIRQ_DOCKER_DIR}
        cloned=$?

        if [[ ! "$cloned" -eq 0 ]]; then
            echo >&2
            clone_docker_repo
        fi
    fi
}

new_branch_checkout() {
    cd "$REPAIRQ_DOCKER_DIR"

    checkout_new_branch() {
        # Empty is not an acceptable value
        while [[ -z "$BRANCH" ]]; do
            read -rp $'\nEnter your new branch name [e.g. '${USER}']: ' BRANCH
        done

        # Successful checkout or start again
        if [[ ${REPAIRQ_DOCKER_GIT} -eq 1 ]]; then
            git checkout -b "user/${BRANCH}" || $(BRANCH="" && checkout_new_branch)
        fi

        # Variable to represent the user specific directory to work with docker
        REPAIRQ_USER_SPECIFIC_DOCKER_DIR=${REPAIRQ_DOCKER_DIR}/dev-local/${BRANCH}/
    }

    checkout_new_branch
    git branch

    # Copying the REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR to a directory corresponding your BRANCH name
    rsync -a ${REPAIRQ_DOCKER_DIR}/dev-local/${REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR}/ ${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}
}

configure_installation_files() {
    REPAIRQ_USER_SPECIFIC_DOCKER_DIR="/var/www/test/RepairQ-Docker/dev-local/maykonn"
    cd "$REPAIRQ_USER_SPECIFIC_DOCKER_DIR"

    echo "Configuring docker-compose.yml..."

    sed -i "s@{{home_path}}@$HOME_PATH_PREFIX@g" ${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}/docker-compose.yml
    sed -i "s@{{repairq_local_sn}}@$REPAIRQ_LOCAL_SN@g" ${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}/docker-compose.yml
    sed -i "s@{{repairq_user_specific_docker_dir}}@$REPAIRQ_USER_SPECIFIC_DOCKER_DIR@g" ${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}/docker-compose.yml

    echo "docker-compose.yml configured"
}
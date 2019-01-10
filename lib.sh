#!/usr/bin/env bash

check_requirements() {
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

    SSH_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
    if [[ -z ${SSH_PUB_KEY} ]]; then
        read -rp 'SSH id_rsa.pub key not found for current user, do you want to generate the ~/.ssh/id_rsa.pub now? [y/c]: ' REPLY

        [[ ${REPLY,,} =~ ^(n|no|c|)$ ]] && { echo "Canceled" && exit 1; }
        if [[ ${REPLY,,} =~ ^(y|yes)$ ]]; then
            while [[ -z "${EMAIL}" ]]; do
                echo 'generating'
                read -rp 'Provide an e-mail for id_rsa.pub: ' EMAIL
                ssh-keygen -t rsa -b 4096 -C ${EMAIL}
                eval "$(ssh-agent -s)"
                ssh-add ~/.ssh/id_rsa
            done
        fi

        SSH_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
    fi
    echo 'User SSH id_rsa.pub -> OK'
}

create_work_dir() {
#    read -rp $'Path to your RepairQ local development directory (will be under '${HOME_PATH}').
#If blank default will be assumed (e.g. type '${REPAIRQ_LOCAL_PROJECTS_DIR_SUFFIX}' if you want '${REPAIRQ_LOCAL_PROJECTS_DIR}'): ' WORKDIR
#
#    if [[ ! -z ${WORKDIR} ]]; then
#        REPAIRQ_LOCAL_PROJECTS_DIR=${HOME_PATH}${WORKDIR}
#    fi

    # Creating the RepairQ workdir with the REPAIRQ_LOCAL_PROJECTS_DIR value (if not already exist)
    if [[ ! -d ${REPAIRQ_LOCAL_PROJECTS_DIR} ]]; then
        mkdir -p "$REPAIRQ_LOCAL_PROJECTS_DIR"
        echo $'\nDirectory created:' ${REPAIRQ_LOCAL_PROJECTS_DIR}
    fi

    echo $'\nLocal work dir for RepairQ is:' ${REPAIRQ_LOCAL_PROJECTS_DIR}$'\n'
}

clone_docker_repo() {
    REPAIRQ_DOCKER_DIR="${REPAIRQ_LOCAL_PROJECTS_DIR}/${REPAIRQ_DOCKER_DIR_SUFFIX}"

    echo $'Creating the RepairQ-Docker('${REPAIRQ_DOCKER_REPOSITORY_URL}$') local project.'

    clone() {
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

    # The RepairQ-Docker directory already exists and is not empty, asking the user how to proceed
    if [[ -d ${REPAIRQ_DOCKER_DIR} ]]; then
        while ! [[ "$REPLY" =~ ^(y|yes|n|no)$ ]]; do
            read -rp $'Directory '${REPAIRQ_DOCKER_DIR}' already exists, do you want to overwrite it? [y/n]: ' REPLY
        done

        #[[ ${REPLY,,} =~ ^(n|no)$ ]] && { echo "Canceled" && exit 1; }
        if [[ ${REPLY,,} =~ ^(y|yes)$ ]]; then
            echo $'Removing the '${REPAIRQ_DOCKER_DIR}' dir'
            rm -rf ${REPAIRQ_DOCKER_DIR}
            clone
        fi

    else
        mkdir -p "$REPAIRQ_DOCKER_DIR"
        echo $'Directory created:'  ${REPAIRQ_DOCKER_DIR}
        clone
    fi
}

new_branch_checkout() {
    cd "$REPAIRQ_DOCKER_DIR"

    checkout_new_branch() {
        # Empty is not an acceptable value
        while [[ -z "$BRANCH" ]]; do
            read -rp $'\nEnter your new branch name [e.g. type '${USER}' for user/'${USER}']: ' BRANCH
        done

        # Successful checkout or start again
        if [[ ${REPAIRQ_DOCKER_GIT} -eq 1 ]]; then
            git checkout -b "user/${BRANCH}" || $(BRANCH="" && checkout_new_branch)
        fi

        # Variable to represent the user specific directory to work with docker
        REPAIRQ_USER_SPECIFIC_DOCKER_DIR=${REPAIRQ_DOCKER_DIR}/dev-local/${BRANCH}
    }

    checkout_new_branch
    git branch

    # Copying the REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR to a directory corresponding your BRANCH name
    rsync -a ${REPAIRQ_DOCKER_DIR}/dev-local/${REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR}/ ${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}
}

configure_installation_files() {
    BRANCH="maykonn"
    REPAIRQ_USER_SPECIFIC_DOCKER_DIR="/var/www/cinq/rq/RepairQ-Docker/dev-local/maykonn"
    rsync -a ${REPAIRQ_DOCKER_DIR}/dev-local/${REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR}/ ${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}

    cd "$REPAIRQ_USER_SPECIFIC_DOCKER_DIR"

    echo $'\nPreparing installation files'

    #APACHE_DOCUMENT_ROOT="/Users/${USER}${REPAIRQ_LOCAL_PROJECTS_DIR_SUFFIX}"
    APACHE_DOCUMENT_ROOT="/Users/${USER}/rq"
    APACHE_SSL_CERT_FILE="${APACHE_DOCUMENT_ROOT}/${REPAIRQ_DOCKER_DIR_SUFFIX}/dev-local/${BRANCH}/certificate.crt"
    APACHE_SSL_CERT_KEY_FILE="${APACHE_DOCUMENT_ROOT}/${REPAIRQ_DOCKER_DIR_SUFFIX}/dev-local/${BRANCH}/privateKey.key"

    DOCKER_COMPOSE_YML_FILE="${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}/docker-compose.yml"
    sed -i "s@{{home_path}}@$HOME_PATH_PREFIX@g" ${DOCKER_COMPOSE_YML_FILE} # /home:/Users
    sed -i "s@{{repairq_projects_directory}}@$REPAIRQ_LOCAL_PROJECTS_DIR@g" ${DOCKER_COMPOSE_YML_FILE} # /home/username/rq
    sed -i "s@{{repairq_user_specific_docker_dir}}@$REPAIRQ_USER_SPECIFIC_DOCKER_DIR@g" ${DOCKER_COMPOSE_YML_FILE} # /home/username/rq/RepairQ-Docker
    sed -i "s@{{user_rq_address_alias}}@$BRANCH.rq.test@g" ${DOCKER_COMPOSE_YML_FILE} # e.g.: maykonn.rq.test
    echo ${DOCKER_COMPOSE_YML_FILE}" -> OK"

    RQ_CONF_FILE="${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}/rq.conf"
    sed -i "s@{{document_root}}@${APACHE_DOCUMENT_ROOT}@g" ${RQ_CONF_FILE} #DocumentRoot /Users/cinq/Projects/repairq
    sed -i "s@{{ssl_cert_file}}@${APACHE_SSL_CERT_FILE}@g" ${RQ_CONF_FILE} #SSLCertificateFile "/Users/cinq/Projects/repairq/RepairQ-Docker/dev-local/maykonn/certificate.crt"
	sed -i "s@{{ssl_cert_key_file}}@${APACHE_SSL_CERT_KEY_FILE}@g" ${RQ_CONF_FILE} #SSLCertificateKeyFile "/Users/cinq/Projects/repairq/RepairQ-Docker/dev-local/maykonn/privateKey.key"
    echo ${RQ_CONF_FILE}" -> OK"

    DOCKER_ENTRYPOINT_FILE="${REPAIRQ_USER_SPECIFIC_DOCKER_DIR}/dockerfiles/bin/docker-entrypoint.sh"
    sed -i "s*{{ssh_id_rsa}}*${SSH_PUB_KEY}*g" ${DOCKER_ENTRYPOINT_FILE} # value of ssh .pub key (@see the check_requirements function)
    echo ${DOCKER_ENTRYPOINT_FILE}" -> OK"

    addhost() {
        ETC_HOSTS="/etc/hosts"
        IP="127.0.0.1"

        HOSTNAME=$1
        HOSTS_LINE="${IP}\t${HOSTNAME}"
        if [[ -n "$(grep ${HOSTNAME} /etc/hosts)" ]]
            then
                echo ${HOSTNAME} $' already exists:\n'$(grep ${HOSTNAME} ${ETC_HOSTS})
            else
                echo "Adding ${HOSTNAME} to your ${ETC_HOSTS}";
                sudo -- sh -c -e "echo '${HOSTS_LINE}' >> ${ETC_HOSTS}";

                if [[ -n "$(grep ${HOSTNAME} /etc/hosts)" ]]
                    then
                        echo ${HOSTNAME} $' was added successfully:\n' $(grep ${HOSTNAME} /etc/hosts);
                    else
                        echo "Failed to Add ${HOSTNAME}, Try again!";
                fi
        fi
    }

    addhost "${BRANCH}.rq.test"
    echo "/etc/hosts                 -> OK"
}
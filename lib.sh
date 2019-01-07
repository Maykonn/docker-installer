#!/usr/bin/env bash

create_work_dir() {
    # Change the LOCAL_REPAIRQ_PROJECTS_DIR var to the user given value or keep the default value if the given value is blank
    read -r -p $'Path to your RepairQ local development directory.\nIf blank default will be assumed ['${REPAIRQ_LOCAL_PROJECTS_DIR}']: ' GIVEN;
    if [[ ! -z ${GIVEN} ]]; then
        REPAIRQ_LOCAL_PROJECTS_DIR=${GIVEN}
    fi

    # Creating the RepairQ work dir with the REPAIRQ_LOCAL_PROJECTS_DIR value (if not already exist)
    if [[ ! -d ${REPAIRQ_LOCAL_PROJECTS_DIR} ]]; then
        mkdir "$REPAIRQ_LOCAL_PROJECTS_DIR"
        echo $'\nDirectory created:'  ${REPAIRQ_LOCAL_PROJECTS_DIR}
    fi
    echo 'Local work dir for RepairQ now is:' ${REPAIRQ_LOCAL_PROJECTS_DIR}
}

clone_docker_repo() {
    REPAIRQ_LOCAL_DOCKER_DIR=${REPAIRQ_LOCAL_PROJECTS_DIR}${REPAIRQ_LOCAL_DOCKER_DIR_SUFFIX}

    echo $'\nCreating the RepairQ-Docker(https://github.com/RepairQ/RepairQ-Docker.git) local project.'

    # The directory already exists, asking the user how to proceed
    if [[ -d ${REPAIRQ_LOCAL_DOCKER_DIR} ]]; then
        read -r -p $'Directory '${REPAIRQ_LOCAL_DOCKER_DIR}' already exists, do you want to overwrite it? [yes/cancel]: '

        # "y|yes|j|ja|s|si|o|oui", or cancel the installation
        [[ ${REPLY,,} =~ ^(c|cancel|)$ ]] && { echo "Selected Cancel"; exit 1; }
        if [[ ${REPLY,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
            echo $'Removing the '${REPAIRQ_LOCAL_DOCKER_DIR}' dir'
            rm -rf ${REPAIRQ_LOCAL_DOCKER_DIR}
        fi
    fi

    # If not cancelled by the user, continues to clone the repository into the correct directory:

    mkdir "$REPAIRQ_LOCAL_DOCKER_DIR"
    echo $'\nDirectory created:'  ${REPAIRQ_LOCAL_DOCKER_DIR}

    echo "Cloning https://github.com/RepairQ/RepairQ-Docker.git into ${REPAIRQ_LOCAL_DOCKER_DIR}"
    cd "$REPAIRQ_LOCAL_DOCKER_DIR" && git clone https://github.com/RepairQ/RepairQ-Docker.git ${REPAIRQ_LOCAL_DOCKER_DIR}
}
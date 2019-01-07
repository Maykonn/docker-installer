#!/usr/bin/env bash

create_work_dir() {
    # Change the LOCAL_REPAIRQ_PROJECTS_DIR var to the user given value or keep the default value if the given value is blank
    read -r -p $'\nPath to your RepairQ local development directory.\nIf blank default will be assumed ['${REPAIRQ_LOCAL_PROJECTS_DIR}']: ' GIVEN;
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

    create_the_project_dir() {
        mkdir "$REPAIRQ_LOCAL_DOCKER_DIR"
        echo $'\nDirectory created:'  ${REPAIRQ_LOCAL_DOCKER_DIR}
    }

    clone_the_project() {
        echo "Cloning https://github.com/RepairQ/RepairQ-Docker.git into ${REPAIRQ_LOCAL_DOCKER_DIR}"
        cd "$REPAIRQ_LOCAL_DOCKER_DIR" && git clone https://github.com/RepairQ/RepairQ-Docker.git ${REPAIRQ_LOCAL_DOCKER_DIR}
    }

    echo $'\nCreating the RepairQ-Docker(https://github.com/RepairQ/RepairQ-Docker.git) local project.'

    # The directory doesn't exists, will be created and the github project cloned into it
    if [[ ! -d ${REPAIRQ_LOCAL_DOCKER_DIR} ]]; then
        create_the_project_dir
        clone_the_project

    # The directory already exists, asking the user how to proceed
    else
        read -r -p $'Directory '${REPAIRQ_LOCAL_DOCKER_DIR}' already exists, do you want to overwrite it? [yes/cancel]: '

        # Yes, or cancel the installation
        [[ ${REPLY,,} =~ ^(c|cancel)$ ]] && { echo "Selected Cancel"; exit 1; }
        if [[ ${REPLY,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
            # Removes the directory, recreates and clone the project into it
            echo $'Removing the '${REPAIRQ_LOCAL_DOCKER_DIR}' dir'
            rm -rf ${REPAIRQ_LOCAL_DOCKER_DIR}

            create_the_project_dir
            clone_the_project
        fi
    fi
}
#!/usr/bin/env bash

create_work_dir() {
    # Change the LOCAL_REPAIRQ_PROJECTS_DIR var to the user given value or keep the default value if the given value is blank
    read -rp $'Path to your RepairQ local development directory.\nIf blank default will be assumed ['${REPAIRQ_LOCAL_PROJECTS_DIR}']: ' DIRECTORY
    if [[ ! -z ${DIRECTORY} ]]; then
        REPAIRQ_LOCAL_PROJECTS_DIR=${DIRECTORY}
    fi

    # Creating the RepairQ work dir with the REPAIRQ_LOCAL_PROJECTS_DIR value (if not already exist)
    if [[ ! -d ${REPAIRQ_LOCAL_PROJECTS_DIR} ]]; then
        mkdir "$REPAIRQ_LOCAL_PROJECTS_DIR"
        echo $'\nDirectory created:'  ${REPAIRQ_LOCAL_PROJECTS_DIR}
    fi
    echo 'Local work dir for RepairQ now is:' ${REPAIRQ_LOCAL_PROJECTS_DIR}

    # Creating a symbolic link to your RepairQ work directory (if not already exists)
    if [[ ! -L ${REPAIRQ_LOCAL_SN} ]]; then
        echo "Creating a symbolic link to RepairQ work directory [${REPAIRQ_LOCAL_SN}]"
        ln -s ${REPAIRQ_LOCAL_PROJECTS_DIR} ${REPAIRQ_LOCAL_SN}
    fi
}

clone_docker_repo() {
    REPAIRQ_DOCKER_DIR=${REPAIRQ_LOCAL_PROJECTS_DIR}${REPAIRQ_DOCKER_DIR_SUFFIX}

    if [[ ${REPAIRQ_DOCKER_REPOSITORY_CLONE} -eq 0 ]]; then
        return 1
    fi

    echo $'\nCreating the RepairQ-Docker('${REPAIRQ_DOCKER_REPOSITORY_URL}$') local project.'

    # The directory already exists, asking the user how to proceed
    if [[ -d ${REPAIRQ_DOCKER_DIR} ]]; then
        read -rp $'Directory '${REPAIRQ_DOCKER_DIR}' already exists, do you want to overwrite it? [yes/cancel]: ' REPLY

        # "y|yes|j|ja|s|si|o|oui", or cancel the installation
        [[ ${REPLY,,} =~ ^(c|cancel|)$ ]] && { echo "Selected Cancel"; exit 1; }
        if [[ ${REPLY,,} =~ ^(y|yes|j|ja|s|si|o|oui)$ ]]; then
            echo $'Removing the '${REPAIRQ_DOCKER_DIR}' dir'
            rm -rf ${REPAIRQ_DOCKER_DIR}
        fi
    fi

    # If not cancelled by the user, continues to clone the repository into the correct directory:
    mkdir "$REPAIRQ_DOCKER_DIR"
    echo $'\nDirectory created:'  ${REPAIRQ_DOCKER_DIR}
    echo "Cloning ${REPAIRQ_DOCKER_REPOSITORY_URL} into ${REPAIRQ_DOCKER_DIR}"
    cd "$REPAIRQ_DOCKER_DIR" && git clone ${REPAIRQ_DOCKER_REPOSITORY_URL} ${REPAIRQ_DOCKER_DIR}
}

new_branch_checkout() {
    cd "$REPAIRQ_DOCKER_DIR"

    checkout_new_branch() {
        # Empty is not an acceptable value
        while [[ -z "$BRANCH" ]]; do
            read -rp $'\nEnter your new branch name [e.g. '${USER}']: ' BRANCH
        done

        # Successful checkout or start again
        if [[ ${REPAIRQ_DOCKER_REPOSITORY_NEW_BRANCH_CHECKOUT} -eq 1 ]]; then
            git checkout -b "user/${BRANCH}" || $(BRANCH="" && checkout_new_branch)
        fi
    }

    checkout_new_branch
    git branch

    # Copying the REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR to a directory corresponding your BRANCH name
    if [[ ${REPAIRQ_DOCKER_REPOSITORY_NEW_BRANCH_RSYNC} -eq 1 ]]; then
        rsync -avP ${REPAIRQ_DOCKER_DIR}/dev-local/${REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR}/ ${REPAIRQ_DOCKER_DIR}/dev-local/${BRANCH}/
    fi
}


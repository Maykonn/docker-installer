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
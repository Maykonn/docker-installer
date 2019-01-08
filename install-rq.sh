#!/bin/bash
source ./lib.sh

REPAIRQ_LOCAL_PROJECTS_DIR=${HOME}/Projects/repairq
REPAIRQ_LOCAL_SN="/var/www/rq"

REPAIRQ_DOCKER_REPOSITORY_CLONE=0
REPAIRQ_DOCKER_REPOSITORY_NEW_BRANCH_CHECKOUT=0
REPAIRQ_DOCKER_REPOSITORY_NEW_BRANCH_RSYNC=0
REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR="linux-tpl"
REPAIRQ_DOCKER_REPOSITORY_URL="https://github.com/RepairQ/RepairQ-Docker.git"
REPAIRQ_DOCKER_DIR_SUFFIX="/RepairQ-Docker"
REPAIRQ_DOCKER_DIR=${REPAIRQ_LOCAL_PROJECTS_DIR}${REPAIRQ_DOCKER_DIR_SUFFIX}

echo $'Starting the installation\n'

create_work_dir
clone_docker_repo
new_branch_and_copies_tpl

echo $'\nInstallation finished'
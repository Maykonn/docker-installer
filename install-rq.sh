#!/bin/bash
source ./lib.sh

HOME_PATH_PREFIX="/var/www"
HOME_PATH=${HOME_PATH_PREFIX}"/"${USER}

REPAIRQ_LOCAL_PROJECTS_DIR_SUFFIX="/Projects/repairq"
REPAIRQ_LOCAL_PROJECTS_DIR=${HOME_PATH}${REPAIRQ_LOCAL_PROJECTS_DIR_SUFFIX}
REPAIRQ_LOCAL_SN=${HOME_PATH_PREFIX}"/rq"

REPAIRQ_DOCKER_LINUX_TEMPLATE_DIR="apl"
REPAIRQ_DOCKER_DIR_SUFFIX="RepairQ-Docker"
REPAIRQ_DOCKER_REPOSITORY_URL="https://github.com/RepairQ/"${REPAIRQ_DOCKER_DIR_SUFFIX}".git"
REPAIRQ_DOCKER_GIT=0 # Clones the RepairQ-Docker from git and checkout to a new branch
REPAIRQ_DOCKER_DIR=${REPAIRQ_LOCAL_PROJECTS_DIR}${REPAIRQ_DOCKER_DIR_SUFFIX}
REPAIRQ_USER_SPECIFIC_DOCKER_DIR=""

echo $'Starting the installation\n'

#check_requirements
#create_work_dir
#clone_docker_repo
#new_branch_checkout
configure_installation_files

echo $'\nInstallation finished'
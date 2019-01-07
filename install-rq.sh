#!/bin/bash
source ./lib.sh

REPAIRQ_LOCAL_PROJECTS_DIR=${HOME}/Projects/repairq
REPAIRQ_LOCAL_DOCKER_DIR_SUFFIX="/RepairQ-Docker"
REPAIRQ_LOCAL_DOCKER_DIR=""

echo Starting the installation

create_work_dir
clone_docker_repo

echo Installation finished
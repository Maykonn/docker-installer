#!/bin/bash
source ./lib.sh

REPAIRQ_LOCAL_PROJECTS_DIR=${HOME}/Projects/repairq
REPAIRQ_LOCAL_DOCKER_DIR_SUFFIX="/RepairQ-Docker"
REPAIRQ_LOCAL_DOCKER_DIR=""

echo Starting installation

create_work_dir

echo ${REPAIRQ_LOCAL_DOCKER_DIR}
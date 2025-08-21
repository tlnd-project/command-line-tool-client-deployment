#!/bin/bash
#-------------------------------------------------------------------------------
# Shell Script: test-tac-automation
# Description: This script deploys the tac-automation project.
# Author: Ricardo Bermudez Bermudez
# Usage: bash refactor_deployment.sh $BRANCH_NAME
# Version: 0.1
#-------------------------------------------------------------------------------

# Its necessary the next files:
# .env_source_code  => define these variables: USER_EXECUTE, BITBUCKET_DOMAIN, BITBUCKET_TOKEN, BITBUCKET_USER, BITBUCKET_REPOSITORY
# .env_keys         => define these variables: BITBUCKET_DATA_SOURCE_URL, BITBUCKET_DATA_SOURCE_BRANCH, BITBUCKET_DATA_SOURCE_TOKEN
# dtcc.jar
# dtcc_bbk.key

# ===> validate < ===
EXECUTION_DIR="$(dirname "$(readlink -f "$0")")"
PATH_DTCC_JAR="$EXECUTION_DIR/dtcc.jar"
PATH_DTCC_BBK_KEY="$EXECUTION_DIR/dtcc_bbk.key"
PATH_ENV_KEYS="$EXECUTION_DIR/.env_keys"
PATH_ENV_SOURCE_CODE="$EXECUTION_DIR/.env_source_code"

if [ $# -eq 0 ]; then
  echo "No parameter 'branch name' provided"
  exit 1
fi

if [[ -f "$PATH_DTCC_JAR" ]]; then
  echo "The file 'dtcc.jar' is necessary"
  exit 1
fi
if [[ -f "$PATH_DTCC_BBK_KEY" ]]; then
  echo "The file 'dtcc_bbk.key' is necessary"
  exit 1
fi
if [[ -f "$PATH_ENV_KEYS" ]]; then
  echo "The file '.env_keys' is necessary"
  exit 1
fi
if [[ -f "$PATH_ENV_SOURCE_CODE" ]]; then
  echo "The file '.env_source_code' is necessary"
  exit 1
fi

# === > Imports < ===
source "$EXECUTION_DIR/lib/tools.sh"
source "$EXECUTION_DIR/lib/logger.sh"
source "$EXECUTION_DIR/lib/bitbucket.sh"
source "$EXECUTION_DIR/.env_source_code"

BRANCH_NAME=$1
NOW=`date +%Y%m%d_%H%M%S`
BASE_WORK_DIRECTORY="/apps/TAL/Script"
NAME_DIRECTORY_PROJECT="tac-automation"
NAME_DIRECTORY_DEPLOYMENT="tac-automation-deployment"
PATH_PROJECT_TAC_AUTOMATION="${BASE_WORK_DIRECTORY}/${NAME_DIRECTORY_PROJECT}"
PATH_DEPLOYMENT_TAC_AUTOMATION="${BASE_WORK_DIRECTORY}/${NAME_DIRECTORY_DEPLOYMENT}"
PATH_PROJECT_TAR_GZ="${PATH_DEPLOYMENT_TAC_AUTOMATION}/${NAME_DIRECTORY_PROJECT}.tar.gz"

# === > Check the user < ===
check_user_run_script "$USER_EXECUTE"
if [[ $? -ne 0 ]];
then
  exit 1
fi

log_info "step 1 backup the project if exist"
if [[ -d "$PATH_PROJECT_TAC_AUTOMATION" ]];
then
  tar -czf "${PATH_DEPLOYMENT_TAC_AUTOMATION}/${NAME_DIRECTORY_PROJECT}${NOW}.tar.gz" -C $BASE_WORK_DIRECTORY $NAME_DIRECTORY_PROJECT
  remove_safely_directory "$PATH_PROJECT_TAC_AUTOMATION"
fi

log_info "step 2 download project.tar.gz"
token=$(java -jar "$PATH_DTCC_JAR" decrypt "$PATH_DTCC_BBK_KEY" "$BITBUCKET_TOKEN")
download_project_tar_gz_user_bitbucket "$BITBUCKET_DOMAIN" "$token" "$BITBUCKET_USER" \
                                       "$BITBUCKET_REPOSITORY" "$BRANCH_NAME" \
                                       "$PATH_PROJECT_TAR_GZ"

log_info "step 3 unzip project.tar.gz"
tar -xzf "$PATH_PROJECT_TAR_GZ" -C $BASE_WORK_DIRECTORY
rm "$PATH_PROJECT_TAR_GZ"

log_info "step 4 move the .env_keys"
mv "$PATH_ENV_KEYS" $PATH_PROJECT_TAC_AUTOMATION

log_info "step 5 set up the project"
# === > Download the project < ===
setup_virtual_environment_with_nexus "$PATH_PROJECT_TAC_AUTOMATION"

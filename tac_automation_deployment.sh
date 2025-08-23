set -eo pipefail

# === > Configuration < ===
HOSTNAME=`hostname`
NOW=`date +%Y%m%d_%H%M%S`
EXECUTION_DIR="$(dirname "$(readlink -f "$0")")"
mkdir -p "$EXECUTION_DIR/logs"

# === > Imports < ===
source "$EXECUTION_DIR/lib/logger.sh"
source "$EXECUTION_DIR/lib/bitbucket.sh"
source "$EXECUTION_DIR/lib/tools.sh"
source "$EXECUTION_DIR/.env"

# === > Check the user < ===
check_user_run_script "$USER_EXECUTE"
if [[ $? -ne 0 ]];
then
  exit 1
fi

# === > Download deployment.csv < ===
log_info "step 2 download deployment.csv"
download_file_user_bitbucket "$BITBUCKET_DOMAIN" "$BITBUCKET_TOKEN" "$BITBUCKET_USER" \
                             "$DEPLOYMENT_REPOSITORY" "$DEPLOYMENT_BRANCH_CSV" \
                             "$DEPLOYMENT_FILE_FULLPATH" "$DEPLOYMENT_OUT_FULLPATH"

if [[ $? -ne 0 ]];
then
  exit 2
fi

# === > Create backup < ===
FAIL_IN_SILENCE=1
NOT_FAIL_IN_SILENCE=0

log_info "step 3 create backup"
create_backup_directory $FAIL_IN_SILENCE "$DIRECTORY_FULLPATH_TAC_AUTOMATION"

if [[ $? -ne 0 ]];
then
  exit 3
fi

# === > Reading Deployment Metadata < ===
log_info "step 4 Reading Deployment Metadata"

declare -a csv_to_array
convert_csv_to_array "$DEPLOYMENT_OUT_FULLPATH"

if [[ $? -ne 0 ]];
then
  exit 4
fi


# === > Download the project < ===
log_info "step 5 Process the deployment.csv"
skip=1
for line in "${csv_to_array[@]}"; do
  if (( skip )); then skip=0; continue; fi # skip the head of the CSV

  FILE=`echo $line | awk -F ',' '{print $1}'`
  VERSION=`echo $line | awk -F ',' '{print $2}'`
  TARGET_DIR=`echo $line | awk -F ',' '{print $3}'`
  FILE_PERMISSION=`echo $line | awk -F ',' '{print $4}'`
  DIRECTORY_PERMISSION=`echo $line | awk -F ',' '{print $5}'`
  RELEASE_BRANCH=`echo $line | awk -F ',' '{print $6}'`
  HOST=`echo $line | awk -F ',' '{print $7}'`

  # set the file name only if the host is equal to $HOST, or if the host parameter does not exist
  if [ -z "$HOST" ]; then
    name_file="${FILE}_${VERSION}"
  elif [ $HOST == $HOSTNAME ]; then
    name_file="${FILE}_${HOST}_${VERSION}"
  else
    log_info "Skip the file ${FILE}_${HOST}_${VERSION}"
    continue
  fi

  # create directories if they do not exist
  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p -m $DIRECTORY_PERMISSION "$TARGET_DIR"
    if [ $? -eq 0 ]; then
      log_info "created Directory $TARGET_DIR"
    else
      log_error "Unable to create $TARGET_DIR, Aborting the Deployment Process on $HOSTNAME at $NOW"
      exit 5;
    fi
  else
    log_info "Target Directory $TARGET_DIR already exists"
  fi

  # creat a backup if the file exist
  if [ -f "$TARGET_DIR$FILE" ]; then
    log_info "Taking backup of Deployment File $TARGET_DIR$FILE"
    cp "$TARGET_DIR$FILE" "$TARGET_DIR$FILE"_bkp_"$NOW"
  fi

  download_file_user_bitbucket "$BITBUCKET_DOMAIN" "$BITBUCKET_TOKEN" "$BITBUCKET_USER" \
                               "$DEPLOYMENT_REPOSITORY" "$RELEASE_BRANCH" \
                               "$DEPLOYMENT_PATH_PROJECT/$name_file" "$TARGET_DIR$FILE"

  if [[ $? -ne 0 ]];
  then
    log_error "Unable to Download a Deployment File from Bitbucket, Skipping the Deployment Process on $HOSTNAME for $FILE"
    exit 6
  fi

  chmod $FILE_PERMISSION "$TARGET_DIR$FILE"
  if [ $? -eq 0 ]; then
    log_info "$TARGET_DIR$FILE permission changed successfully"
  else
    log_error "Unable to Set File Permission on $TARGET_DIR$FILE"
    log_error "Deployment ended with Issues on $HOSTNAME at $NOW, Need manual intervention"
    exit 7;
  fi
done

# === > Download the project < ===
setup_virtual_environment_with_nexus "/apps/TAL/Scripts/tac-automation"

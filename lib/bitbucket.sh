#!/bin/bash

EXECUTION_DIR="$(dirname "$(readlink -f "$0")")"
source "$EXECUTION_DIR/lib/logger.sh"

# ===> avoids double importation
if [[ -n "${__BITBUCKET_IMPORTED__:-}" ]]; then
  return
fi
__BITBUCKET_IMPORTED__=1

# download_file_user_bitbucket
#   download the file from bitbucket repository
# parameters:
#   bitbucket_domain         - domain
#   bitbucket_bearer         - token authorization Bearer
#   bitbucket_user           - user of the repository
#   bitbucket_repository     - name of the repository
#   bitbucket_branch         - name of the branch
#   bitbucket_fullpath_file  - file to download, it is necessary full path
#   output_fullpath_file     - full path and name for save the file
# return:
#   return with code 0 upon successful execution
# example:
#   download_file_user_bitbucket "domain.com" "KEY" "user" \
#                                "test_repository" "test_branch" "directory/test/deploy.py" \
#                                "/home/user/directory/deploy.py"
#
download_file_user_bitbucket(){
  log_info "[dfub]: == > Execute download_file_user_bitbucket"
  local bitbucket_domain="$1"
  local bitbucket_bearer="$2"
  local bitbucket_user="$3"
  local bitbucket_repository="$4"
  local bitbucket_branch="$5"
  local bitbucket_fullpath_file="$6"
  local output_fullpath_file="$7"

  local bitbucket_url="\
https://${bitbucket_domain}\
/rest/api/latest/users/${bitbucket_user}/repos/${bitbucket_repository}/raw/${bitbucket_fullpath_file}\
?at=refs%2Fheads%2F${bitbucket_branch}\
"
  log_debug "[dfub]: $bitbucket_url"

  http_code=$(curl -s -S -H "Authorization: Bearer ${bitbucket_bearer}" \
        -o "${output_fullpath_file}" \
        -L "${bitbucket_url}" \
        -w "%{http_code}")
  exit_code=$?

  if [[ "$exit_code" -ne 0 ]];
  then
    log_error "[dfub]: fail curl: exit with $exit_code"
    rm -f "$output_fullpath_file"
    return 1
  fi

  if [[ "$http_code" != "200" ]];
  then
    log_error "[dfub]: fail http: exit with $http_code"
    rm -f "$output_fullpath_file"
    return 2
  fi

  return 0
}


# download_project_tar_gz_user_bitbucket
#   download the project.tar.gz from bitbucket repository
# parameters:
#   bitbucket_domain         - domain
#   bitbucket_bearer         - token authorization Bearer
#   bitbucket_user           - user of the repository
#   bitbucket_repository     - name of the repository
#   bitbucket_branch         - name of the branch
#   output_fullpath_file     - full path and name for save the file
# return:
#   return with code 0 upon successful execution
# example:
#   download_project_tar_gz_user_bitbucket "domain.com" "KEY" "user" \
#                                          "test_repository" "test_branch" \
#                                          "/home/user/directory/deploy.tar.gz"
#
download_project_tar_gz_user_bitbucket(){
  log_info "[dfub]: == > Execute download_file_user_bitbucket"
  local bitbucket_domain="$1"
  local bitbucket_bearer="$2"
  local bitbucket_user="$3"
  local bitbucket_repository="$4"
  local bitbucket_branch="$5"
  local output_fullpath_file="$6"

  local bitbucket_url="\
https://${bitbucket_domain}\
/rest/api/latest/users/${bitbucket_user}/repos/${bitbucket_repository}/archive\
?at=refs%2Fheads%2F${bitbucket_branch}&format=tar.gz\
"
  log_debug "[dfub]: $bitbucket_url"

  http_code=$(curl -s -S -H "Authorization: Bearer ${bitbucket_bearer}" \
        -o "${output_fullpath_file}" \
        -L "${bitbucket_url}" \
        -w "%{http_code}")
  exit_code=$?

  if [[ "$exit_code" -ne 0 ]];
  then
    log_error "[dfub]: fail curl: exit with $exit_code"
    rm -f "$output_fullpath_file"
    return 1
  fi

  if [[ "$http_code" != "200" ]];
  then
    log_error "[dfub]: fail http: exit with $http_code"
    rm -f "$output_fullpath_file"
    return 2
  fi

  return 0
}


# download_repository_tar_gz:
#   download the repository example.tar.gz from bitbucket
# parameters:
#   bitbucket_domain         - domain
#   bitbucket_bearer         - token authorization Bearer
#   bitbucket_project_key    - the key to the project. if the project is personal the add the symbol ~
#   bitbucket_repository     - name of the repository
#   bitbucket_branch         - name of the branch
#   output_fullpath_name     - full path and name for save the file
# return:
#   return with code 0 upon successful execution
# example:
#   download_repository_tar_gz "domain.com" "KEY" "key-project" \
#                              "test_branch" "directory/test/deploy.py" \
#                              "/home/user/directory/project.tar.gz"
#
download_repository_tar_gz_from_project(){
  log_info "[dfub]: == > Execute download_file_user_bitbucket"
  local bitbucket_domain="$1"
  local bitbucket_bearer="$2"
  local bitbucket_project_key="$3"
  local bitbucket_repository="$4"
  local bitbucket_branch="$5"
  local output_fullpath_name="$6"

  local bitbucket_url="\
https://${bitbucket_domain}\
/rest/api/latest/projects/${bitbucket_project_key}/repos/${bitbucket_repository}/archive\
?at=refs%2Fheads%2F${bitbucket_branch}&format=tar.gz\
"
  log_debug "[drtz]: $bitbucket_url"

  http_code=$(curl -s -S -H "Authorization: Bearer ${bitbucket_bearer}" \
        -o "${output_fullpath_name}" \
        -L "${bitbucket_url}" \
        -w "%{http_code}")
  exit_code=$?

  if [[ "$exit_code" -ne 0 ]];
  then
    log_error "[drtz]: fail curl: exit with $exit_code"
    rm -f "$output_fullpath_name"
    return 1
  fi

  if [[ "$http_code" != "200" ]];
  then
    log_error "[drtz]: fail http: exit with $http_code"
    log_error "[drtz]: $(<"$output_fullpath_name")"
    rm -f "$output_fullpath_name"
    return 2
  fi

  return 0
}

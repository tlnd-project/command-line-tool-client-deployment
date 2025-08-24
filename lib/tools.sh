#!/bin/bash

EXECUTION_DIR="$(dirname "$(readlink -f "$0")")"
source "$EXECUTION_DIR/lib/logger.sh"

# ===> avoids double importation
if [[ -n "${__TOOLS_IMPORTED__:-}" ]]; then
  return
fi
__TOOLS_IMPORTED__=1

# check if the script run with the specific user
check_user_run_script(){
  log_info "[curs]: == > Execute check_user_run_script"
  local required_user="$1"
  local current_user="$(whoami)"

  if [[ "$current_user" != "$required_user" ]]; then
    log_error "[curs]: Run the script with the other user than required: $required_user is different to $current_user"
    return 1
  fi

  return 0
}

# create the virtual environment for python with nexus repository and install requirements.txt
setup_virtual_environment_with_nexus(){
  log_info "[svewn]: == > Execute setup_virtual_environment_with_nexus"
  local virtual_fullpath_directory_install="$1"
  local virtual_directory_name="${2:-"venv"}"

  local dtcc_nexus_repo=https://repo.dtcc.com/repository/dtcc-pypi-public/simple
  local dtcc_nexus_host=repo.dtcc.com
  local virtual_venv="$virtual_fullpath_directory_install/$virtual_directory_name"

  if [ ! -e "$virtual_venv/bin/activate" ];
  then
    python3 -m venv $virtual_venv
  fi
  source $virtual_venv/bin/activate
  pip install --upgrade pip -i $dtcc_nexus_repo --trusted-host $dtcc_nexus_host
  pip install -r $virtual_fullpath_directory_install/requirements.txt -i $dtcc_nexus_repo --trusted-host $dtcc_nexus_host

}

# create a backup of all directory
create_backup_directory(){
  # TODO: test the permission of the user for create directory
  log_info "[cbd]: == > Execute create_backup_directory"
  local fail_silently=${1} # 0 => false or 1 => true
  local directory_to_backup="${2%/}" # %/ remove the slash / if the path has the symbol

  if [[ ! -d "$directory_to_backup" ]];
  then
    if [[ $fail_silently -eq 0 ]];
    then
      log_error "[cdb]: The directory $directory_to_backup does not exist"
      return 1
    else
      return 0
    fi
  fi

  local default_name_of_directory="$(basename "$directory_to_backup")"
  local name_of_directory_backup="${3:-$default_name_of_directory}.backup"
  local default_path_to_backup="$(dirname "$directory_to_backup")"
  local path_to_backup="${4:-$default_path_to_backup}"

  if [[ -d "$path_to_backup/$name_of_directory_backup" ]];
  then
    if [[ $fail_silently -eq 0 ]];
    then
      log_error "[cdb]: The directory $path_to_backup/$name_of_directory_backup exist"
      return 2
    else
      return 0
    fi
  fi

  mv "$directory_to_backup" "$path_to_backup/$name_of_directory_backup"
  return 0

}

#
remove_safely_directory(){
  log_info "[rsd]: == > Execute remove_safely_directory"
	DEFAULT_INVALID_ROOT_DIRECTORY=/|/etc|/bin|/boot|/dev|/etc|/lib|/lib64|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var
	local directory_to_remove="${1%/}"
	local root_directory=$(dirname "$directory_to_remove")
	local directory_base="${2:-$root_directory}"
	local invalid_root_directory="${3:-$DEFAULT_INVALID_ROOT_DIRECTORY}"

	if [[ -z "$directory_to_remove" ]];
	then
		log_error "[rsd]: The directory to remove is empty"
		return 1
	fi

	if [[ ! -d "$directory_to_remove" ]];
	then
		log_error "[rsd]: The directory to remove no exist: $directory_to_remove"
		return 2
	fi

	case "$root_directory" in
	    $invalid_root_directory)
 		    log_error "[rsd]: The directory is inside of the directories without permission to deleted => $DEFAULT_INVALID_ROOT_DIRECTORY"
		    return 3
	    ;;
	esac

	# the user can defined the work safely path
  # the $directory_base is interpreted as a regular expression.
	if [[ ! "$directory_to_remove" =~ $directory_base ]];
	then
		log_error "[rsd]: The directory $directory_to_remove can not removed"
		return 4
	fi

	rm -rf "$directory_to_remove"
	log_info "the directory $directory_to_remove has been removed"
	return 0
}

# read the file and put the rows into the array. The variable csv_to_array need to declare before the function
convert_csv_to_array(){
  log_info "[ccta]: == > convert_csv_to_array"
  local file_fullpath="$1"
  local i=0
  local tmp
  local line
  csv_to_array=() # global variable
  log_debug "[ccta]: Path $file_fullpath"

  while IFS= read -r line || [ -n "$line" ]; do
    log_debug "[ccta]: $line"
    tmp=$(echo "$line" | xargs)
    if [[ -n "$tmp" ]]; then
      csv_to_array[i]="$tmp"
      i=$((i + 1))
      log_debug "add $tmp"
    else
      log_debug "skipt $tmp"
    fi
  done < "$file_fullpath"
  return 0
}

valid_file_finally_enter(){
  local file="$1"
  local last_byte
  last_byte=$(tail -c1 "$file" | hexdump -v -e '1/1 "%02x"')
  if [[ $last_byte == "0a" ]];
  then
    return 0
  fi
  return 1
}
#!/bin/bash

# ===> avoids double importation
if [[ -n "${__LOGGER_IMPORTED__:-}" ]]; then
  return
fi
__LOGGER_IMPORTED__=1

# === > start the script
LOG_LEVEL=${LOG_LEVEL:-"INFO"}
LOG_FILE=${LOG_FILE:-"./logs/out.log"}

declare -A LOG_LEVELS=(
  ["ERROR"]=0
  ["WARN"]=1
  ["INFO"]=2
  ["DEBUG"]=3
)

declare -A LOG_COLORS=(
  ["ERROR"]="\e[31m"
  ["WARN"]="\e[33m"
  ["INFO"]="\e[32m"
  ["DEBUG"]="\e[34m"
)

log_msg (){
  local level="$1"
  local message="$2"
  local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  local tag_end_color="\e[0m"

  if [[ ${LOG_LEVELS[$level]} -le ${LOG_LEVELS[$LOG_LEVEL]} ]];
  then
    echo -e "[${LOG_COLORS[$level]}${level}] $timestamp - ${message}${tag_end_color}\n"
    echo "[$level] $timestamp - $message" >> "$LOG_FILE"
  fi
}

# === > public methods
log_error(){
  log_msg "ERROR" "$@"
}
log_warn(){
  log_msg "WARN" "$@"
}
log_info(){
  log_msg "INFO" "$@"
}
log_debug(){
  log_msg "DEBUG" "$@"
}

set -uo pipefail

LOGGING_SCRIPTNAME="$(basename "$0")"

# Enable handlers in this array by setting the handler's name to the log level
# its enabled for.
declare -A LOGGING_HANDLERS

declare -A LOGGING_SEVERITIES=(
  ['emerg']=0
  ['alert']=1
  ['crit']=2
  ['err']=3
  ['warn']=4
  ['notice']=5
  ['info']=6
  ['debug']=7
)
readonly LOGGING_SEVERITIES

declare -a LOGGING_DISPLAY_NAMES=(
  'EMERG'
  'ALERT'
  'CRITICAL'
  'ERROR'
  'WARNING'
  'NOTICE'
  'INFO'
  'DEBUG'
)

logging_exception() {
  printf "Logging Exception: %s\n" "$*" >&2
}

# function log (level, message, ...)
#
log() {
  local log_level="$1"
  shift
  local line="$*"

  local name; local -i severity
  for name in "${!LOGGING_SEVERITIES[@]}"; do
    if [[ $log_level =~ $name ]]; then
      severity="${LOGGING_SEVERITIES[${name}]}"
      break
    fi
  done
  if [[ -z $severity ]]; then
    log error "Undefined log level trying to log: ${log_level} ${line}"
    return 1
  fi

  local handler; local -i level_enabled
  for handler in "${!LOGGING_HANDLERS[@]}"; do
    level_enabled="${LOGGING_HANDLERS[${handler}]:--1}"
    if ((severity <= level_enabled)); then
      "$handler" "$severity" "$line"
    fi
  done
}

# function logging_syslog (severity, message, ...)
#
logging_syslog() {
  local severity="$1"
  shift
  local line="$*"

  local tag="${LOGGING_SYSLOG_TAG:-${LOGGING_SCRIPTNAME}}"
  local facility="${LOGGING_SYSLOG_FACILITY:-local0}"

  local pid="$$"

  local cmd=( logger
              --id="${pid}" --tag="${tag}"
              --priority="${facility}.${severity}"
              -- "$line" )
  if ! "${cmd[@]}"; then
    logging_exception "${cmd[*]}"
  fi
}

# function logging_file (severity, message, ...)
#
logging_file() {
  local severity="$1"
  shift
  local line="$*"

  local level_name="${LOGGING_DISPLAY_NAMES[${severity}]:-UNKNOWN}"

  local file_path
  if [[ ${LOGGING_FILE_PATH:-} ]]; then
    file_path="$LOGGING_FILE_PATH"
  else
    local tmp_dir="${TMPDIR:-/tmp}"
    file_path="${tmp_dir}/${LOGGING_SCRIPTNAME}.log"
  fi
  local date_format="${LOGGING_DATE_FORMAT:-%F %T}"

  local date
  # Strip leading '+' from date_format if present.
  printf -v date "%(${date_format#+})T" -1

  local cmd=( printf '%s %s %s\n' "$date" "$level_name" "$line" )
  if ! "${cmd[@]}" >> "$file_path"; then
    logging_exception "${cmd[*]} >> ${file_path}"
  fi
}

# function logging_json (severity, message, ...)
#
logging_json() {
  local severity="$1"
  shift
  local line="$*"

  local json_path
  if [[ ${LOGGING_JSON_PATH:-} ]]; then
    json_path="$LOGGING_JSON_PATH"
  else
    local tmp_dir="${TMPDIR:-/tmp}"
    json_path="${tmp_dir}/${LOGGING_SCRIPTNAME}.log.json"
  fi

  local cmd=( printf '{"timestamp":%d,"level":%d,"message":"%s"}\n'
              "$EPOCHSECONDS" "$severity" "$line" )
  if ! "${cmd[@]}" >> "$json_path"; then
    logging_exception "${cmd[*]} >> ${json_path}"
  fi
}

# function logging_stderr (severity, message, ...)
#
logging_stderr() {
  local severity="$1"
  shift
  local line="$*"

  local prog="${LOGGING_PROG:-${LOGGING_SCRIPTNAME}}"
  local level_name="${LOGGING_DISPLAY_NAMES[${severity}]:-UNKNOWN}"

  printf '%s: %s: %s\n' "$prog" "$level_name" "$line" >&2
}

# shellcheck disable=SC2034
declare prev_cmd="null"
declare this_cmd="null"
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG || \
  logging_exception 'DEBUG trap failed to set'

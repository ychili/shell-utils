declare -a LOGGING_COLORS=(
  '1;37;41' # emerg: bold white on red
  '1;37;41' # alert: bold white on red
  '1;37;43' # crit: bold white on yellow
  '1;91'    # err: bold bright red
  '33'      # warn: yellow
  '0'       # notice
  '0'       # info
  '2'       # debug: faint
)

# function logging_stderr (severity, message, ...)
#
# Log message to standard error.
# Color the level name from LOGGING_DISPLAY_NAMES with SGR codes from
# LOGGING_COLORS.
logging_stderr() {
  local severity="$1"
  shift
  local line="$*"

  local code="${LOGGING_COLORS[${severity}]:-0}"
  local prog="${LOGGING_PROG:-${LOGGING_SCRIPTNAME}}"
  local level_name="${LOGGING_DISPLAY_NAMES[${severity}]:-UNKNOWN}"

  printf '%s: \033[%sm%s\033[0m: %s\n' \
    "$prog" "$code" "$level_name" "$line" >&2
}

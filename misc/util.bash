# Suspend execution, displaying the prompt "Press any key to continue . . .",
# until a key is pressed or, optionally, until a timeout is reached.
#
# Optional number of seconds to timeout is read from the first positional
# parameter or from the global variable `timeout`.
pause() {
  local -a read_opts=()
  local mytimeout="${1:-${timeout}}"
  if [[ -n $mytimeout ]]; then
    read_opts+=( -t "${mytimeout}" )
  fi

  # shellcheck disable=SC2162
  read -s -n 1 -p "Press any key to continue . . . " "${read_opts[@]}"
  # -s: Silent mode
  # -n 1: Return after reading 1 character
  echo
}

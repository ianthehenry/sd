#!/usr/bin/env bash

__sd_join_path() {
  echo "$@" | tr ' ' /
}

__sd_which() {
  echo "$1"
}

__sd_cat() {
  ${SD_CAT:-cat} "$1"
}

__sd_edit() {
  ${SD_EDITOR:-${VISUAL:-${EDITOR:-vi}}} "$1"
}

__sd_directory_help() {
  local target="$1"
  local i file helpfile help command
  local -a commands helps
  if [[ -d "$target" ]]; then
    helpfile="$target/help"
  else
    helpfile="$target.help"
  fi
  # in case you have `sd help` as a command alias, we don't
  # want to print that when you just run "sd" by itself.
  # Admittedly we don't check this in any other place, which
  # could be considered a bug, but whatever it's a weird little
  # hack and no one uses this.
  if [[ -e "$helpfile" && ! -x "$helpfile" ]]; then
    __sd_cat "$helpfile"
    echo
  else
    command=$(basename "$target")
    echo "$command commands"
    echo
  fi
  commands=()
  helps=()
  for file in "$target"/*; do
    if [[ ! -x "$file" ]]; then
      continue
    fi
    command=$(basename "$file")

    if [[ -d "$file" ]]; then
      helpfile="$file/help"
      if [[ -f "$helpfile" ]]; then
        help=$(head -n1 "$helpfile")
      else
        help="$command commands"
      fi
      command="$command ..."
    else
      helpfile="$file.help"
      if [[ -f "$helpfile" ]]; then
        help=$(head -n1 "$helpfile")
      else
        help=$(sed -nE -e '/^#!/d' -e '/^#/{s/^# *//; p; q;}' "$file")
      fi
    fi

    commands+=("$command")
    helps+=("$help")
  done

  if [[ ${#commands[@]} -eq 0 ]]; then
    echo "(no subcommands found)"
  else
    local max_length=0
    local length
    for command in "${commands[@]}"; do
      length=${#command}
      max_length=$((length > max_length ? length : max_length))
    done

    if [[ -n ${ZSH_EVAL_CONTEXT+x} ]]; then
      set -o LOCAL_OPTIONS
      # we need to ensure we have 0-indexed arrays
      # in order for this loop to work properly.
      # zsh doesn't support ${!commands[@]} expansion
      set -o KSH_ARRAYS
    fi

    for ((i = 0; i < ${#commands[@]}; i++)); do
      printf "%-${max_length}s -- %s\n" "${commands[i]}" "${helps[i]}"
    done
  fi
}

__sd_help() {
  local target=$1

  if [[ -d "$target" ]]; then
    __sd_directory_help "$target"
  elif [[ -f "$target.help" ]]; then
    __sd_cat "$target.help"
  else
    help=$(sed -nE -e '/^#!/d' -e $':start\n /^#/{ s/^# ?//; p; \nb start\n }' "$target")
    if [[ -z "$help" ]]; then
      echo "there is no help for you here" >&2
      exit 1
    else
      echo "$help"
    fi
  fi
}

__sd_print_template() {
  if [[ -f "$1/template" ]]; then
    cat "$1/template"
  else
    if [[ "$1" = "${SD_ROOT:-$HOME/sd}" ]]; then
      cat <<EOF
#!/usr/bin/env bash

set -euo pipefail
EOF
    else
      __sd_print_template "$(dirname "$1")"
    fi
  fi
}

__sd_new() {
  local script dir target body
  target="$1"
  shift

  local -a command_path=()

  for arg in "$@"; do
    case "$arg" in
      --new) shift; break ;;
      *) command_path+=("$arg"); shift ;;
    esac
  done

  if [[ ${#command_path[@]} -eq 0 ]]; then
    echo "error: $target already exists" >&2
    exit 1
  fi

  if [[ -f "$target" ]]; then
    echo "error: command prefix $target is a regular file" >&2
    exit 1
  fi

  body="$*"

  script="$target"/"$(__sd_join_path "${command_path[@]}")"

  if [[ -e "$script" ]]; then
    echo "$script already exists!" >&2
    exit 1
  fi

  dir="$(dirname "$script")"
  mkdir -p "$dir"
  (
    __sd_print_template "$dir"
    if [[ -n "$body" ]]; then
      printf "\n%s\n" "$body"
    fi
  ) >"$script"

  chmod +x "$script"

  if [[ -z "$body" ]]; then
    __sd_edit "$script"
  fi
}

__sd_new_user_help() {
  root=$1
  echo >&2 "error: $root not found"
  echo >&2
  echo >&2 "It looks like you don't have a script directory yet!"
  echo >&2
  echo >&2 "Get started by creating your first script:"
  echo >&2
  echo >&2 "    sd hello --new 'echo \"Hello, sd!\"'"
  echo >&2
  echo >&2 "And then run it like this:"
  echo >&2
  echo >&2 "    sd hello"
}

__sd() {
  set -euo pipefail

  local root=${SD_ROOT:-$HOME/sd}

  if [[ -e "$root" && ! -d "$root" ]]; then
    echo "error: $root is not a directory" >&2
    exit 1
  fi

  local target=$root
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ -d "$target/$arg" ]]; then
      target="$target/$arg"
      shift
    elif [[ -f "$target/$arg" ]]; then
      target="$target/$arg"
      shift
      break
    else
      break
    fi
  done

  local found_help="false"
  local found_new="false"
  local found_edit="false"
  local found_cat="false"
  local found_which="false"
  local found_really="false"

  for arg in "$@"; do
    case "$arg" in
      --help) found_help=true ;;
      --new) found_new=true ;;
      --edit) found_edit=true ;;
      --cat) found_cat=true ;;
      --which) found_which=true ;;
      --really) found_really=true ;;
    esac
  done

  # you're allowed to run --new even if there is no
  # script directory root, in order to bootstrap it
  if [[ "$found_really" = "true" || "$found_new" = "false" ]]; then
    if [[ ! -d "$root" ]]; then
        __sd_new_user_help "$root"
        exit 1
      fi
  fi

  if [[ "$found_really" = "true" ]]; then
    local -a preserved=()
    for arg in "$@"; do
      case "$arg" in
        '--really') shift; break ;;
        *) preserved+=("$arg"); shift ;;
      esac
    done
    if [[ ${#preserved[@]} -gt 0 ]]; then
      set -- "${preserved[@]}" "$@"
    fi
  elif [[ "$found_new" = "true" ]]; then
    __sd_new "$target" "$@"
    exit 0
  elif [[ "$found_help" = "true" ]]; then
    __sd_help "$target"
    exit 0
  elif [[ "$found_edit" = "true" ]]; then
    __sd_edit "$target"
    exit 0
  elif [[ "$found_cat" = "true" ]]; then
    __sd_cat "$target"
    exit 0
  elif [[ "$found_which" = "true" ]]; then
    __sd_which "$target"
    exit 0
  fi

  if [[ -d "$target" ]]; then
    __sd_directory_help "$target"
    if [[ $# -gt 0 ]]; then
      echo >&2
      echo "$target/$(__sd_join_path "$@") not found" >&2
      exit 1
    fi
  elif [[ -x "$target" ]]; then
    SD="$(dirname "$target")" exec "$target" "$@"
  else
    __sd_cat "$@"
  fi
}

# If you source this file and use function-mode sd, we want to
# wrap the execution in a subshell so that set -e doesn't kill
# the interactive shell, and so that we can exec the subshell
# without destroying the interactive shell.
sd() (
  __sd "$@"
)

# If you source this file, it will define the function sd,
# which you can use from your shell. If you *run* this file
# as an executable, it will just invoke that function. We
# have to do some tricks to detect that reliably on bash/zsh.

if [[ -n ${ZSH_EVAL_CONTEXT+x} ]]; then
  # we are in zsh
  if [[ "$ZSH_EVAL_CONTEXT" = toplevel ]]; then
    __sd "$@"
  fi
elif [[ -n ${BASH_SOURCE[0]+x} ]]; then
  # we are in bash
  if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    __sd "$@"
  fi
fi

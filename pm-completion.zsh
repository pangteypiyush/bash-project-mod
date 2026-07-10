#compdef pm
# Native zsh completion for pm

_comp_pm_get_projects() {
  [[ -z "$PROJECT_BASE" || ! -d "$PROJECT_BASE" ]] && return
  local dir
  for dir in "$PROJECT_BASE"/*(/N); do
    print -r -- "${dir:t}"
  done | sort
}

_comp_pm_get_bases() {
  local bases_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm/config"
  [[ ! -d "$bases_dir" ]] && return
  local file
  for file in "$bases_dir"/*.base(N); do
    print -r -- "${file:t:r}"
  done | sort
}

_comp_pm_get_env_files() {
  local env_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm/env"
  [[ ! -d "$env_dir" ]] && return
  local file
  for file in "$env_dir"/*.env(N); do
    print -r -- "${file:t}"
  done | sort
}

_comp_pm_get_attached_files() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm"
  local current_base="${PM_CURRENT_BASE:-}"
  local current_project="${PROJECT:-}"
  [[ -z "$current_base" || -z "$current_project" ]] && return

  local assoc_file="$config_dir/env-$current_base-$current_project"
  [[ -f "$assoc_file" ]] && sed '/^$/d' "$assoc_file"
}

_comp_pm_get_unattached_files() {
  local -a all_files attached_files unattached_files
  local file

  all_files=("${(@f)$(_comp_pm_get_env_files)}")
  attached_files=("${(@f)$(_comp_pm_get_attached_files)}")

  [[ ${#all_files[@]} -eq 0 ]] && return

  for file in "${all_files[@]}"; do
    [[ -z "$file" ]] && continue
    if (( ${attached_files[(Ie)$file]} == 0 )); then
      unattached_files+=("$file")
    fi
  done

  print -rl -- "${unattached_files[@]}"
}

_comp_pm_match_list() {
  local prefix="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$prefix"* ]] && print -r -- "$item"
  done
}

_comp_pm_resolve_unique_prefix() {
  local prefix="$1"
  shift
  local -a matches
  matches=(${(@f)$(_comp_pm_match_list "$prefix" "$@")})
  matches=("${matches[@]:#}")

  if (( ${#matches[@]} == 1 )); then
    print -r -- "${matches[1]}"
  fi
}

_comp_pm_complete_ls_paths() {
  [[ -z "$PROJECT_BASE" || -z "$PROJECT" ]] && return
  local project_dir="$PROJECT_BASE/$PROJECT"
  [[ ! -d "$project_dir" ]] && return

  # Complete project-relative paths.
  _path_files -W "$project_dir"
}

_comp_pm() {
  local cur cmd raw_sub env_sub base_sub
  local -a commands env_subcommands default_subcommands base_subcommands

  cur="$words[CURRENT]"
  cmd="${words[2]}"

  commands=(init base switch cd ls pwd default env help)
  env_subcommands=(edit list attach detach show use)
  default_subcommands=(get set base)
  base_subcommands=(get set)

  if (( CURRENT == 2 )); then
    compadd -Q -- ${(@f)$(_comp_pm_match_list "$cur" "${commands[@]}")}
    return
  fi

  cmd="$(_comp_pm_resolve_unique_prefix "$cmd" "${commands[@]}")"
  [[ -z "$cmd" ]] && cmd="${words[2]}"

  case "$cmd" in
    init)
      if (( CURRENT == 3 )); then
        _files -/
      fi
      ;;

    switch)
      if (( CURRENT == 3 )); then
        compadd -Q -- ${(@f)$(_comp_pm_get_projects)}
      fi
      ;;

    base)
      if (( CURRENT == 3 )); then
        compadd -Q -- ${(@f)$(_comp_pm_get_bases)}
      fi
      ;;

    default)
      raw_sub="${words[3]}"
      if (( CURRENT == 3 )); then
        compadd -Q -- ${(@f)$(_comp_pm_match_list "$cur" "${default_subcommands[@]}")}
        return
      fi

      raw_sub="$(_comp_pm_resolve_unique_prefix "$raw_sub" "${default_subcommands[@]}")"
      [[ -z "$raw_sub" ]] && raw_sub="${words[3]}"

      case "$raw_sub" in
        set)
          if (( CURRENT == 4 )); then
            compadd -Q -- ${(@f)$(_comp_pm_get_projects)}
          fi
          ;;
        base)
          base_sub="${words[4]}"
          if (( CURRENT == 4 )); then
            compadd -Q -- ${(@f)$(_comp_pm_match_list "$cur" "${base_subcommands[@]}")}
            return
          fi
          base_sub="$(_comp_pm_resolve_unique_prefix "$base_sub" "${base_subcommands[@]}")"
          [[ -z "$base_sub" ]] && base_sub="${words[4]}"
          if [[ "$base_sub" == "set" ]] && (( CURRENT == 5 )); then
            compadd -Q -- ${(@f)$(_comp_pm_get_bases)}
          fi
          ;;
      esac
      ;;

    env)
      env_sub="${words[3]}"

      if (( CURRENT == 3 )); then
        compadd -Q -- ${(@f)$(_comp_pm_match_list "$cur" "${env_subcommands[@]}")}
        return
      fi

      env_sub="$(_comp_pm_resolve_unique_prefix "$env_sub" "${env_subcommands[@]}")"
      [[ -z "$env_sub" ]] && env_sub="${words[3]}"

      if (( CURRENT == 4 )); then
        case "$env_sub" in
          edit|list|use)
            compadd -Q -- ${(@f)$(_comp_pm_get_env_files)}
            ;;
          attach)
            compadd -Q -- ${(@f)$(_comp_pm_get_unattached_files)}
            ;;
          detach)
            compadd -Q -- ${(@f)$(_comp_pm_get_attached_files)}
            ;;
          show)
            compadd -Q -- ${(@f)$(_comp_pm_get_projects)}
            ;;
        esac
      fi
      ;;

    ls)
      _comp_pm_complete_ls_paths
      ;;

    cd|pwd|help)
      ;;
  esac
}

compdef _comp_pm pm

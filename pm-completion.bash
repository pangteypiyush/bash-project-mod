# bash/zsh completion for pm
# Source this in your .bashrc or .zshrc:
#   source /path/to/pm-completion.bash

_pm_completion() {
	local cur prev words cword

	# Initialize completion variables (works with both bash and zsh)
	if [[ -n "${ZSH_VERSION:-}" ]]; then
		# Zsh
		cur="${words[CURRENT]}"
		prev="${words[CURRENT-1]}"
		cword=$((CURRENT - 1))
	else
		# Bash
		cur="${COMP_WORDS[COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD-1]}"
		words=("${COMP_WORDS[@]}")
		cword="$COMP_CWORD"
	fi

	local cmd="${words[1]}"
	local subcommand="${words[2]}"

	# List available projects
	_pm_get_projects() {
		[[ -z "$PROJECT_BASE" ]] && return
		find "$PROJECT_BASE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
	}

	# List available bases
	_pm_get_bases() {
		local bases_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm/config"
		[[ ! -d "$bases_dir" ]] && return
		find "$bases_dir" -maxdepth 1 -name '*.base' -type f -printf '%f\n' 2>/dev/null | sed 's/.base$//' | sort
	}

	# List available env files
	_pm_get_env_files() {
		local env_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm/env"
		[[ ! -d "$env_dir" ]] && return
		find "$env_dir" -maxdepth 1 -name '*.env' -type f -printf '%f\n' 2>/dev/null | sort
	}

	# List env files attached to current project
	_pm_get_attached_files() {
		local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm"
		local current_base="${PM_CURRENT_BASE:-}"
		local current_project="${PROJECT:-}"
		[[ -z "$current_base" ]] || [[ -z "$current_project" ]] && return
		local assoc_file="$config_dir/env-$current_base-$current_project"
		[[ -f "$assoc_file" ]] && cat "$assoc_file" | grep -v '^$'
	}

	# List env files NOT attached to current project
	_pm_get_unattached_files() {
		local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/pm"
		local current_base="${PM_CURRENT_BASE:-}"
		local current_project="${PROJECT:-}"
		[[ -z "$current_base" ]] || [[ -z "$current_project" ]] && _pm_get_env_files && return

		local assoc_file="$config_dir/env-$current_base-$current_project"
		local all_files
		all_files=$(_pm_get_env_files)

		if [[ ! -f "$assoc_file" ]]; then
			# No association file, so all files are unattached
			echo "$all_files"
		else
			# Filter out attached files
			local attached
			attached=$(cat "$assoc_file" | grep -v '^$')
			echo "$all_files" | while IFS= read -r file; do
				[[ -z "$file" ]] && continue
				if ! grep -q "^${file}$" <<< "$attached" 2>/dev/null; then
					echo "$file"
				fi
			done
		fi
	}

	# Helper: Get all commands matching a prefix
	_pm_match_commands() {
		local prefix="$1"
		local -a commands=(init base switch cd ls pwd default env help)
		local -a matches=()
		local cmd

		for cmd in "${commands[@]}"; do
			if [[ "$cmd" == "$prefix"* ]]; then
				matches+=("$cmd")
			fi
		done

		[[ ${#matches[@]} -gt 0 ]] && printf '%s\n' "${matches[@]}"
	}

	# If completing the command itself (first argument), try prefix matching
	if [[ $cword -eq 1 && -n "$cmd" ]]; then
		local matching_cmds
		matching_cmds=$(_pm_match_commands "$cmd")
		if [[ -n "$matching_cmds" ]]; then
			COMPREPLY=($(compgen -W "$matching_cmds" -- "$cmd"))
			return
		fi
	fi

	case "$cmd" in
		# Main command completion (only full command names, not prefixes)
		"")
			COMPREPLY=($(compgen -W "init base switch cd ls pwd default env help" -- "$cur"))
			;;

		# pm init [DIR] [NAME]
		init)
			COMPREPLY=($(compgen -d -- "$cur"))
			;;

		# pm switch [PROJECT_NAME]
		switch)
			if [[ $cword -eq 2 ]]; then
				COMPREPLY=($(compgen -W "$(_pm_get_projects)" -- "$cur"))
			fi
			;;

		# pm default [get|set|base] [PROJECT_NAME|get|set] [BASE_NAME]
		default)
			case "$subcommand" in
				"")
					COMPREPLY=($(compgen -W "get set base" -- "$cur"))
					;;
				get)
					;;
				set)
					if [[ $cword -eq 3 ]]; then
						COMPREPLY=($(compgen -W "$(_pm_get_projects)" -- "$cur"))
					fi
					;;
				base)
					local base_subcommand="${words[3]}"
					case "$base_subcommand" in
						"")
							COMPREPLY=($(compgen -W "get set" -- "$cur"))
							;;
						get)
							;;
						set)
							if [[ $cword -eq 4 ]]; then
								COMPREPLY=($(compgen -W "$(_pm_get_bases)" -- "$cur"))
							fi
							;;
					esac
					;;
			esac
			;;

		# pm ls [LS_OPTIONS/FILES_IN_PROJECT]
		ls)
			if [[ -z "$PROJECT_BASE" ]] || [[ -z "$PROJECT" ]]; then
				return
			fi
			# Complete files/directories in current project
			local project_dir="$PROJECT_BASE/$PROJECT"
			[[ ! -d "$project_dir" ]] && return

			# Build the full path to complete from
			local full_path="$project_dir"
			[[ -n "$cur" ]] && full_path="$project_dir/$cur"

			# Get all completions (files and directories)
			local -a all_matches=()
			local item base_name

			# Handle directory traversal - if cur ends with / or current full_path is a dir
			if [[ "$cur" == */ ]] && [[ -d "$full_path" ]]; then
				# Completing inside a directory - get contents
				local dir_contents
				while IFS= read -r item; do
					base_name="${item##*/}"  # Get just the filename
					if [[ -d "$item" ]]; then
						all_matches+=("${cur}${base_name}/")
					else
						all_matches+=("${cur}${base_name}")
					fi
				done < <(find "$full_path" -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null | sort)
			else
				# Complete a partial path - get matching items
				local parent_dir prefix_pattern
				if [[ "$cur" == */* ]]; then
					# Has directory component - extract parent and prefix
					parent_dir="$project_dir/${cur%/*}"
					prefix_pattern="${cur##*/}"
				else
					# No directory component - completing at root
					parent_dir="$project_dir"
					prefix_pattern="$cur"
				fi

				[[ ! -d "$parent_dir" ]] && return

				# Find matching items
				while IFS= read -r item; do
					base_name="${item##*/}"  # Get just the filename
					# Check if it matches the prefix pattern
					if [[ "$base_name" == "$prefix_pattern"* ]]; then
						if [[ "$cur" == */* ]]; then
							# Preserve directory path
							if [[ -d "$item" ]]; then
								all_matches+=("${cur%/*}/${base_name}/")
							else
								all_matches+=("${cur%/*}/${base_name}")
							fi
						else
							# Root level
							if [[ -d "$item" ]]; then
								all_matches+=("${base_name}/")
							else
								all_matches+=("${base_name}")
							fi
						fi
					fi
				done < <(find "$parent_dir" -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null | sort)
			fi

			COMPREPLY=($(printf '%s\n' "${all_matches[@]}" | sort -u))
			;;

		# pm base [BASE_NAME]
		base)
			if [[ $cword -eq 2 ]]; then
				COMPREPLY=($(compgen -W "$(_pm_get_bases)" -- "$cur"))
			fi
			;;

		# pm env [SUBCOMMAND] [FILE/PROJECT]
		env)
			if [[ $cword -eq 2 ]]; then
				# Complete env subcommands (with prefix matching support)
				local prefix="${words[2]}"
				local -a all_subcmds=(edit list attach detach show use)
				local -a matching_subcmds=()
				for subcmd in "${all_subcmds[@]}"; do
					if [[ "$subcmd" == "$prefix"* ]]; then
						matching_subcmds+=("$subcmd")
					fi
				done
				COMPREPLY=($(compgen -W "$(printf '%s\n' "${matching_subcmds[@]}")" -- "$prefix"))
			elif [[ $cword -eq 3 ]]; then
				# Complete arguments based on subcommand
				case "$subcommand" in
					edit|list|use)
						# Env file names for edit, list, and use
						COMPREPLY=($(compgen -W "$(_pm_get_env_files)" -- "$cur"))
						;;
					attach)
						# Unattached files only
						COMPREPLY=($(compgen -W "$(_pm_get_unattached_files)" -- "$cur"))
						;;
					detach)
						# Attached files only
						COMPREPLY=($(compgen -W "$(_pm_get_attached_files)" -- "$cur"))
						;;
					show)
						# Project names for show (optional, defaults to current)
						if [[ -n "$PROJECT_BASE" ]] && [[ -d "$PROJECT_BASE" ]]; then
							COMPREPLY=($(compgen -W "$(find "$PROJECT_BASE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)" -- "$cur"))
						fi
						;;
				esac
			fi
		;;

		# No args needed for these
		cd|pwd|help)
			;;
	esac
}

# Register completion for bash and zsh
if [[ -n "${ZSH_VERSION:-}" ]]; then
	# Zsh completion
	autoload -U +X compinit && compinit
	autoload -U +X bashcompinit && bashcompinit
	complete -F _pm_completion pm
else
	# Bash completion
	complete -F _pm_completion -o bashdefault -o nospace pm
fi

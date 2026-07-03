#!/usr/bin/env bash
# pm - Project Manager (sourceable function)
# Works with bash 4.0+ and zsh
# Source this in your ~/.bashrc or ~/.zshrc: source /path/to/pm.sh

# ============================================================================
# Config Directories
# ============================================================================

readonly PM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pm"
readonly PM_BASES_DIR="$PM_CONFIG_DIR/config"
readonly PM_ENV_DIR="$PM_CONFIG_DIR/env"
readonly PM_DEFAULT_BASE_FILE="$PM_CONFIG_DIR/default-base"

# Initialize directories
mkdir -p "$PM_BASES_DIR" "$PM_ENV_DIR" 2>/dev/null

# ============================================================================
# Utility: Print error/warning to stderr
# ============================================================================

_pm_err() {
	echo "pm: error: $*" >&2
	return 1
}

_pm_warn() {
	echo "pm: warning: $*" >&2
}

# ============================================================================
# Phase 1: Config System (Base Management)
# ============================================================================

# Get list of all available bases
_pm_list_bases() {
	[[ ! -d "$PM_BASES_DIR" ]] && return 1
	find "$PM_BASES_DIR" -maxdepth 1 -name "*.base" -type f -printf '%f\n' | sed 's/\.base$//' | sort
}

# Get base path from its file
_pm_get_base_path() {
	local base="$1"
	[[ -f "$PM_BASES_DIR/$base.base" ]] || return 1
	cat "$PM_BASES_DIR/$base.base"
}

# Set a base definition
_pm_set_base() {
	local base="$1"
	local path="$2"
	echo "$path" > "$PM_BASES_DIR/$base.base"
}

# Get current/default base name
_pm_get_current_base() {
	[[ -f "$PM_DEFAULT_BASE_FILE" ]] && cat "$PM_DEFAULT_BASE_FILE"
}

# Set current/default base
_pm_set_current_base() {
	local base="$1"
	echo "$base" > "$PM_DEFAULT_BASE_FILE"
}

# Get default project for a base
_pm_get_default_project() {
	local base="$1"
	[[ -f "$PM_CONFIG_DIR/default-project-$base" ]] && cat "$PM_CONFIG_DIR/default-project-$base"
}

# Set default project for a base
_pm_set_default_project() {
	local base="$1"
	local project="$2"
	echo "$project" > "$PM_CONFIG_DIR/default-project-$base"
}

# Validate project exists in current base
_pm_validate_project() {
	local project="$1"
	[[ -z "$project" ]] && return 1
	[[ -d "$PROJECT_BASE/$project" ]] || return 1
}

# List all projects in current base
_pm_list_projects() {
	[[ ! -d "$PROJECT_BASE" ]] && return 1
	find "$PROJECT_BASE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

# ============================================================================
# Phase 1: Config System (Env File Management)
# ============================================================================

# Get list of all available env files
_pm_list_env_files() {
	[[ ! -d "$PM_ENV_DIR" ]] && return 1
	find "$PM_ENV_DIR" -maxdepth 1 -name "*.env" -type f -printf '%f\n' | sort
}

# Get env associations for current project
_pm_get_env_files() {
	local base="$1"
	local project="$2"
	local assoc_file="$PM_CONFIG_DIR/env-$base-$project"
	[[ -f "$assoc_file" ]] && cat "$assoc_file"
}

# Add env file to project association
_pm_add_env_file() {
	local base="$1"
	local project="$2"
	local env_file="$3"
	local assoc_file="$PM_CONFIG_DIR/env-$base-$project"
	echo "$env_file" >> "$assoc_file"
}

# Remove env file from project association
_pm_remove_env_file() {
	local base="$1"
	local project="$2"
	local env_file="$3"
	local assoc_file="$PM_CONFIG_DIR/env-$base-$project"
	[[ ! -f "$assoc_file" ]] && return 1
	grep -v "^$env_file\$" "$assoc_file" > "$assoc_file.tmp"
	mv "$assoc_file.tmp" "$assoc_file"
}

# Source env files with error handling (non-fatal)
_pm_source_env_files() {
	local base="$1"
	local project="$2"
	local env_files
	env_files=$(_pm_get_env_files "$base" "$project")

	[[ -z "$env_files" ]] && return 0

	local env_file
	while IFS= read -r env_file; do
		[[ -z "$env_file" ]] && continue
		local env_path="$PM_ENV_DIR/$env_file"
		if [[ -f "$env_path" ]]; then
			# shellcheck source=/dev/null
			source "$env_path" 2>/dev/null || {
				_pm_warn "failed to source env file: $env_file"
			}
		else
			_pm_warn "env file not found: $env_file"
		fi
	done <<< "$env_files"
}

# Helper: Match env subcommand with prefix (e.g., 'e' matches 'edit')
_pm_env_match_cmd() {
	local prefix="$1"
		local -a cmds=(edit list attach detach show use)
	local -a matches=()
	local cmd

	for cmd in "${cmds[@]}"; do
		if [[ "$cmd" == "$prefix"* ]]; then
			matches+=("$cmd")
		fi
	done

	[[ ${#matches[@]} -eq 1 ]] && echo "${matches[0]}" || echo ""
}

# ============================================================================
# Helper: Match command prefix
# ============================================================================

_pm_match_cmd() {
	local prefix="$1"
	local -a cmds=(init switch cd ls pwd default base env help)
	local -a matches=()
	local cmd

	for cmd in "${cmds[@]}"; do
		if [[ "$cmd" == "$prefix"* ]]; then
			matches+=("$cmd")
		fi
	done

	case "${#matches[@]}" in
		0) return 1 ;;
		1) echo "${matches[0]}" ;;
		*) _pm_err "ambiguous command: $prefix (${matches[*]})"; return 1 ;;
	esac
}

# ============================================================================
# Main pm function
# ============================================================================

pm() {
	local cmd="${1:-}"

	# Match prefix to full command name (but only if not a full match)
	if [[ -n "$cmd" ]] && [[ "$cmd" != "init" ]] && [[ "$cmd" != "switch" ]] && [[ "$cmd" != "cd" ]] && [[ "$cmd" != "ls" ]] && [[ "$cmd" != "pwd" ]] && [[ "$cmd" != "default" ]] && [[ "$cmd" != "base" ]] && [[ "$cmd" != "env" ]] && [[ "$cmd" != "help" ]]; then
		cmd=$(_pm_match_cmd "$cmd") || return 1
	fi

	case "$cmd" in
		# ====================================================================
		# Phase 2: Initialize or add project base
		# ====================================================================
		init)
			local dir="${2:-.}"
			[[ ! -d "$dir" ]] && {
				_pm_err "directory not found: $dir"
				return 1
			}
			dir=$(cd "$dir" && pwd)

			# Extract base name from path, or use explicit name if provided
			local base_name
			if [[ -n "$3" ]]; then
				# Explicit base name provided
				base_name="$3"
			else
				# Use directory basename
				base_name=$(basename "$dir")
			fi

			# Register base
			_pm_set_base "$base_name" "$dir"

			# Set as current base if none exists
			if [[ -z "$(_pm_get_current_base)" ]]; then
				_pm_set_current_base "$base_name"
			fi

			echo "pm initialized"
			echo "  base name: $base_name"
			echo "  path: $dir"

			# Update environment
			export PM_CURRENT_BASE="$base_name"
			export PROJECT_BASE="$dir"
			;;

		# ====================================================================
		# Phase 2: Select and switch between bases
		# ====================================================================
		base)
			local base_name="$2"

			if [[ -z "$base_name" ]]; then
				# Interactive selection with fzf
				base_name=$(_pm_list_bases | fzf --preview="bat --color=always -pp $PM_BASES_DIR/{}.base" \
					--preview-window=down --no-info --cycle)
				[[ -z "$base_name" ]] && return 1
			fi

			# Validate base exists
			local base_path
			base_path=$(_pm_get_base_path "$base_name") || {
				_pm_err "base not found: $base_name"
				return 1
			}

			# Switch to base
			_pm_set_current_base "$base_name"
			export PM_CURRENT_BASE="$base_name"
			export PROJECT_BASE="$base_path"

			# Auto-switch to default project for this base
			local default_project
			default_project=$(_pm_get_default_project "$base_name")

			if [[ -n "$default_project" ]] && _pm_validate_project "$default_project"; then
				export PROJECT="$default_project"
				_pm_source_env_files "$base_name" "$default_project"
				echo "switched to base: $base_name (project: $default_project)"
			else
				export PROJECT=""
				echo "switched to base: $base_name"
			fi
			;;

		# ====================================================================
		# Phase 3: Select and switch projects
		# ====================================================================
		switch)
			local project="$2"
			local base_name
			base_name=$(_pm_get_current_base)

			[[ -z "$base_name" ]] && {
				_pm_err "no base selected. use 'pm base' first"
				return 1
			}

			local base_path
			base_path=$(_pm_get_base_path "$base_name") || {
				_pm_err "base not found: $base_name"
				return 1
			}

			# Update PROJECT_BASE
			export PROJECT_BASE="$base_path"

			if [[ -z "$project" ]]; then
				# Interactive selection with fzf
				project=$(_pm_list_projects | fzf --preview="ls -lah $PROJECT_BASE/{} 2>/dev/null" \
					--preview-window=down --no-info --cycle)
				[[ -z "$project" ]] && return 1
			fi

			_pm_validate_project "$project" || {
				_pm_err "project not found: $project"
				return 1
			}

			export PROJECT="$project"
			_pm_set_default_project "$base_name" "$project"

			# Source env files for this project (non-fatal errors)
			_pm_source_env_files "$base_name" "$project"

			echo "switched to project: $project"
			;;

		# ====================================================================
		# Change directory to current project
		# ====================================================================
		cd)
			[[ -z "$PROJECT" ]] && {
				_pm_err "no project selected"
				return 1
			}
			_pm_validate_project "$PROJECT" || {
				_pm_err "project not found: $PROJECT"
				return 1
			}
			cd "$PROJECT_BASE/$PROJECT" || return 1
			;;

		# ====================================================================
		# List files in current project
		# ====================================================================
		ls)
			[[ -z "$PROJECT" ]] && {
				_pm_err "no project selected"
				return 1
			}
			_pm_validate_project "$PROJECT" || {
				_pm_err "project not found: $PROJECT"
				return 1
			}

			# Resolve file/directory paths relative to project base
			local project_dir="$PROJECT_BASE/$PROJECT"
			local -a resolved_args=()
			local arg

			shift  # remove command name
			for arg in "$@"; do
				# Keep ls options as-is (start with -)
				if [[ "$arg" == -* ]]; then
					resolved_args+=("$arg")
				else
					# Try to resolve as path relative to project
					if [[ -e "$project_dir/$arg" ]]; then
						resolved_args+=("$project_dir/$arg")
					else
						# Keep as-is if doesn't exist (let ls handle the error)
						resolved_args+=("$arg")
					fi
				fi
			done

			# Call ls with resolved paths
			if [[ ${#resolved_args[@]} -eq 0 ]]; then
				command ls "$project_dir"
			else
				command ls "${resolved_args[@]}"
			fi
			;;

		# ====================================================================
		# Get path of current project
		# ====================================================================
		pwd)
			[[ -z "$PROJECT" ]] && {
				_pm_err "no project selected"
				return 1
			}
			_pm_validate_project "$PROJECT" || {
				_pm_err "project not found: $PROJECT"
				return 1
			}
			echo "$PROJECT_BASE/$PROJECT"
			;;

		# ====================================================================
		# Phase 3: Get/set defaults for base or project
		# ====================================================================
		default)
			local subcommand="$2"

			case "$subcommand" in
				base)
					local base_subcommand="$3"
					case "$base_subcommand" in
						g|get)
							local current_base
							current_base=$(_pm_get_current_base)
							[[ -z "$current_base" ]] && {
								_pm_err "no default base set"
								return 1
							}
							local base_path
							base_path=$(_pm_get_base_path "$current_base")
							echo "$base_path"
							;;
						s|set)
							local base="$4"
							[[ -z "$base" ]] && base="$PM_CURRENT_BASE"
							[[ -z "$base" ]] && {
								_pm_err "no base specified"
								return 1
							}
							_pm_get_base_path "$base" >/dev/null || {
								_pm_err "base not found: $base"
								return 1
							}
							_pm_set_current_base "$base"
							export PM_CURRENT_BASE="$base"
							echo "default base set to: $base"
							;;
						*)
							_pm_err "invalid subcommand: pm default base $base_subcommand"
							return 1
							;;
					esac
					;;
				g|get)
					local current_base
					current_base=$(_pm_get_current_base)
					[[ -z "$current_base" ]] && {
						_pm_err "no base selected"
						return 1
					}
					local default_project
					default_project=$(_pm_get_default_project "$current_base")
					[[ -z "$default_project" ]] && {
						_pm_err "no default project set"
						return 1
					}
					_pm_validate_project "$default_project" || {
						_pm_err "default project not found: $default_project"
						return 1
					}
					echo "$PROJECT_BASE/$default_project"
					;;
				s|set)
					local project="$3"
					[[ -z "$project" ]] && project="$PROJECT"
					[[ -z "$project" ]] && {
						_pm_err "no project specified"
						return 1
					}
					local base_name
					base_name=$(_pm_get_current_base)
					[[ -z "$base_name" ]] && {
						_pm_err "no base selected"
						return 1
					}
					_pm_validate_project "$project" || {
						_pm_err "project not found: $project"
						return 1
					}
					export PROJECT="$project"
					_pm_set_default_project "$base_name" "$project"
					echo "default project set to: $project"
					;;
				*)
					_pm_err "invalid subcommand: pm default $subcommand"
					return 1
					;;
			esac
			;;

		# ====================================================================
		# Phase 4: Env file management
		# ====================================================================
		env)
			local env_subcommand="$2"

			# Try prefix matching if exact match not found
			if [[ ! "$env_subcommand" =~ ^(edit|list|attach|detach|show|use)$ ]]; then
				local matched
				matched=$(_pm_env_match_cmd "$env_subcommand")
				if [[ -z "$matched" ]]; then
					_pm_err "invalid subcommand: pm env $env_subcommand"
					return 1
				fi
				env_subcommand="$matched"
			fi

			case "$env_subcommand" in
				edit)
					local env_name="$3"

				# If no arg, use fzf to select from available env files
				if [[ -z "$env_name" ]]; then
					env_name=$(_pm_list_env_files | fzf --preview="bat --color=always -pp $PM_ENV_DIR/{}" \
						--preview-window=down --no-info --cycle)
					[[ -z "$env_name" ]] && return 0  # User cancelled
				fi
					local editor="${EDITOR:-nano}"
					local env_file="$PM_ENV_DIR/$env_name"
					# Create if doesn't exist
					[[ ! -f "$env_file" ]] && touch "$env_file"

					$editor "$env_file"
					echo "edited: $env_file"
					;;

				list)
					# List all env files with fzf preview, print realpath on selection
				selected=$(_pm_list_env_files | fzf --preview="bat --color=always -pp $PM_ENV_DIR/{}" \
					--preview-window=down --no-info --cycle)
					if [[ -n "$selected" ]]; then
						realpath "$PM_ENV_DIR/$selected"
					fi
					;;

				attach)
				local project="$PROJECT"
				[[ -z "$project" ]] && {
					_pm_err "no project selected"
					return 1
				}

				local base_name
				base_name=$(_pm_get_current_base)
				[[ -z "$base_name" ]] && {
					_pm_err "no base selected"
					return 1
				}

				local env_file="$3"

				# If no arg, use fzf to select from available (not yet attached) env files
				if [[ -z "$env_file" ]]; then
					local assoc_file="$PM_CONFIG_DIR/env-$base_name-$project"
					local attached_files
					[[ -f "$assoc_file" ]] && attached_files=$(cat "$assoc_file")

					# Get list of unattached files (all files minus attached ones)
					local all_files
					all_files=$(_pm_list_env_files)

					local unattached_files
					while IFS= read -r file; do
						[[ -z "$file" ]] && continue
						if ! grep -q "^${file}$" <<< "$attached_files" 2>/dev/null; then
							unattached_files+=$(echo "$file")
							unattached_files+=$'\n'
						fi
					done <<< "$all_files"

					[[ -z "$unattached_files" ]] && {
						echo "no available env files to attach"
						return 0
					}

					env_file=$(printf '%s' "$unattached_files" | grep -v '^$' | fzf --preview="bat --color=always -pp $PM_ENV_DIR/{}" \
						--preview-window=down --no-info --cycle)
					[[ -z "$env_file" ]] && return 0  # User cancelled
				fi
					# Verify env file exists
					[[ ! -f "$PM_ENV_DIR/$env_file" ]] && {
						_pm_err "env file not found: $env_file"
						return 1
					}

					# Append to association file
					_pm_add_env_file "$base_name" "$project" "$env_file"
					echo "attached: $env_file to project $project"
					;;

				detach)
				local project="$PROJECT"
				[[ -z "$project" ]] && {
					_pm_err "no project selected"
					return 1
				}

				local base_name
				base_name=$(_pm_get_current_base)
				[[ -z "$base_name" ]] && {
					_pm_err "no base selected"
					return 1
				}

				local env_file="$3"

				# If no arg, use fzf to select from attached env files
				if [[ -z "$env_file" ]]; then
					local assoc_file="$PM_CONFIG_DIR/env-$base_name-$project"
					if [[ ! -f "$assoc_file" ]] || [[ ! -s "$assoc_file" ]]; then
						echo "no env files attached to current project"
						return 0
					fi

					env_file=$(cat "$assoc_file" | grep -v '^$' | fzf --preview="bat --color=always -pp $PM_ENV_DIR/{}" \
						--preview-window=down --no-info --cycle)
					[[ -z "$env_file" ]] && return 0  # User cancelled
				fi
					# Remove from association file
					_pm_remove_env_file "$base_name" "$project" "$env_file"
					echo "detached: $env_file from project $project"
					;;

				show)
					local project="$3"
					[[ -z "$project" ]] && project="$PROJECT"
					[[ -z "$project" ]] && {
						_pm_err "no project specified"
						return 1
					}

					local base_name
					base_name=$(_pm_get_current_base)
					[[ -z "$base_name" ]] && {
						_pm_err "no base selected"
						return 1
					}

					# Get env files associated with project (from association file)
					local assoc_file="$PM_CONFIG_DIR/env-$base_name-$project"
					if [[ ! -f "$assoc_file" ]] || [[ ! -s "$assoc_file" ]]; then
						echo "no env files associated with project: $project"
						return 0
					fi

					# Display associated env files with fzf preview, print realpath on selection
				selected=$(cat "$assoc_file" | fzf --preview="bat --color=always -pp $PM_ENV_DIR/{}" \
					--preview-window=down --no-info --cycle)
					if [[ -n "$selected" ]]; then
						realpath "$PM_ENV_DIR/$selected"
					fi
					;;

				use)
					local env_file="$3"

					# If no arg, use fzf to select from available env files
					if [[ -z "$env_file" ]]; then
					env_file=$(_pm_list_env_files | fzf --preview="bat --color=always -pp $PM_ENV_DIR/{}" \
						--preview-window=down --no-info --cycle)
						[[ -z "$env_file" ]] && return 0  # User cancelled
					fi

					local env_path="$PM_ENV_DIR/$env_file"
					[[ ! -f "$env_path" ]] && {
						_pm_err "env file not found: $env_file"
						return 1
					}

					# Source env file ad-hoc (non-fatal)
					# shellcheck source=/dev/null
					source "$env_path" && echo "sourced: $env_file" || {
						_pm_warn "failed to source: $env_file"
					}
					;;

				*)
					_pm_err "invalid subcommand: pm env $env_subcommand"
					return 1
					;;
			esac
			;;

		# ====================================================================
		# Show help
		# ====================================================================
		help | --help | -h | "")
			cat <<-EOF
				pm - Project Manager (bash/zsh compatible)

				USAGE:
				  pm init [DIR] [NAME]         Add/initialize project base (i)
				  pm base [NAME]               Select/switch base (b [NAME])
				  pm switch [NAME]             Select/switch project (s [NAME])
				  pm cd                        Change to current project directory (c)
				  pm ls [LS_ARGS]              List current project contents (l)
				  pm pwd                       Print path of current project (p)
				  pm default base get          Get current default base (d b g)
				  pm default base set [BASE]   Set default base (d b s [BASE])
				  pm default get               Get default project path (d g)
				  pm default set [PROJECT]     Set default project (d s [PROJECT])
				  pm env edit <name>           Edit/create env file (e e <name>)
				  pm env list                  List env files with preview (e l)
				  pm env attach <file>          Attach env file to current project (e a <file>)
				  pm env detach <file>          Detach env file from current project (e d <file>)
				  pm env show [PROJECT]        Show associated env files (e s [PROJECT])
				  pm env use <file>            Source env file ad-hoc (e us <file>)
				  pm help                      Show this help (h)

				PREFIX MATCHING:
				Commands can be invoked using unambiguous prefixes. Examples:
				  pm i ~/projects              # same as: pm init ~/projects (base name = "projects")
				  pm i ~/data/mybase custom    # Initialize with explicit base name "custom"
				  pm b                         # same as: pm base (interactive)
				  pm s                         # same as: pm switch (interactive)
				  pm e l                       # same as: pm env list

				EXAMPLES:
				  pm i ~/projects              # Initialize/add base (uses "projects" as base name)
				  pm i ~/data/storage backend  # Initialize with explicit base name "backend"
				  pm b                         # Select base interactively
				  pm s                         # Switch project interactively
				  pm c                         # Change to project directory
				  pm e e common                # Edit common.env file
				  pm e l                       # List env files with preview
				  pm e li common.env           # Link common.env to current project
				  pm s myapp                   # Switch project (auto-sources env files)
			EOF
			;;

		*)
			_pm_err "unknown command: $cmd"
			return 1
			;;
	esac
}

# ============================================================================
# Initialize environment on first source
# ============================================================================

# Load current base if set
if [[ -z "$PM_CURRENT_BASE" && -f "$PM_DEFAULT_BASE_FILE" ]]; then
	PM_CURRENT_BASE=$(cat "$PM_DEFAULT_BASE_FILE")
	export PM_CURRENT_BASE
fi

# Load base path
if [[ -n "$PM_CURRENT_BASE" ]]; then
	PROJECT_BASE=$(_pm_get_base_path "$PM_CURRENT_BASE")
	[[ -n "$PROJECT_BASE" ]] && export PROJECT_BASE
fi

# Load default project for current base
if [[ -z "$PROJECT" && -n "$PM_CURRENT_BASE" ]]; then
	default_proj=$(_pm_get_default_project "$PM_CURRENT_BASE")
	[[ -n "$default_proj" ]] && {
		export PROJECT="$default_proj"
		_pm_source_env_files "$PM_CURRENT_BASE" "$default_proj"
	}
fi

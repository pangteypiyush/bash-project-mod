# bash-project-mod

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

A lightweight bash/zsh project manager for fast project switching and navigation.

## Features

- **Direct shell integration** — sourceable bash/zsh function, not a script
- **Fast project switching** with optional fzf support
- **Prefix matching** — commands support unambiguous prefix matching for convenience
- **Environment-based** — uses `PROJECT_BASE` and `PROJECT` variables
- **Bash/zsh completion** — tab-complete for all commands and projects
- **Minimal dependencies** — just bash/zsh, optionally fzf
- **Zero overhead** — function-based, loads on shell startup

## Installation

### For ArchLinux Users (with makepkg)

```bash
# Build and install the package
makepkg -si

# Or just build
makepkg
```

This installs pm to `/usr/share/pm/` with bash and zsh completion support.

### Manual Installation

1. Copy files to your location:
```bash
cp pm.sh ~/.local/share/pm/
cp pm-completion.bash ~/.local/share/pm/
```

2. Add to your `~/.bashrc` (for bash):
```bash
source ~/.local/share/pm/pm.sh
source ~/.local/share/pm/pm-completion.bash
```

Or add to your `~/.zshrc` (for zsh):
```bash
source ~/.local/share/pm/pm.sh
source ~/.local/share/pm/pm-completion.bash
```

3. Initialize pm with your projects directory:
```bash
pm init ~/projects           # base name will be 'projects' (directory name)
pm init ~/projects mybase    # explicit base name 'mybase'
```

## Quick Start

```bash
# Initialize pm
pm init ~/projects              # base name = 'projects' (dirname)
pm init ~/data/storage mybase  # explicit base name = 'mybase'

# Interactive project selection
pm switch

# Switch to specific project
pm switch web-api

# Change directory to current project
pm cd

# View current project path
pm pwd

# List current project contents
pm ls

# Manage default project
pm default set my-project
pm default get
```

## Prefix Matching

All commands support unambiguous prefix matching:

```bash
pm init ~/projects      # Initialize with base name 'projects'
pm init ~/data custom   # Initialize with explicit base name 'custom'
pm switch              # Interactive project selection
pm switch my-app       # Switch to specific project
pm cd                  # Change to project directory
pm pwd                 # Print project path
pm ls -la              # List with details
pm default get         # Get default project
pm default set my-proj # Set default project
```

## Commands

| Command | Prefix | Description |
|---------|--------|-------------|
| `pm init [DIR] [NAME]` | `i` | Initialize pm with project base directory (optional explicit base name) |
| `pm base [NAME]` | `b` | Select/switch project base (interactive or by name) |
| `pm switch [NAME]` | `s` | Select/switch project (interactive or by name) |
| `pm cd` | `c` | Change to current project directory |
| `pm ls [LS_ARGS]` | `l` | List files in current project |
| `pm pwd` | `p` | Print absolute path of current project |
| `pm default base get/set` | `d b g/s` | Manage default base |
| `pm default get/set` | `d g/s` | Manage default project |
| `pm env` | `e` | Manage environment files (edit, list, attach, detach, show, use) |
| `pm help` | `h` | Show help message |

### Base Management

`pm base` — Select and switch between project bases. Automatically switches to the default project for that base.

```bash
pm base                    # Interactive selection with fzf
pm base mybase             # Switch to 'mybase'
pm base production         # Switch to 'production'
```

**Auto-switching behavior:**
- Switching bases automatically loads the default project for that base
- If no default project is set for a base, just the base is switched
- Environment files linked to the new project are auto-sourced

### Project Management

`pm switch` — Select and switch between projects within the current base.

```bash
pm switch                  # Interactive selection with fzf
pm switch web-api          # Switch to 'web-api'
pm switch worker           # Switch to 'worker'
```

**Auto-sourcing:**
- When switching projects, linked environment files are automatically sourced
- See `pm env` for managing environment file associations

### Default Management

`pm default` — Manage default base and default project.

**Default Project** (within current base):
```bash
pm default set my-app      # Set 'my-app' as default project for current base
pm default get             # Show default project path
```

**Default Base:**
```bash
pm default base set production    # Set 'production' as default base
pm default base get              # Show default base name
```

When `pm.sh` is sourced, it automatically loads the default base and its default project.

### Environment File Management

`pm env` — Manage environment files associated with projects.

**Create/Edit env files:**
```bash
pm env edit common         # Create/edit ~/.config/pm/env/common.env
pm env edit staging        # Create/edit ~/.config/pm/env/staging.env
```

**List env files:**
```bash
pm env list               # List all env files with preview
```

**Attach env files to projects:**
```bash
pm env attach common.env    # Attach common.env to current project
pm env attach staging.env   # Attach staging.env to current project
```

Attached env files are automatically sourced when you switch to that project.

**Detach env files:**
```bash
pm env detach common.env  # Remove common.env from current project
```

**Show attached env files:**
```bash
pm env show               # Show env files attached to current project
pm env show other-app     # Show env files attached to specific project
```

**Source env file ad-hoc:**
```bash
pm env use common.env     # Source env file without linking
```

**Environment File Locations:**
- Location: `~/.config/pm/env/`
- Format: Plain bash source file (can contain exports)
- Example content:
  ```bash
  # common.env
  export DB_HOST=localhost
  export DB_PORT=5432
  export API_KEY=my-key
  ```

## Configuration

**Base definitions**: `~/.config/pm/config/*.base`
- Each base has its own file (e.g., `mybase.base`)
- Contains the directory path for that base

**Default base**: `~/.config/pm/default-base`
- Contains the name of the currently selected default base

**Default project per base**: `~/.config/pm/default-project-<base>`
- Contains the name of the default project for that base
- Example: `~/.config/pm/default-project-production`

**Environment associations**: `~/.config/pm/env-<base>-<project>`
- Lists env files linked to a specific project
- Example: `~/.config/pm/env-production-api`

**Environment files**: `~/.config/pm/env/*.env`
- User-created bash files to source
- Example: `~/.config/pm/env/common.env`

## Environment Variables

- **`PM_CURRENT_BASE`** — Currently selected project base name (exported)
- **`PROJECT_BASE`** — Base directory path for current base (exported)
- **`PROJECT`** — Currently selected project name (exported)

These are automatically initialized from config when `pm.sh` is sourced.

## Completion Features

Bash/Zsh tab-completion is automatically enabled when pm is sourced:

**Command Prefix Matching:**
- `pm sw<TAB>` → completes to `switch`
- `pm ba<TAB>` → completes to `base`
- `pm de<TAB>` → completes to `default`
- `pm en<TAB>` → completes to `env`
- `pm in<TAB>` → completes to `init`

**Argument Completion:**
- `pm switch <TAB>` — Lists available projects
- `pm base <TAB>` — Lists available bases
- `pm default set <TAB>` — Lists available projects
- `pm env <TAB>` — Lists env files (edit, list, attach, etc.)
- `pm init <TAB>` — Lists directories

**File/Directory Completion:**
- `pm ls <TAB>` — Lists files and directories with indicators:
  - Directories show with `/` suffix (e.g., `src/`)
  - Files show without suffix (e.g., `README.md`)
- `pm ls src/<TAB>` — Shows contents inside `src/`
- `pm ls src/m<TAB>` — Filters matching files in `src/`

## Testing

Run unit tests to verify functionality:

```bash
bash test.sh
```

## Architecture

**Files:**
- `pm.sh` — Main function (source this in bashrc)
- `pm-completion.bash` — Bash completion support
- `test.sh` — Unit tests
- `PKGBUILD` — ArchLinux package definition

**Why this approach?**
- **Function vs script** — Can directly modify shell environment
- **Direct `cd`** — No wrapper functions needed
- **Environment variables** — Fast, persistent across commands
- **Sourced** — Loads on shell startup, no subprocess overhead

## Examples

### Basic usage
```bash
pm init ~/my-projects
pm switch                   # interactive selection
pm switch backend-api      # switch to specific project
pm cd                       # change to project directory
pm pwd                      # get project path
```

### File operations
```bash
pm ls                       # list project contents
pm ls -la                   # list with details
pm ls src/                  # list subdirectory contents
pm ls src/file.go           # list specific file
```

### Default project management
```bash
pm default set web-frontend         # set default project for current base
pm default get                      # show default project path
```

### Base management
```bash
pm base                     # interactive base selection
pm base production          # switch to production base
pm default base set staging # set staging as default base
pm default base get        # show default base name
```

### Environment file management
```bash
pm env edit common          # edit/create common.env
pm env list                 # list all env files
pm env attach common.env      # attach common.env to current project
pm env detach staging.env   # detach staging.env
pm env show                 # show env files for current project
pm env use common.env       # source env file ad-hoc
```

## Troubleshooting

**pm function not found?**
- Make sure `pm.sh` is sourced in your bashrc
- Test: `declare -F pm` should show the function
- Reload shell: `source ~/.bashrc`

**fzf not found?**
- Install fzf for interactive selection (optional)
- `pacman -S fzf` on ArchLinux
- Falls back to menu selection if fzf unavailable

**Config not found?**
- Run `pm init /path/to/projects` to create config
- Manually create `~/.config/pm/config` with:
  ```
  base=/your/projects/path
  ```

**No projects showing?**
- Check `PROJECT_BASE` env var: `echo $PROJECT_BASE`
- Projects must be immediate subdirectories (depth 1)
- Verify directory exists: `ls -d $PROJECT_BASE/*/`

## Dependencies

- **bash** 4.0+
- **fzf** (optional, for interactive selection)
- Standard Unix tools: `find`, `grep`, `sort`

## License

[GPL v3](LICENSE)

## Building for ArchLinux

```bash
# Build the package
makepkg

# Build and install
makepkg -si

# Install from AUR-like source
makepkg -si --skipchecksums
```

The PKGBUILD handles installation of:
- Main pm script to `/usr/share/pm/`
- Bash completion to `/usr/share/bash-completion/completions/`
- License file

## Changelog

See git history for changes and version information.

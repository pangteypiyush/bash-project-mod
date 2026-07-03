# AGENTS.md — Project Development Guide

## Project Overview

**bash-project-mod** is a lightweight, production-ready bash/zsh project manager distributed as a sourceable shell function. It enables fast project switching, navigation, and management with minimal overhead.

**Repository**: https://github.com/pangteypiyush/bash-project-mod
**License**: GPL v3
**Target Users**: Developers who frequently work with multiple projects

## Architecture

### Core Components

#### 1. **pm.sh** (~450 lines)
- **Type**: Sourceable bash function
- **Purpose**: Main project management interface with multi-base support
- **Architecture**: Multi-base system allows managing multiple independent project bases (production, staging, etc.)
- **Why Function, Not Script**: Direct shell environment integration, no subprocess overhead
- **Key Functions**:
  - `pm()` — Main entry point (case statement for subcommands)
  - `_pm_err()` — Error handling to stderr
  - `_pm_set_base()` / `_pm_get_base_path()` — Base configuration management
  - `_pm_set_current_base()` / `_pm_get_current_base()` — Current base tracking
  - `_pm_add_env_file()` / `_pm_remove_env_file()` — Environment file management
  - `_pm_source_env_files()` / `_pm_list_env_files()` — Env auto-sourcing on project switch
  - `_pm_match_cmd()` — Unambiguous prefix matching

**Subcommands** (9 total):
- `init [DIR] [NAME]` (i) — Initialize with project base (optional explicit base name)
- `base [BASE]` (b) — Switch between bases and load default project
- `switch [NAME]` (s) — Select/switch project
- `cd` (c) — Change to current project
- `ls [PATH]` (l) — List project contents (supports subpaths)
- `pwd` (p) — Print project path
- `default [get|set|base]` (d) — Manage project or base defaults
- `env [SUBCOMMAND]` (e) — Manage environment files (edit, list, link, unlink, show, use)
- `help` (h) — Show help

**Features:**
- All subcommands have unique first letters: **i, b, s, c, l, p, d, e, h**
- Prefix matching: `pm s project` or just `pm s` both work
- Base name inference: `pm init ~/projects` uses "projects" as base name, or explicit via `pm init ~/projects mybase`
- Multi-base support: `pm base` switches between different project bases with automatic default project loading
- Environment file management: Link/unlink env files per project, auto-sourced on project switch
- fzf support for interactive selection (graceful fallback to menu) - **hard dependency**
- Bash 4.0+ and Zsh compatible
- Environment-based project tracking via variables (PM_CURRENT_BASE, PROJECT_BASE, PROJECT)

**Configuration Structure**:
- Location: `~/.config/pm/`
- `config/` — Base definitions (named `basename.base`, contains path)
- `env/` — Environment files (named `filename.env`)
- `config` — Current base config file
- `default` — Default project file
- `env/project-name/` — Per-project env file symlinks

#### 2. **pm-completion.bash** (~225 lines)
- **Type**: Shell completion script
- **Compatibility**: Bash and Zsh (uses bashcompinit wrapper)
- **Helper Functions**:
  - `_pm_get_projects()` — Lists available projects
  - `_pm_get_bases()` — Lists available bases from config/*.base files
  - `_pm_get_env_files()` — Lists available env files from env/*.env files
  - `_pm_match_commands()` — Prefix matching for command names
- **Features**:
  - Detects shell type (BASH_VERSION, ZSH_VERSION) with fallback
  - Dynamic project name completion
  - Base name completion for `pm base` and `pm default base set`
  - Environment file completion for `pm env` subcommands (edit, list, link, unlink, show, use)
  - File/directory completion for `pm ls` with subpath support (dirs show `/` suffix)
  - Full command name completion with prefix matching support
- **Installation**: Sourced from ~/.bashrc or ~/.zshrc

#### 3. **test.sh** (150 lines)
- **Type**: Bash unit test suite (NOT packaged in ArchLinux release)
- **Test Count**: 20 tests across 7 suites ✅ ALL PASSING
- **Suites**:
  1. Initialization (2 tests) — Base setup, project creation
  2. Base Management (2 tests) — Base creation, switching
  3. Project Management (3 tests) — Project switching, defaults
  4. Default Management (2 tests) — Default project get/set
  5. Env File Management (4 tests) — Linking, unlinking env files
  6. Env File Auto-Sourcing (1 test) — Auto-source on project switch
  7. File Operations (4 tests) — Directory listing, nested paths
- **Run**: `bash test.sh`
- **Status**: ✅ All 20 tests passing

#### 4. **PKGBUILD** (27 lines)
- **Type**: ArchLinux package definition
- **Version**: 2.0.0
- **Installs**:
  - `/usr/share/pm/pm.sh` (755 mode)
  - `/usr/share/bash-completion/completions/pm`
  - `/usr/share/zsh/site-functions/_pm`
  - `/usr/share/licenses/bash-project-mod/LICENSE`
- **Dependencies**: bash 4.0+, fzf (hard dependency)
- **Build**: `makepkg -si`
- **Tests**: Runs `bash test.sh` during `check()` phase

### File Structure
```
bash-project-mod/
├── pm.sh                    # Core function
├── pm-completion.bash       # Shell completion
├── test.sh                  # Unit tests
├── PKGBUILD                 # ArchLinux package
├── README.md                # User documentation
├── LICENSE                  # GPL v3
└── AGENTS.md               # This file
```

## Development Workflow

### For Agents: Modifying Core Functionality

#### When to modify `pm.sh`:
1. **Adding Subcommands**: Add new case in main `pm()` function
2. **Improving Prefix Matching**: Modify `_pm_match_cmd()` function
3. **Fixing Bugs**: Ensure tests still pass before commit
4. **Changing Behavior**: Update help text and README simultaneously

#### Step-by-step process:
1. Make code changes to `pm.sh`
2. Run `bash test.sh` to verify tests pass
3. Manual test in shell: `source pm.sh && pm <command>`
4. Update relevant documentation (README.md, help text)
5. Update completion script if needed
6. Verify PKGBUILD is still valid: `makepkg --nobuild`

### For Agents: Adding Features

#### Example: Add a new subcommand "config"

**1. Add to pm.sh case statement**:
```bash
config)
    # Implementation here
    ;;
```

**2. Add to _pm_match_cmd() command list**:
```bash
local -a cmds=(init switch cd ls pwd config default help)
```

**3. Update help text** with new command and prefix

**4. Add tests to test.sh**:
```bash
_test "config command works" "pm config >/dev/null 2>&1"
```

**5. Update completion** in pm-completion.bash to handle new command (add case for full command name only)

**6. Update README.md** with usage examples

### For Agents: Testing

#### Running tests:
```bash
cd /home/ppang/Public/bash-project-mod
bash test.sh
```

#### Adding new tests:
1. Add test case in appropriate suite in test.sh
2. Use `_test "description" "command"` format
3. Ensure command returns exit code 0 on success
4. Run full test suite to verify

#### Manual testing:
```bash
# Setup temporary test environment
export XDG_CONFIG_HOME=/tmp/test_config
export HOME=/tmp/test_home
mkdir -p /tmp/test_config/pm
mkdir -p /tmp/test_projects/{proj1,proj2}

# Source and test
source pm.sh
pm init /tmp/test_projects
pm project proj1
pm pwd
pm cd
```

## Important Patterns

### 1. Error Handling
```bash
[[ condition ]] && {
    _pm_err "error message"
    return 1
}
```

### 2. Environment Variables
- `PROJECT_BASE` — Base directory containing all projects (exported)
- `PROJECT` — Currently selected project (exported)
- `XDG_CONFIG_HOME` — Config directory (respects XDG spec)
- `HOME` — Home directory fallback

### 3. Prefix Matching Rules
- Must be unambiguous (single match)
- Full command names always work
- Ambiguous prefixes show error with available matches
- All subcommands have unique first letters: **i, b, s, c, l, p, d, e, h** (9 commands, 9 unique prefixes)
- Examples: `pm s` for switch, `pm p` for pwd, `pm i` for init, `pm b` for base, `pm e` for env (no conflicts)

### 4. Multi-Base Configuration
- Multiple bases supported via `~/.config/pm/config/basename.base` files
- Each base file contains one line: the full path to the projects directory
- Current base tracked in `~/.config/pm/config` (simple text file with base name)
- Default project per base: `~/.config/pm/default` (simple text file with project name)
- Environment files stored in `~/.config/pm/env/filename.env`
- Per-project env symlinks: `~/.config/pm/env/project-name/` (directory of symlinks)
- Auto-sourced when switching projects via `pm switch` or `pm base`

## Completion Behavior

### Bash Completion
- Function: `_pm_completion()`
- Variables: `COMP_WORDS`, `COMP_CWORD`, `COMPREPLY`
- Registration: `complete -F _pm_completion pm` in .bashrc

### Zsh Completion
- Uses bashcompinit to wrap bash completion
- Variables: `words[CURRENT]` for current word
- Registration: `complete -F _pm_completion pm` (wrapped via bashcompinit)

### Command Completion Coverage
- **init**: Directory completion
- **base**: Base name completion (from ~/.config/pm/config/*.base)
- **switch**: Project name completion
- **default**: Subcommand completion (get, set, base) with nested options for `base set`
- **ls**: File/directory completion with subpath support (directories show `/` suffix)
- **env**: Subcommand completion (edit, list, link, unlink, show, use) with env file name completion
- **cd, pwd, help**: No arguments needed

### Prefix Matching in Completion
- Early check in `_pm_completion()` for command name matching at position 1
- Helper function `_pm_match_commands()` finds all commands matching prefix
- Automatically completes partial command names
- Example: `pm sw<TAB>` completes to `switch`, `pm b<TAB>` completes to `base`

### Extending Completion
1. Add helper function if needed (e.g., `_pm_get_new_items()`)
2. Add case for new command in main `_pm_completion()` function
3. Use `compgen -W` or similar to set `COMPREPLY`
4. Add command name to `_pm_match_commands()` array
5. Test: `source pm-completion.bash && COMP_WORDS=(pm cmd arg) COMP_CWORD=N _pm_completion`
6. Test both bash and zsh

## Building and Distribution

### ArchLinux Package
```bash
# Validate PKGBUILD
makepkg --nobuild -f

# Build locally
makepkg -f

# Install built package
makepkg -si
```

### Package Changes
- Modify PKGBUILD pkgrel for revisions
- Update pkgver for new releases
- Keep version synchronized with code

### Test in Package Build
- Tests run during `makepkg` via `check()` function
- Modify `check()` if test.sh location changes

## Code Quality Standards

### Bash Style
- Use `[[ ... ]]` for conditionals (not `[ ... ]`)
- Quote variables: `"$var"` not `$var`
- Use functions for reusable code
- Comments for non-obvious logic

### Testing
- All changes must pass existing tests
- Add tests for new features
- Test both bash and zsh when relevant

### Documentation
- Update README.md with user-facing changes
- Update help text with command changes
- Include examples for new features

## Common Maintenance Tasks

### Updating Version
```bash
# In PKGBUILD
pkgver=2.0.1
pkgrel=1
```

### Adding New Subcommand
1. **Implement in pm.sh**: Add case statement in main `pm()` function
2. **Add tests to test.sh**: Create new test suite or add tests to existing suite
3. **Update completion**: Add helper function if needed, add case statement to `_pm_completion()`
4. **Update README.md**: Add examples and documentation
5. **Update help text**: Ensure `pm help` shows new command
6. **Update _pm_match_commands()**: Add command to array if prefix matching needed
7. **Verify**: Run `bash test.sh` to ensure all tests pass

### Adding New Environment Variable
1. Export in `pm()` function (after setting)
2. Document in AGENTS.md under "Environment Variables"
3. Document in README.md
4. Update any relevant tests
5. Check PKGBUILD if variable needs special handling

### Fixing Bugs
1. Create test case that reproduces bug (or verify existing test)
2. Fix the bug in pm.sh
3. Verify test passes: `bash test.sh`
4. Test manually in bash and zsh: `source pm.sh && pm <command>`
5. If completion-related, test: `source pm-completion.bash` and verify COMPREPLY

### Releasing
1. Verify all tests pass: `bash test.sh` (expect 20/20 passing)
2. Verify PKGBUILD valid: `makepkg --nobuild -f`
3. Verify syntax: `bash -n pm.sh && bash -n pm-completion.bash`
4. Update version in PKGBUILD if needed
5. Commit changes with clear message
6. Tag release: `git tag -a v2.0.1 -m "Release 2.0.1"`
7. Build and test: `makepkg -f` then `makepkg -si`

## Improvements Summary

### Recent Enhancements (v2.0+)
1. **Command Prefix Matching** — All commands can be invoked by unambiguous prefix
2. **Unique First Letters** — i, s, c, l, p, d, h enable single-char shortcuts
3. **Improved ls Completion** — Shows directories with `/`, files without
4. **Subpath Support** — `pm ls src/` and `pm ls src/file.go` work correctly
5. **Smart fzf Defaults** — Adaptive preview window, handles all terminal sizes
6. **Bash/Zsh Completion** — Full prefix matching in tab-complete

## Known Limitations

1. **fzf Optional**: Interactive project selection requires fzf, falls back to `select` menu if not available
2. **Bash 4.0+ Only**: Uses bash 4.0+ features (arrays, `[[`)
3. **Zsh Compatibility**: Completion requires bashcompinit wrapper

## References

- **Bash Documentation**: https://www.gnu.org/software/bash/manual/
- **Zsh Documentation**: https://zsh.sourceforge.io/Doc/
- **ArchLinux Packaging**: https://wiki.archlinux.org/title/PKGBUILD
- **XDG Spec**: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

## Contact & Support

**Repository**: https://github.com/pangteypiyush/bash-project-mod
**Maintainer**: Piyush Pangtey <me at pangtey dot co dot in>
**License**: GPL v3

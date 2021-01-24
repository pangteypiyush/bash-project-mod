# bash-project-mod

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

## Installation

1. define base directory of projects in bashrc
```shell
PROJECT_BASE=~/Projects
```

2. load project-mod and initialize environment
```shell
source /usr/share/bash-project-mod/project-mod && __init_project
```

Note: PKGBUILD is available for ArchLinux

## Usage

### Change project
```shell
# dmenu
chproject
# or
chproject <project>
```

### Change dir relative to current project
```shell
# cd to project root
cdp
# cd to <project>/path/to/dir
cdp /path/to/dir
```

### List absolute path of dir relative to current project
```shell
# list project root dir
lsp
# list absolute path of <project>/path/to/dir
lsp /path/to/dir
```

### Setting current project as default
```shell
lsp --set-default
```

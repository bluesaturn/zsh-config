# zsh-config

Personal Zsh configuration for macOS on Apple Silicon.

This repository contains my `.zshrc` and documents the shell environment, prompt, completions, development tools, and utility functions configured through it.

## Requirements

The configuration is designed for:

- macOS on Apple Silicon
- Zsh
- Homebrew installed in `/opt/homebrew`

Some sections depend on optional tools and are only useful when the corresponding software is installed.

## Main Features

### Environment

The configuration defines environment variables for:

- Java 21
- Android SDK
- Go
- Python virtual environments
- Homebrew Cask

Homebrew GUI applications are configured to install into:

```text
~/Applications
```

instead of the system-wide:

```text
/Applications
```

### PATH Management

The `path_prepend` helper safely adds directories to the beginning of `PATH`.

A directory is added only when:

- the path is not empty;
- the directory exists;
- it is not already present in `PATH`.

This prevents stale or nonexistent directories from accumulating in the shell environment.

Configured paths include, when available:

- `~/.local/bin`
- Java
- MATLAB
- Android platform tools
- Android emulator
- Android command-line tools
- Android build tools

### Zsh Completion System

Zsh completions are initialized through `compinit`.

The `.zcompdump` completion cache is:

- rebuilt when missing;
- rebuilt when `.zshrc` is newer;
- automatically removed when older than 30 days;
- otherwise loaded using the faster cached path.

The `fix_compinit` function can be used to manually rebuild the completion cache:

```sh
fix_compinit
```

Python `argcomplete` support for `pipx` is enabled when available.

### Node.js and NVM

NVM is loaded lazily to avoid paying its startup cost every time a new shell is opened.

Running:

```sh
nvm
```

loads NVM on demand.

Running:

```sh
node
npm
npx
```

loads NVM and activates the configured default Node.js version.

The current lazy-loading state can be inspected with:

```sh
nvmstatus
```

### Git Prompt

The prompt displays Git repository information when the current directory is inside a repository.

Example:

```text
git:(main +!?*)↓2/↑1
```

Working-tree indicators:

| Symbol | Meaning |
| --- | --- |
| `+` | Staged changes |
| `!` | Unstaged changes |
| `?` | Untracked files |
| `*` | Stash present |
| `✗` | Conflicts |

Upstream indicators:

| Symbol | Meaning |
| --- | --- |
| `↓N` | N commits behind |
| `↑N` | N commits ahead |

The information is obtained using Git's porcelain v2 status format.

### Python Environments

The right prompt displays the active Python environment.

It supports:

- standard Python virtual environments;
- Poetry environments.

The normal virtualenv prompt prefix is disabled so that environment information is displayed consistently in the custom right prompt.

Two helper functions are available:

```sh
mkvenv
```

Creates `.venv`, activates it, and updates the basic Python packaging tools.

```sh
workon
```

Activates `.venv` in the current directory when present.

### Safe Zsh Reloading

The `reload` function validates `.zshrc` before replacing the current shell:

```sh
reload
```

It first runs:

```sh
zsh -n ~/.zshrc
```

If the syntax is valid, a new Zsh process replaces the current one.

If validation fails, the existing working shell is preserved.

### Environment Diagnostics

The configuration provides:

```sh
check_bin <command>
```

to locate a command, and:

```sh
check_env_info
```

to display information about the current Python, Java, MATLAB, and `PATH` configuration.

### PDF Utilities

The `pdfkeep` helper uses `qpdf` to keep selected page ranges from a PDF.

Examples:

```sh
pdfkeep file.pdf 2-5 output.pdf
pdfkeep file.pdf "1-3,5-7,9-z" output.pdf
```

Run:

```sh
pdfkeep --help
```

for usage information.

### WireGuard

Convenience functions are provided for WireGuard:

```sh
wgup
wgdown
wgshow
wgrestart
wgstatus
```

Custom Zsh completions are also provided for WireGuard configuration files and active interfaces.

### Aliases

Aliases are included for frequently used commands in:

- Python
- Git
- Docker
- npm
- file and directory navigation

Examples:

```sh
gs
gd
gco
gl
dps
dcu
dcd
drm
drmi
```

## Installation

Clone or copy this repository to a local directory.

Before replacing an existing configuration, back it up:

```sh
cp ~/.zshrc ~/.zshrc.backup
```

Then install the repository version as `~/.zshrc`.

After installation, validate it:

```sh
zsh -n ~/.zshrc
```

and start a fresh shell:

```sh
exec zsh
```

## Notes

This configuration is personal and intentionally tailored to the tools installed on my Mac.

Optional sections may depend on software such as:

- Homebrew
- NVM
- Node.js
- Python / pipx / Poetry
- Java 21
- Android SDK
- MATLAB
- Git
- Docker
- qpdf
- WireGuard

Missing optional tools should generally not prevent Zsh from starting, although functionality associated with those tools will not be available.
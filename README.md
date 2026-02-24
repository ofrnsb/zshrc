# EZPZ .zshrc

**Overview**
This repository contains my personal Zsh configuration, tuned for general software engineering use with optional personal customization. Personal secrets and machine-specific settings are loaded from a separate file to keep the repo safe to share.

**Install**

1. Clone this repo.
2. Link or copy `.zshrc` to your home directory:

```sh
ln -s /path/to/repo/.zshrc ~/.zshrc
```

3. Reload your shell:

```sh
source ~/.zshrc
```

**Personal Overrides**
This config loads a personal file if it exists:

```sh
# default path
~/.zshrc.personal
```

To use a custom path, set `ZSHRC_PERSONAL` before loading `.zshrc`:

```sh
export ZSHRC_PERSONAL="$HOME/.mac/.zshrc.personal"
```

**Customizable Environment Variables**

- `ZSHRC_PERSONAL`: path to your personal overrides file.
- `KAFKA_HOME`: Kafka install directory (required for `kafkac`).
- `VENV_HOME`: root directory for centralized Python venvs (defaults to `~/.venvs`).
- `GIT_PROFILE_PERSONAL_USER`: GitHub username for `gcs` auto profile configuration.
- `GIT_PROFILE_PERSONAL_EMAIL`: Git email for `gcs` auto profile configuration.

**Highlights**

- Custom prompt with git-aware display and tab title updates.
- Project-aware VSCode launcher.
- Interactive helpers for Git, Kafka, Docker, Redis, and project runs.
- Centralized Python venv manager.
- Zsh completion, syntax highlighting, and autosuggestions.

**Commands**
Command | Description
--- | ---
`javac` | Interactive Java version switcher (23/17/8).
`j23`, `j17`, `j8` | Set `JAVA_HOME` for a specific version.
`ras` | Run Android Emulator (`Pixel`).
`cc` | Open VSCode with profile based on project type.
`runs` | Run a project based on detected type (Node, Java/Spring, Python, C).
`run_mySql_Server` | Start MySQL service if not running.
`stop_mySql_Server` | Stop MySQL service.
`run_postgreSql_Server` | Start PostgreSQL service if not running.
`stop_postgreSql_Server` | Stop PostgreSQL service.
`dbdump` | Dump a Postgres or MySQL database to a file.
`dbrestore` | Restore a Postgres or MySQL database from a file.
`dbc` | Interactive database command center.
`gitc` | Interactive git command center (includes clean merged branches).
`gpl` | `gitc pull`.
`gpo` | `gitc push`.
`gg` | `git_acp` (add/commit/push).
`gcs` | Clone repo and optionally set git user for personal GitHub.
`gco` | Interactive branch checkout or creation.
`git_acp` | Initialize repo (if needed), add/commit/push, and create GitHub repo.
`vsp` | Publish VSCode extension via `vsce`.
`ca` | Create app templates (`an`, `ne`, `vu`).
`npmc` | Interactive npm command center.
`yarnc` | Interactive yarn command center.
`tfc` | Interactive Terraform command center.
`k8sc` | Interactive kubectl command center.
`sz` | Reload `.zshrc`.
`op` | Open current directory in Finder.
`ee` | Exit terminal.
`kp` | Kill processes on a port or port range.
`del` | Remove a folder.
`kafkac` | Interactive Kafka command center.
`ka` | Alias to `kafkac`.
`dockerc` | Interactive Docker command center.
`dkr` | Alias to `dockerc`.
`hide` | Hide file or folder (macOS).
`unhide` | Unhide file or folder (macOS).
`ctm` | Clean macOS caches.
`cl` | Clear terminal.
`pvenv` | Centralized Python venv manager.
`pysetup` | Install Python 3.13 via Homebrew.
`redisc` | Interactive Redis command center.
`sre` | Start Redis and open CLI.
`ssre` | Stop Redis.
`inre` | Redis service info.
`setup_java` | Install Java 23 and 17 (Oracle tarballs).
`setup_android` | Install Android command-line tools.

**Notes**

- `git_acp` requires GitHub CLI (`gh`) and authentication.
- `kafkac` requires `KAFKA_HOME` to be set.
- `k8sc` requires `kubectl`.
- `tfc` requires `terraform`.
- Some tools assume Homebrew is installed.
- Add personal paths, credentials, and machine-specific settings in `~/.zshrc.personal`.

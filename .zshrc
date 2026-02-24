[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

######################################################################################## THEME & PROMPT

# Hide Last Login
printf '\33c\e[3J'

# Host name
function show_b() {
    echo " %K{$0000}%F{$0000}\uf2c0%K{$0000} "
}

# Get branch name
function parse_git_branch() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local gitBranch=$(git branch --show-current 2>/dev/null)
    echo "%K{#0000}%F{122}$gitBranch"
  fi
}

DISABLE_AUTO_TITLE="true"
# Format the directory display and show '~' as an icon
function parse_directory() {
    local dir=$(pwd)
    local home_dir=$(eval echo "~")
    local electro_icon=$(echo -e "\uf0e7")
    local formatted_dir=${dir/$home_dir/}
    local gitLogo="\uf113"

    if [[ -n "$formatted_dir" ]]; then
        local last_dir="${formatted_dir##*/}"
        local formatted_last_dir="%F{#0F9A00}$last_dir%F{15}"
        local dir_without_last="${formatted_dir%/*}"
        if [[ "$dir_without_last" == "$formatted_dir" ]]; then
          dir_without_last=""
        else
          dir_without_last="${dir_without_last}/"
        fi
        formatted_dir="${dir_without_last}${formatted_last_dir}"
    fi

    if [[ "$dir" == "$home_dir" ]]; then
      echo "%K{#0000}%F{220}$electro_icon$formatted_dir%K{#0000}"
    elif git rev-parse --is-inside-work-tree &>/dev/null; then
      if [[ $TERM_PROGRAM == "Apple_Terminal" ]]; then
        echo "%K{#0000}%F{122}$gitLogo "
      else
        echo "%K{#0000}%F{122}$gitLogo $formatted_dir $(parse_git_branch)"
      fi
    else
      echo "%K{#0000}%F{220}$electro_icon%K{#0000}"
    fi
}

set_tab_title() {
  local dir=$(pwd)
  local home_dir=$(eval echo "~")
  local electro_icon=$(echo -e "\uf0e7")
  local formatted_dir=${dir/$home_dir/}
  local gitLogo="\uf113"

  if [[ -n "$formatted_dir" ]]; then
    local last_dir="${formatted_dir##*/}"
    local formatted_last_dir="$last_dir"
    local dir_without_last="${formatted_dir%/*}"
    if [[ "$dir_without_last" == "$formatted_dir" ]]; then
      dir_without_last=""
    else
      dir_without_last="${dir_without_last}/"
    fi
    formatted_dir="${dir_without_last}${formatted_last_dir}"
  fi

  tab_count=$(ps -afx | grep "\\-zsh" | grep -iv "grep" | tr -d ' '| wc -l )
  tab_count=$((tab_count - 1))
  pid=$$
  cwd=$(lsof -a -p $pid -d cwd | awk 'NR>1 {print $NF}')

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local git_branch=$(git branch --show-current 2>/dev/null)
    if [ "$tab_count" -eq 1 ]; then
      printf "\e]0;$git_branch\a"
      printf "\e]1;\a"
    else
      printf "\e]0; \a"
      printf "\e]1;$git_branch\a"
    fi
  else
    printf "\e]0; \e\\"
    printf "\e]1;$formatted_dir\e\\"
  fi
}

precmd() {
  set_tab_title
  if [ "$tab_count" -gt 1 ]; then
    change_other_tab
  fi
}

change_other_tab() {
  currentPid=$$
  pids=($(pgrep -af '^-zsh'))
  for pid in "${pids[@]}"; do
    local cwd=$(lsof -a -p $pid -d cwd | awk 'NR>1 {print $NF}')
    if [[ -n $cwd && ! $cwd =~ ^/dev/ && -d "$cwd" ]]; then
      if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
        local git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
        local terminal_device=$(lsof -p $pid | grep '/dev/tty' | awk '{print $9}' | uniq)
        if [[ $pid != "$currentPid" ]]; then
          printf "\e]0; \a" > $terminal_device;
          printf "\e]1;$git_branch\a" > $terminal_device;
          return;
        fi
      fi
    fi
  done
}

# Use the configured format
setopt PROMPT_SUBST
PS1='$(parse_directory)%f%b '
LSCOLORS="exfxcxdxbxegedabagacad"
export LSCOLORS
export CLICOLOR=1

######################################################################################## TERMINAL
# Add modified_cd helper for directory navigation
modified_cd() {
    local path="$HOME"
    local input="$*"
    local directories=(${(s:/:)input})

    for dir in $directories; do
        local match=0
        for item in "$path"/*(/); do
            if [[ ${item:t} == $dir ]]; then
                path="$item"
                match=1
                break
            fi
        done
        if [[ $match == 0 ]]; then
            echo "Directory not found: $dir"
            return 1
        fi
    done

    cd "$path"
}

######################################################################################## ENV & PATH
# Base environment variables
export HOMEBREW_NO_ENV_HINTS=1

path_prepend() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    case ":$PATH:" in
      *":$dir:"*) ;;
      *) PATH="$dir:$PATH" ;;
    esac
  fi
}

path_append() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    case ":$PATH:" in
      *":$dir:"*) ;;
      *) PATH="$PATH:$dir" ;;
    esac
  fi
}

# Minimal default PATHs
path_prepend "$HOME/bin"
path_prepend "/usr/local/bin"
path_prepend "/opt/homebrew/bin"

# Load optional personal overrides (not tracked in git)
ZSHRC_PERSONAL="${ZSHRC_PERSONAL:-$HOME/.zshrc.personal}"
if [[ -f "$ZSHRC_PERSONAL" ]]; then
  source "$ZSHRC_PERSONAL"
fi

######################################################################################## FUNCTIONS

# Java
# Shortcut to change Java version
j23() {
  export JAVA_HOME=$(/usr/libexec/java_home -v 23)
}
j17() {
  export JAVA_HOME=`/usr/libexec/java_home -v 17`
}
j8() {
  export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
}

javac() {
  echo "Select Java version:"
  echo "1) 23"
  echo "2) 17"
  echo "3) 8"
  read -k -s reply
  echo ""
  case "$reply" in
    1) j23 ;;
    2) j17 ;;
    3) j8 ;;
    *) echo "Invalid selection." ;;
  esac
}

# Android
# Shortcut to run Android Emulator
ras(){
  emulator -avd Pixel
}

# Project / Editor
# Shortcut to open VSCode and set the profile based on the project language/framework/library
cc() {
  # Detect project profile
  local profile="Default"
  if [ -f package.json ]; then
    if grep -qE "next|react" package.json; then
      profile="Next"
    elif grep -q "@angular/core" package.json; then
      profile="Angular"
    fi
  elif [[ -f pom.xml || $1 == "j" ]]; then
    profile="Java"
  elif [[ -n $(find "$PWD" -maxdepth 1 -type f -name "*.py") ]]; then
    profile="Python"
  elif [[ -n $(find "$PWD" -maxdepth 1 -type f -name "*.c") ]]; then
    profile="C"
  fi

  code . --profile "$profile"
}

# Database
# Check MySQL server status
function run_mySql_Server() {
  local mysql_status=$(pgrep mysqld | wc -l)
  if [ $mysql_status -eq 0 ]; then
     echo -e "\033[1;31mMySQL Server is not running.\033[0m"
      brew services start mysql
    else
      echo "MySQL Server is running."
  fi
}

function stop_mySql_Server() {
  brew services stop mysql
}

function run_postgreSql_Server() {
  local pg_status=$(pgrep postgres | wc -l)
  if [ $pg_status -eq 0 ]; then
    echo -e "\033[1;31mPostgreSQL Server is not running.\033[0m"
    brew services start postgresql@16
  else
    echo "PostgreSQL Server is running."
  fi
}

function stop_postgreSql_Server() {
  brew services stop postgresql@16
}

dbdump() {
  local engine="$1"
  local db="$2"
  local out="$3"

  if [[ -z "$engine" || -z "$db" || -z "$out" ]]; then
    echo "Usage: dbdump pg|mysql <db> <out.sql>"
    return 1
  fi

  case "$engine" in
    pg|postgres)
      pg_dump "$db" > "$out"
      ;;
    mysql)
      mysqldump "$db" > "$out"
      ;;
    *)
      echo "Unknown database engine: $engine"
      return 1
      ;;
  esac
}

dbrestore() {
  local engine="$1"
  local db="$2"
  local infile="$3"

  if [[ -z "$engine" || -z "$db" || -z "$infile" ]]; then
    echo "Usage: dbrestore pg|mysql <db> <in.sql>"
    return 1
  fi

  case "$engine" in
    pg|postgres)
      psql "$db" < "$infile"
      ;;
    mysql)
      mysql "$db" < "$infile"
      ;;
    *)
      echo "Unknown database engine: $engine"
      return 1
      ;;
  esac
}

# Project Runner
runs() {
  if [ -f package.json ]; then
    if grep -q "next" package.json; then
      npm run dev
    elif grep -q "react" package.json; then
      npm start
    elif grep -q "vue" package.json; then
      npm run serve
    elif grep -q "@angular/core" package.json; then
      ng serve
    fi
  elif [ -f pom.xml ]; then
    JAVA_VERSION=$(grep -o '<java.version>.*</java.version>' pom.xml | sed 's/<java.version>\(.*\)<\/java.version>/\1/')
    if [ "$JAVA_VERSION" = "17" ]; then
      j17
      echo -e "\033[0;32mRunning Java version 17\033[0m"
    elif [ "$JAVA_VERSION" = "1.8" ]; then
      j8
      echo -e "\033[0;32mRunning Java version 1.8\033[0m"
    else
      echo -e "\033[0;32mRunning Java version 23\033[0m"
      j23
    fi

    PROFILE_DIR="src/main/resources"
    PROFILES=($(find src/main/resources -maxdepth 1 -type f \( \
      -name "application.properties" -o \
      -name "application.yaml" -o \
      -name "application.yml" -o \
      -name "application-*.properties" -o \
      -name "application-*.yaml" -o \
      -name "application-*.yml" \) | sed -E 's/.*application-?(.*)\.(properties|yaml|yml)/\1/' | sed 's/^$/default/'))

    echo "Select profile (press Q to exit):"

    if [[ ${#PROFILES[@]} -eq 0 ]]; then
      echo "No profiles found, using default profile: dev"
      SELECTED_PROFILE="dev"
    else
      for i in {1..${#PROFILES[@]}}; do
        echo "$i) ${PROFILES[$i]}"
      done

      while true; do
        read -k 1 -s REPLY
        if [[ "$REPLY" =~ [Qq] ]]; then
          echo "Exit."
          return
        elif [[ "$REPLY" =~ ^[1-${#PROFILES[@]}]$ ]]; then
          SELECTED_PROFILE="${PROFILES[$REPLY]}"
          break
        else
          echo "Invalid selection. Try again."
        fi
      done
    fi

    PS3="Select database (press Q to exit): "
    echo "$PS3"
    echo "1) MySQL"
    echo "2) PostgreSQL"
    while true; do
      read -k 1 -s REPLY
      case "$REPLY" in
        [Qq])
          echo "Exit."
          return
          ;;
        1)
          run_mySql_Server \
            && echo -e "\033[0;32mRunning Spring Boot\033[0m" \
            && mvn spring-boot:run -Dspring-boot.run.profiles=$SELECTED_PROFILE -DskipTests \
            && echo -e "\033[1;31mMySQL Stopping Spring Boot.\033[0m" \
            && mvn spring-boot:stop \
            && stop_mySql_Server
          return
          ;;
        2)
          run_postgreSql_Server \
            && echo -e "\033[0;32mRunning Spring Boot\033[0m" \
            && mvn spring-boot:run -Dspring-boot.run.profiles=$SELECTED_PROFILE -DskipTests \
            && echo -e "\033[1;31mPostgreSQL Stopping Spring Boot.\033[0m" \
            && mvn spring-boot:stop \
            && stop_postgreSql_Server
          return
          ;;
      esac
    done
  elif [[ -n $(find "$PWD" -maxdepth 1 -type f -name "*.py") ]]; then
    local files=()
    while IFS= read -r -d '' file; do
      files+=("$(basename "$file")")
    done < <(find "$PWD" -maxdepth 1 -type f -name "*.py" -print0)
    IFS=$'\n' files=($(sort -f <<<"${files[*]}"))
    unset IFS

    if [[ ${#files[@]} -eq 1 ]]; then
      python3 "${files}"
      return
    fi

    if [[ ${#files[@]} -gt 9 ]]; then
      display_available "files" "${files[@]}" | column
    else
      display_available "files" "${files[@]}"
    fi

    PS3="Select Python file (press Q to exit): "
    while true; do
      if [[ ${#files[@]} -gt 9 ]]; then
        read REPLY
      else
        read -k -s REPLY
      fi
      if [[ "$REPLY" =~ [Qq] ]]; then
        echo "Exit."
        return
      fi
      if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= ${#files[@]} )); then
        python3 "${files[$REPLY]}"
        break
      else
        echo "Not valid. Try again."
        display_available "files" "${files[@]}"
      fi
    done
  elif [[ -n $(find "$PWD" -maxdepth 1 -type f -name "*.c") ]]; then
    local files=()
    while IFS= read -r -d '' file; do
      files+=("$(basename "$file")")
    done < <(find "$PWD" -maxdepth 1 -type f -name "*.c" -print0)
    IFS=$'\n' files=($(sort -f <<<"${files[*]}"))
    unset IFS

    if [[ ${#files[@]} -eq 1 ]]; then
      clang -o "${files%.*}" "${files}" && ./"${files%.*}"
      return
    fi

    if [[ ${#files[@]} -gt 9 ]]; then
      display_available "files" "${files[@]}" | column
    else
      display_available "files" "${files[@]}"
    fi

    PS3="Select C file (press Q to exit): "
    while true; do
      if [[ ${#files[@]} -gt 9 ]]; then
        read REPLY
      else
        read -k -s REPLY
      fi
      if [[ "$REPLY" =~ [Qq] ]]; then
        echo "Exit."
        return
      fi
      if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= ${#files[@]} )); then
        clang -o "${files[$REPLY]%.*}" "${files[$REPLY]}" && ./"${files[$REPLY]%.*}"
        break
      else
        echo "Not valid. Try again."
        display_available "files" "${files[@]}"
      fi
    done
  else
    echo "Unknown project type"
  fi
}

# Git
gitc() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository."
    return 1
  fi

  local action="${1:-}"
  if [[ -z "$action" ]]; then
    echo "Git command:"
    echo "1) status"
    echo "2) pull"
    echo "3) push"
    echo "4) checkout"
    echo "5) merge"
    echo "6) commit"
    echo "7) add+commit+push"
    echo "8) log"
    echo "9) sync (pull+push)"
    read -k -s action
    echo ""
  fi

  case "$action" in
    1|s|status)
      git status
      ;;
    2|p|pull)
      local branch="${2:-}"
      if [[ -n "$branch" ]]; then
        git pull origin "$branch"
      else
        git pull
      fi
      ;;
    3|P|push)
      local branch="${2:-}"
      if [[ -n "$branch" ]]; then
        git push origin "$branch"
      else
        local current_branch
        current_branch=$(git branch --show-current)
        if [[ -z "$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)" ]]; then
          git push --set-upstream origin "$current_branch"
        else
          git push
        fi
      fi
      ;;
    4|c|checkout)
      gco "${2:-}"
      ;;
    5|m|merge)
      local branches=($(git branch -a | grep -v ' -> ' | sed -E 's#remotes/[^/]*/##' | sed 's/^[* ]*//' | sort -u))
      if [[ ${#branches[@]} -eq 0 ]]; then
        echo "No branches found."
        return 1
      fi
      display_available "branches" "${branches[@]}"
      read -r target_idx
      if [[ "$target_idx" =~ ^[0-9]+$ ]] && (( target_idx >= 1 && target_idx <= ${#branches[@]} )); then
        git merge "${branches[$target_idx]}"
      else
        echo "Invalid selection."
      fi
      ;;
    6|commit)
      local msg="${2:-}"
      if [[ -z "$msg" ]]; then
        read -r "msg?Commit message: "
      fi
      git add -A
      git commit -m "$msg"
      ;;
    7|acp)
      local msg="${2:-}"
      if [[ -z "$msg" ]]; then
        read -r "msg?Commit message: "
      fi
      git_acp "$msg"
      ;;
    8|log)
      git log --oneline --decorate -n 20
      ;;
    9|sync)
      local branch="${2:-}"
      if [[ -n "$branch" ]]; then
        git pull origin "$branch" && git push origin "$branch"
      else
        git pull
        gitc push
      fi
      ;;
    *)
      echo "Unknown action."
      ;;
  esac
}

gpl() { gitc pull "$1"; }
gpo() { gitc push "$1"; }
gg() { git_acp "$1"; }
gcs() {
  repo_url="$1"
  if [[ -z "$repo_url" ]]; then
    echo "Usage: gcs <repo_url>"
    return 1
  fi

  # GitHub Personal (SSH)
  if [[ $repo_url == *"github.com:$GIT_PROFILE_PERSONAL_USER"* ]]; then
    git clone $repo_url && cd "$(basename $repo_url .git)"
    echo -e "[user]\n    name = $GIT_PROFILE_PERSONAL_USER\n    email = $GIT_PROFILE_PERSONAL_EMAIL" >> .git/config
    if [ -f package.json ]; then
      npm i
    fi

  # GitHub Personal (HTTPS)
  elif [[ $repo_url == *"github.com/$GIT_PROFILE_PERSONAL_USER"* ]]; then
    repo_url=${repo_url/https:\/\/github.com\//git@github.com:}
    git clone $repo_url && cd "$(basename $repo_url .git)"
    echo -e "[user]\n    name = $GIT_PROFILE_PERSONAL_USER\n    email = $GIT_PROFILE_PERSONAL_EMAIL" >> .git/config
    if [ -f package.json ]; then
      npm i
    fi

  # Default
  else
    git clone "$repo_url" && cd "$(basename "$repo_url" .git)"
    if [ -f package.json ]; then
      npm i
    fi
  fi
}

# Available Branches
display_available() {
  local category=$1
  shift
  local branches=("$@")
  local num_branches=${#branches[@]}

  echo "Available $category:"
  local i=1
  for b in "${branches[@]}"; do
    echo "$i) $b"
    ((i++))
  done
}

gitclean() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository."
    return 1
  fi

  git fetch --prune >/dev/null 2>&1
  local branches=($(git branch --merged | sed 's/^[* ]*//' | grep -vE '^(main|master|develop)$'))

  if [[ ${#branches[@]} -eq 0 ]]; then
    echo "No merged branches to delete."
    return 0
  fi

  echo "Delete merged branches?"
  display_available "branches" "${branches[@]}"
  read -k -s reply
  echo ""

  if [[ "$reply" =~ ^[Qq]$ ]]; then
    echo "Exit."
    return 0
  fi

  if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#branches[@]} )); then
    git branch -d "${branches[$reply]}"
  else
    echo "Invalid selection."
    return 1
  fi
}

gco() {
  # Ensure we're inside a Git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "\033[1;31mNot a git repository.\033[0m"
    return 1
  fi

  # Determine default remote (prefer 'origin', otherwise first available remote)
  local default_remote=""
  if git remote 2>/dev/null | grep -qx "origin"; then
    default_remote="origin"
  else
    default_remote="$(git remote 2>/dev/null | head -n1)"
  fi

  if [ -n "$1" ]; then
    # Check if argument is a number
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      # Argument is a number, get branches list and checkout by index
      local branches=()
      if [[ -n "$default_remote" ]]; then
        branches=($(git branch -a | grep "remotes/${default_remote}" | grep -v ' -> ' | sed "s#remotes/${default_remote}/##" | sort -f))
      else
        branches=($(git branch | sed 's/^[* ]*//' | sort -f))
      fi

      # Check if the number is valid
      if (( $1 >= 1 && $1 <= ${#branches[@]} )); then
        local branch=${branches[$1]}
        echo -e "\033[0;32m Switching to branch #$1: $branch\033[0m"
        if git show-ref --verify --quiet "refs/heads/$branch"; then
          git checkout "$branch"
        elif [[ -n "$default_remote" ]] && git ls-remote --heads "$default_remote" "$branch" | grep -q "refs/heads/$branch$"; then
          git checkout --track "$default_remote/$branch"
        else
          echo -e "\033[0;36m Creating new branch: $branch\033[0m"
          git checkout -b "$branch"
        fi
      else
        echo -e "\033[1;31mError: Invalid branch number. Valid range is 1-${#branches[@]}\033[0m"
        # Show available branches
        echo -e "\n\033[0;36mAvailable branches:\033[0m"
        if [[ ${#branches[@]} -gt 9 ]]; then
          display_available "branches" "${branches[@]}" | column
        else
          display_available "branches" "${branches[@]}"
        fi
        return 1
      fi
    else
      # Not a number, handle as branch name
      # Check if branch exists locally
      if git show-ref --verify --quiet "refs/heads/$1"; then
        echo -e "\033[0;32m Switching to existing local branch: $1\033[0m"
        git checkout "$1"
      else
        # Branch doesn't exist locally, create it
        echo -e "\033[0;36m Creating new branch: $1\033[0m"
        git checkout -b "$1"
      fi
    fi
  else
    # Get all branches (local and remote, deduplicated)
    local all_branches=($(git branch -a | grep -v ' -> ' | sed -E 's#remotes/[^/]*/##' | sed 's/^[* ]*//' | sort -u))
    local branches=()
    if [[ -n "$default_remote" ]]; then
      branches=($(git branch -a | grep "remotes/${default_remote}" | grep -v ' -> ' | sed "s#remotes/${default_remote}/##" | sort -f))
    else
      branches=($(git branch | sed 's/^[* ]*//' | sort -f))
    fi

    if [[ ${#branches[@]} -gt 9 ]]; then
      display_available "branches" "${branches[@]}" | column
    else
      display_available "branches" "${branches[@]}"
    fi

    local user_input=""
    while true; do
      echo -n -e "\033[0;33mYour choice: \033[0m$user_input"

      # Read single character
      read -k 1 -s char

      # Handle immediate selection for numbers 1-9
      if [[ "$char" =~ ^[1-9]$ ]] && [[ -z "$user_input" ]]; then
        # Single digit number pressed when input is empty - immediate selection
        if (( char <= ${#branches[@]} )); then
          echo "$char"
          branch=${branches[$char]}
          echo -e "\033[0;32m Switching to: $branch\033[0m"
          if git show-ref --verify --quiet "refs/heads/$branch"; then
            git checkout "$branch"
          elif [[ -n "$default_remote" ]] && git ls-remote --heads "$default_remote" "$branch" | grep -q "refs/heads/$branch$"; then
            git checkout --track "$default_remote/$branch"
          else
            echo -e "\033[0;36mCreating new branch: $branch\033[0m"
            git checkout -b "$branch"
          fi
          return
        fi
      fi

      # Handle special keys
      if [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]]; then
        # Backspace - remove last character
        if [[ -n "$user_input" ]]; then
          user_input="${user_input%?}"
          echo -ne "\r\033[K" # Clear line
          continue
        fi
      elif [[ "$char" == $'\n' ]] || [[ "$char" == $'\r' ]]; then
        # Enter pressed
        echo "" # New line

        # Process the input
        if [[ -z "$user_input" ]]; then
          # Re-display options and list when user just presses Enter
          echo -e "\033[0;36m=== Git Branch Selector ===\033[0m"
          if [[ ${#branches[@]} -gt 9 ]]; then
            display_available "branches" "${branches[@]}" | column
          else
            display_available "branches" "${branches[@]}"
          fi
          echo -e "\n\033[0;36mOptions:\033[0m"
          echo "- Enter number (1-${#branches[@]}) to select from list"
          echo "- Start typing to filter/create branch"
          echo "- Press Q to exit"
          echo ""
          user_input=""
          continue
        fi

        # Check for quit
        if [[ "$user_input" =~ ^[Qq]$ ]]; then
          echo "Exit."
          return
        fi

        # Check if it's a number selection
        if [[ "$user_input" =~ ^[0-9]+$ ]] && (( user_input >= 1 && user_input <= ${#branches[@]} )); then
          branch=${branches[$user_input]}
          echo -e "\033[0;32m Switching to: $branch\033[0m"
          if git show-ref --verify --quiet "refs/heads/$branch"; then
            git checkout "$branch"
          elif [[ -n "$default_remote" ]] && git ls-remote --heads "$default_remote" "$branch" | grep -q "refs/heads/$branch$"; then
            git checkout --track "$default_remote/$branch"
          else
            echo -e "\033[0;36m Creating new branch: $branch\033[0m"
            git checkout -b "$branch"
          fi
          return
        fi

        # Check if user typed a branch name (not a number)
        if [[ ! "$user_input" =~ ^[0-9]+$ ]]; then
          # Check for exact match first
          local exact_match=""
          for b in "${all_branches[@]}"; do
            if [[ "$b" == "$user_input" ]]; then
              exact_match="$b"
              break
            fi
          done

          if [[ -n "$exact_match" ]]; then
            echo -e "\033[0;32m Switching to: $exact_match\033[0m"
            if git show-ref --verify --quiet "refs/heads/$exact_match"; then
              git checkout "$exact_match"
            elif [[ -n "$default_remote" ]] && git ls-remote --heads "$default_remote" "$exact_match" | grep -q "refs/heads/$exact_match$"; then
              git checkout --track "$default_remote/$exact_match"
            else
              echo -e "\033[0;36mCreating new branch: $exact_match\033[0m"
              git checkout -b "$exact_match"
            fi
            return
          fi

          # Show suggestions if partial matches exist
          local matches=()
          for b in "${all_branches[@]}"; do
            if [[ "$b" == *"$user_input"* ]]; then
              matches+=("$b")
            fi
          done

          if [[ ${#matches[@]} -eq 1 ]]; then
            # Single match found
            echo -e "\033[0;32m Found match: ${matches[0]}\033[0m"
            single_match="${matches[0]}"
            if git show-ref --verify --quiet "refs/heads/$single_match"; then
              git checkout "$single_match"
            elif [[ -n "$default_remote" ]] && git ls-remote --heads "$default_remote" "$single_match" | grep -q "refs/heads/$single_match$"; then
              git checkout --track "$default_remote/$single_match"
            else
              echo -e "\033[0;36mCreating new branch: $single_match\033[0m"
              git checkout -b "$single_match"
            fi
            return
          elif [[ ${#matches[@]} -gt 1 ]]; then
            # Multiple matches found
            echo -e "\033[0;33mMultiple matches found:\033[0m"
            local i=1
            for m in "${matches[@]}"; do
              echo "  $i) $m"
              ((i++))
            done
            echo "Please be more specific or select a number."
            user_input=""
            continue
          else
            # No matches, automatically create new branch
            echo -e "\033[0;36mCreating new branch: $user_input\033[0m"
            git checkout -b "$user_input"
            return
          fi
        else
          echo "Invalid selection. Try again."
          user_input=""
          continue
        fi
      elif [[ "$char" == $'\033' ]]; then
        # Escape sequence (like arrow keys) - ignore for now
        read -k 2 -s # consume the rest of escape sequence
        continue
      elif [[ "$char" =~ ^[Qq]$ ]] && [[ -z "$user_input" ]]; then
        # Q pressed when input is empty
        echo ""
        echo "Exit."
        return
      else
        # Regular character - add to input
        user_input="${user_input}${char}"
        echo -n "$char"

        # Show real-time suggestions as user types
        if [[ -n "$user_input" ]] && [[ ! "$user_input" =~ ^[0-9]+$ ]]; then
          local matches=()
          for b in "${all_branches[@]}"; do
            if [[ "$b" == *"$user_input"* ]]; then
              matches+=("$b")
            fi
          done

          if [[ ${#matches[@]} -gt 0 ]] && [[ ${#matches[@]} -le 5 ]]; then
            echo -ne "\033[0;90m (suggestions: "
            local first=1
            for m in "${matches[@]}"; do
              if [[ $first -eq 1 ]]; then
                echo -n "$m"
                first=0
              else
                echo -n ", $m"
              fi
            done
            echo -ne ")\033[0m"
            echo -ne "\r\033[0;33mYour choice: \033[0m$user_input"
          fi
        fi
      fi
    done
  fi
}

# Git ACP
git_acp() {
  local remote_origin=$(git remote get-url origin 2>/dev/null)
  if [[ ! -e .git ]]; then
  echo "\033[1;31mNot a git repository.\033[0m"
    git init
    if [[ ! -f .gitignore ]]; then
      echo -e "${BLUE}Creating smart .gitignore...${RESET}"

      # Base ignore files (unchanged)
      echo "# Common" > .gitignore
      echo ".DS_Store" >> .gitignore
      echo ".env" >> .gitignore
      echo "*.log" >> .gitignore
      echo "*.gguf" >> .gitignore

      # Detect project type (unchanged)
      if [[ -f package.json ]]; then
        echo -e "${GREEN}Node.js project detected${RESET}"
        echo "\n# Node" >> .gitignore
        echo "node_modules/" >> .gitignore
        echo "dist/" >> .gitignore
        echo "*.env" >> .gitignore
      elif [[ -f requirements.txt || -f Pipfile ]]; then
        echo -e "${GREEN}Python project detected${RESET}"
        echo "\n# Python" >> .gitignore
        echo "__pycache__/" >> .gitignore
        echo "*.pyc" >> .gitignore
        echo "venv/" >> .gitignore
        echo ".venv/" >> .gitignore
      elif ls *.gguf >/dev/null 2>&1; then
        echo -e "${CYAN}LLM model files detected${RESET}"
        echo "\n# LLM Models" >> .gitignore
        echo "*.gguf" >> .gitignore
        echo "*.bin" >> .gitignore
        echo "*.h5" >> .gitignore
      fi
    fi
    repo_name=$(basename "$(pwd)")
    gh repo create "$repo_name" --source=. --private
  fi

  local git_branch=$(git branch --show-current)
  git add .
  git status

  echo "1) Continue"
  echo "2) Abort"
  read -r -k -s reply
  if [[ "$reply" == "2" ]]; then
    echo "Exit."
    return
  else
     git commit -m "$1"
     if [[ -z "$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)" ]]; then
       git push --set-upstream origin "$git_branch"
     else
       git push
     fi
   fi
}

# Project Tools
vsp(){
   vsce publish
}

# Shortcut to create an app by type
ca() {
  if [[ "$1" == "an" ]]; then
    ng new "$2" --routing --style=css
  elif [[ "$1" == "ne" ]]; then
      npx create-next-app@latest
  elif [[ "$1" == "vu" ]]; then
    vue create "$2" --default --babel --eslint
  else
    echo "Framework not supported."
  fi
}

npmc() {
  local action="${1:-}"
  if [[ -z "$action" ]]; then
    echo "NPM command:"
    echo "1) install"
    echo "2) test"
    echo "3) lint"
    echo "4) build"
    echo "5) dev"
    read -k -s action
    echo ""
  fi

  case "$action" in
    1|i|install) npm install ;;
    2|t|test) npm test ;;
    3|l|lint) npm run lint ;;
    4|b|build) npm run build ;;
    5|d|dev) npm run dev ;;
    *) echo "Unknown action." ;;
  esac
}

yarnc() {
  local action="${1:-}"
  if [[ -z "$action" ]]; then
    echo "Yarn command:"
    echo "1) install"
    echo "2) test"
    echo "3) lint"
    echo "4) build"
    echo "5) dev"
    read -k -s action
    echo ""
  fi

  case "$action" in
    1|i|install) yarn install ;;
    2|t|test) yarn test ;;
    3|l|lint) yarn lint ;;
    4|b|build) yarn build ;;
    5|d|dev) yarn dev ;;
    *) echo "Unknown action." ;;
  esac
}

# Infra
tfc() {
  if ! command -v terraform >/dev/null 2>&1; then
    echo "terraform not found."
    return 1
  fi

  local action="${1:-}"
  if [[ -z "$action" ]]; then
    echo "Terraform command:"
    echo "1) init"
    echo "2) plan"
    echo "3) apply"
    echo "4) destroy"
    echo "5) fmt"
    read -k -s action
    echo ""
  else
    shift
  fi

  case "$action" in
    1|i|init) terraform init "$@" ;;
    2|p|plan) terraform plan "$@" ;;
    3|a|apply) terraform apply "$@" ;;
    4|d|destroy) terraform destroy "$@" ;;
    5|f|fmt) terraform fmt "$@" ;;
    *) echo "Unknown action." ;;
  esac
}

k8sc() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found."
    return 1
  fi

  local action="${1:-}"
  if [[ -z "$action" ]]; then
    echo "K8s command:"
    echo "1) contexts"
    echo "2) use context"
    echo "3) namespaces"
    echo "4) set namespace"
    echo "5) pods"
    echo "6) services"
    read -k -s action
    echo ""
  else
    shift
  fi

  case "$action" in
    1|ctx|contexts)
      kubectl config get-contexts
      ;;
    2|use)
      local contexts=($(kubectl config get-contexts -o name))
      if [[ ${#contexts[@]} -eq 0 ]]; then
        echo "No contexts found."
        return 1
      fi
      display_available "contexts" "${contexts[@]}"
      read -k -s reply
      echo ""
      if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#contexts[@]} )); then
        kubectl config use-context "${contexts[$reply]}"
      else
        echo "Invalid selection."
        return 1
      fi
      ;;
    3|ns|namespaces)
      kubectl get ns
      ;;
    4|setns)
      local namespaces=($(kubectl get ns -o jsonpath='{.items[*].metadata.name}'))
      if [[ ${#namespaces[@]} -eq 0 ]]; then
        echo "No namespaces found."
        return 1
      fi
      display_available "namespaces" "${namespaces[@]}"
      read -k -s reply
      echo ""
      if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#namespaces[@]} )); then
        kubectl config set-context --current --namespace="${namespaces[$reply]}"
      else
        echo "Invalid selection."
        return 1
      fi
      ;;
    5|pods)
      kubectl get pods -A
      ;;
    6|svc|services)
      kubectl get svc -A
      ;;
    *)
      echo "Unknown action."
      ;;
  esac
}

sz() {
  source ~/.zshrc
}

# Shortcut to open the current directory
op(){
  open .
}

# Shortcut to exit terminal
ee() {
  exit
}

# Shortcut to kill a port
kp() {
  local PORT1=$1
  local PORT2=$2

  if [ -z "$PORT1" ]; then
    echo "Please specify at least one port to kill processes."
    return
  fi

  if [ -z "$PORT2" ]; then
    # If only one port is provided, find the PID for that port.
    local PID=$(lsof -ti :$PORT1)
    if [ -z "$PID" ]; then
      echo "No process found on port $PORT1"
    else
      kill -9 "$PID"
      echo "Process on port $PORT1 (PID: $PID) has been killed"
    fi
  else
    # If two ports are provided, kill processes across the port range.
    for ((port = PORT1; port <= PORT2; port++)); do
      local PID=$(lsof -ti :$port)
      if [ -n "$PID" ]; then
        kill -9 "$PID"
        echo "Process on port $port (PID: $PID) has been killed"
      fi
    done
  fi
}

# Shortcut to delete a folder
del(){
  rm -rf "$1"
}

# Kafka
# Shared helpers used by kafka and docker pickers
display_available_topics() {
  local topics=("$@")
  local num_topics=${#topics[@]}

  local i
  for ((i=1; i<=num_topics; i++)); do
    echo "$i) ${topics[$i]}"
  done
}
display_available_groups() {
  local groups=("$@")
  local num_groups=${#groups[@]}

  local i
  for ((i=1; i<=num_groups; i++)); do
    echo "$i) ${groups[$i]}"
  done
}

# Kafka
kafkac(){
  if [[ -z "${KAFKA_HOME:-}" ]]; then
    echo "Set KAFKA_HOME to your Kafka install directory."
    return 1
  fi
  if [[ ! -d "$KAFKA_HOME" ]]; then
    echo "KAFKA_HOME not found: $KAFKA_HOME"
    return 1
  fi

  PS3="What to run?
  1.Start Zookeeper  2.Start Kafka   3.Create Topic  4.Topic Info
  5.Send Event       6.Listen Event  7.Stop Process  8. Delete Topic"
  if [[ -z "$1" ]]; then
    echo "$PS3"
    read -k -s REPLY
  else
    REPLY="$1"
  fi

  if [[ -n $(ps -ef | grep -v grep | grep zookeeper) ]] && [[ -n $(ps -ef | grep -v grep | grep kafka.Kafka) ]] && [[ "$REPLY" =~ ^[4568]$ ]]; then
    allTopics=($("$KAFKA_HOME"/bin/kafka-topics.sh --list --bootstrap-server localhost:9092 | sed '1d'))
    if [[ "$REPLY" == "6" ]]; then
      allGroups=($("$KAFKA_HOME"/bin/kafka-consumer-groups.sh --list --bootstrap-server localhost:9092))
    fi
  fi

  if [[ "$REPLY" == "1" ]]; then
    echo -n "\033[0;32mZookpeer is Running\033[0m \n"
    "$KAFKA_HOME"/bin/zookeeper-server-start.sh "$KAFKA_HOME"/config/zookeeper.properties
    echo "\033[1;31m\nZookeeper has been stopped.\033[0m" && cd ~/

  elif [[ "$REPLY" == "2" ]]; then
    for i in {20..1}; do
      echo -n "\033[1;31mRunning Kafka in $i \033[0m"
      sleep 1
      echo -n "\r"
    done
    echo -n "\033[2K"
    echo -n "\033[0;32mKafka Server is Running\033[0m \n"
    "$KAFKA_HOME"/bin/kafka-server-start.sh "$KAFKA_HOME"/config/server.properties
    echo "\033[1;31\nmKafka Server has been stopped.\033[0m" && cd ~/

  elif [[ "$REPLY" == "3" ]]; then
    echo "Enter topic name to create:"
    read topicName
    echo "Enter Number of Partitions:"
    read numberOfPartitions
    if [[ "$numberOfPartitions" =~ ^[0-9]+$ ]]; then
      "$KAFKA_HOME"/bin/kafka-topics.sh --create --topic "$topicName" --bootstrap-server localhost:9092 --partitions "$numberOfPartitions" && cd ~/
    else
      echo "Invalid input"
      return
    fi

  elif [[ "$REPLY" == "4" ]]; then
    if [[ -z "${allTopics[@]}" ]]; then
      echo "No topic available"
      return
    else
      PS3="Get info from topic"
      echo "$PS3"
      display_available_topics "${allTopics[@]}"
      read -k -s topicToListen
      if [[ "$topicToListen" =~ ^[0-9]+$ ]] && (( topicToListen >= 1 && topicToListen <= ${#allTopics[@]} )); then
        local selectedTopic=${allTopics[$topicToListen]}
        echo "\033[0;32mGetting info from topic $selectedTopic\033[0m" && "$KAFKA_HOME"/bin/kafka-topics.sh --describe --topic "$selectedTopic" --bootstrap-server localhost:9092 && cd ~/
      else
        echo "Invalid input"
        return
      fi
    fi

  elif [[ "$REPLY" == "5" ]]; then
    if [[ -z "${allTopics[@]}" ]]; then
      echo "No topic available"
      return
    else
      PS3="Send event to topic"
      echo "$PS3"
      display_available_topics "${allTopics[@]}"
      read -k -s topicToListen
      if [[ "$topicToListen" =~ ^[0-9]+$ ]] && (( topicToListen >= 1 && topicToListen <= ${#allTopics[@]} )); then
        local selectedTopic=${allTopics[$topicToListen]}
        echo "\033[0;32mSending event to topic $selectedTopic\033[0m" && "$KAFKA_HOME"/bin/kafka-console-producer.sh --topic "$selectedTopic" --bootstrap-server localhost:9092
        echo "\033[1;31m\nSending event to topic $selectedTopic has been stopped.\033[0m"  && cd ~/.
      else
        echo "Invalid input"
        return
      fi
    fi

  elif [[ "$REPLY" == "6" ]]; then
    if [[ -z "${allTopics[@]}" ]]; then
      echo "No topic available"
      return
    else
      PS3="Listen event from topic"
      echo "$PS3"
      display_available_topics "${allTopics[@]}"
      read -k -s topicToListen

      if [[ "$topicToListen" =~ ^[0-9]+$ ]] && (( topicToListen >= 1 && topicToListen <= ${#allTopics[@]} )); then
        local selectedTopic=${allTopics[$topicToListen]}
        PS3="Make a group? (Y/N)"
        echo "$PS3"
        read -k -s makeGroup
        if [[ "$makeGroup" =~ ^[Yy]$ ]]; then
          echo "Enter group name"
          read groupToListen
          echo "\033[0;32mListening event from topic $selectedTopic with $groupToListen group\033[0m" && "$KAFKA_HOME"/bin/kafka-console-consumer.sh --topic "$selectedTopic" --group "$groupToListen" --from-beginning --bootstrap-server localhost:9092
          echo "\033[1;31m\nListening event from topic $selectedTopic with $groupToListen group has been stopped.\033[0m"  && cd ~/.
        else
          if [[ -z "${allGroups[@]}" ]]; then
            echo "\033[0;32mListening event from $selectedTopic topic\033[0m" && "$KAFKA_HOME"/bin/kafka-console-consumer.sh --topic "$selectedTopic" --from-beginning --bootstrap-server localhost:9092
            echo "\033[1;31m\nListening event from topic $selectedTopi has been stopped.\033[0m"  && cd ~/.
          else
            PS3="Select topic group (q to listen without group)"
            echo "$PS3"
            display_available_groups "${allGroups[@]}"
            read -k -s groupToListen

            if [[ "$groupToListen" =~ ^[0-9]+$ ]] && (( groupToListen >= 1 && groupToListen <= ${#allGroups[@]} )); then
              local selectedGroup=${allGroups[$topicToListen]}
              echo "\033[0;32mListening event from topic $selectedTopic with $selectedGroup group\033[0m" && "$KAFKA_HOME"/bin/kafka-console-consumer.sh --topic "$selectedTopic" --group "$selectedGroup" --from-beginning --bootstrap-server localhost:9092
              echo "\033[1;31m\nListening event from topic $selectedTopic with $groupToListen group has been stopped.\033[0m"  && cd ~/.
            elif [[ "$groupToListen" =~ ^[qQ]$ ]]; then
              echo "\033[0;32mListening event from $selectedTopic topic\033[0m" && "$KAFKA_HOME"/bin/kafka-console-consumer.sh --topic "$selectedTopic" --from-beginning --bootstrap-server localhost:9092
              echo "\033[1;31m\nListening event from topic $selectedTopi has been stopped.\033[0m"  && cd ~/.
            fi
          fi
        fi

      else
        echo "Invalid input"
        return
      fi
    fi

  elif [[ "$REPLY" == "7" ]]; then
    if [[ -n $(ps -ef | grep -v grep | grep zookeeper) ]] && [[ -n $(ps -ef | grep -v grep | grep kafka.Kafka) ]]; then
      "$KAFKA_HOME"/bin/zookeeper-server-stop.sh && "$KAFKA_HOME"/bin/kafka-server-stop.sh && echo "\033[1;31mZookeeper and Kafka Server has been stopped\033[0m" && cd ~/.
    elif  [[ -n $(ps -ef | grep -v grep | grep zookeeper) ]]; then
      "$KAFKA_HOME"/bin/zookeeper-server-stop.sh && echo "\033[1;31mZookeeper Server has been stopped\033[0m" && cd ~/.
    elif  [[ -n $(ps -ef | grep -v grep | grep kafka.Kafka) ]]; then
      "$KAFKA_HOME"/bin/kafka-server-stop.sh && echo "\033[1;31mKafka Server has been stopped\033[0m" && cd ~/.
    else
      echo "\033[1;31mZookeeper and Kafka Server is not running\033[0m"
    fi

  elif [[ "$REPLY" == "8" ]]; then
    if [[ -z "${allTopics[@]}" ]]; then
      echo "No topic available"
      return
    else
      echo "Delete all Topic? (Y/N)"
      read -k -s deleteAll
      if [[ "$deleteAll" =~ ^[Yy]$ ]]; then
        "$KAFKA_HOME"/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic ".*"
        echo "\033[1;31mAll topics has been deleted\033[0m"
      else
        PS3="Delete topic"
        echo "$PS3"
        display_available_topics "${allTopics[@]}"
        read -k -s topicToListen
        if [[ "$topicToListen" =~ ^[0-9]+$ ]] && (( topicToListen >= 1 && topicToListen <= ${#allTopics[@]} )); then
          local selectedTopic=${allTopics[$topicToListen]}
          "$KAFKA_HOME"/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic "$selectedTopic"
          echo "\033[1;31mTopic $selectedTopic has been deleted.\033[0m"
        fi
      fi
    fi

  else
    echo "Invalid input"
    return
  fi
}

ka(){ kafkac "$@"; }

# Docker
dockerps() {
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

dockerkill() {
  local containers=($(docker ps --format '{{.Names}}'))
  if [[ ${#containers[@]} -eq 0 ]]; then
    echo "No running containers."
    return 0
  fi

  echo "Select container to stop and remove:"
  display_available_topics "${containers[@]}"
  read -k -s reply
  echo ""
  if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#containers[@]} )); then
    local selected="${containers[$reply]}"
    docker stop "$selected" && docker rm "$selected"
  else
    echo "Invalid selection."
    return 1
  fi
}

dockerc(){

  PS3="What to run?
  1.Docker Build  2.Docker Run  3.Compose Up
  4.Compose Down  5.Docker Bash 6.Docker Stop"
  if [[ -z "$1" ]]; then
    echo "$PS3"
    read -k -s REPLY
  else
      REPLY="$1"
  fi

  if [[ "$REPLY" == "1" ]]; then
    docker build -t "$2":latest .

  elif [[ "$REPLY" == "2" ]]; then
    allImages=($(docker images | grep -v "REPOSITORY" | awk '{print $1}'))
    echo "Select Image:"
    display_available_topics "${allImages[@]}"
    read -k -s ImageName
    if [[ "$ImageName" =~ ^[0-9]+$ ]] && (( ImageName >= 1 && ImageName <= ${#allImages[@]} )); then
      local selectedImage=${allImages[$ImageName]}
      echo "Enter Port to Run:"
      read Port
      docker run -d -p "$Port":"$Port" --name "$selectedImage" "$selectedImage":"$(docker images | grep "redis" | awk '{print $2}')"
    else
      echo "Invalid input"
      return
    fi

  elif [[ "$REPLY" == "3" ]]; then
    docker-compose up

  elif [[ "$REPLY" == "4" ]]; then
    docker-compose down

  elif [[ "$REPLY" == "5" ]]; then
    allImages=($(docker images | grep -v "REPOSITORY" | awk '{print $1}'))
    echo "Select Image:"
    display_available_topics "${allImages[@]}"
    read -k -s ImageName
    if [[ "$ImageName" =~ ^[0-9]+$ ]] && (( ImageName >= 1 && ImageName <= ${#allImages[@]} )); then
      local selectedImage=${allImages[$ImageName]}
      docker exec -it "$selectedImage" /bin/sh
    else
      echo "Invalid input"
      return
    fi

    elif [[ "$REPLY" == "6" ]]; then
    allImages=($(docker images | grep -v "REPOSITORY" | awk '{print $1}'))
    echo "Select Image:"
    display_available_topics "${allImages[@]}"
    read -k -s ImageName
    if [[ "$ImageName" =~ ^[0-9]+$ ]] && (( ImageName >= 1 && ImageName <= ${#allImages[@]} )); then
      local selectedImage=${allImages[$ImageName]}
      docker stop "$selectedImage" && docker rm "$selectedImage"
    else
      echo "Invalid input"
      return
    fi

  else
    echo "Invalid input"
    return
  fi
}

dkr(){ dockerc "$@"; }

# Misc
# Shortcut to hide folder/file
hide(){
  chflags hidden "$1"
}

# Shortcut to unhide folder/file
unhide() {
  chflags nohidden "$1"
}

# Shortcut to clean macOS caches
ctm(){
  # cd ~/Library/Caches/
  rm -rf ~/Library/Caches/*
  # osascript -e 'tell app "loginwindow" to event aevtrrst' # restart
  cd -
  clear
}

# Shortcut to clear the terminal
cl(){
  clear
}

# Python
# Centralized Python venv management
# pvenv        = create/activate venv for current dir
# pvenv --view = list all venvs
# pvenv --rm   = remove venv for current dir
pvenv() {
  local root="${VENV_HOME:-$HOME/.venvs}"
  local dir_name="${PWD##*/}"
  local short_hash="$(echo "$PWD" | shasum -a 256 | cut -c1-8)"
  local venv="$root/${dir_name}-${short_hash}"

  case "$1" in
    --view)
      echo "Centralized venvs in $root:"
      ls -la "$root" 2>/dev/null || echo "No venvs found."
      ;;
    --rm)
      if [[ -d "$venv" ]]; then
        rm -rf "$venv"
        echo "Removed: $venv"
      else
        echo "No venv found for this directory."
      fi
      ;;
    *)
      mkdir -p "$root"
      if [[ ! -d "$venv" ]]; then
        echo "Creating venv at $venv..."
        python3 -m venv "$venv"
      fi
      source "$venv/bin/activate"
      echo "Activated: $venv"
      ;;
  esac
}

pysetup() {
  echo "Installing Python 3.13..."
  brew install python@3.13
  brew link --overwrite python@3.13
  echo "Done!"
  python3 --version
}

# Redis
redisc() {
  echo "Redis command:"
  echo "1) start"
  echo "2) stop"
  echo "3) info"
  echo "4) cli"
  echo "5) start + cli"
  read -k -s reply
  echo ""
  case "$reply" in
    1) brew services start redis ;;
    2) brew services stop redis ;;
    3) brew services info redis ;;
    4) redis-cli ;;
    5) sre ;;
    *) echo "Invalid selection." ;;
  esac
}

sre(){
  brew services start redis && redis-cli
}

ssre(){
  brew services stop redis
}

inre(){
  brew services info redis
}

# Setup
setup_java() {
  echo "Setting up Java..."

  # Define versions and their URLs
  JAVA_VERSIONS=(
    "23 https://download.oracle.com/java/23/latest/jdk-23_macos-aarch64_bin.tar.gz"
    "17 https://download.oracle.com/java/17/archive/jdk-17.0.12_macos-aarch64_bin.tar.gz"
  )

  INSTALL_DIR="/Library/Java/JavaVirtualMachines"
  TEMP_DIR="/tmp/jdk-install"

  # Ensure sudo privileges
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to run with sudo privileges."
    echo "Please enter your password to continue."
  fi

  for entry in "${JAVA_VERSIONS[@]}"; do
    # Extract version and URL
    version=$(echo $entry | cut -d ' ' -f 1)
    URL=$(echo $entry | cut -d ' ' -f 2)
    DEST_DIR="${INSTALL_DIR}/jdk-${version}.jdk"

    # Skip if already installed
    if [ -d "$DEST_DIR" ]; then
      echo "Java $version is already installed at $DEST_DIR."
      continue
    fi

    # Create temporary directory
    mkdir -p "$TEMP_DIR"

    # Download JDK tarball
    echo "Downloading Java $version from $URL..."
    curl -L -o "$TEMP_DIR/jdk-${version}.tar.gz" "$URL"

    # Extract tarball
    echo "Extracting Java $version..."
    tar -xzf "$TEMP_DIR/jdk-${version}.tar.gz" -C "$TEMP_DIR"

    # Locate the extracted `.jdk` directory
    EXTRACTED_DIR=$(find "$TEMP_DIR" -type d -name "jdk-*.jdk" | head -n 1)

    # Check if the extracted directory exists
    if [ -z "$EXTRACTED_DIR" ]; then
      echo "Error: Unable to find the extracted .jdk directory for Java $version."
      continue
    fi

    # Move and rename to the correct directory
    echo "Moving Java $version to $DEST_DIR..."
    sudo mv "$EXTRACTED_DIR" "$DEST_DIR"

    echo "Java $version installed successfully at $DEST_DIR."
  done

  # Clean up temporary files
  rm -rf "$TEMP_DIR"
  echo "All Java versions are set up!"
}

# Function to download and extract Android command-line tools
setup_android() {
  local ANDROID_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
  local DEST_DIR="$HOME/Android/cmdline-tools"
  local ZIP_FILE="$DEST_DIR/tools.zip"
  mkdir -p "$DEST_DIR"
  echo "Downloading Android command-line tools..."
  curl -o "$ZIP_FILE" -L "$ANDROID_TOOLS_URL"

  echo "Extracting files..."
  unzip -o "$ZIP_FILE" -d "$DEST_DIR"

  mv "$DEST_DIR/cmdline-tools" "$DEST_DIR/latest" 2>/dev/null

  echo "Android command-line tools installed in: $DEST_DIR/latest"
  rm "$ZIP_FILE"
}

# Notes:
# Postman arm64 download:
# https://dl.pstmn.io/download/latest/osx_arm64?deviceId=1niRW2aSM4xoRNiCcJlnKx
# Angular CLI autocompletion:
# source <(ng completion script)

######################################################################################## ZSH CONFIG
# VSCode integration (PATH set in ENV & PATH section)
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# Syntax highlighting
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  ZSH_HL_FILE="$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "$ZSH_HL_FILE" ]] && source "$ZSH_HL_FILE"
fi

# Remove the underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES

# Adjusted coloring for better contrast
ZSH_HIGHLIGHT_STYLES[function]=fg=#00994C,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=#0066CC,bold
ZSH_HIGHLIGHT_STYLES[path]=fg=#007A00,bold
ZSH_HIGHLIGHT_STYLES[path_pathseparator]=fg=#007A00
ZSH_HIGHLIGHT_STYLES[path_prefix]=fg=#007A00
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=#FF4C4C,bold
ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=#FFFFFF,bold
ZSH_HIGHLIGHT_STYLES[default]=fg=#D1FF6D
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=#D1FF6D

# Autosuggestions
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  ZSH_AS_FILE="$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$ZSH_AS_FILE" ]] && source "$ZSH_AS_FILE"
fi
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#009A48,bold'

# Set the background for readability
export ZSH_HIGHLIGHT_STYLES[background]=bg=#1F1F1F

# Enable AUTO_CD
setopt AUTO_CD

# Turn On Colors
autoload -Uz colors && colors

# Disable case-sensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Prioritize directories in completion
zstyle ':completion:*:default' group-order 'directories' 'files'

# Suggest only file and folder names
zstyle ':completion:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} r:|[._-]=*'
zstyle ':completion:*' completer _files
zstyle ':completion:*' menu select
zstyle ':completion:*' menu yes select

zmodload -i zsh/complist
bindkey -M menuselect '^M' .accept-line
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" \
  "di=38;5;34:fi=38;5;7:ln=38;5;14:pi=38;5;11:ex=38;5;2" \
  "*.py=38;5;33:*.java=38;5;42:*.txt=38;5;8:*.sh=38;5;45" \
  "ma=48;2;255;255;255;18;2;0;0;0"  # Add custom color for 'ma' entries

# Enable auto-completion
autoload -U compinit; compinit

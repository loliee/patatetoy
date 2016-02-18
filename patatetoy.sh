#!/usr/bin/env bash
# Patatetoy
#
# by Maxime Loliée
# https://github.com/loliee/patatetoy

# Bring a light and modified version of git-prompt.sh
# Git original git-prompt from Shawn O. Pearce <spearce@spearce.org>
# https://github.com/git/git/blob/8976500cbbb13270398d3b3e07a17b8cc7bff43f/contrib/completion/git-prompt.sh

c='\[\e[0m\]'

# shellcheck disable=SC2034
black='\[\e[0;30m\]'
red='\[\e[0;31m\]'
# shellcheck disable=SC2034
green='\[\e[0;32m\]'
yellow='\[\e[0;33m\]'
blue='\[\e[0;34m\]'
# shellcheck disable=SC2034
magenta='\[\e[0;35m\]'
# shellcheck disable=SC2034
cyan='\[\e[0;36m\]'
grey='\[\e[0;30m\]'
# shellcheck disable=SC2034
white='\[\e[0;97m\]'

PATATETOY_PROMPT_SYMBOL=${PATATETOY_PROMPT_SYMBOL:-❯}
PATATETOY_VIM_MODE=${PATATETOY_VIM_MODE:-0}
PATATETOY_GIT_DIRTY_SYMBOL=${PATATETOY_GIT_DIRTY_SYMBOL:-★}
PATATETOY_GIT_ARROW_COLOR=${PATATETOY_GIT_ARROW_COLOR:-$blue}
PATATETOY_GIT_UP_ARROW=${PATATETOY_GIT_UP_ARROW:-⬆}
PATATETOY_GIT_DOWN_ARROW=${PATATETOY_GIT_DOWN_ARROW:-⬇}
PATATETOY_GIT_STASH_CHECK=${PATATETOY_GIT_STASH_CHECK:-1}
PATATETOY_GIT_STASH_SYMBOL=${PATATETOY_GIT_STASH_SYMBOL:-"↯"}
PATATETOY_GIT_STASH_COLOR=${PATATETOY_GIT_STASH_COLOR:-$red}
PATATETOY_FORCE_DISPLAY_USERNAME=${PATATETOY_FORCE_DISPLAY_USERNAME:-0}
PATATETOY_USERNAME_COLOR=${PATATETOY_USERNAME_COLOR:-$red}
PATATETOY_ROOT_SYMBOL=${PATATATETOY_ROOT_SYMBOL:-"%F{red}✦"}
PATATETOY_CURSOR_COLOR_OK=${PATATETOY_CURSOR_COLOR_OK:-$yellow}
PATATETOY_CURSOR_COLOR_KO=${PATATETOY_CURSOR_COLOR_KO:-$red}
PATATETOY_GIT_DELAY_DIRTY_CHECK=${PATATETOY_GIT_DELAY_DIRTY_CHECK:-1800}
PATATETOY_GIT_UNTRACKED_DIRTY=${PATATETOY_GIT_UNTRACKED_DIRTY:-1}

__git_ps1_show_upstream () {
  local count
  local upstream="@{upstream}"
  # Find how many commits we are ahead/behind our upstream
  count="$(git rev-list --count --left-right \
        "$upstream"...HEAD 2>/dev/null)"
  count="$(echo "$count" | sed -r 's/\s+//')"
  case "$count" in
  "") # no upstream
    p="";;
  "00") # equal to upstream
    p="" ;;
  "0"*) # ahead of upstream
    p="$PATATETOY_GIT_UP_ARROW" ;;
  *"0") # behind upstream
    p="$PATATETOY_GIT_DOWN_ARROW" ;;
  *)      # diverged from upstream
    p="$PATATETOY_GIT_DOWN_ARROW$PATATETOY_GIT_UP_ARROW" ;;
  esac
  echo " $PATATETOY_GIT_ARROW_COLOR$p$c"
}

__git_ps1() {
  local pcmode=no
  case "$#" in
    2|3)  pcmode=yes
      ps1pc_start="$1"
      ps1pc_end="$2"
      printf_format="${3:-$printf_format}"
    ;;
    0|1)  printf_format="${1:-$printf_format}"
    ;;
    *)  return
    ;;
  esac
  local repo_info rev_parse_exit_code
  repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
    --is-bare-repository --is-inside-work-tree \
    --short HEAD 2>/dev/null)"
  rev_parse_exit_code="$?"

  if [ -z "$repo_info" ]; then
    if [ $pcmode = yes ]; then
      #In PC mode PS1 always needs to be set
      PS1="$ps1pc_start$ps1pc_end"
    fi
    return
  fi
  local short_sha
  if [ "$rev_parse_exit_code" = "0" ]; then
    short_sha="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
  fi
  local inside_worktree="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  local bare_repo="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  local inside_gitdir="${repo_info##*$'\n'}"
  local g="${repo_info%$'\n'*}"
  local rebase=""
  local branch=""
  local step=""
  local total=""
  if [ -d "$g/rebase-merge" ]; then
    read -r branch 2>/dev/null <"$g/rebase-merge/head-name"
    read -r step 2>/dev/null <"$g/rebase-merge/msgnum"
    read -r total 2>/dev/null <"$g/rebase-merge/end"
    if [ -f "$g/rebase-merge/interactive" ]; then
      rebase="|rebase-i"
    else
      rebase="|rebase-m"
    fi
  else
    if [ -d "$g/rebase-apply" ]; then
      read -r step 2>/dev/null <"$g/rebase-apply/next"
      read -r total 2>/dev/null <"$g/rebase-apply/last"
      if [ -f "$g/rebase-apply/rebasing" ]; then
        read -r branch 2>/dev/null <"$g/rebase-apply/head-name"
        rebase="|rebase"
      elif [ -f "$g/rebase-apply/applying" ]; then
        rebase="|am"
      else
        rebase="|am/rebase"
      fi
    elif [ -f "$g/MERGE_HEAD" ]; then
      rebase="|merging"
    elif [ -f "$g/CHERRY_PICK_HEAD" ]; then
      rebase="|cherry-picking"
    elif [ -f "$g/REVERT_HEAD" ]; then
      rebase="|reverting"
    elif [ -f "$g/BISECT_LOG" ]; then
      rebase="|bisecting"
    fi
    if [ -n "$branch" ]; then
      :
    elif [ -h "$g/HEAD" ]; then
      # symlink symbolic ref
      branch="$(git symbolic-ref HEAD 2>/dev/null)"
    else
      local head=""
      if ! read -r head 2>/dev/null <"$g/HEAD"; then
        if [ $pcmode = yes ]; then
          PS1="$ps1pc_start$ps1pc_end"
        fi
        return
      fi
      # is it a symbolic ref?
      branch="${head#ref: }"
      if [ "$head" = "$branch" ]; then
        branch="$(
        case "${GIT_PS1_DESCRIBE_STYLE-}" in
        (contains)
          git describe --contains HEAD ;;
        (branch)
          git describe --contains --all HEAD ;;
        (describe)
          git describe HEAD ;;
        (* | default)
          git describe --tags --exact-match HEAD ;;
        esac 2>/dev/null)" ||

        branch="$short_sha..."
        branch="$branch"
      fi
    fi
  fi
  if [ -n "$step" ] && [ -n "$total" ]; then
    rebase="$rebase $step/$total"
  fi
  local dirty=""
  local stash=""
  if [ "true" = "$inside_gitdir" ]; then
    if [ "true" = "$bare_repo" ]; then
      ci="bare"
    fi
  elif [ "true" = "$inside_worktree" ]; then
    if [ "$(git config --bool bash.showDirtyState)" != "false" ]
    then
      git diff --no-ext-diff --quiet --exit-code || dirty="$PATATETOY_GIT_DIRTY_SYMBOL"
      if [ -n "$short_sha" ]; then
        git diff-index --cached --quiet HEAD -- || dirty="$PATATETOY_GIT_DIRTY_SYMBOL"
      else
        dirty="$PATATETOY_GIT_DIRTY_SYMBOL"
      fi
    fi
    if [ -r "$g/refs/stash" ]; then
      stash="$PATATETOY_GIT_STASH_COLOR $PATATETOY_GIT_STASH_SYMBOL$c"
    fi
  fi
  branch=${branch##refs/heads/}
  local gitstring="$grey $branch$ci$rebase$dirty$c$stash"
  echo "$gitstring"
}

PROMPT_COMMAND=__prompt_command

function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  exec_cmd_time=$((SECONDS - timer))
  unset timer
}

function format_exec_cmd_time {
    local dcmd='date'
    if [[ -f '/usr/local/bin/gdate' ]]; then
      dcmd='/usr/local/bin/gdate'
    fi
    if [[ $exec_cmd_time -le 5 ]]; then
      prompt_time=""
      return
    fi
    if [[ $exec_cmd_time -le 59 ]]; then
      prompt_time=" $("$dcmd" -d@$exec_cmd_time -u +%ss)"
      return
    fi
    if [[ $exec_cmd_time -le 3599 ]]; then
      prompt_time=" $("$dcmd" -d@$exec_cmd_time -u +%-Mm %-Ss)"
      return
    fi
    prompt_time=" $("$dcmd" -d@$exec_cmd_time -u +%-Hh %-Mm %-Ss)"
}

function __prompt_command() {
    local exit_code=$?
    local current_dir

    # check previous command result
    if [[ $exit_code -ne 0 ]]; then
        prompt_symbol="${PATATETOY_CURSOR_COLOR_KO}\[\n\]$PATATETOY_PROMPT_SYMBOL ${c}"
    else
        prompt_symbol="${PATATETOY_CURSOR_COLOR_OK}\[\n\]$PATATETOY_PROMPT_SYMBOL ${c}"
    fi

    # Manage command time execution.
    timer_stop
    format_exec_cmd_time

    # Format current directory
    current_dir=$(p=${PWD/#"$HOME"/~};((${#p}>80))&& echo "${p::10}…${p:(-19)}"||echo "\w")

    PS1="\n"
    if [[ "$SSH_CONNECTION" != '' ]] || [[ $PATATETOY_FORCE_DISPLAY_USERNAME == 1 ]]; then
      PS1+="${PATATETOY_USERNAME_COLOR}\u@\h${c} "
    fi

    # Init prompt sequence
    PS1+="${blue}$current_dir${c}$(__git_ps1 "$@")$(__git_ps1_show_upstream "$@")${yellow}$prompt_time${c}$prompt_symbol"

    # show red star if root
    if [[ $UID -eq 0 ]]; then
      PS1+="$PATATETOY_ROOT_SYMBOL${c}"
    fi

    export PS1
}

# Set timer
trap 'timer_start' DEBUG
export PROMPT_COMMAND

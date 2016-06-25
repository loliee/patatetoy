# Patatetoy
# by Maxime Loliée
# https://github.com/loliee/patatetoy

. "$HOME/.patatetoy/patatetoy_common.sh"

c='\[\e[0m\]'
black='\[\e[0;90m\]'
red='\[\e[0;31m\]'
green='\[\e[0;32m\]'
yellow='\[\e[0;33m\]'
blue='\[\e[0;34m\]'
magenta='\[\e[0;35m\]'
cyan='\[\e[0;36m\]'
grey='\[\e[0;30m\]'
white='\[\e[0;97m\]'

PATATETOY_USERNAME_COLOR=${PATATETOY_USERNAME_COLOR:-$red}
PATATETOY_ROOT_SYMBOL_COLOR=${PATATETOY_ROOT_SYMBOL_COLOR:-$red}
PATATETOY_VIRTUALENV_COLOR=${PATATETOY_VIRTUALENV_COLOR:-$black}
PATATETOY_CURSOR_COLOR_OK=${PATATETOY_CURSOR_COLOR_OK:-$yellow}
PATATETOY_CURSOR_COLOR_KO=${PATATETOY_CURSOR_COLOR_KO:-$red}
PATATETOY_GIT_ARROW_COLOR=${PATATETOY_GIT_ARROW_COLOR:-$yellow}
PATATETOY_GIT_BRANCH_COLOR=${PATATETOY_GIT_BRANCH_COLOR:-$black}
PATATETOY_GIT_STASH_COLOR=${PATATETOY_GIT_STASH_COLOR:-$red}
PATATETOY_GIT_DIRTY_SYMBOL_COLOR=${PATATETOY_GIT_DIRTY_SYMBOL_COLOR:-$black}
PATATETOY_GIT_DISABLE=${PATATETOY_GIT_DISABLE:-0}

PROMPT_COMMAND=__prompt_command

function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  elapsed=$((SECONDS - timer))
  unset timer
}

function __prompt_command() {
    local exit_code=$?

    # check previous command result
    if [[ $exit_code -ne 0 ]]; then
        prompt_symbol="${PATATETOY_CURSOR_COLOR_KO}\n$PATATETOY_PROMPT_SYMBOL ${c}"
    else
        prompt_symbol="${PATATETOY_CURSOR_COLOR_OK}\n$PATATETOY_PROMPT_SYMBOL ${c}"
    fi
    # Manage command time execution.
    timer_stop
    patatetoy_cmd_exec_time $elapsed

    # Init prompt sequence
    PS1="\n"
    if [[ "$SSH_CONNECTION" != '' ]] || [[ $PATATETOY_FORCE_DISPLAY_USERNAME == 1 ]]; then
      PS1+="${PATATETOY_USERNAME_COLOR}\u@\h${c} "
    fi

    # show red star if root
    if [[ $UID -eq 0 ]]; then
      PS1+="${PATATETOY_ROOT_SYMBOL_COLOR}$PATATETOY_ROOT_SYMBOL${c} "
    fi

    PS1+="${blue}$(patatetoy_collapse_pwd)${c}"

    if [[ -n $patatetoy_vcs_working_tree ]] && [[ $PATATETOY_GIT_DISABLE != 1 ]]; then
      patatetoy_vcs_info
      patatetoy_git_branch
      patatetoy_git_upstream
      PS1+="${PATATETOY_GIT_BRANCH_COLOR}$patatetoy_git_branch${c}${PATATETOY_GIT_DIRTY_SYMBOL_COLOR}$(patatetoy_git_dirty)${c}"
      PS1+="${PATATETOY_GIT_STASH_COLOR}$(patatetoy_git_stash)$c$PATATETOY_GIT_ARROW_COLOR$patatetoy_git_upstream${c}"
    fi

    PS1+="${PATATETOY_VIRTUALENV_COLOR}$(patatetoy_virtualenv_info)${c}"
    PS1+="${yellow}$prompt_patatetoy_cmd_exec_time${c}$prompt_symbol"

    export PS1
}

# Set timer
trap 'timer_start' DEBUG
export PROMPT_COMMAND

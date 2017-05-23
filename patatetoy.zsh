# Patatetoy
# by Maxime Loliée
# https://github.com/loliee/patatetoy
#
# Zsh initialy forked from https://github.com/sindresorhus/pure

PATATETOY_INSTALL_DIR=${PATATETOY_INSTALL_DIR:-$HOME}
. "$PATATETOY_INSTALL_DIR/.patatetoy/patatetoy_common.sh"

PATATETOY_VIM_MODE=${PATATETOY_VIM_MODE:-0}
PATATETOY_GIT_PULL=${PATATETOY_GIT_PULL:-1}
PATATETOY_GIT_DELAY_DIRTY_CHECK=${PATATETOY_GIT_DELAY_DIRTY_CHECK:-1800}

# Colors
PATATETOY_USERNAME_COLOR=${PATATETOY_USERNAME_COLOR:-white}
PATATETOY_ROOT_SYMBOL_COLOR=${PATATETOY_ROOT_SYMBOL_COLOR:-red}
PATATETOY_VIRTUALENV_COLOR=${PATATETOY_VIRTUALENV_COLOR:-8}
PATATETOY_CURSOR_COLOR_OK=${PATATETOY_CURSOR_COLOR_OK:-yellow}
PATATETOY_CURSOR_COLOR_KO=${PATATETOY_CURSOR_COLOR_KO:-red}
PATATETOY_GIT_ARROW_COLOR=${PATATETOY_GIT_ARROW_COLOR:-yellow}
PATATETOY_GIT_BRANCH_COLOR=${PATATETOY_GIT_BRANCH_COLOR:-8}
PATATETOY_GIT_DIRTY_SYMBOL_COLOR=${PATATETOY_GIT_DIRTY_SYMBOL_COLOR:-8}
PATATETOY_GIT_STASH_COLOR=${PATATETOY_GIT_STASH_COLOR:-red}

# stores (into prompt_patatetoy_cmd_exec_time) the exec time of the last command if set threshold was exceeded
prompt_patatetoy_check_cmd_exec_time() {
  integer elapsed
  (( elapsed = EPOCHSECONDS - ${prompt_patatetoy_cmd_timestamp:-$EPOCHSECONDS} ))
  patatetoy_cmd_exec_time $elapsed
}

function zle-line-init zle-keymap-select {
  prompt_patatetoy_vim_mode="%F{$PATATETOY_GIT_BRANCH_COLOR}${${KEYMAP/vicmd/n }/(main|viins)/i }%f"
  zle reset-prompt
}

prompt_patatetoy_clear_screen() {
  # enable output to terminal
  zle -I
  # clear screen and move cursor to (0, 0)
  print -n '\e[2J\e[0;0H'
  # print preprompt
  prompt_patatetoy_preprompt_render precmd
}

prompt_patatetoy_set_title() {
  # emacs terminal does not support settings the title
  (( ${+EMACS} )) && return

  # tell the terminal we are setting the title
  print -n '\e]0;'
  # show hostname if connected through ssh
  [[ -n $SSH_CONNECTION ]] && print -Pn '(%m) '
  case $1 in
    expand-prompt)
      print -Pn $2;;
    ignore-escape)
      print -rn $2;;
  esac
  # end set title
  print -n '\a'
}

prompt_patatetoy_preexec() {
  # attempt to detect and prevent prompt_patatetoy_async_git_fetch from interfering with user initiated git or hub fetch
  [[ $2 =~ (git|hub)\ .*(pull|fetch) ]] && async_flush_jobs 'prompt_patatetoy'

  prompt_patatetoy_cmd_timestamp=$EPOCHSECONDS

  # shows the current dir and executed command in the title while a process is active
  prompt_patatetoy_set_title 'ignore-escape' "$PWD:t: $2"
}

# string length ignoring ansi escapes
prompt_patatetoy_string_length_to_var() {
  local str=$1 var=$2 length
  # perform expansion on str and check length
  length=$(( ${#${(S%%)str//(\%([KF1]|)\{*\}|\%[Bbkf])}} ))

  # store string length in variable as specified by caller
  typeset -g "${var}"="${length}"
}

prompt_patatetoy_preprompt_render() {
  # store the current prompt_subst setting so that it can be restored later
  local prompt_subst_status=$options[prompt_subst]

  # make sure prompt_subst is unset to prevent parameter expansion in prompt
  setopt local_options no_prompt_subst

  # check that no command is currently running, the preprompt will otherwise be rendered in the wrong place
  [[ -n ${prompt_patatetoy_cmd_timestamp+x} && "$1" != "precmd" ]] && return

  # construct preprompt, beginning with path # username and machine if applicable
  local preprompt="$prompt_patatetoy_username%F{blue}$(patatetoy_collapse_pwd)%f"

  # git info
  patatetoy_git_branch
  preprompt+="%F{$PATATETOY_GIT_BRANCH_COLOR}${patatetoy_git_branch}%f"
  preprompt+="%F{${PATATETOY_GIT_DIRTY_SYMBOL_COLOR}}${patatetoy_git_dirty}%f"
  preprompt+="%F{$PATATETOY_GIT_STASH_COLOR}${patatetoy_git_stash}%f"
  preprompt+="%F{$PATATETOY_GIT_ARROW_COLOR}${patatetoy_git_upstream}%f"
  preprompt+="%F{$PATATETOY_VIRTUALENV_COLOR}$(patatetoy_virtualenv_info)%f"

  # execution time
  preprompt+="%F{yellow}$prompt_patatetoy_cmd_exec_time%f"

  # make sure prompt_patatetoy_last_preprompt is a global array
  typeset -g -a prompt_patatetoy_last_preprompt

  # if executing through precmd, do not perform fancy terminal editing
  if [[ "$1" == "precmd" ]]; then
    print -P "\n${preprompt}"
  else
    # only redraw if the expanded preprompt has changed
    [[ "${prompt_patatetoy_last_preprompt[2]}" != "${(S%%)preprompt}" ]] || return

    # calculate length of preprompt and store it locally in preprompt_length
    integer preprompt_length lines
    prompt_patatetoy_string_length_to_var "${preprompt}" "preprompt_length"

    # calculate number of preprompt lines for redraw purposes
    (( lines = ( preprompt_length - 1 ) / COLUMNS + 1 ))

    # calculate previous preprompt lines to figure out how the new preprompt should behave
    integer last_preprompt_length last_lines
    prompt_patatetoy_string_length_to_var "${prompt_patatetoy_last_preprompt[1]}" "last_preprompt_length"
    (( last_lines = ( last_preprompt_length - 1 ) / COLUMNS + 1 ))

    # clr_prev_preprompt erases visual artifacts from previous preprompt
    local clr_prev_preprompt
    if (( last_lines > lines )); then
      # move cursor up by last_lines, clear the line and move it down by one line
      clr_prev_preprompt="\e[${last_lines}A\e[2K\e[1B"
      while (( last_lines - lines > 1 )); do
        # clear the line and move cursor down by one
        clr_prev_preprompt+='\e[2K\e[1B'
        (( last_lines-- ))
      done

      # move cursor into correct position for preprompt update
      clr_prev_preprompt+="\e[${lines}B"
    # create more space for preprompt if new preprompt has more lines than last
    elif (( last_lines < lines )); then
      # move cursor using newlines because ansi cursor movement can't push the cursor beyond the last line
      printf $'\n'%.0s {1..$(( lines - last_lines ))}
    fi

    # disable clearing of line if last char of preprompt is last column of terminal
    local clr='\e[K'
    (( COLUMNS * lines == preprompt_length )) && clr=

    # modify previous preprompt
    print -Pn "${clr_prev_preprompt}\e[${lines}A\e[${COLUMNS}D${preprompt}${clr}\n"

    if [[ $prompt_subst_status = 'on' ]]; then
      # re-eanble prompt_subst for expansion on PS1
      setopt prompt_subst
    fi

    # redraw prompt (also resets cursor position)
    zle && zle .reset-prompt
  fi

  # store both unexpanded and expanded preprompt for comparison
  prompt_patatetoy_last_preprompt=("$preprompt" "${(S%%)preprompt}")
}

prompt_patatetoy_precmd() {
  # check exec time and store it in a variable
  prompt_patatetoy_check_cmd_exec_time

  # by making sure that prompt_patatetoy_cmd_timestamp is defined here the async functions are prevented from interfering
  # with the initial preprompt rendering
  prompt_patatetoy_cmd_timestamp=

  # check for git arrows
  patatetoy_git_upstream

  # shows the full path in the title
  prompt_patatetoy_set_title 'expand-prompt' '%~'

  # get vcs info
  patatetoy_vcs_info

  # preform async git dirty check and fetch
  prompt_patatetoy_async_tasks

  # print the preprompt
  prompt_patatetoy_preprompt_render "precmd"

  # remove the prompt_patatetoy_cmd_timestamp, indicating that precmd has completed
  unset prompt_patatetoy_cmd_timestamp
}

# fastest possible way to check if repo is dirty
patatetoy_async_git_dirty() {
  # use cd -q to avoid side effects of changing directory, e.g. chpwd hooks
  builtin cd -q "$*"
  patatetoy_git_dirty
}

patatetoy_async_git_stash() {
  # use cd -q to avoid side effects of changing directory, e.g. chpwd hooks
  builtin cd -q "$*"
  patatetoy_git_stash
}

prompt_patatetoy_async_git_fetch() {
  # use cd -q to avoid side effects of changing directory, e.g. chpwd hooks
  builtin cd -q "$*"

  # set GIT_TERMINAL_PROMPT=0 to disable auth prompting for git fetch (git 2.3+)
  export GIT_TERMINAL_PROMPT=0
  # set ssh BachMode to disable all interactive ssh password prompting
  export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-"ssh -o BatchMode=yes"}

  command git -c gc.auto=0 fetch
}

prompt_patatetoy_async_tasks() {
  # initialize async worker
  ((!${prompt_patatetoy_async_init:-0})) && {
    async_start_worker "prompt_patatetoy" -u -n
    async_register_callback "prompt_patatetoy" prompt_patatetoy_async_callback
    prompt_patatetoy_async_init=1
  }

  # store working_tree without the "x" prefix
  local working_tree="$patatetoy_vcs_working_tree"

  # check if the working tree changed (prompt_patatetoy_current_working_tree is prefixed by "x")
  if [[ ${prompt_patatetoy_current_working_tree#x} != $working_tree ]]; then
    # stop any running async jobs
    async_flush_jobs "prompt_patatetoy"

    # reset git preprompt variables, switching working tree
    unset patatetoy_git_branch
    unset patatetoy_git_dirty
    unset patatetoy_git_stash
    unset prompt_patatetoy_git_last_dirty_check_timestamp

    # set the new working tree and prefix with "x" to prevent the creation of a named path by AUTO_NAME_DIRS
    prompt_patatetoy_current_working_tree="x${working_tree}"
  fi

  # only perform tasks inside git working tree
  [[ -n $working_tree ]] || return

  # do not preform git fetch if it is disabled or working_tree == HOME
  if (( ${PATATETOY_GIT_PULL:-1} )) && [[ $working_tree != $HOME ]]; then
    # tell worker to do a git fetch
    async_job "prompt_patatetoy" prompt_patatetoy_async_git_fetch "${working_tree}"
  fi

  # if dirty checking is sufficiently fast, tell worker to check it again, or wait for timeout
  integer time_since_last_dirty_check=$(( EPOCHSECONDS - ${prompt_patatetoy_git_last_dirty_check_timestamp:-0} ))
  if (( time_since_last_dirty_check > $PATATETOY_GIT_DELAY_DIRTY_CHECK)); then
    unset prompt_patatetoy_git_last_dirty_check_timestamp
    # check check if there is anything to pull
    async_job "prompt_patatetoy" patatetoy_async_git_dirty "${working_tree}"
  fi

  # check for stash
  local time_since_last_stash_check=$(( $EPOCHSECONDS - ${prompt_patatetoy_git_last_stash_check_timestamp:-0} ))
  if (( $time_since_last_stash_check > 1800 )); then
    unset prompt_patatetoy_git_last_stash_check_timestamp
    # check if there is anything any stash
    async_job "prompt_patatetoy" patatetoy_async_git_stash "$working_tree"
  fi
}

prompt_patatetoy_async_callback() {
  local job=$1
  local output=$3
  local exec_time=$4

  case "${job}" in
    patatetoy_async_git_dirty)
      patatetoy_git_dirty=$output
      prompt_patatetoy_preprompt_render

      # When prompt_patatetoy_git_last_dirty_check_timestamp is set, the git info is displayed in a different color.
      # To distinguish between a "fresh" and a "cached" result, the preprompt is rendered before setting this
      # variable. Thus, only upon next rendering of the preprompt will the result appear in a different color.
      (( $exec_time > 2 )) && prompt_patatetoy_git_last_dirty_check_timestamp=$EPOCHSECONDS
      ;;
    patatetoy_async_git_stash)
      patatetoy_git_stash=$output
      prompt_patatetoy_preprompt_render

      (( $exec_time > 2 )) && prompt_patatetoy_git_last_stash_check_timestamp=$EPOCHSECONDS
      ;;
    prompt_patatetoy_async_git_fetch)
      patatetoy_git_upstream
      prompt_patatetoy_preprompt_render
      ;;
  esac
}

prompt_patatetoy_setup() {
  # prevent percentage showing up
  # if output doesn't end with a newline
  export PROMPT_EOL_MARK=''

  prompt_opts=(subst percent)

  zmodload zsh/datetime
  zmodload zsh/zle
  zmodload zsh/parameter
  autoload -Uz add-zsh-hook
  autoload -Uz async && async

  add-zsh-hook precmd prompt_patatetoy_precmd
  add-zsh-hook preexec prompt_patatetoy_preexec

  # if the user has not registered a custom zle widget for clear-screen,
  # override the builtin one so that the preprompt is displayed correctly when
  # ^L is issued.
  if [[ $widgets[clear-screen] == 'builtin' ]]; then
    zle -N clear-screen prompt_patatetoy_clear_screen
  fi

  # show username@host if logged in through SSH
  if [[ "$SSH_CONNECTION" != '' ]] || [[ $PATATETOY_FORCE_DISPLAY_USERNAME == 1 ]]; then
    prompt_patatetoy_username='%F{$PATATETOY_USERNAME_COLOR}%n%F{$PATATETOY_USERNAME_COLOR}@%m '
  fi

  # show red star if root
  if [[ $UID -eq 0 ]]; then
    prompt_patatetoy_username+="%F{$PATATETOY_ROOT_SYMBOL_COLOR}$PATATETOY_ROOT_SYMBOL%f "
  fi

  # Check if vim mode enable
  if [[ $PATATETOY_VIM_MODE == 1 ]] then;
    zle -N zle-line-init
    zle -N zle-keymap-select
    PROMPT='${prompt_patatetoy_vim_mode}'
  else
    PROMPT=''
  fi

  # prompt turns red if the previous command didn't exit with 0
  PROMPT+='%(?.%F{$PATATETOY_CURSOR_COLOR_OK}.%F{$PATATETOY_CURSOR_COLOR_KO})$PATATETOY_PROMPT_SYMBOL%f '
}

prompt_patatetoy_setup "$@"

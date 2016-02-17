# Patatetoy
#
# by Maxime Loliée
# https://github.com/loliee/patatetoy
#
# Initialy forked from https://github.com/sindresorhus/pure
# MIT License

# For my own and others sanity
# git:
# %b => current branch
# %a => current action (rebase/merge)
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)
# terminal codes:
# \e7   => save cursor position
# \e[2A => move cursor 2 lines up
# \e[1G => go to position 1 in terminal
# \e8   => restore cursor position
# \e[K  => clears everything after the cursor on the current line
# \e[2K => clear everything on the current line

PATATETOY_PROMPT_SYMBOL=${PATATETOY_PROMPT_SYMBOL:-❯}
PATATETOY_VIM_MODE=${PATATETOY_VIM_MODE:-0}
PATATETOY_GIT_DIRTY_SYMBOL=${PATATETOY_GIT_DIRTY_SYMBOL:-★}
PATATETOY_GIT_ARROW_COLOR=${PATATETOY_GIT_ARROW_COLOR:-blue}
PATATETOY_GIT_UP_ARROW=${PATATETOY_GIT_UP_ARROW:-⬆}
PATATETOY_GIT_DOWN_ARROW=${PATATETOY_GIT_DOWN_ARROW:-⬇}
PATATETOY_GIT_STASH_CHECK=${PATATETOY_GIT_STASH_CHECK:-1}
PATATETOY_GIT_STASH_SYMBOL=${PATATETOY_GIT_STASH_SYMBOL:-"↯"}
PATATETOY_GIT_STASH_COLOR=${PATATETOY_GIT_STASH_COLOR:-red}
PATATETOY_FORCE_DISPLAY_USERNAME=${PATATETOY_FORCE_DISPLAY_USERNAME:-0}
PATATETOY_USERNAME_COLOR=${PATATETOY_USERNAME_COLOR:-white}
PATATATETOY_ROOT_SYMBOL=${PATATATETOY_ROOT_SYMBOL:-"%F{red}✦"}
PATATETOY_CURSOR_COLOR_OK=${PATATETOY_CURSOR_COLOR_OK:-yellow}
PATATETOY_CURSOR_COLOR_KO=${PATATETOY_CURSOR_COLOR_KO:-red}
PATATETOY_GIT_DELAY_DIRTY_CHECK=${PATATETOY_GIT_DELAY_DIRTY_CHECK:-1800}
PATATETOY_GIT_UNTRACKED_DIRTY=${PATATETOY_GIT_UNTRACKED_DIRTY:-1}
PATATETOY_CMD_MAX_EXEC_TIME=${PATATETOY_CMD_MAX_EXEC_TIME:-5}
PATATETOY_GIT_PULL=${PATATETOY_GIT_PULL:-1}

#
# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
prompt_patatetoy_human_time_to_var() {
  local human=" " total_seconds=$1 var=$2
  local days=$(( total_seconds / 60 / 60 / 24 ))
  local hours=$(( total_seconds / 60 / 60 % 24 ))
  local minutes=$(( total_seconds / 60 % 60 ))
  local seconds=$(( total_seconds % 60 ))
  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"

  # store human readable time in variable as specified by caller
  typeset -g "${var}"="${human}"
}

# stores (into prompt_patatetoy_cmd_exec_time) the exec time of the last command if set threshold was exceeded
prompt_patatetoy_check_cmd_exec_time() {
  integer elapsed
  (( elapsed = EPOCHSECONDS - ${prompt_patatetoy_cmd_timestamp:-$EPOCHSECONDS} ))
  prompt_patatetoy_cmd_exec_time=
  (( elapsed > $PATATETOY_CMD_MAX_EXEC_TIME )) && {
    prompt_patatetoy_human_time_to_var $elapsed "prompt_patatetoy_cmd_exec_time"
  }
}

function zle-line-init zle-keymap-select {
  if [[ -z $PATATETOY_VIM_MODE ]] then;
    VIM_MODE=''
  else
    VIM_MODE="%F{$git_color}${${KEYMAP/vicmd/n }/(main|viins)/i }%f"
    zle reset-prompt
  fi
}

prompt_patatetoy_clear_screen() {
  # enable output to terminal
  zle -I
  # clear screen and move cursor to (0, 0)
  print -n '\e[2J\e[0;0H'
  # print preprompt
  prompt_patatetoy_preprompt_render precmd
}

prompt_patatetoy_check_git_arrows() {
  # reset git arrows
  prompt_patatetoy_git_arrows=

  # check if there is an upstream configured for this branch
  command git rev-parse --abbrev-ref @'{u}' &>/dev/null || return

  local arrow_status
  # check git left and right arrow_status
  arrow_status="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  # exit if the command failed
  (( !$? )) || return

  # left and right are tab-separated, split on tab and store as array
  arrow_status=(${(ps:\t:)arrow_status})
  local arrows left=${arrow_status[1]} right=${arrow_status[2]}

  (( ${right:-0} > 0 )) && arrows+="$PATATETOY_GIT_DOWN_ARROW"
  (( ${left:-0} > 0 )) && arrows+="$PATATETOY_GIT_UP_ARROW"

  [[ -n $arrows ]] && prompt_patatetoy_git_arrows=" ${arrows}"
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
  # check that no command is currently running, the preprompt will otherwise be rendered in the wrong place
  [[ -n ${prompt_patatetoy_cmd_timestamp+x} && "$1" != "precmd" ]] && return

  # set color for git branch/dirty status, change color if dirty checking has been delayed
  local git_color=242
  [[ -n ${prompt_patatetoy_git_last_dirty_check_timestamp+x} ]] && git_color=red

  # construct preprompt, beginning with path # username and machine if applicable
  local preprompt="$prompt_patatetoy_username%F{blue}%~%f"

  # git info
  preprompt+="%F{$git_color}${vcs_info_msg_0_}${prompt_patatetoy_git_dirty}${prompt_patatetoy_git_stash}%f"
  preprompt+="%F{$PATATETOY_GIT_ARROW_COLOR}${prompt_patatetoy_git_arrows}%f"
  # execution time
  preprompt+="%F{yellow}${prompt_patatetoy_cmd_exec_time}%f"

  # if executing through precmd, do not perform fancy terminal editing
  if [[ "$1" == "precmd" ]]; then
    print -P "\n${preprompt}"
  else
    # only redraw if preprompt has changed
    [[ "${prompt_patatetoy_last_preprompt}" != "${preprompt}" ]] || return

    # calculate length of preprompt and store it locally in preprompt_length
    integer preprompt_length lines
    prompt_patatetoy_string_length_to_var "${preprompt}" "preprompt_length"

    # calculate number of preprompt lines for redraw purposes
    (( lines = ( preprompt_length - 1 ) / COLUMNS + 1 ))

    # calculate previous preprompt lines to figure out how the new preprompt should behave
    integer last_preprompt_length last_lines
    prompt_patatetoy_string_length_to_var "${prompt_patatetoy_last_preprompt}" "last_preprompt_length"
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

    # redraw prompt (also resets cursor position)
    zle && zle .reset-prompt
  fi

  # store previous preprompt for comparison
  prompt_patatetoy_last_preprompt=$preprompt
}

prompt_patatetoy_precmd() {
  # check exec time and store it in a variable
  prompt_patatetoy_check_cmd_exec_time

  # by making sure that prompt_patatetoy_cmd_timestamp is defined here the async functions are prevented from interfering
  # with the initial preprompt rendering
  prompt_patatetoy_cmd_timestamp=

  # check for git arrows
  prompt_patatetoy_check_git_arrows

  # shows the full path in the title
  prompt_patatetoy_set_title 'expand-prompt' '%~'

  # get vcs info
  vcs_info

  # preform async git dirty check and fetch
  prompt_patatetoy_async_tasks

  # print the preprompt
  prompt_patatetoy_preprompt_render "precmd"

  # remove the prompt_patatetoy_cmd_timestamp, indicating that precmd has completed
  unset prompt_patatetoy_cmd_timestamp
}

# fastest possible way to check if repo is dirty
prompt_patatetoy_async_git_dirty() {
  local untracked_dirty=$1; shift

  # use cd -q to avoid side effects of changing directory, e.g. chpwd hooks
  builtin cd -q "$*"

  if [[ "$untracked_dirty" == "0" ]]; then
    command git diff --no-ext-diff --quiet --exit-code
  else
    test -z "$(command git status --porcelain --ignore-submodules -unormal)"
  fi

  (( $? )) && echo "$PATATETOY_GIT_DIRTY_SYMBOL"

}

prompt_patatetoy_async_git_fetch() {
  # use cd -q to avoid side effects of changing directory, e.g. chpwd hooks
  builtin cd -q "$*"

  # set GIT_TERMINAL_PROMPT=0 to disable auth prompting for git fetch (git 2.3+)
  GIT_TERMINAL_PROMPT=0 command git -c gc.auto=0 fetch
}

prompt_patatetoy_async_git_stash() {
  local stash_check=$1; shift

  # use cd -q to avoid side effects of changing directory, e.g. chpwd hooks
  builtin cd -q "$*"

  if [[ "$stash_check" == "1" && -f "$(command git rev-parse --show-toplevel)/.git/refs/stash" ]]; then
    stashed="$(git stash list 2> /dev/null | wc -l | awk '{print $1}')"
    if (( $stashed > 0 )); then
      echo "%F{$PATATETOY_GIT_STASH_COLOR} $PATATETOY_GIT_STASH_SYMBOL%f"
    fi
  fi
}

prompt_patatetoy_async_tasks() {
  # initialize async worker
  ((!${prompt_patatetoy_async_init:-0})) && {
    async_start_worker "prompt_patatetoy" -u -n
    async_register_callback "prompt_patatetoy" prompt_patatetoy_async_callback
    prompt_patatetoy_async_init=1
  }

  # store working_tree without the "x" prefix
  local working_tree="${vcs_info_msg_1_#x}"

  # check if the working tree changed (prompt_patatetoy_current_working_tree is prefixed by "x")
  if [[ ${prompt_patatetoy_current_working_tree#x} != $working_tree ]]; then
    # stop any running async jobs
    async_flush_jobs "prompt_patatetoy"

    # reset git preprompt variables, switching working tree
    unset prompt_patatetoy_git_dirty
    unset prompt_patatetoy_git_stash
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
    async_job "prompt_patatetoy" prompt_patatetoy_async_git_dirty "$PATATETOY_GIT_UNTRACKED_DIRTY" "${working_tree}"
  fi

  # check for stash
  local time_since_last_stash_check=$(( $EPOCHSECONDS - ${prompt_patatetoy_git_last_stash_check_timestamp:-0} ))
  if (( $time_since_last_stash_check > 1800 )); then
    unset prompt_patatetoy_git_last_stash_check_timestamp
    # check if there is anything any stash
    async_job "prompt_patatetoy" prompt_patatetoy_async_git_stash "$PATATETOY_GIT_STASH_CHECK" "$working_tree"
  fi
}

prompt_patatetoy_async_callback() {
  local job=$1
  local output=$3
  local exec_time=$4

  case "${job}" in
    prompt_patatetoy_async_git_dirty)
      prompt_patatetoy_git_dirty=$output
      prompt_patatetoy_preprompt_render

      # When prompt_patatetoy_git_last_dirty_check_timestamp is set, the git info is displayed in a different color.
      # To distinguish between a "fresh" and a "cached" result, the preprompt is rendered before setting this
      # variable. Thus, only upon next rendering of the preprompt will the result appear in a different color.
      (( $exec_time > 2 )) && prompt_patatetoy_git_last_dirty_check_timestamp=$EPOCHSECONDS
      ;;
    prompt_patatetoy_async_git_stash)
      prompt_patatetoy_git_stash=$output
      prompt_patatetoy_preprompt_render

      (( $exec_time > 2 )) && prompt_patatetoy_git_last_stash_check_timestamp=$EPOCHSECONDS
      ;;
    prompt_patatetoy_async_git_fetch)
      prompt_patatetoy_check_git_arrows
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
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  autoload -Uz async && async

  # Check if vim mode enable
  if [[ -z $PATATETOY_VIM_MODE ]] then;
    VIM_MODE=''
  else
    zle -N zle-line-init
    zle -N zle-keymap-select
  fi

  add-zsh-hook precmd prompt_patatetoy_precmd
  add-zsh-hook preexec prompt_patatetoy_preexec

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' use-simple true
  # only export two msg variables from vcs_info
  zstyle ':vcs_info:*' max-exports 2
  # vcs_info_msg_0_ = ' %b' (for branch)
  # vcs_info_msg_1_ = 'x%R' git top level (%R), x-prefix prevents creation of a named path (AUTO_NAME_DIRS)
  zstyle ':vcs_info:git*' formats ' %b' 'x%R'
  zstyle ':vcs_info:git*' actionformats ' %b|%a' 'x%R'

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
    prompt_patatetoy_username+="$PATATATETOY_ROOT_SYMBOL"
  fi

  # prompt turns red if the previous command didn't exit with 0
  PROMPT='${VIM_MODE}%(?.%F{$PATATETOY_CURSOR_COLOR_OK}.%F{$PATATETOY_CURSOR_COLOR_KO})$PATATETOY_PROMPT_SYMBOL%f '
}

prompt_patatetoy_setup "$@"

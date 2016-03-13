# Bring a light and modified version of git-prompt.sh from Shawn O. Pearce <spearce@spearce.org>
# https://github.com/git/git/blob/8976500cbbb13270398d3b3e07a17b8cc7bff43f/contrib/completion/git-prompt.sh
# ~/Dev master✗ⵢ ⬇⬆

export VIRTUAL_ENV_DISABLE_PROMPT=${VIRTUAL_ENV_DISABLE_PROMPT:-1}
export PATATETOY_FORCE_DISPLAY_USERNAME=${PATATETOY_FORCE_DISPLAY_USERNAME:-0}
export PATATETOY_CMD_MAX_EXEC_TIME=${PATATETOY_CMD_MAX_EXEC_TIME:-5}
export PATATETOY_ROOT_SYMBOL=${PATATATETOY_ROOT_SYMBOL:-"✦"}
export PATATETOY_PROMPT_SYMBOL=${PATATETOY_PROMPT_SYMBOL:-❯}
export PATATETOY_GIT_DIRTY_SYMBOL=${PATATETOY_GIT_DIRTY_SYMBOL:-'✗'}
export PATATETOY_GIT_UP_ARROW=${PATATETOY_GIT_UP_ARROW:-⬆}
export PATATETOY_GIT_DOWN_ARROW=${PATATETOY_GIT_DOWN_ARROW:-⬇}
export PATATETOY_GIT_STASH_CHECK=${PATATETOY_GIT_STASH_CHECK:-1}
export PATATETOY_GIT_STASH_SYMBOL=${PATATETOY_GIT_STASH_SYMBOL:-"ⵢ"}
export PATATETOY_GIT_UNTRACKED_DIRTY=${PATATETOY_GIT_UNTRACKED_DIRTY:-1}

patatetoy_vcs_info() {
  export patatetoy_vcs_bare_repo=
  export patatetoy_vcs_short_sha=
  export patatetoy_vcs_inside_git_dir=
  export patatetoy_vcs_inside_worktree=
  export patatetoy_vcs_working_tree=
  local repo_info
  local patatetoy_vcs_repo_info rev_parse_exit_code
  repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
    --is-bare-repository --is-inside-work-tree \
    --short HEAD 2>/dev/null)"
  rev_parse_exit_code="$?"
  if [ -z "$repo_info" ]; then
    return
  fi
  patatetoy_vcs_short_sha=""
  if [ "$rev_parse_exit_code" = "0" ]; then
    patatetoy_vcs_short_sha="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
  fi
  patatetoy_vcs_inside_worktree="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  patatetoy_vcs_bare_repo="${repo_info##*$'\n'}"
  patatetoy_vcs_repo_info="${repo_info%$'\n'*}"
  patatetoy_vcs_inside_git_dir="${patatetoy_vcs_repo_info##*$'\n'}"
  patatetoy_vcs_g="${patatetoy_vcs_repo_info%$'\n'*}"
  if [ "true" = "$patatetoy_vcs_inside_worktree" ]; then
    patatetoy_vcs_working_tree=$(pwd)
  fi
}

patatetoy_git_upstream() {
  export patatetoy_git_upstream=
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
    p=" $PATATETOY_GIT_UP_ARROW" ;;
  *"0") # behind upstream
    p=" $PATATETOY_GIT_DOWN_ARROW" ;;
  *)      # diverged from upstream
    p=" $PATATETOY_GIT_DOWN_ARROW$PATATETOY_GIT_UP_ARROW" ;;
  esac
 patatetoy_git_upstream="$p"
}

patatetoy_git_branch() {
  export patatetoy_git_branch=
  local rebase=""
  local branch=""
  local step=""
  local total=""
  if [[ -z $patatetoy_vcs_inside_worktree ]]; then
    return
  fi
  if [ -d "$patatetoy_vcs_g/rebase-merge" ]; then
    read -r branch 2>/dev/null <"$patatetoy_vcs_g/rebase-merge/head-name"
    if [ -f "$patatetoy_vcs_g/rebase-merge/msgnum" ]; then
      read -r step 2>/dev/null <"$patatetoy_vcs_g/rebase-merge/msgnum"
    fi
    if [ -f "$patatetoy_vcs_g/rebase-merge/end" ]; then
      read -r total 2>/dev/null <"$patatetoy_vcs_g/rebase-merge/end"
    fi
    if [ -f "$patatetoy_vcs_g/rebase-merge/interactive" ]; then
      rebase="|rebase-i"
    else
      rebase="|rebase-m"
    fi
  else
    if [ -d "$patatetoy_vcs_g/rebase-apply" ]; then
      if [ -f "$patatetoy_vcs_g/rebase-apply/next" ]; then
        read -r step 2>/dev/null <"$patatetoy_vcs_g/rebase-apply/next"
      fi
      if [ -f "$patatetoy_vcs_g/rebase-apply/last" ]; then
        read -r total 2>/dev/null <"$patatetoy_vcs_g/rebase-apply/last"
      fi
      if [ -f "$patatetoy_vcs_g/rebase-apply/rebasing" ]; then
        read -r branch 2>/dev/null <"$patatetoy_vcs_g/rebase-apply/head-name"
        rebase="|rebase"
      elif [ -f "$patatetoy_vcs_g/rebase-apply/applying" ]; then
        rebase="|am"
      else
        rebase="|am/rebase"
      fi
    elif [ -f "$patatetoy_vcs_g/MERGE_HEAD" ]; then
      rebase="|merging"
    elif [ -f "$patatetoy_vcs_g/CHERRY_PICK_HEAD" ]; then
      rebase="|cherry-picking"
    elif [ -f "$patatetoy_vcs_g/REVERT_HEAD" ]; then
      rebase="|reverting"
    elif [ -f "$patatetoy_vcs_g/BISECT_LOG" ]; then
      rebase="|bisecting"
    fi
    if [ -n "$branch" ]; then
      :
    elif [ -h "$patatetoy_vcs_g/HEAD" ]; then
      # symlink symbolic ref
      branch="$(git symbolic-ref HEAD 2>/dev/null)"
    else
      local head=""
      if ! read -r head 2>/dev/null <"$patatetoy_vcs_g/HEAD"; then
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

        branch="$patatetoy_vcs_short_sha..."
        branch="$branch"
      fi
    fi
  fi
  if [ -n "$step" ] && [ -n "$total" ]; then
    rebase="$rebase $step/$total "
  fi
  branch=${branch##refs/heads/}
  patatetoy_git_branch=" $branch$rebase"
}

patatetoy_git_stash() {
  if [[ "$PATATETOY_GIT_STASH_CHECK" == "1" ]]; then
    [[ $(git stash list 2> /dev/null | tail -n1) != "" ]] && echo  "$PATATETOY_GIT_STASH_SYMBOL"
  fi
}

# fastest possible way to check if repo is dirty
patatetoy_git_dirty() {
  if [[ "$PATATETOY_GIT_DIRTY_CHECK" == "0" ]]; then
    return
  fi

  if [[ "$PATATETOY_GIT_UNTRACKED_DIRTY" == "0" ]]; then
    command git diff --no-ext-diff --quiet --exit-code
  else
    test -z "$(command git status --porcelain --ignore-submodules -unormal)"
  fi

  (( $? )) && echo "$PATATETOY_GIT_DIRTY_SYMBOL"
}

function patatetoy_virtualenv_info {
  [ "$VIRTUAL_ENV" ] && echo " ($(basename "$VIRTUAL_ENV"))"
}

function patatetoy_collapse_pwd {
  p=$(pwd | sed -e "s,^$HOME,~,")
  if [[ ${#p} -gt 90 ]]; then
    echo "…${p:(-90)}"
  else
    echo "$p"
  fi
}

patatetoy_cmd_exec_time() {
  local elapsed=$1
  prompt_patatetoy_cmd_exec_time=
  if [[ $elapsed -gt $PATATETOY_CMD_MAX_EXEC_TIME ]]; then
    local human=" " total_seconds=$1
    local days=$(( total_seconds / 60 / 60 / 24 ))
    local hours=$(( total_seconds / 60 / 60 % 24 ))
    local minutes=$(( total_seconds / 60 % 60 ))
    local seconds=$(( total_seconds % 60 ))
    (( days > 0 )) && human+="${days}d "
    (( hours > 0 )) && human+="${hours}h "
    (( minutes > 0 )) && human+="${minutes}m "
    human+="${seconds}s"
    export prompt_patatetoy_cmd_exec_time="${human}"
  fi
}

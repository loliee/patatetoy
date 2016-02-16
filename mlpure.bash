# mlPure
# by Maxime Loliée
# https://github.com/loliee/mlpure
# MIT License

# Git original script from Shawn O. Pearce <spearce@spearce.org>
# https://github.com/git/git/blob/8976500cbbb13270398d3b3e07a17b8cc7bff43f/contrib/completion/git-prompt.sh

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1

__git_printf_supports_v=
printf -v __git_printf_supports_v -- '%s' yes >/dev/null 2>&1

__git_ps1_colorize_gitstring() {
	local c_red='\[\e[31m\]'
	local c_green='\[\e[32m\]'
	local c_lblue='\[\e[1;34m\]'
	local c_clear='\[\e[0m\]'
	local bad_color=$c_red
	local ok_color=$c_green
	local flags_color="$c_lblue"
	local branch_color=""
	if [ "$detached" = no ]; then
		branch_color="$ok_color"
	else
		branch_color="$bad_color"
	fi
	c="$branch_color$c"
	z="$c_clear$z"
	if [ "$w" = "▲" ]; then
		w="$bad_color$w"
	fi
	if [ -n "$i" ]; then
		i="$ok_color$i"
	fi
	if [ -n "$s" ]; then
		s="$flags_color$s"
	fi
	if [ -n "$u" ]; then
		u="$bad_color$u"
	fi
	r="$c_clear$r"
}

__mingit_ps1() {
	local pcmode=no
	local detached=no
	local ps1pc_start='\u@\h:\w '
	local ps1pc_end='\$ '
	local printf_format='%s'
	case "$#" in
		2|3)	pcmode=yes
			ps1pc_start="$1"
			ps1pc_end="$2"
			printf_format="${3:-$printf_format}"
		;;
		0|1)	printf_format="${1:-$printf_format}"
		;;
		*)	return
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
	local r=""
	local b=""
	local step=""
	local total=""
	if [ -d "$g/rebase-merge" ]; then
		read b 2>/dev/null <"$g/rebase-merge/head-name"
		read step 2>/dev/null <"$g/rebase-merge/msgnum"
		read total 2>/dev/null <"$g/rebase-merge/end"
		if [ -f "$g/rebase-merge/interactive" ]; then
			r="|REBASE-i"
		else
			r="|REBASE-m"
		fi
	else
		if [ -d "$g/rebase-apply" ]; then
			read step 2>/dev/null <"$g/rebase-apply/next"
			read total 2>/dev/null <"$g/rebase-apply/last"
			if [ -f "$g/rebase-apply/rebasing" ]; then
				read b 2>/dev/null <"$g/rebase-apply/head-name"
				r="|REBASE"
			elif [ -f "$g/rebase-apply/applying" ]; then
				r="|AM"
			else
				r="|AM/REBASE"
			fi
		elif [ -f "$g/MERGE_HEAD" ]; then
			r="|MERGING"
		elif [ -f "$g/CHERRY_PICK_HEAD" ]; then
			r="|CHERRY-PICKING"
		elif [ -f "$g/REVERT_HEAD" ]; then
			r="|REVERTING"
		elif [ -f "$g/BISECT_LOG" ]; then
			r="|BISECTING"
		fi
		if [ -n "$b" ]; then
			:
		elif [ -h "$g/HEAD" ]; then
			# symlink symbolic ref
			b="$(git symbolic-ref HEAD 2>/dev/null)"
		else
			local head=""
			if ! read head 2>/dev/null <"$g/HEAD"; then
				if [ $pcmode = yes ]; then
					PS1="$ps1pc_start$ps1pc_end"
				fi
				return
			fi
			# is it a symbolic ref?
			b="${head#ref: }"
			if [ "$head" = "$b" ]; then
				detached=yes
				b="$(
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

				b="$short_sha..."
				b="$b"
			fi
		fi
	fi
	if [ -n "$step" ] && [ -n "$total" ]; then
		r="$r $step/$total"
	fi
	local w=""
	local i=""
	local s=""
	local u=""
	local c=""
	local p=""
	if [ "true" = "$inside_gitdir" ]; then
		if [ "true" = "$bare_repo" ]; then
			c="BARE:"
		else
			b="GIT_DIR!"
		fi
	elif [ "true" = "$inside_worktree" ]; then
		if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] &&
			[ "$(git config --bool bash.showDirtyState)" != "false" ]
		then
			git diff --no-ext-diff --quiet --exit-code || i="★"
			if [ -n "$short_sha" ]; then
				git diff-index --cached --quiet HEAD -- || i="★"
			else
				i="★"
			fi
		fi
		if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] &&
			[ -r "$g/refs/stash" ]; then
			s="▲"
		fi

		if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] &&
			[ "$(git config --bool bash.showUntrackedFiles)" != "false" ] &&
			git ls-files --others --exclude-standard --error-unmatch -- "★" >/dev/null 2>/dev/null
		then
			u="%${ZSH_VERSION+%}"
		fi
	fi
	local z="${GIT_PS1_STATESEPARATOR-""}"
	if [ $pcmode = yes ] && [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
		__git_ps1_colorize_gitstring
	fi
	b=${b##refs/heads/}
	local f="$i$s$u"
	local gitstring="$c$b${f:+$z$f}$r$p"
	if [ $pcmode = yes ]; then
		if [ "${__git_printf_supports_v-}" != yes ]; then
			gitstring=$(printf -- "$printf_format" "$gitstring")
		else
			printf -v gitstring -- "$printf_format" "$gitstring"
		fi
		PS1="$ps1pc_start$gitstring$ps1pc_end"
	else
		printf -- "$printf_format" "$gitstring"
	fi
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
    if [[ $exec_cmd_time -le 5 ]]; then
      prompt_time=""
      return
    fi
    if [[ $exec_cmd_time -le 59 ]]; then
      prompt_time=$(date -d@$exec_cmd_time -u +%ss)
      return
    fi
    if [[ $exec_cmd_time -le 3599 ]]; then
      prompt_time=$(date -d@$exec_cmd_time -u "+%-Mm %-Ss")
      return
    fi
    prompt_time=$(date -d@$exec_cmd_time -u "+%-Hh %-Mm %-Ss")
}

function __prompt_command() {
    local exit_code=$?
    local current_dir
    local c='\[\e[0m\]'
    local red='\[\e[0;31m\]'
    local yellow='\[\e[1;33m\]'
    local blue='\[\e[1;34m\]'
    #local green='\[\e[0;32m\]'

    # check previous command result
    if [[ $exit_code -ne 0 ]]; then
        prompt_symbol="${red}\n❯ ${c}"
    else
        prompt_symbol="${yellow}\n❯ ${c}"
    fi
    # Manage command time execution.
    timer_stop
    format_exec_cmd_time

    # Format current directory
    current_dir=$(p=${PWD/#"$HOME"/~};((${#p}>30))&& echo "${p::10}…${p:(-19)}"||echo "\w")

    # Init prompt sequence
    PS1="${red}\u@\h${c} ${blue}$current_dir${c} $(__mingit_ps1 "$@") ${yellow}$prompt_time${c}$prompt_symbol"

    # show red star if root
    if [[ $UID -eq 0 ]]; then
      PS1+="${red}\u2726${c}"
    fi

    export PS1
}

# Set timer
trap 'timer_start' DEBUG
export PROMPT_COMMAND

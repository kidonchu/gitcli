# shellcheck source=./utils/config.bash
source "$__root/src/utils/config.bash"
# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"
# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"
# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"
# shellcheck source=./utils/branch.bash
source "$__root/src/utils/branch.bash"
# shellcheck source=./utils/interaction.bash
source "$__root/src/utils/interaction.bash"

function switchstory() {
	
	while [ $# -gt 0 ]
	do
		case "$1" in
			-p | --pattern)
				pattern="${2:-}"
				shift
				;;
			-r | --recent)
				showRecent=true
				shift
				;;
			*) # unknown flag
				print_usage >&2
				exit 1
				;;
		esac
		shift
	done

	if [ ${showRecent:-false} = false ]; then
		switch_with_pattern "$pattern"
		return $?
	fi

	switch_with_recent "$@"
	return $?
}

function switch_with_pattern() {
	if [[ -z "${1:-}" ]]; then
		_error "please specify pattern"
		return 1
	fi
	pattern="${1}"

	local branches=()
	_process "searching for branches with pattern '$pattern'"
	if ! read -r -a branches <<< "$(get_branches_with_pattern "$pattern")"; then
		_error "unable to get branches matching pattern '$pattern'"
		return 1
	fi
	
	if [[ "${#branches[@]}" -eq 0 ]]; then
		_notice "no branch found that matches the pattern '$pattern'"
		return 0
	fi

	if [[ "${#branches[@]}" -eq 1 ]]; then
		switch_branch "${branches[0]}" || return 1
		return 0
	fi

	choice=$(choose_one "${branches[@]}")

	switch_branch "$choice" || return 1
}


function switch_with_recent() {

	if ! read -r -a branches <<< "$(get_recent_branch_list)"; then
		_error "no branch found in recent branch list"
		return 1
	fi
	
	if [[ "${#branches[@]}" -eq 0 ]]; then
		_notice "no branch found in recent branch list"
		return 0
	fi

	if [[ "${#branches[@]}" -eq 1 ]]; then
		switch_branch "${branches[0]}" || return 1
		return 0
	fi

	choice=$(choose_one "${branches[@]}")

	switch_branch "$choice" || return 1
}

function switch_branch() {
	if [[ -z "${1:-}" ]]; then
		_error "no branch specified to switch to"
		return 1
	fi
	 local targetBranch=${1}

	# save stash for current branch
	_process "switch_branch: saving stash"
	if ! save_stash; then
		_error "could not save stash for current branch"
		return 1
	fi

	_process "switch_branch: getting current branch"
	if ! currentBranch="$(get_current_branch 2>&1)"; then
		_error "could not get current branch ($currentBranch)"
		return 1
	fi

	_process "switch_branch: adding branch '$currentBranch' to recent branch list"
	if ! add_recent_branch "$currentBranch"; then
		_error "could not add current branch to recent branch list before switching to another branch"
		return 1
	fi

	# checkout branch
	_process "switch_branch: checking out target branch '$targetBranch'"
	if ! git checkout "$targetBranch"; then
		_error "could not checkout the branch '$targetBranch'"
		return 1
	fi

	_process "switch_branch: dropping target branch '$targetBranch' from recent branch list"
	if ! drop_recent_branch "$targetBranch" 1>/dev/null; then
		_error "could not drop branch '$targetBranch' from recent branch list after switching to the branch"
		return 1
	fi

	# save stash for current branch
	_process "switch_branch: popping out saved stash"
	if ! pop_stash; then
		_error "could not pop saved stash for current branch"
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story switch [-r|--recent] [-p|--pattern 'regex_pattern']"
}

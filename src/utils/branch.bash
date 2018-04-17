# shellcheck source=./message.bash
source "$__root/src/utils/message.bash"

# gets current git branch
function get_current_branch() {

	if ! branch="$(git rev-parse --abbrev-ref HEAD)"; then
		echo "error: unable to find currench branch" >&2
		return 1
	fi

	if [[ -z "$branch" ]]; then
		echo "error: currench branch doesn't exist" >&2
		return 1
	fi

	echo "$branch"
}

function get_branches_with_pattern() {
	if [[ -z "${1:-}" ]]; then
		_error "please specify pattern"
		return 1
	fi
	pattern="${1}"

	mapfile -t branches < <(git branch | grep -v '*')

	# trim out spaces
	for i in "${!branches[@]}"; do
		branches[i]=$(echo "${branches[$i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	done

	choices=()
	for branch in "${branches[@]}"; do
		if [[ "$branch" =~ $pattern ]]; then
			choices+=("$branch")
		fi
	done

	echo "${choices[@]}"
}

function add_recent_branch() {
	if branch="${1:-}" && [ -z "$branch" ]; then
		_error "please specify branch to add to recent list"
		return 1
	fi

	if ! read -r -a branches <<< "$(git config story.recent)"; then
		branches=""
	fi

	[ ! -z "$branches" ] && if ! drop_recent_branch "$branch" 1>/dev/null; then
		_error "could not remove duplicates in recent branch list for branch '$branch'"
		return 1
	fi

	[ ! -z "$branches" ] \
		&& branches=("$branch" "${branches[*]}") \
		|| branches=("$branch")

	if ! git config story.recent "${branches[*]}"; then
		_error "could not add '$branch' to recent branch list"
		return 1
	fi
}

function drop_recent_branch() {
	if branchToPop="${1:-}" && [ -z "$branchToPop" ]; then
		_error "branch to pop from recent branch list is not specified"
		return 1
	fi

	if ! read -r -a branches <<< "$(git config story.recent)" || [ "${#branches[*]}" -eq 0 ]; then
		_error "no branch exists in recent branch list"
		return 1
	fi

	hadBranch=false
	for i in "${!branches[@]}"
	do
		local branchToCompare="${branches[i]}"
		if [ "$branchToCompare" = "$branchToPop" ]; then
			hadBranch=true
			unset 'branches[i]'
		fi
	done

	if [ $hadBranch = false ]; then
		_notice "branch '$branchToPop' does not exist in recent branch list"
		return 0
	fi

	if ! git config story.recent "${branches[*]}"; then
		_error "could not update recent branch list after pop"
		return 1
	fi
}

function get_recent_branch_list() {
	if ! read -r -a branches <<< "$(git config story.recent)"; then
		branches=()
	fi
	echo "${branches[*]}"
}

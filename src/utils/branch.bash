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

	branches=($(git branch | grep -v '*'))
	choices=()
	for branch in "${branches[@]}"; do
		if [[ "$branch" =~ $pattern ]]; then
			choices+=("$branch")
		fi
	done

	echo "${choices[@]}"
}

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

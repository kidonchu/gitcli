function get_remote_from_branch() {
	if [[ -z "${1:-}" ]]; then
		echo "error: branch to get remote from must be provided" >&2
		return 1
	fi
	branch="${1}"

	if [[ ! "$branch" =~ ^([[:alnum:]]+)/.* ]]; then
		echo "error: format of branch doesn't match with <remote_name>/<branch_name>: '$branch'" >&2
		return 1
	fi

	remote=${BASH_REMATCH[1]}
	echo "$remote"
}

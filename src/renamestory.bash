# shellcheck source=./utils/branch.bash
source "$__root/src/utils/branch.bash"
# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"
# shellcheck source=./deletestory.bash
source "$__root/src/deletestory.bash"

function renamestory() {

	while [ $# -gt 0 ]
	do
		case "$1" in
			-b | --branch)
				newBranch="$2"
				shift
				;;
			*) # unknown flag
				print_usage >&2
				exit 1
				;;
		esac
		shift
	done

	if [[ -z "${newBranch:-}" ]]; then
		_error "new branch name was not provided"
		return 1
	fi

	rename_branch "$newBranch"
}

function rename_branch() {

	newBranch="${1}"
	if [[ -z "$newBranch" ]]; then
		_error "rename_branch: new branch name was not provided"
		return 1
	fi

	_process "rename_branch: getting current branch"
	if ! oldBranch="$(get_current_branch)" || [[ -z "$oldBranch" ]]; then
		_error "could not get current branch ($oldBranch)"
		return 1
	fi

	_process "rename_branch: creating a new branch '$newBranch'"
	if ! git branch "$newBranch"; then
		_error "rename_branch: could not create a branch '$newBranch'"
		return 1
	fi

	_process "rename_branch: checking out just created branch"
	if ! git checkout "$newBranch"; then
		_error "rename_branch: could not checkout new branch '$newBranch'"
		return 1
	fi

	_process "rename_branch: finding remote of old branch"
	if ! remote=$(get_tracking_remote_from_branch "$oldBranch") || [[ -z "$remote" ]]; then
		_notice "rename_branch: could not find remote from old branch '$oldBranch'"
	fi

	if [[ ! -z "$remote" ]]; then
		_process "rename_branch: pushing new branch to remote"
		if ! git push -u "$remote" "$newBranch"; then
			_error "rename_branch: could not push new branch '$newBranch' to remote '$remote'"
			return 1
		fi
	fi

	_process "rename_branch: deleting old branch"
	if ! delete_branch "$oldBranch"; then
		_error "rename_branch: could not delete old branch '$oldBranch'"
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story rename [-b|--branch <new_branch>]"
}

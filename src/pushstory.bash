# shellcheck source=./utils/branch.bash
source "$__root/src/utils/branch.bash"

function pushstory() {
	
	while [ $# -gt 0 ]
	do
		case "$1" in
			-r | --remote)
				remoteTarget="$2"
				shift
				;;
			*) # unknown flag
				print_usage >&2
				exit 1
				;;
		esac
		shift
	done

	# check command line arg first for remote target.
	# If not specified, try gitconfig
	remoteTarget="${remoteTarget:-}"
	if [[ -z "$remoteTarget" ]]; then
		if ! remoteTarget=$(git config story.remotetarget) \
			|| [ -z "$remoteTarget" ]; then
			# default to origin if none specified
			remoteTarget="origin"
		fi
	fi

	_process "getting current branch"
	if ! currentBranch="$(get_current_branch)"; then
		_error "could not get current branch ($branch)"
		return 1
	fi

	_process "pushing branch to remote '$remoteTarget'"
	if ! git push -u "$remoteTarget" "$currentBranch"; then
		_error "could not push '$currentBranch' to the remote '$remoteTarget'"
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story push [-r|--remote]"
}

# shellcheck source=./utils/config.bash
source "$__root/src/utils/config.bash"
# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"
# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"
# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"

function newstory() {
	
	while [ $# -gt 0 ]
	do
		case "$1" in
			-s | --source)
				src="$2"
				shift
				;;
			-b | --branch)
				newBranch="$2"
				shift
				;;
			-r | --remote)
				remoteTarget="$2"
				shift
				;;
			--no-stash)
				noStash=true
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

	# find source branch using $src
	src=${src:-default}
	if ! srcBranch="$(get_config "story.source.$src" 2>/dev/null)"; then
		srcBranch="$src"
	fi

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

	_process "new branch: $newBranch"
	_process "source branch: $srcBranch"
	_process "remote target: $remoteTarget"
	_process "no stash: $noStash"

	# save stash for current branch
	[ ${noStash:-false} = false ] && if ! save_stash; then
		_error "could not save stash for current branch"
		return 1
	fi

	# get remote name from source branch
	if ! remote="$(get_remote_from_branch "$srcBranch" 2>&1)"; then
		_error "could not get remote from source branch '$srcBranch' ($remote)"
		return 1
	fi

	# fetch most recent remote source
	if ! git fetch "$remote"; then
		_error "could not fetch from remote '$remote'"
		return 1
	fi

	# create new branch
	if ! git branch --no-track "$newBranch" "refs/remotes/$srcBranch"; then
		_error "could not create new branch"
		return 1
	fi

	# checkout new branch
	if ! git checkout "$newBranch"; then
		_error "could not checkout new branch"
		return 1
	fi

	# push new branch to remote
	if ! git push -u "$remoteTarget" "$newBranch"; then
		_error "could not push '$newBranch' to the remote '$remoteTarget'"
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story new [-s|--source <source>] [-b|--branch <new_branch>] [-r|--remote <remote_target>] [--no-stash]"
}

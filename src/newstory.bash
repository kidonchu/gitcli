# shellcheck source=./utils/config.bash
source "$__root/src/utils/config.bash"
# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"
# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"

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
		echo "error: new branch name was not provided" >&2
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

	echo "new branch: $newBranch"
	echo "source branch: $srcBranch"
	echo "remote target: $remoteTarget"

	# save stash for current branch
	if ! save_stash; then
		echo "error: could not save stash for current branch" >&2
		return 1
	fi

	# get remote name from source branch
	if ! remote="$(get_remote_from_branch "$srcBranch" 2>&1)"; then
		echo "error: could not get remote from source branch '$srcBranch' ($remote)" >&2
		return 1
	fi

	# fetch most recent remote source
	if ! git fetch "$remote"; then
		echo "error: could not fetch from remote '$remote'" >&2
		return 1
	fi

	# create new branch
	if ! git branch --no-track "$newBranch" "refs/remotes/$srcBranch"; then
		echo "error: could not create new branch" >&2
		return 1
	fi

	# checkout new branch
	if ! git checkout "$newBranch"; then
		echo "error: could not checkout new branch" >&2
		return 1
	fi

	# push new branch to remote
	if ! git push -u "$remoteTarget" "$newBranch"; then
		echo "error: could not push '$newBranch' to the remote '$remoteTarget'" >&2
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story new [-s|--source <source>] [-b|--branch <new_branch>] [-r|--remote <remote_target>] [--no-stash]"
}

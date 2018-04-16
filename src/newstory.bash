# shellcheck source=./utils/config.bash
source "$__root/src/utils/config.bash"
# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"

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

	# get remote name from source branch
	if ! remote=$(get_remote_from_branch "$srcBranch" 2>&1); then
		echo "error: could not get remote from source branch '$srcBranch' ($remote)" >&2
		return 1
	fi

	# fetch most recent remote source
	if ! output=$(git fetch "$remote" 2>&1); then
		echo "error: could not fetch from remote '$remote' ($output)" >&2
		return 1
	fi

	# create new branch
	if ! output=$(git branch "$newBranch" "$srcBranch" 2>&1); then
		echo "error: could not create new branch ($output)" >&2
		return 1
	fi

	# checkout new branch
	if ! output=$(git checkout "$newBranch" 2>&1); then
		echo "error: could not checkout new branch ($output)" >&2
		return 1
	fi

	# push new branch to remote
	if ! output=$(git push -u "$remote" "$newBranch" 2>&1); then
		echo "error: could not push '$newBranch' to the remote '$remote' ($output)" >&2
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story new [-s|--source <source>] [-b|--branch <new_branch>] [-r|--remote <remote_target>] [--no-stash]"
}

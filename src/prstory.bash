# shellcheck source=./utils/config.bash
source "$__root/src/utils/config.bash"
# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"
# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"
# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"

function prstory() {
	
	while [ $# -gt 0 ]
	do
		case "$1" in
			-s | --source)
				src="$2"
				shift
				;;
			*) # unknown flag
				print_usage >&2
				exit 1
				;;
		esac
		shift
	done

	# find source branch using $src
	src=${src:-default}
	if ! srcBranch="$(get_config "story.source.$src" 2>/dev/null)"; then
		srcBranch="$src"
	fi

	if ! url=$(get_pr_url "$srcBranch"); then
		_error "could not get PR URL"
		exit 1
	fi

	open "$url"
}

function get_pr_url() {

	if ! base=${1:-} || [ -z "$base" ]; then
		_error "base branch is not provided"
		return 1
	fi

	if [[ ! "$base" =~ ([^/]+)/(.*) ]]; then
		_error "base branch '$base' does not have correct format"
		return 1
	fi

	baseRemote="${BASH_REMATCH[1]}"
	baseBranch="${BASH_REMATCH[2]}"
	baseRemoteURL="$(git remote get-url "$baseRemote" | sed -e 's/.*://' -e 's/\.git//')"
	baseOwner="$(echo "$baseRemoteURL" | cut -d'/' -f 1)"
	baseRepo="$(echo "$baseRemoteURL" | cut -d'/' -f 2)"

	if [ -z "$baseRemote" ] || [ -z "$baseBranch" ] || [ -z "$baseRemoteURL" ] || [ -z "$baseOwner" ] || [ -z "$baseRepo" ]; then
		_error "something is wrong with base settings. remote: $baseRemote, branch: $baseBranch, remote url: $baseRemoteURL, owner: $baseOwner, repo: $baseRepo"
		return 1
	fi

	headBranch="$(get_current_branch)"
	headRemote="$(get_tracking_remote_from_branch "$headBranch")"
	headRemoteURL="$(git remote get-url "$headRemote" | sed -e 's/.*://' -e 's/\.git//')"
	headOwner="$(echo "$headRemoteURL" | cut -d'/' -f 1)"
	headRepo="$(echo "$headRemoteURL" | cut -d'/' -f 2)"

	if [ -z "$headRemote" ] || [ -z "$headBranch" ] || [ -z "$headRemoteURL" ] || [ -z "$headOwner" ] || [ -z "$headRepo" ]; then
		_error "something is wrong with head settings. remote: $headRemote, branch: $headBranch, remote url: $headRemoteURL, owner: $headOwner, repo: $headRepo"
		return 1
	fi

	url=$(printf "https://github.com/%s/%s/compare/%s...%s:%s?expand=1" \
		"${baseOwner}" "${baseRepo}" "${baseBranch}" "${headOwner}" "${headBranch}")

	echo "$url"
}

function print_usage() {
	echo "usage: gitcli s|story pr|pullrequest [-s|--source <source>]"
}

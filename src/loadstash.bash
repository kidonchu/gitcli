# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"

function loadstash() {

	while [ $# -gt 0 ]
	do
		case "$1" in
			*) # unknown flag
				print_usage >&2
				exit 1
				;;
		esac
		shift
	done

	_process "loadstash: popping stash"
	if ! pop_stash; then
		_error "could not load stash for current branch"
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story [ps | popstash]"
}

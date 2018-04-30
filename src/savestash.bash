# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"

function savestash() {

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

	_process "savestash: saving stash"
	if ! save_stash; then
		_error "could not save stash for current branch"
		return 1
	fi
}

function print_usage() {
	echo "usage: gitcli story savestash"
}

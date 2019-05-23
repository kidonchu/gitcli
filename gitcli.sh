#!/usr/bin/env bash

# exit if command fails
set -e
# exit when trying to use undeclared variable
set -o nounset
# fail with piped command too
set -o pipefail

# set -x

if [ ! -z "${DEBUG_GITCLI-}" ]; then
	# trace what gets executed
	set -o xtrace
fi

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .zsh)"
__root="$__dir"
__srcdir="${__dir}/src"

# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"

# command stored in $1, subcommand stored in $2
cmd="${1:-}"
subcmd="${2:-}"

if [[ -z "${cmd}" || -z "${subcmd}" ]]; then
	echo "usage: git|gitcli story COMMANDS"
	echo
	echo "COMMANDS"
	echo -e "  n | new"
	echo -e "  s | switch"
	echo -e "  d | delete"
	echo -e "  pr | pullrequest"
	echo -e "  ss | savestash"
	echo -e "  ps | push"
	echo -e "  rn | rename"
	echo -e "  rb | rebase"
	echo
	echo "EXAMPLES"
	echo -e "  ${__base} story new -s|--source default -b|--branch feature/new-story --no-stash"
	echo -e "  ${__base} story switch -r|--recent"
	echo -e "  ${__base} story switch -p|--pattern 'some-pattern'"
	echo -e "  ${__base} story delete -c|--current"
	echo -e "  ${__base} story delete -p|--pattern 'some-pattern'"
	echo -e "  ${__base} story pullrequest -s|--source default"
	echo -e "  ${__base} story savestash"
	echo -e "  ${__base} story push -r|--remote upstream"
	echo -e "  ${__base} story rename -b|--breanch feature/renamed-story"
	echo -e "  ${__base} story rebase -p|--pattern 'some-pattern'"
	echo -e "  ${__base} story rebase -s|--source default"
	exit 1
fi

if [[ "${cmd}" != "s" && "${cmd}" != "story" ]]; then
	_error "Unsupported command: ${cmd}"
	echo "only 'story' command is supported at the moment"
	exit 1
fi

# get rid of cmd and subcmd from arguments
shift 2

case "${subcmd}" in
	n | new)
		source ${__srcdir}/newstory.bash
		newstory "$@" || exit 1
		;;
	s | switch)
		source ${__srcdir}/switchstory.bash
		switchstory "$@" || exit 1
		;;
	pr | pullrequest)
		source ${__srcdir}/prstory.bash
		prstory "$@" || exit 1
		;;
	d | delete)
		source ${__srcdir}/deletestory.bash
		deletestory "$@" || exit 1
		;;
	ss | savestash)
		source ${__srcdir}/savestash.bash
		savestash "$@" || exit 1
		;;
    ls | loadstash)
        source ${__srcdir}/loadstash.bash
        loadstash "$@" || exit 1
        ;;
	ps | push)
		source ${__srcdir}/pushstory.bash
		pushstory "$@" || exit 1
		;;
	rn | rename)
		source ${__srcdir}/renamestory.bash
		renamestory "$@" || exit 1
		;;
	rb | rebase)
		source ${__srcdir}/rebasestory.bash
		rebasestory "$@" || exit 1
		;;
	*)
		_error "Unsupported subcommand: ${subcmd}"
		exit 1
esac

_success

exit 0

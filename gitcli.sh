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

# source common functions
source ${__srcdir}/messages.sh
source ${__srcdir}/utils.sh

# command stored in $1, subcommand stored in $2
cmd="${1}"
subcmd="${2}"

if [[ -z "${cmd}" || -z "${subcmd}" ]]; then
	echo "usage: ${__base} <command> <subcommand> [-r] [file ...]"
	exit 1
fi

if [[ "${cmd}" != "s" && "${cmd}" != "story" ]]; then
	_gitcli_error "Unsupported command: ${cmd}"
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
	p | pull)
		source ${__srcdir}/pullstory.sh
		pullstory "$@"
		;;
	r | rebase)
		source ${__srcdir}/rebasestory.sh
		rebasestory "$@"
		;;
	d | delete)
		source ${__srcdir}/deletestory.sh
		deletestory "$@"
		;;
	o | open)
		source ${__srcdir}/openstory.sh
		openstory "$@"
		;;
	*)
		_gitcli_error "Unsupported subcommand: ${subcmd}"
		exit 1
esac

_gitcli_success

exit 0

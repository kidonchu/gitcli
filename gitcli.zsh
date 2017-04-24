#!/usr/bin/env bash

# exit if command fails
set -o errexit
# exit when trying to use undeclared variable
# set -o nounset
# fail with piped command too
# set -o pipefail

if [ ! -z "${DEBUG_GITCLI-}" ]; then
	# trace what gets executed
	set -o xtrace
fi

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .zsh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"

# source common functions
source ${__dir}/messages.zsh
source ${__dir}/utils.zsh

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
		source ${__dir}/newstory.zsh
		newstory "$@"
		;;
	s | switch)
		source ${__dir}/switchstory.zsh
		switchstory "$@"
		;;
	pr | pullrequest)
		source ${__dir}/prstory.zsh
		prstory "$@"
		;;
	p | pull)
		source ${__dir}/pullstory.zsh
		pullstory "$@"
		;;
esac

_gitcli_success

exit 0

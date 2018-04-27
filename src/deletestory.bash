# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"
# shellcheck source=./utils/stash.bash
source "$__root/src/utils/stash.bash"
# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"
# shellcheck source=./utils/branch.bash
source "$__root/src/utils/branch.bash"
# shellcheck source=./utils/interaction.bash
source "$__root/src/utils/interaction.bash"

function deletestory() {
	
	# idea: show branches older than X days
	
	local pattern=''

	while [ $# -gt 0 ]
	do
		case "$1" in
			-p | --pattern)
				pattern="$2"
				shift
				;;
			*) # unknown flag
				print_usage >&2
				exit 1
				;;
		esac
		shift
	done

	delete_with_pattern "$pattern"
}

function delete_with_pattern() {
	if [[ -z "${1:-}" ]]; then
		_error "please specify pattern"
		return 1
	fi
	pattern="${1}"

	local branches=()
	_process "searching for branches with pattern '$pattern'"
	if ! read -r -a branches <<< "$(get_branches_with_pattern "$pattern")"; then
		_error "unable to get branches matching pattern '$pattern'"
		return 1
	fi
	
	if [[ "${#branches[@]}" -eq 0 ]]; then
		_notice "no branch found that matches the pattern '$pattern'"
		return 0
	fi

	if ! read -r -a selected <<< "$(choose_multiple "${branches[*]}")"; then
		_error "could not get selected branches to delete"
		return 1
	fi

	for branchToDelete in "${selected[@]}"; do
		delete_branch "$branchToDelete"
	done
}

function delete_branch() {
	local branch
	if ! branch=${1:-} || [[ -z "$branch" ]]; then
		_error "no branch specified to delete"
		return 1
	fi

	# get name of the remote
	if remote=$(get_tracking_remote_from_branch "$branch") && [[ "$remote" == "origin" ]]; then
		_process "deleting origin remote branch '$branch'"
		git push origin --delete "$branch"
	fi

	_process "deleting local branch '$branch'"
	if ! output="$(git branch -d "$branch" 2>&1)"; then
		if [[ "$output" =~ 'is not fully merged' ]]; then

			# if not fully merged, ask user whether to use force
			read -r -p "This branch is not fully merged. Force delete? (nY): " answer

			answer=${answer:-n}
			case "${answer}" in
				Y)
					_process "force-deleting local branch '$branch'"
					git branch -D "$branch"
					;;
				*)
					return 0
					;;
			esac
		fi
	fi
}

function print_usage() {
	echo "usage: gitcli story delete [-p|--pattern 'regex_pattern']"
}

# shellcheck source=./utils/message.bash
source "$__root/src/utils/message.bash"
# shellcheck source=./utils/branch.bash
source "$__root/src/utils/branch.bash"
# shellcheck source=./utils/interaction.bash
source "$__root/src/utils/interaction.bash"
# shellcheck source=./utils/remote.bash
source "$__root/src/utils/remote.bash"

function rebasestory() {
	while [ $# -gt 0 ]
	do
		case "$1" in
			-p | --pattern)
				pattern="$2"
				shift
				;;
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

	src="${src:-}"
	pattern="${pattern:-}"

	if [[ -z "$src" && -z "$pattern" ]]; then
		_error "please specify source or pattern"
		return 1
	fi

	if [[ ! -z "$src" ]]; then
		if ! rebase_with_source "$src"; then
			_error "count not rebase with source"
			return 1
		fi
	fi

	if [[ ! -z "$pattern" ]]; then
		if ! rebase_with_pattern "$pattern"; then
			_error "count not rebase with pattern"
			return 1
		fi
	fi
}

function rebase_with_pattern() {
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

	if [[ "${#branches[@]}" -eq 1 ]]; then
		git rebase "${branches[0]}" || return 1
		return 0
	fi

	choice=$(choose_one "${branches[@]}")

	git rebase "$choice" || return 1
}

function rebase_with_source() {
	if [[ -z "${1:-}" ]]; then
		_error "please specify source"
		return 1
	fi
	src="${1}"

	# find source branch using $src
	if ! srcBranch="$(git config "story.source.$src" 2>/dev/null)"; then
		# or use src as-is
		srcBranch="$src"
	fi

	_process "getting remote from branch '$srcBranch'"
	if ! remote="$(get_remote_from_branch "$srcBranch" 2>&1)"; then
		_error "could not get remote from source branch '$srcBranch' ($remote)"
		return 1
	fi

	_process "fetching remote '$remote'"
	git fetch "$remote"

	git rebase "$srcBranch" || return 1
}

function print_usage() {
	echo "usage: gitcli story rebase [-s|--source <source>] [-p|--pattern 'regex_pattern']"
}

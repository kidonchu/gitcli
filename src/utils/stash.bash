# shellcheck source=./branch.bash
source "$__root/src/utils/branch.bash"
# shellcheck source=./message.bash
source "$__root/src/utils/message.bash"

function save_stash() {

	# check to see if there are things to be stashed
	if ! hasChanges="$(git status -s)"; then
		_error "error: unable to determine change status"
		return 1
	fi

	# if no change, no need to stash
	_process "checking if there are any changes to stash"
	if [[ -z "$hasChanges" ]]; then
		return 0
	fi

	# if has something to stash, stash them and store the commit in config
	_process "adding changes for current branch"
	if ! git add -A; then
		_error "could not add all changes to index"
		return 1
	fi

	_process "stashing changes for current branch"
	if ! git stash; then
		_error "unable to stash"
		return 1
	fi

	_process "getting hash for just saved stash"
	if ! sha="$(git rev-parse stash@\{0\})"; then
		_error "could not retrieve stash hash"
		return 1
	fi

	_process "getting current branch to store stash hash"
	if ! branch="$(get_current_branch)"; then
		_error "could not get current branch ($branch)"
		return 1
	fi

	_process "storing saved stash's hash to current branch's config"
	if ! git config "branch.$branch.laststash" "$sha"; then
		_error "could not save stash hash into config"
		return 1
	fi
}

function pop_stash() {

	if ! branch="$(get_current_branch 2>&1)"; then
		echo "error: could not get current branch ($branch)" >&2
		return 1
	fi

	_process "getting last stash's hash from config"
	if ! hash="$(git config "branch.$branch.laststash")" || [ -z "$hash" ]; then
		# no stash associated with current branch, just return ok
		return 0
	fi

	_process "getting a list of stashes"
	if ! stashes="$(git reflog show stash --pretty=format:'%gD %H' 2>&1)"; then
		echo "error: unable to get a list of stashes ($stashes)" >&2
		return 1
	fi

	_process "checking if branch's last stash hash matches any stash in the list of stashes"
	if ! stash=$(echo "${stashes[@]}" | grep "$hash") || [ -z "$stash" ]; then
		echo "error: unable to find a stash with '$hash'" >&2
		return 1
	fi
	
	if [[ "$stash" =~ stash@\{([[:digit:]]+)\}[[:space:]]+[[:alnum:]]+ ]]; then
		index="${BASH_REMATCH[1]}"
		git stash pop "stash@{$index}"
		git reset
	else
		echo "error: stash didn't match the pattern: stash@{#} XXX" >&2
		return 1
	fi
}

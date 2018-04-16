# shellcheck source=./branch.bash
source "$__root/src/utils/branch.bash"

function save_stash() {

	# check to see if there are things to be stashed
	if ! hasChanges="$(git status -s)"; then
		echo "error: unable to determine change status" >&2
		return 1
	fi

	# if no change, no need to stash
	if [[ -z "$hasChanges" ]]; then
		return 0
	fi

	# if has something to stash, stash them and store the commit in config
	if ! output="$(git add -A && git stash)"; then
		echo "error: unable to stash ($output)" >&2
		return 1
	fi

	if ! sha="$(git reflog show stash --pretty=format:%H | head -1)"; then
		echo "error: could not retrieve stash hash" >&2
		return 1
	fi

	if ! branch="$(get_current_branch)"; then
		echo "error: could not get current branch ($branch)" >&2
		return 1
	fi

	if ! git config "branch.$branch.laststash" "$sha"; then
		echo "error: could not save stash hash into config" >&2
		return 1
	fi
}

function pop_stash() {

	if ! branch="$(get_current_branch 2>&1)"; then
		echo "error: could not get current branch ($branch)" >&2
		return 1
	fi

	if ! hash="$(git config "branch.$branch.laststash")" || [ -z "$hash" ]; then
		# no stash associated with current branch, just return ok
		return 0
	fi

	if ! stashes="$(git reflog show stash --pretty=format:'%gD %H' 2>&1)"; then
		echo "error: unable to get a list of stashes ($stashes)" >&2
		return 1
	fi

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

	return 0
}

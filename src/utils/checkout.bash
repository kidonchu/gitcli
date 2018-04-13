function checkout() {

	if [[ -z "${1:-}" ]]; then
		echo "error: branch to checkout must be specified" >&2
		return 1
	fi
	branch="${1}"

	if ! output=$(git checkout "$branch" 2>&1); then
		echo "error: unable to checkout '$branch' ($output)" >&2
		return 1
	fi	

	git checkout "$branch"
}

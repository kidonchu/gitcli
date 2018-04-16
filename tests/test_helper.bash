__root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
__test_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_tmp_dir="$__test_root/bats-test-tmp"

function _setup_git() {
	{
		if [[ -d "$_tmp_dir" ]]; then
			rm -rf "$_tmp_dir"
		fi
		git init "$_tmp_dir" &> /dev/null
		cd "$_tmp_dir" || return
		git checkout -b feature/test-branch
		touch a.txt && run git add a.txt
		git commit -m "Add a.txt"
		cd "$__test_root"
	} &> /dev/null
}

function _teardown_git() {
	if [[ -d "$_tmp_dir" ]]; then
		rm -rf "$_tmp_dir" &> /dev/null
	fi
}

function _cd_git() {
	cd "$_tmp_dir" || return
}

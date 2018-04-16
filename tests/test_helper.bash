__root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
__test_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__tmp_dir="$__test_root/bats-test-tmp"
__bare__tmp_dir="$__test_root/bats-test-tmp-bare"

function _setup_git() {
	{
		if [[ -d "$__tmp_dir" ]]; then
			rm -rf "$__tmp_dir"
		fi
		if [[ -d "$__bare__tmp_dir" ]]; then
			rm -rf "$__bare__tmp_dir"
		fi
		git init "$__tmp_dir" &> /dev/null
		git clone --bare "$__tmp_dir" "$__bare__tmp_dir"
		cd "$__tmp_dir" || return
		git remote add upstream "$__bare__tmp_dir"
		git checkout -b feature/test-branch
		touch a.txt && run git add a.txt
		git commit -m "Add a.txt"
		git push upstream feature/test-branch
		git branch --set-upstream-to=upstream/feature/test-branch
		cd "$__test_root"
	} &> /dev/null
}

function _teardown_git() {
	if [[ -d "$__tmp_dir" ]]; then
		rm -rf "$__tmp_dir" &> /dev/null
	fi
	if [[ -d "$__bare__tmp_dir" ]]; then
		rm -rf "$__bare__tmp_dir" &> /dev/null
	fi
}

function _cd_git() {
	cd "$__tmp_dir" || return
}

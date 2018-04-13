_tmp_dir='bats-test-tmp'

function _setup_git() {
	if [[ ! -d "$_tmp_dir" ]]; then
		git init "$_tmp_dir" &> /dev/null
	fi
}

function _teardown_git() {
	if [[ -d "$_tmp_dir" ]]; then
		rm -rf "$_tmp_dir" &> /dev/null
	fi
}

function _cd_git() {
	cd "$_tmp_dir"
}

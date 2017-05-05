function newstory() {

	if [[ $# -lt 2 ]]; then
		echo >&2 `print_usage`
		exit 1
	fi

	src="default"
	newBranch=""

	while [ $# -gt 0 ]
	do
		case "${1}" in
			-s | --source)
				src=${2}
				shift
				;;
			-b | --branch)
				newBranch=${2}
				shift
				;;
			*) # unknown flag
				echo >&2 `print_usage`
				exit 1;;
		esac
		shift
	done

	if [[ -z "${newBranch}" ]]; then
		_gitcli_error "Specify new branch name"
		exit 1
	fi

	# find source branch using $src
	srcBranch=`_gitcli_get_config "story.source.${src}"`
	if [[ -z "${srcBranch}" ]]; then
		_gitcli_error "Unable to find source branch with ${src}"
		exit 1
	fi

	# create new branch
	_gitcli_create "${newBranch}" "${srcBranch}"

	# checkout new branch
	_gitcli_process "Checking out new branch"
	_gitcli_checkout "${newBranch}"

	# push to remote
	remoteTarget=`_gitcli_get_config "story.remotetarget"`
	if [[ -z "${remoteTarget}" ]]; then
		remoteTarget="origin"
	fi
	_gitcli_process "Pushing to remote target: ${remoteTarget}"
	git push -u "${remoteTarget}" "${newBranch}"
}

function print_usage() {
	echo "usage: gitcli story new [-s|--source <source>] [-b|--branch <new_branch>]"
}

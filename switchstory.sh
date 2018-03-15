function switchstory() {

	recent=0
	pattern=""

	while [ $# -gt 0 ]
	do
		case "${1}" in
			-p | --pattern)
				pattern=${2}
				shift
				;;
			-r | --recent)
				recent=1
				;;
			*) # unknown flag
				echo >&2 "usage: gitcli story switch [-r|--recent] [-p|--pattern 'regex_pattern']"
				exit 1;;
		esac
		shift
	done

	if [[ ${recent} == 1 ]]; then
		switch_to_recent
	else
		switch_to_pattern "${pattern}"
	fi
}

function switch_to_recent() {

	_gitcli_process "Looking for most recent branches"

	branches=(`_gitcli_get_recent_branches`)
	toBranch=`_gitcli_choose_one ${branches[@]}`

	if [[ -z "$toBranch" ]]; then
		_gitcli_process "No recent branch exists"
		return
	fi

	_gitcli_checkout "${toBranch}"

	_gitcli_remove_recent_branch_by_name "$toBranch"

	# _gitcli_post_checkout
}

function switch_to_pattern() {
	pattern=${1}
	if [[ -z "${pattern}" ]]; then
		pattern="^.*$"
	fi

	_gitcli_process "Looking for branches that match the pattern"
	branches=`git branch | grep -v '*'`
	choices=()
	for branch in ${branches}; do
		if [[ ${branch} =~ ${pattern} ]]; then
			choices+=("${branch}")
		fi
	done

	# if only one branch matches the pattern check it out
	if [[ ${#choices[@]} == 0 ]]; then
		_gitcli_error "Unable to find branches that match the pattern '${pattern}'"
		return 1
	elif [[ ${#choices[@]} == 1 ]]; then
		_gitcli_checkout "${choices[0]}"
		return 0
	fi

	# otherwise, display a list of branches for user to choose
	toBranch=`_gitcli_choose_one "${choices[@]}"`

	# checkout chosen branch
	_gitcli_checkout "${toBranch}"
}

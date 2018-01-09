function deletestory() {

	pattern=""
	force=0

	while [ $# -gt 0 ]
	do
		case "${1}" in
			-p | --pattern)
				pattern=${2}
				shift
				;;
			*) # unknown flag
				echo >&2 "usage: gitcli story delete [-p|--pattern 'regex_pattern']"
				exit 1;;
		esac
		shift
	done

	delete_with_pattern "${pattern}" "${force}"
}

function delete_with_pattern() {

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
	fi

	# continuous deletion until Ctrl+C is pressed or no matching branches
	total=${#choices[@]}
	while [[ $total -gt 0 ]]; do
		# display a list of branches for user to choose
		toDelete=`_gitcli_choose_one ${choices}`

		if [[ -z "$toDelete" ]]; then
			echo
			_gitcli_notice "Invalid option"
			echo
			continue
		fi

		# delete chosen branch
		_gitcli_delete "${toDelete}" "${force}"

		# get rid of deleted branch from choices
		for i in ${!choices[@]}; do
			if [[ "${choices[$i]}" == "$toDelete" ]]; then
				unset 'choices[i]'
			fi
		done

		# fill in the index that got deleted
		choices=("${choices[@]}")

		total=${#choices[@]}

		echo
	done
}

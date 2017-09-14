function prstory() {

	src=""

	while [ $# -gt 0 ]
	do
		case "${1}" in
			-s | --source)
				src=${2}
				shift
				;;
			*) # unknown flag
				print_usage
				exit 1;;
		esac
		shift
	done

	# use default src if not specified
	if [[ -z "${src}" ]]; then
		src="default"
	fi

	# find source branch using $src
	srcBranch=`_gitcli_find_src_branch "${src}"`

	# open browser with PR url
	_gitcli_open_pr_url "${srcBranch}"

	_gitcli_copy_issue_to_clipboard

	# _gitcli_create_pr "#{srcBranch}"
}

function print_usage() {
	echo "usage: gitcli story pullrequest [-s|--source <source>]"
}

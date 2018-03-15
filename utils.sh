function _gitcli_get_config() {
	config=`git config --list | grep "${1}"`
	if [ -z "${config}" ]; then
		return 0
	fi
	config=`echo ${config} | cut -d'=' -f 2`
	echo "${config}"
}

function _gitcli_current_branch() {
	branch=`git branch | grep \* | cut -d ' ' -f2`
	echo "${branch}"
}

function _gitcli_create() {

	_gitcli_process "Preparing to create new branch ${newBranch} from ${srcBranch}"

	newBranch=${1}
	srcBranch=${2}

	# first, check if we already have a branch with same name
	if [[ ! -z `git branch --list ${1}` ]]; then
		_gitcli_notice "Branch ${newBranch} already exists"
		return 0
	fi

	_gitcli_fetch_by_branch "${srcBranch}"

	_gitcli_process "Creating new branch ${newBranch} from ${srcBranch}"

	git branch "${newBranch}" ${srcBranch}
}

function _gitcli_checkout() {

	fromBranch=`_gitcli_current_branch`
	toBranch=${1}
	noStash=false

	if [[ $# -gt 1 ]]; then
		noStash=${2}
	fi

	_gitcli_process "${fromBranch} => ${toBranch}"

	# check to see if there are things to be stashed
	hasChanges=`git status -s`
	if [[ "${noStash}" = false && ! -z "${hasChanges}" ]]; then
		_gitcli_process "Stashing changes"
		# if has something to stash, stash them and store the commit in config
		git add -A
		git stash
		sha=`git reflog show stash --pretty=format:%H | head -1`
		git config "branch.${fromBranch}.laststash" "${sha}"
	fi

	# store fromBranch as recent branch now and checkout toBranch
	_gitcli_process "Checking out ${toBranch}"
	git config story.mostrecent "${fromBranch}"
	git checkout ${toBranch}

	_gitcli_process "Adding $fromBranch to recent branches list"
	_gitcli_add_recent_branch "$fromBranch"

	# if there is last stash for the switched branch, pop that out
	laststash=`_gitcli_get_config "branch.${toBranch}.laststash"`
	if [[ ! -z "${laststash}" ]]; then

		_gitcli_process "Preparing to pop out last stash"

		stashIndex=0
		stashes=(`git reflog show stash --pretty=format:%H`)
		for stash in ${stashes[@]}; do
			if [[ ${stash} == ${laststash} ]]; then
				break
			fi
			((stashIndex+=1))
		done

		if [[ $stashIndex -lt ${#stashes[@]} ]]; then
			_gitcli_process "Popping out stash@{${stashIndex}}"
			git stash pop "stash@{${stashIndex}}"
			git reset
		fi

		git config "branch.${toBranch}.laststash" ""
	fi
}

function _gitcli_pull() {

	fromBranch=${1}

	_gitcli_process "Preparing to pull from ${fromBranch}"

	# check to see if there are things to be stashed
	hasChanges=`git status -s`
	if [[ ! -z "${hasChanges}" ]]; then
		_gitcli_error "You have changes. Resolve them first"
		exit 1
	fi

	# assuming $fromBranch will always be in the form of
	# <remote>/(feature/bugfix)/branch-name
	remote=`echo ${fromBranch} | cut -d'/' -f 1`
	branch=`echo ${fromBranch} | cut -d'/' -f 2,3`

	_gitcli_process "Fetching from ${remote}"

	git fetch $remote

	_gitcli_process "Pulling from ${fromBranch}"

	git pull "${remote}" "${branch}"
}

function _gitcli_rebase() {

	branch=${1}

	_gitcli_process "Preparing to rebase on ${branch}"

	# check to see if there are things to be stashed
	hasChanges=`git status -s`
	if [[ ! -z "${hasChanges}" ]]; then
		_gitcli_error "You have changes. Resolve them first"
		exit 1
	fi

	_gitcli_fetch_by_branch "${srcBranch}"

	_gitcli_process "Rebasing on ${branch}"

	git rebase "${branch}"
}

function _gitcli_delete() {

	branch=${1}

	# get name of the remote
	remote=`_gitcli_get_config branch.${branch}.remote`
	if [[ ! -z "$remote" ]]; then
		if [[ "$remote" == "origin" ]]; then
			_gitcli_process "Deleting remote branch for ${branch}"
			git push origin --delete "${branch}"
		else
			_gitcli_process "remote '${remote}' is not origin for ${branch}"
		fi
	else
		_gitcli_process "remote branch was not found for ${branch}"
	fi

	_gitcli_process "Deleting local branch for ${branch}"

	set +e
	result=`git branch -d "${branch}" 2>&1`
	set -e

	if [[ "${result}" =~ 'is not fully merged' ]]; then
		echo
		# if not fully merged, ask user whether to use force
		read -p "This branch is not fully merged. Force delete? (nY): " answer
		answer=${answer:-n}
		echo "answer:" $answer
		case "${answer}" in
			Y)
				_gitcli_process "***FORCE*** Deleting local branch for ${branch}"
				git branch -D "${branch}"
				;;
			*)
				_gitcli_process "Exiting without deleting local branch"
				return 0
				;;
		esac
	fi
}

function _gitcli_open() {

	branch=`_gitcli_current_branch`
	remote=`_gitcli_get_config "branch.${branch}.remote"`
	url=`_gitcli_get_config "remote.${remote}.url"`
	url=${url/git@github.com:/https://github.com/}
	url=${url/.git//tree}
	url="$url/$branch"

	open "$url"
}

function _gitcli_copy_issue_to_clipboard() {

	branch=`_gitcli_current_branch`
	pattern='^([a-zA-Z0-9]+)/([[:alpha:]]+-[0-9]+)(-.*)?'

	if [[ "$branch" =~ $pattern ]]; then
		# if issue id exists in the branch name, copy to clipboard
		issueId=${BASH_REMATCH[2]}
		issueId=`echo $issueId | awk '{print toupper($0)}'`
		echo `printf "[%s]" ${issueId}` | pbcopy &> /dev/null
	else
		_gitcli_notice "Unable to extract issue id from ${branch}"
	fi

	return 0
}

function _gitcli_open_pr_url() {

	base="${1}"

	_gitcli_process "Preparing to open Pull Request URL with base ${base}"

	# prepare base information
	baseRemote=`echo ${base} | cut -d'/' -f 1`
	baseBranch=`echo ${base} | cut -d'/' -f 2,3`
	baseUri=`_gitcli_get_config "remote.${baseRemote}.url" | sed 's/git@github.com://' | sed 's/\.git//'`
	baseOwner=`echo ${baseUri} | cut -d'/' -f 1`
	baseRepo=`echo ${baseUri} | cut -d'/' -f 2`

	#prepare head information
	headBranch=`_gitcli_current_branch`
	headRemote=`_gitcli_get_config "branch.${headBranch}.remote"`
	headUri=`_gitcli_get_config "remote.${headRemote}.url" | sed 's/git@github.com://' | sed 's/\.git//'`
	headOwner=`echo ${headUri} | cut -d'/' -f 1`
	headRepo=`echo ${headUri} | cut -d'/' -f 2`

	url=`printf "https://github.com/%s/%s/compare/%s...%s:%s?expand=1" \
		"${baseOwner}" "${baseRepo}" "${baseBranch}" "${headOwner}" "${headBranch}"`

	_gitcli_process "Opening Pull Request URL with base ${base}"

	open "${url}"
}

function _gitcli_fetch_all() {
	_gitcli_process "Fetching all remotes"
	git fetch --all
}

function _gitcli_fetch_by_branch() {
	srcBranch="${1}"

	if [[ "${srcBranch}" =~ ([-a-zA-Z0-9]+)/.* ]]; then
		remote=${BASH_REMATCH[1]}
		_gitcli_process "Fetching most recent changes from ${remote}"
		git fetch "${remote}"
	else
		_gitcli_process "Fetching most recent changes"
		git fetch
	fi
}

function _gitcli_create_pr() {

	token=`_gitcli_get_config "story.oauthtoken"`
	if [[ -z "${token}" ]]; then
		_gitcli_error "Missing oauth token. Add one using `git config story.oauthtoken <token>`"
		exit 1
	fi

	# prepare headers
	headers=()
	headers+=("Authorization: token ${token}")
	headers+=("Accept: application/vnd.github.polaris-preview+json")
	headers+=("Content-Type: application/json")

	cmd="curl -X POST"
	for header in "${headers[@]}"; do
		cmd="${cmd} -H '${header}'"
	done

	title="Title"
	body="Body"
	head="kidonchu:test/feature3"
	base="master"

	title=`cat ./.git/PR_BODY_MESSAGE.md`

	body=`echo "<?php echo json_encode(array('title' => '${title}')); ?>" | php`

	owner="kidonchu"
	repo="test-repo"
	url=`sprinf "https://api.github.com/repos/%s/%s/pulls" "${owner}" "${repo}"`
	curl -i -X POST -H 'Authorization: token ' -H 'Content-Type: application/json' -H 'Accept: application/vnd.github.polaris-preview+json' -d '{"title": "Title","base":"master","head":"feature/test3"}' https://api.github.com/repos/kidonchu/test-repo/pulls
}

function _gitcli_find_src_branch() {

	src=${1}

	srcBranch=`_gitcli_get_config "story.source.${src}"`
	if [[ -z "${srcBranch}" ]]; then
		_gitcli_error "Unable to find source branch with ${src}"
		exit 1
	fi

	echo "${srcBranch}"
}

function _gitcli_choose_one() {

	choices=("$@")

	PS3=">>> Choose one: "
	select choice in "${choices[@]}"
	do
		case ${choice} in
			*)
				echo ${choice}
				break
				;;
		esac
	done
}

function _gitcli_post_checkout() {
	echo "hi" > /dev/null
	# cp $HOME/vagrant/dev/hosted/config/env_kchu.php $HOME/vagrant/dev/hosted/config/env_dev.php
	# cd $HOME/vagrant/dev/hosted/admin/svg
	# ln -sfn ../../../ember-app/dist/assets/svg/sprite.symbol.svg .
}

function _gitcli_get_recent_branches() {

	items=()

	total=`git config story.recent.total`
	for i in `seq $total 1`
	do
		branch=`git config "story.recent.l$i"`
		items+=("${branch}")
	done

	echo "${items[@]}"
}

function _gitcli_add_recent_branch() {
	local branch="$1"
	_gitcli_process "branch: $branch"

	# check if we have `story.recent.total` node already set
	# if not set, configure total to 0
	{
		git config story.recent.total || git config story.recent.total 0
	} &> /dev/null

	total=`git config story.recent.total`

	_gitcli_process "total: $total"

	let index=total+1
	git config "story.recent.l$index" "$branch"
	git config "story.recent.total" "$index"
}

function _gitcli_remove_recent_branch() {

	local index="$1"
	total=`git config story.recent.total`

	_gitcli_process "total: $total"

	if [[ $total > 1 ]]; then
		for newIndex in `seq $((index)) $((total-1))`
		do
			let oldIndex=newIndex+1
			branch=`git config story.recent.l$oldIndex`
			git config "story.recent.l$newIndex" "$branch"
			_gitcli_process "setting story.recent.l$newIndex to $branch"
		done
	fi

	git config --unset "story.recent.l$total"
	git config "story.recent.total" "$((total-1))"
}

function _gitcli_remove_recent_branch_by_name() {

	local branchToRemove="$1"

	_gitcli_process "Removing $branchToRemove from recent branches list"

	local total=`git config story.recent.total`

	# get recent branches from gitconfig
	local branches=()
	for i in `seq 1 $total`; do
		branches+=(`git config story.recent.l$i`)
	done

	local index=0
	for i in "${!branches[@]}"
	do
		local branchToCompare="${branches[i]}"
		if [[ "$branchToCompare" == "$branchToRemove" ]]; then
			unset 'branches[i]'
		fi
	done

	# reorganize indices
	local newarray=()
	for branch in "${branches[@]}"; do
		newarray+=("$branch")
	done
	branches=("${newarray[@]}")
	unset newarray

	# update gitconfig with new list of recent branches
	local oldTotal="$total"
	local newTotal=0
	for i in "${!branches[@]}"; do
		key="story.recent.l$((i+1))"
		branch="${branches[i]}"
		git config "$key" "$branch"
		let newTotal=newTotal+1
	done
	git config "story.recent.total" "$newTotal"

	# cleanup extra items in the recent list
	for i in `seq $((newTotal+1)) $oldTotal`; do
		key="story.recent.l$i"
		git config --unset "$key"
	done
}







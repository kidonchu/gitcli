# shellcheck source=./message.bash
source "$__root/src/utils/message.bash"

function choose_one() {
	read -r -a choices <<< "$@"
	if [[ "${#choices[@]}" -eq 0 ]]; then
		_error "nothing to choose one from"
		return 1
	fi

	# we don't want to hang bats test with `select`
	if [[ "$GITCLI_ENV" == "test" ]]; then
		echo "${choices[0]}"
		return 0
	fi
	
	PS3=">>> Choose one: "
	select choice in "${choices[@]}"
	do
		case "$choice" in
			*)
				echo "$choice"
				break
				;;
		esac
	done
}

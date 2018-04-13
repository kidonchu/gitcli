# sets git config
function set_config() {

	if [[ -z "${1:-}" ]]; then
		echo "error: key must not be empty" >&2
		return 1
	fi
	key="${1}"

	if [[ -z "${2+x}" ]]; then
		echo "error: value must be set" >&2
		return 1
	fi
	value="${2}"

	git config "$key" "$value"
}

# gets git config
function get_config() {

	if [[ -z "${1:-}" ]]; then
		echo "error: key must not be empty" >&2
		return 1
	fi
	key="${1}"
	
	if ! config="$(git config "$key")"; then
		echo "error: unable to retrieve config with '$key'" >&2
		return 1
	fi

	echo "$config"
}

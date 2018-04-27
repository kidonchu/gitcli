function _error() {
	prefix="ERROR:"
	if command -v tput >/dev/null; then
		prefix="$(tput setaf 1)ERROR:$(tput sgr0)"
	fi
	>&2 echo "$prefix $*"
}

function _process() {
	prefix="PROCESSING:"
	if command -v tput >/dev/null; then
		prefix="$(tput setaf 5)PROCESSING:$(tput sgr0)"
	fi
	>&2 echo "$prefix $*"
}

function _success() {
	local prefix
	local suffix
	if command -v tput >/dev/null; then
		prefix="$(tput setaf 2)"
		suffix="$(tput sgr0)"
	fi
	echo "${prefix}Job Done. Go Break a LEG! $suffix"
}

function _notice() {
	prefix="NOTICE:"
	if command -v tput >/dev/null; then
		prefix="$(tput setaf 4)NOTICE:$(tput sgr0)"
	fi
	>&2 echo "$prefix $*"
}

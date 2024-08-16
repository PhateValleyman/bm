# Complete function for the 'bm' command
_bm() {
	local cur prev opts bookmarks_file

	# Current word being completed
	cur="${COMP_WORDS[COMP_CWORD]}"
	# Previous word in the command
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	# Available options for the bm command
	opts="-a --add -d --delete -g --go -p --print -l --list -h --help -v --version -c --completion"

	# Set the bookmarks file path (same as in your Go script)
	bookmarks_file="${SDIRS:-${PREFIX:-/data/data/com.termux/files/usr}/etc/sdirs}"

	# Fetch bookmarks from the file
	if [[ -f "$bookmarks_file" ]]; then
		mapfile -t bookmarks < <(grep -oP '^export DIR_\K[^=]+' "$bookmarks_file")
	else
		bookmarks=()
	fi

	# Completion logic
	case "$prev" in
		-a|--add|-d|--delete|-g|--go|-p|--print)
			# Complete with bookmark names
			COMPREPLY=( $(compgen -W "${bookmarks[*]}" -- "$cur") )
			return 0
			;;
		*)
			# Complete with options and bookmark names
			COMPREPLY=( $(compgen -W "$opts ${bookmarks[*]}" -- "$cur") )
			return 0
			;;
	esac
}

# Register the completion function for the bm command
complete -F _bm bm

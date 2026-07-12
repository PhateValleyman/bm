#!/ffp/bin/bash

# bm - Bookmark Manager v1.5
# Senior-level bash implementation optimized for performance and Go conversion.
# Author: PhateValleyman | Jonas.Ned@outlook.com

# --- Configuration (Go: Config) ---
_BM_FILE_DEFAULT="${SDIRS:-$HOME/.config/bm/bookmarks}"

# --- Colors (Go: color package) ---
_BM_C_RED='\033[01;31m'
_BM_C_GREEN='\033[01;32m'
_BM_C_BLUE='\033[01;34m'
_BM_C_YELLOW='\033[01;33m'
_BM_C_CYAN='\033[01;36m'
_BM_C_NONE='\033[0m'

bm() {
	# Local state (Go: map[string]string)
	local -A _bookmarks
	local _modified=0
	local _BM_FILE="$_BM_FILE_DEFAULT"

	# --- Helper Functions (Go: internal/ui) ---
	_bm_err() { echo -e "${_BM_C_RED}Error:${_BM_C_NONE} $1" >&2; }
	_bm_warn() { echo -e "${_BM_C_YELLOW}Warning:${_BM_C_NONE} $1"; }
	_bm_info() { echo -e "${_BM_C_BLUE}$1${_BM_C_NONE}"; }
	_bm_ok() { echo -e "${_BM_C_GREEN}$1${_BM_C_NONE}"; }

	# --- Internal Logic (Go: internal/storage) ---

	# Load bookmarks from file
	_bm_load() {
		if [[ -f "$_BM_FILE" ]]; then
			while IFS= read -r line; do
				# Match export DIR_name="path"
				if [[ "$line" =~ ^export\ DIR_([^=]+)=\"(.*)\"$ ]]; then
					_bookmarks["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
				fi
			done < "$_BM_FILE"
		fi
	}

	# Save bookmarks to file atomically (Go: Storage.Save)
	_bm_save() {
		local dir
		dir=$(dirname "$_BM_FILE")
		[[ ! -d "$dir" ]] && mkdir -p "$dir"

		local tmp_file="${_BM_FILE}.tmp"
		local name
		local sorted_names
		
		# Sort names for deterministic file content
		sorted_names=$(printf '%s\n' "${!_bookmarks[@]}" | sort)
		
		: > "$tmp_file"
		for name in $sorted_names; do
			[[ -z "$name" ]] && continue
			printf 'export DIR_%s="%s"\n' "$name" "${_bookmarks[$name]}" >> "$tmp_file"
		done
		
		mv "$tmp_file" "$_BM_FILE"
	}

	_bm_is_valid_name() { [[ "$1" =~ ^[a-zA-Z0-9_]+$ ]]; }

	# --- Command Handlers (Go: cmd/) ---

	_bm_list() {
		local name
		local sorted_names
		sorted_names=$(printf '%s\n' "${!_bookmarks[@]}" | sort)

		echo -e "     ${_BM_C_GREEN}Saved bookmarks${_BM_C_NONE}:"
		echo ""
		
		for name in $sorted_names; do
			[[ -z "$name" ]] && continue
			printf "  ${_BM_C_YELLOW}%-20s${_BM_C_NONE} %s\n" "$name" "${_bookmarks[$name]}"
		done
		echo ""
	}

	_bm_usage() {
		echo -e "Usage: ${_BM_C_RED}bm${_BM_C_NONE} [${_BM_C_CYAN}global options${_BM_C_NONE}] [${_BM_C_GREEN}option${_BM_C_NONE}] <${_BM_C_YELLOW}bookmark${_BM_C_NONE}>"
		echo -e "\nGlobal Options:"
		echo -e "  ${_BM_C_CYAN}-f, --file${_BM_C_NONE}    <path>  Use custom bookmarks file"
		echo -e "\nOptions:"
		echo -e "  ${_BM_C_GREEN}-a, --add${_BM_C_NONE}     <name>  Add current directory"
		echo -e "  ${_BM_C_GREEN}-d, --delete${_BM_C_NONE}  <name>  Remove bookmark"
		echo -e "  ${_BM_C_GREEN}-l, --list${_BM_C_NONE}            List all bookmarks"
		echo -e "  ${_BM_C_GREEN}-p, --print${_BM_C_NONE}   <name>  Show bookmark path"
		echo -e "  ${_BM_C_GREEN}-c, --completion${_BM_C_NONE}      Generate completion script"
		echo -e "  ${_BM_C_GREEN}-v, --version${_BM_C_NONE}         Show version information"
		echo -e "  ${_BM_C_GREEN}-h, --help${_BM_C_NONE}            Show this help message"
	}

	# --- Main Dispatcher (Go: main/cobra) ---

	# Parse global flags
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-f|--file)
				if [[ -n "$2" ]]; then
					_BM_FILE="$2"
					shift 2
				else
					_bm_err "Option '--file' requires an argument."
					return 1
				fi
				;;
			*) break ;;
		esac
	done

	_bm_load

	case "$1" in
		-a|--add)
			local name="$2"
			if [[ -z "$name" ]]; then
				_bm_err "Missing bookmark name."
				return 1
			fi
			if _bm_is_valid_name "$name"; then
				_bookmarks["$name"]="$(pwd)"
				_modified=1
				_bm_info "Added: $name -> $(pwd) (File: $_BM_FILE)"
			else
				_bm_err "Invalid name '$name'. Use alphanumeric and underscores only."
				return 1
			fi
			;;
		-d|--delete)
			local name="$2"
			if [[ -n "${_bookmarks[$name]}" ]]; then
				unset "_bookmarks[$name]"
				_modified=1
				_bm_err "Deleted: $name (File: $_BM_FILE)"
			else
				_bm_err "Bookmark '$name' not found."
				return 1
			fi
			;;
		-l|--list)
			_bm_list
			;;
		-p|--print)
			local name="$2"
			if [[ -n "${_bookmarks[$name]}" ]]; then
				echo "${_bookmarks[$name]}"
			else
				_bm_err "Bookmark '$name' not found."
				return 1
			fi
			;;
		-c|--completion)
			cat << 'EOF'
_bm_completion() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prev="${COMP_WORDS[COMP_CWORD-1]}"
	local opts="-a --add -d --delete -l --list -p --print -h --help -c --completion -v --version -f --file"
	
	# Detect custom file in current command line
	local bfile="${SDIRS:-$HOME/.config/bm/bookmarks}"
	local i
	for ((i=1; i < ${#COMP_WORDS[@]}; i++)); do
		if [[ "${COMP_WORDS[i]}" == "-f" || "${COMP_WORDS[i]}" == "--file" ]]; then
			[[ -n "${COMP_WORDS[i+1]}" ]] && bfile="${COMP_WORDS[i+1]}"
			break
		fi
	done

	# Complete files after -f/--file
	if [[ "$prev" == "-f" || "$prev" == "--file" ]]; then
		COMPREPLY=( $(compgen -f -- "$cur") )
		return 0
	fi

	# Complete bookmarks from the detected file
	local bookmarks=""
	if [[ -f "$bfile" ]]; then
		bookmarks=$(grep -oE 'DIR_[a-zA-Z0-9_]+' "$bfile" | cut -d_ -f2-)
	fi
	
	COMPREPLY=( $(compgen -W "$opts $bookmarks" -- "$cur") )
}
complete -F _bm_completion bm
EOF
			;;
		-v|--version)
			echo "bm v1.5 (Pre-Go Revision)"
			echo "Author: Jonas Mueller (PhateValleyman)"
			;;
		-h|--help|"")
			_bm_usage
			;;
		*)
			local target="${_bookmarks[$1]}"
			if [[ -n "$target" ]]; then
				if [[ -d "$target" ]]; then
					cd "$target" || return 1
					_bm_info "Jumped to: $target"
				else
					_bm_err "Target directory '$target' no longer exists."
					return 1
				fi
			else
				_bm_err "Unknown command or bookmark: '$1'"
				return 1
			fi
			;;
	esac

	# Sync to disk if state changed
	[[ $_modified -eq 1 ]] && _bm_save
}

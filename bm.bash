#!/ffp/bin/bash

# bm - Bookmark Manager v1.4
# Optimized and structured for future Golang conversion

# --- Configuration ---
_BM_SDIRS="${SDIRS:-}"
_BM_PREFIX="${PREFIX:-/ffp}"
_BM_FILE="${_BM_SDIRS:-${_BM_PREFIX}/etc/sdirs}"

# --- Colors ---
_BM_C_RED='\033[01;31m'
_BM_C_GREEN='\033[01;32m'
_BM_C_BLUE='\033[01;34m'
_BM_C_YELLOW='\033[01;33m'
_BM_C_CYAN='\033[01;36m'
_BM_C_NONE='\033[0m'

# Ensure environment is ready
[[ ! -d "$(dirname "$_BM_FILE")" ]] && mkdir -p "$(dirname "$_BM_FILE")"
[[ ! -f "$_BM_FILE" ]] && touch "$_BM_FILE"

bm() {
	# Local state (Analogous to Go map[string]string)
	local -A _bookmarks
	local _modified=0

	# --- Internal Logic ---

	# Load bookmarks into memory
	_bm_load() {
		while IFS= read -r line; do
			if [[ "$line" =~ ^export\ DIR_([^=]+)=\"(.*)\"$ ]]; then
				_bookmarks["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
			fi
		done < "$_BM_FILE"
	}

	# Save bookmarks to disk (Atomic write)
	_bm_save() {
		local tmp_file="${_BM_FILE}.tmp"
		: > "$tmp_file"
		local name
		for name in "${!_bookmarks[@]}"; do
			printf 'export DIR_%s="%s"\n' "$name" "${_bookmarks[$name]}" >> "$tmp_file"
		done
		mv "$tmp_file" "$_BM_FILE"
	}

	_bm_is_valid() { [[ "$1" =~ ^[a-zA-Z0-9_]+$ ]]; }

	# --- Commands ---

	_bm_list() {
		echo -e "     ${_BM_C_GREEN}Saved bookmarks${_BM_C_NONE}:"
		echo ""
		local name
		# Sort names for consistent output
		local sorted_names
		sorted_names=$(printf '%s\n' "${!_bookmarks[@]}" | sort)
		
		for name in $sorted_names; do
			[[ -z "$name" ]] && continue
			printf "  ${_BM_C_YELLOW}%-20s${_BM_C_NONE} %s\n" "$name" "${_bookmarks[$name]}"
		done
	}

	_bm_usage() {
		echo -e "Usage: ${_BM_C_RED}bm${_BM_C_NONE} [${_BM_C_GREEN}option${_BM_C_NONE}] <${_BM_C_YELLOW}bookmark${_BM_C_NONE}>"
		echo -e "\nOptions:"
		echo -e "  ${_BM_C_GREEN}-a${_BM_C_NONE},${_BM_C_GREEN} --add${_BM_C_NONE}    <${_BM_C_YELLOW}name${_BM_C_NONE}>  Add current directory"
		echo -e "  ${_BM_C_GREEN}-d${_BM_C_NONE},${_BM_C_GREEN} --delete${_BM_C_NONE} <${_BM_C_YELLOW}name${_BM_C_NONE}>  Remove bookmark"
		echo -e "  ${_BM_C_GREEN}-l${_BM_C_NONE},${_BM_C_GREEN} --list${_BM_C_NONE}           List all bookmarks"
		echo -e "  ${_BM_C_GREEN}-p${_BM_C_NONE},${_BM_C_GREEN} --print${_BM_C_NONE}  <${_BM_C_YELLOW}name${_BM_C_NONE}>  Show path"
		echo -e "  ${_BM_C_GREEN}-c${_BM_C_NONE},${_BM_C_GREEN} --completion${_BM_C_NONE}     Generate completion script"
		echo -e "  ${_BM_C_GREEN}-v${_BM_C_NONE},${_BM_C_GREEN} --version${_BM_C_NONE}        Show version"
		echo -e "  ${_BM_C_GREEN}-h${_BM_C_NONE},${_BM_C_GREEN} --help${_BM_C_NONE}           Show this help"
	}

	# --- Main Dispatcher ---

	_bm_load

	case "$1" in
		-a|--add)
			local name="$2"
			if _bm_is_valid "$name"; then
				_bookmarks["$name"]="$(pwd)"
				_modified=1
				echo -e "${_BM_C_BLUE}Added:${_BM_C_NONE} $name -> $(pwd)"
			else
				echo -e "${_BM_C_RED}Error:${_BM_C_NONE} Invalid name (use a-z, 0-9, _)"
				return 1
			fi
			;;
		-d|--delete)
			if [[ -n "${_bookmarks[$2]}" ]]; then
				unset "_bookmarks[$2]"
				_modified=1
				echo -e "${_BM_C_RED}Deleted:${_BM_C_NONE} $2"
			else
				echo -e "${_BM_C_RED}Error:${_BM_C_NONE} Bookmark '$2' not found"
				return 1
			fi
			;;
		-l|--list) _bm_list ;;
		-p|--print)
			if [[ -n "${_bookmarks[$2]}" ]]; then
				echo "${_bookmarks[$2]}"
			else
				echo -e "${_BM_C_RED}Error:${_BM_C_NONE} Bookmark '$2' not found"
				return 1
			fi
			;;
		-c|--completion)
			cat << 'EOF'
_bm_completion() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local opts="-a --add -d --delete -l --list -p --print -h --help -c --completion -v --version"
	local bookmarks_file="${SDIRS:-${PREFIX:-/ffp}/etc/sdirs}"
	local bookmarks=""
	if [[ -f "$bookmarks_file" ]]; then
		bookmarks=$(grep -oP '(?<=export DIR_)[^=]+' "$bookmarks_file" 2>/dev/null)
	fi
	COMPREPLY=( $(compgen -W "$opts $bookmarks" -- "$cur") )
}
complete -F _bm_completion bm
EOF
			;;
		-v|--version) echo "bm v1.4 (Pre-Go)" ;;
		-h|--help|"") _bm_usage ;;
		*)
			local target="${_bookmarks[$1]}"
			if [[ -d "$target" ]]; then
				cd "$target" || return 1
				echo -e "${_BM_C_BLUE}Jumped to:${_BM_C_NONE} $target"
			else
				echo -e "${_BM_C_RED}Error:${_BM_C_NONE} Bookmark '$1' invalid or directory missing"
				return 1
			fi
			;;
	esac

	# Sync back to disk if modified
	[[ $_modified -eq 1 ]] && _bm_save
}

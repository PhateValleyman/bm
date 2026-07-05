#!/ffp/bin/bash

# /ffp/etc/profile.d/bm.sh

# bm - Bookmark Manager function
# This function provides quick access to saved directories

# Color codes
RED='\033[01;31m'
GREEN='\033[01;32m'
BLUE='\033[01;34m'
YELLOW='\033[01;33m'
CYAN='\033[01;36m'
NONE='\033[0m'

# Determine bookmarks file location
SDIRS="${SDIRS:-}"
PREFIX="${PREFIX:-/ffp}"
BOOKMARKS_FILE="${SDIRS:-${PREFIX}/etc/sdirs}"

# Ensure bookmarks file exists
mkdir -p "$(dirname "$BOOKMARKS_FILE")"
touch "$BOOKMARKS_FILE"

bm() {

    # Print usage information
    print_usage() {
        echo -e "Usage: ${RED}bm${NONE} [${GREEN}option${NONE}] <${YELLOW}bookmark${NONE}>"
        echo " "
        echo "Quick access to saved directories"
        echo " "
        echo -e "${RED}bm${NONE} <${YELLOW}bookmark${NONE}>             - ${BLUE}Go to directory${NONE} '${YELLOW}bookmark${NONE}'"
        echo -e "${RED}bm${NONE} ${GREEN}-a${NONE},${GREEN}--add${NONE} <${YELLOW}bookmark${NONE}>    - ${BLUE}Add bookmark${NONE} '${YELLOW}bookmark${NONE}'"
        echo -e "${RED}bm${NONE} ${GREEN}-g${NONE},${GREEN}--go${NONE} <${YELLOW}bookmark${NONE}>     - ${BLUE}Go to directory${NONE} '${YELLOW}bookmark${NONE}'"
        echo -e "${RED}bm${NONE} ${GREEN}-p${NONE},${GREEN}--print${NONE} <${YELLOW}bookmark${NONE}>  - ${BLUE}Show directory${NONE} '${YELLOW}bookmark${NONE}'"
        echo -e "${RED}bm${NONE} ${GREEN}-d${NONE},${GREEN}--delete${NONE} <${YELLOW}bookmark${NONE}> - ${BLUE}Delete bookmark${NONE} '${YELLOW}bookmark${NONE}'"
        echo -e "${RED}bm${NONE} ${GREEN}-l${NONE},${GREEN}--list${NONE}              - ${BLUE}Show available bookmarks${NONE}"
        echo -e "${RED}bm${NONE} ${GREEN}-h${NONE},${GREEN}--help${NONE}              - ${BLUE}Show usage information${NONE}"
        echo -e "${RED}bm${NONE} ${GREEN}-v${NONE},${GREEN}--version${NONE}           - ${BLUE}Show version${NONE}"
        echo -e "${RED}bm${NONE} ${GREEN}-c${NONE},${GREEN}--completion${NONE}        - ${BLUE}Generate bash completion script${NONE}"
        echo " "
    }

    # Print version information
    print_version() {
        echo "bm v1.3"
        echo "by PhateValleyman"
        echo "Jonas.Ned@outlook.com"
    }

    # Validate bookmark name
    isValidBookmarkName() {
        local name="$1"

        if [[ -z "$name" ]]; then
            return 1
        fi

        if [[ ! "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
            return 1
        fi

        return 0
    }

    # Read bookmarks from file
    readBookmarks() {
        while IFS= read -r line; do
            if [[ "$line" =~ ^export\ DIR_([^=]+)=\"(.*)\"$ ]]; then
                echo "${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
            fi
        done < "$BOOKMARKS_FILE"
    }

    # Write bookmarks to file
    writeBookmarks() {
        local bookmarksStr="$1"
        > "$BOOKMARKS_FILE"

        declare -A bookmarks

        while IFS= read -r line; do
            if [[ "$line" =~ ^([^:]+):(.*)$ ]]; then
                bookmarks["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
            fi
        done <<< "$bookmarksStr"

        for name in "${!bookmarks[@]}"; do
            echo "export DIR_${name}=\"${bookmarks[$name]}\"" >> "$BOOKMARKS_FILE"
        done
    }

    # Add a bookmark
    addBookmark() {
        local name="$1"

        if ! isValidBookmarkName "$name"; then
            echo -e "${RED}Invalid bookmark name${NONE}"
            return 1
        fi

        local curDir="$(pwd)"
        local bookmarksStr="$(readBookmarks)"

        if grep -q "^$name:" <<< "$bookmarksStr"; then
            echo -e "${YELLOW}Bookmark '$name' already exists, updating...${NONE}"
            bookmarksStr="$(grep -v "^$name:" <<< "$bookmarksStr")"
        fi

        bookmarksStr+=$'\n'"$name:$curDir"
        writeBookmarks "$bookmarksStr"
    }

    # Delete a bookmark
    deleteBookmark() {
        local name="$1"

        if ! isValidBookmarkName "$name"; then
            echo -e "${RED}Invalid bookmark name${NONE}"
            return 1
        fi

        local bookmarksStr="$(readBookmarks)"

        if ! grep -q "^$name:" <<< "$bookmarksStr"; then
            echo -e "${RED}Bookmark '${name}' does not exist${NONE}"
            return 1
        fi

        bookmarksStr="$(grep -v "^$name:" <<< "$bookmarksStr")"
        writeBookmarks "$bookmarksStr"
    }

    # Go to a bookmarked directory
    goToBookmark() {
        local name="$1"
        local bookmarksStr="$(readBookmarks)"

        local dir="$(grep "^$name:" <<< "$bookmarksStr" | cut -d: -f2-)"

        if [[ -z "$dir" ]]; then
            echo -e "${RED}WARNING: Bookmark '${name}' does not exist${NONE}"
            return 1
        fi

        if [[ ! -d "$dir" ]]; then
            echo -e "${RED}WARNING: Directory '${dir}' does not exist${NONE}"
            return 1
        fi

        cd "$dir"
        echo "Changed to directory: $dir"
    }

    # Print a bookmarked directory
    printBookmark() {
        local name="$1"
        local bookmarksStr="$(readBookmarks)"

        local dir="$(grep "^$name:" <<< "$bookmarksStr" | cut -d: -f2-)"

        if [[ -z "$dir" ]]; then
            echo -e "${RED}Bookmark '${name}' does not exist${NONE}"
            return 1
        fi

        echo "$dir"
    }

    # List all bookmarks
    listBookmarks() {
        local bookmarksStr="$(readBookmarks)"

        echo -e "     ${GREEN}Saved bookmarks${NONE}:"
        echo " "

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local name="${line%%:*}"
            local path="${line#*:}"
            printf "${YELLOW}%-20s${NONE} %s\n" "$name" "$path"
        done <<< "$(echo "$bookmarksStr" | sort)"
    }

    # Generate completion script (FIXED)
    generateCompletionScript() {
        cat << 'EOF'
_bm() {
    # Current word
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Previous word
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Options
    opts="-a --add -d --delete -g --go -p --print -l --list -h --help -v --version -c --completion"

    # Bookmarks file
    bookmarks_file="${SDIRS:-${PREFIX:-/ffp}/etc/sdirs}"

    # Load bookmark names only (NO PATHS)
    bookmarks=()
    if [[ -f "$bookmarks_file" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^export\ DIR_([^=]+)= ]] && bookmarks+=("${BASH_REMATCH[1]}")
        done < "$bookmarks_file"
    fi

    case "$prev" in
        -a|--add|-d|--delete|-g|--go|-p|--print)
            COMPREPLY=( $(compgen -W "${bookmarks[*]}" -- "$cur") )
            ;;
        *)
            COMPREPLY=( $(compgen -W "$opts ${bookmarks[*]}" -- "$cur") )
            ;;
    esac
}
complete -F _bm bm
EOF
    }

    case "$1" in
        -a|--add) [[ -n "$2" ]] && addBookmark "$2" ;;
        -d|--delete) [[ -n "$2" ]] && deleteBookmark "$2" ;;
        -g|--go) [[ -n "$2" ]] && goToBookmark "$2" ;;
        -p|--print) [[ -n "$2" ]] && printBookmark "$2" ;;
        -l|--list) listBookmarks ;;
        -v|--version) print_version ;;
        -c|--completion) generateCompletionScript ;;
        -h|--help|"") print_usage ;;
        *) goToBookmark "$1" ;;
    esac
}

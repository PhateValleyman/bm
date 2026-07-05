# bm - Bookmark Manager

A lightweight bash function for quick access to frequently used directories. Save, navigate to, and manage directory bookmarks with ease.

**Version:** 1.3
**Author:** PhateValleyman | **Email:** Jonas.Ned@outlook.com

---

## Overview
`bm` is a simple yet powerful directory bookmark manager that integrates seamlessly into your bash shell. Instead of typing long paths or using `cd` repeatedly, create bookmarks for your favorite directories and jump to them instantly.

---

## Installation
1. Source the `bm.bash` file in your shell profile (`.bashrc`, `.bash_profile`, or `.profile`):
   ```bash
   source /path/to/bm.bash
   ```
   Or copy the function into your shell configuration file directly.

2. The script automatically creates a bookmarks file at:
   - `$SDIRS` (if the environment variable is set)
   - `$PREFIX/etc/sdirs` (if `PREFIX` is set, defaults to `/ffp`)

---

## Usage

### Basic Commands

#### Jump to a Bookmark
```bash
bm <bookmark>
```
Navigates to the directory associated with the bookmark.

#### Add a Bookmark
```bash
bm -a <bookmark>
# or
bm --add <bookmark>
```
Creates a bookmark for the current working directory.

#### Go to a Bookmark
```bash
bm -g <bookmark>
# or
bm --go <bookmark>
```
Explicitly navigate to a bookmarked directory (same as `bm <bookmark>`).

#### Print a Bookmark Path
```bash
bm -p <bookmark>
# or
bm --print <bookmark>
```
Displays the full path of a bookmark without changing directories.

#### Delete a Bookmark
```bash
bm -d <bookmark>
# or
bm --delete <bookmark>
```
Removes a bookmark from your saved list.

#### List All Bookmarks
```bash
bm -l
# or
bm --list
```
Displays all saved bookmarks with their associated paths in alphabetical order.

#### Show Help
```bash
bm -h
# or
bm --help
```
Displays all available commands and usage information.

#### Show Version
```bash
bm -v
# or
bm --version
```
Displays the current version and author information.

#### Generate Bash Completion Script
```bash
bm -c
# or
bm --completion
```
Outputs a bash completion script for use with the `complete` command.

---

## Bookmark Naming Rules
Bookmark names must:
- Contain only alphanumeric characters and underscores (`a-z`, `A-Z`, `0-9`, `_`)
- Not be empty
- Not contain spaces or special characters

**Valid names:** `work`, `project_2024`, `MyDocuments`
**Invalid names:** `work-project`, `my documents`, `docs@home`

---

## Configuration

### Environment Variables
- **`SDIRS`** - Full path to store the bookmarks file.
- **`PREFIX`** - Base directory for default storage. Defaults to `/ffp`.

```bash
export SDIRS="/home/user/.config/bm"
source bm.bash
```

---

## Features
- ✅ **Lightweight** - Pure bash, no dependencies
- ✅ **Fast** - Instantly jump between directories
- ✅ **Persistent** - Bookmarks saved across sessions
- ✅ **Colored Output** - Enhanced readability
- ✅ **Bash Completion** - Auto-complete support
- ✅ **Error Handling** - Name and path validation
- ✅ **Flexible** - Custom bookmark storage

---

## Examples

### Workflow
```bash
cd ~/Developer/projects
bm -a projects          # Add bookmark
bm projects             # Jump to directory
bm -l                   # List all bookmarks
bm -p projects          # Print path
bm -d projects          # Delete bookmark
```

### Bash Completion
```bash
# Add to your .bashrc:
eval "$(bm --completion)"

# Then use:
bm proj<TAB>  # Auto-completes to "projects"
```

---

## File Format
Bookmarks are stored as bash export statements:
```bash
export DIR_work="/home/user/Documents/work"
export DIR_projects="/home/user/Developer/projects"
```

---

## Troubleshooting
- **Bookmark doesn't work** - Check with `bm -l`, verify bookmark name is valid (alphanumeric + underscore only).
- **Bookmarks file corrupted** - Delete and recreate bookmarks (default: `/ffp/etc/sdirs`).
- **Directory not found** - Script warns if target directory no longer exists.

---

## License
Created by PhateValleyman | Jonas.Ned@outlook.com

---

## Changelog

### v1.3
- Fixed bash completion script generation
- Enhanced error handling for invalid bookmark names
- Improved directory existence validation
- Better handling of paths with special characters

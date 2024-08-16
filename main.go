package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	Red    = "\033[01;31m"
	Green  = "\033[01;32m"
	Blue   = "\033[01;34m"
	Yellow = "\033[01;33m"
	Cyan   = "\033[01;36m"
	None   = "\033[0m"
)

var bookmarksFile string

func init() {
	bookmarksFile = os.Getenv("SDIRS")
	if bookmarksFile == "" {
		prefix := os.Getenv("PREFIX")
		if prefix == "" {
			prefix = "/data/data/com.termux/files/usr"
		}
		bookmarksFile = filepath.Join(prefix, "etc", "sdirs")
	}

	if _, err := os.Stat(bookmarksFile); os.IsNotExist(err) {
		if _, err := os.Create(bookmarksFile); err != nil {
			panic(err)
		}
	}
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		return
	}

	switch os.Args[1] {
	case "-a", "--add":
		if len(os.Args) < 3 {
			fmt.Println("Missing bookmark name")
			printUsage()
		} else {
			addBookmark(os.Args[2])
		}
	case "-d", "--delete":
		if len(os.Args) < 3 {
			fmt.Println("Missing bookmark name")
			printUsage()
		} else {
			deleteBookmark(os.Args[2])
		}
	case "-g", "--go":
		if len(os.Args) < 3 {
			fmt.Println("Missing bookmark name")
			printUsage()
		} else {
			goToBookmark(os.Args[2])
		}
	case "-p", "--print":
		if len(os.Args) < 3 {
			fmt.Println("Missing bookmark name")
			printUsage()
		} else {
			printBookmark(os.Args[2])
		}
	case "-l", "--list":
		listBookmarks()
	case "-h", "--help":
		printUsage()
	case "-v", "--version":
		printVersion()
	case "-c", "--completion":
		if len(os.Args) == 2 {
			fmt.Println(generateCompletionScript())
		} else if len(os.Args) == 3 {
			err := saveCompletionScript(os.Args[2])
			if err != nil {
				fmt.Println("Error saving completion script:", err)
			} else {
				fmt.Println("Completion script saved to", os.Args[2])
			}
		} else {
			fmt.Println("Invalid usage of the completion option.")
			printUsage()
		}
	default:
		if len(os.Args[1]) > 0 {
			goToBookmark(os.Args[1])
		} else {
			printUsage()
		}
	}
}

func printUsage() {
	fmt.Printf("Usage: %sbm%s [%soption%s] <%sbookmark%s>\n", Red, None, Green, None, Yellow, None)
	fmt.Println(" ")
	fmt.Println("Quick access to saved directories")
	fmt.Println(" ")
	fmt.Printf("%sbm%s <%sbookmark%s>             - %sGo to directory%s '%sbookmark%s'\n", Red, None, Yellow, None, Blue, None, Yellow, None)
	fmt.Printf("%sbm%s %s-a%s,%s--add%s <%sbookmark%s>    - %sAdd bookmark%s '%sbookmark%s'\n", Red, None, Green, None, Green, None, Yellow, None, Blue, None, Yellow, None)
	fmt.Printf("%sbm%s %s-g%s,%s--go%s <%sbookmark%s>     - %sGo to directory%s '%sbookmark%s'\n", Red, None, Green, None, Green, None, Yellow, None, Blue, None, Yellow, None)
	fmt.Printf("%sbm%s %s-p%s,%s--print%s <%sbookmark%s>  - %sShow directory%s '%sbookmark%s'\n", Red, None, Green, None, Green, None, Yellow, None, Blue, None, Yellow, None)
	fmt.Printf("%sbm%s %s-d%s,%s--delete%s <%sbookmark%s> - %sDelete bookmark%s '%sbookmark%s'\n", Red, None, Green, None, Green, None, Yellow, None, Blue, None, Yellow, None)
	fmt.Printf("%sbm%s %s-l%s,%s--list%s              - %sShow available bookmarks%s\n", Red, None, Green, None, Green, None, Blue, None)
	fmt.Println(" ")
	fmt.Printf("%sbm%s %s-h%s,%s--help%s              - %sShow usage information%s\n", Red, None, Green, None, Green, None, Blue, None)
	fmt.Printf("%sbm%s %s-v%s,%s--version%s           - %sShow version%s\n", Red, None, Green, None, Green, None, Blue, None)
	fmt.Printf("%sbm%s %s-c%s,%s--completion%s [%spath%s] - %sGenerate bash completion script%s\n", Red, None, Green, None, Green, None, Yellow, None, Blue, None)
	fmt.Println(" ")
}

func printVersion() {
	fmt.Println("bm v1.3")
	fmt.Println("by PhateValleyman")
	fmt.Println("Jonas.Ned@outlook.com")
}

func addBookmark(name string) {
	if !isValidBookmarkName(name) {
		fmt.Println("Invalid bookmark name")
		return
	}
	curDir, err := os.Getwd()
	if err != nil {
		fmt.Println("Error getting current directory:", err)
		return
	}
	bookmarks, err := readBookmarks()
	if err != nil {
		fmt.Println("Error reading bookmarks:", err)
		return
	}
	bookmarks[name] = curDir
	if err := writeBookmarks(bookmarks); err != nil {
		fmt.Println("Error saving bookmark:", err)
	}
}

func deleteBookmark(name string) {
	if !isValidBookmarkName(name) {
		fmt.Println("Invalid bookmark name")
		return
	}
	bookmarks, err := readBookmarks()
	if err != nil {
		fmt.Println("Error reading bookmarks:", err)
		return
	}
	delete(bookmarks, name)
	if err := writeBookmarks(bookmarks); err != nil {
		fmt.Println("Error deleting bookmark:", err)
	}
}

func goToBookmark(name string) {
	bookmarks, err := readBookmarks()
	if err != nil {
		fmt.Println("Error reading bookmarks:", err)
		return
	}
	dir, ok := bookmarks[name]
	if !ok {
		fmt.Printf("%sWARNING: Bookmark '%s' does not exist%s\n", Red, name, None)
		return
	}
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		fmt.Printf("%sWARNING: Directory '%s' does not exist%s\n", Red, dir, None)
		return
	}
	if err := os.Chdir(dir); err != nil {
		fmt.Println("Error changing directory:", err)
		return
	}
	cmd := exec.Command("bash")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Println("Error executing shell:", err)
	}
}

func printBookmark(name string) {
	bookmarks, err := readBookmarks()
	if err != nil {
		fmt.Println("Error reading bookmarks:", err)
		return
	}
	dir, ok := bookmarks[name]
	if !ok {
		fmt.Printf("%sBookmark '%s' does not exist%s\n", Red, name, None)
		return
	}
	fmt.Println(dir)
}

func listBookmarks() {
	bookmarks, err := readBookmarks()
	if err != nil {
		fmt.Println("Error reading bookmarks:", err)
		return
	}
	fmt.Printf("     %sSaved bookmarks%s:\n", Green, None)
	fmt.Println(" ")
	for name, dir := range bookmarks {
		fmt.Printf("%s%-20s%s %s\n", Yellow, name, None, dir)
	}
}

func isValidBookmarkName(name string) bool {
	if name == "" {
		return false
	}
	for _, r := range name {
		if !(r == '_' || ('A' <= r && r <= 'Z') || ('a' <= r && r <= 'z') || ('0' <= r && r <= '9')) {
			return false
		}
	}
	return true
}

func readBookmarks() (map[string]string, error) {
	file, err := os.Open(bookmarksFile)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	bookmarks := make(map[string]string)
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "export DIR_") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				name := strings.TrimPrefix(parts[0], "export DIR_")
				dir := strings.Trim(parts[1], "\"")
				bookmarks[name] = dir
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return bookmarks, nil
}

func writeBookmarks(bookmarks map[string]string) error {
	file, err := os.Create(bookmarksFile)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	for name, dir := range bookmarks {
		if _, err := writer.WriteString(fmt.Sprintf("export DIR_%s=\"%s\"\n", name, dir)); err != nil {
			return err
		}
	}
	return writer.Flush()
}

// Generates the bash completion script
func generateCompletionScript() string {
	return `_bm() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-a --add -d --delete -g --go -p --print -l --list -h --help -v --version -c --completion"

    case "${prev}" in
        -g|--go|-d|--delete|-p|--print)
            local bookmarks=$(awk -F '=' '/^export DIR_/ {gsub(/^export DIR_/, "", $1); print $1}' "` + bookmarksFile + `")
            COMPREPLY=( $(compgen -W "${bookmarks}" -- ${cur}) )
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _bm bm`
}

// Saves the bash completion script to a specified file
func saveCompletionScript(path string) error {
	script := generateCompletionScript()
	file, err := os.Create(filepath.Join(path, "bm.bash"))
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.WriteString(script)
	return err
}

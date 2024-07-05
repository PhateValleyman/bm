package main

import (
	"bufio"
//	"errors"
	"fmt"
	"os"
	"os/exec"
//	"os/user"
	"path/filepath"
	"strings"
)

// Constants for color codes
const (
	Red    = "\033[01;31m"
	Green  = "\033[01;32m"
	Blue   = "\033[01;34m"
	Yellow = "\033[01;33m"
	Cyan   = "\033[01;36m"
	None   = "\033[0m"
)

// Bookmarks file path
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

// Main function to handle commands
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
	default:
		if len(os.Args[1]) > 0 {
			goToBookmark(os.Args[1])
		} else {
			printUsage()
		}
	}
}

// Print usage information
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
	fmt.Println(" ")
}

// Print version information
func printVersion() {
	fmt.Println(" ")
	fmt.Println("bm v1.2")
	fmt.Println("by PhateValleyman")
	fmt.Println("Jonas.Ned@outlook.com")
	fmt.Println(" ")
}

// Save the current directory to bookmarks
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

// Delete a bookmark
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

// Jump to a bookmark
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

// Print a bookmark
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

// List bookmarks with directory names
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

// Validate bookmark name
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

// Read bookmarks from file
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

// Write bookmarks to file
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

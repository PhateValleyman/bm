package main

import (
	"flag"
	"fmt"
	"os"
	"sort"

	"github.com/phatevalleyman/bm/internal/config"
	"github.com/phatevalleyman/bm/internal/storage"
	"github.com/phatevalleyman/bm/internal/ui"
)

var version = "1.5"

func main() {
	// Flags
	customFile := flag.String("f", "", "Use custom bookmarks file")
	add := flag.String("a", "", "Add current directory")
	deleteFlag := flag.String("d", "", "Remove bookmark")
	list := flag.Bool("l", false, "List all bookmarks")
	printPath := flag.String("p", "", "Show bookmark path")
	showVersion := flag.Bool("v", false, "Show version information")
	completion := flag.Bool("c", false, "Generate completion script")

	// Custom usage
	flag.Usage = func() {
		fmt.Printf("Usage: %s [%s] [%s] <%s>\n", ui.Red("bm"), ui.Cyan("global options"), ui.Green("option"), ui.Yellow("bookmark"))
		fmt.Println("\nGlobal Options:")
		fmt.Printf("  %s    <path>  Use custom bookmarks file\n", ui.Cyan("-f, --file"))
		fmt.Println("\nOptions:")
		fmt.Printf("  %s     <name>  Add current directory\n", ui.Green("-a, --add"))
		fmt.Printf("  %s  <name>  Remove bookmark\n", ui.Green("-d, --delete"))
		fmt.Printf("  %s            List all bookmarks\n", ui.Green("-l, --list"))
		fmt.Printf("  %s   <name>  Show bookmark path\n", ui.Green("-p, --print"))
		fmt.Printf("  %s      Generate completion script\n", ui.Green("-c, --completion"))
		fmt.Printf("  %s         Show version information\n", ui.Green("-v, --version"))
		fmt.Printf("  %s            Show this help message\n", ui.Green("-h, --help"))
	}

	// Handle long flags manually since standard 'flag' doesn't support them well
	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--file": args[i] = "-f"
		case "--add": args[i] = "-a"
		case "--delete": args[i] = "-d"
		case "--list": args[i] = "-l"
		case "--print": args[i] = "-p"
		case "--version": args[i] = "-v"
		case "--completion": args[i] = "-c"
		case "--help": args[i] = "-h"
		}
	}
	
	flag.CommandLine.Parse(args)

	cfg := config.LoadConfig(*customFile)
	s := storage.NewStorage(cfg.BookmarkFile)
	if err := s.Load(); err != nil {
		ui.Err("Failed to load bookmarks: %v", err)
		os.Exit(1)
	}

	if *showVersion {
		fmt.Printf("bm v%s\nby PhateValleyman\nJonas.Ned@outlook.com\n", version)
		return
	}

	if *list {
		ui.Ok("     Saved bookmarks:")
		fmt.Println()
		var names []string
		for name := range s.Bookmarks {
			names = append(names, name)
		}
		sort.Strings(names)
		for _, name := range names {
			fmt.Printf("  %s %s\n", ui.Yellow(fmt.Sprintf("%-20s", name)), s.Bookmarks[name])
		}
		fmt.Println()
		return
	}

	if *add != "" {
		pwd, _ := os.Getwd()
		s.Bookmarks[*add] = pwd
		if err := s.Save(); err != nil {
			ui.Err("Failed to save: %v", err)
			os.Exit(1)
		}
		ui.Info("Added: %s -> %s (File: %s)", *add, pwd, cfg.BookmarkFile)
		return
	}

	if *deleteFlag != "" {
		if _, ok := s.Bookmarks[*deleteFlag]; ok {
			delete(s.Bookmarks, *deleteFlag)
			if err := s.Save(); err != nil {
				ui.Err("Failed to save: %v", err)
				os.Exit(1)
			}
			ui.Err("Deleted: %s (File: %s)", *deleteFlag, cfg.BookmarkFile)
		} else {
			ui.Err("Bookmark '%s' not found.", *deleteFlag)
			os.Exit(1)
		}
		return
	}

	if *printPath != "" {
		if path, ok := s.Bookmarks[*printPath]; ok {
			fmt.Println(path)
		} else {
			ui.Err("Bookmark '%s' not found.", *printPath)
			os.Exit(1)
		}
		return
	}
	
	if *completion {
		fmt.Println(`_bm_completion() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prev="${COMP_WORDS[COMP_CWORD-1]}"
	local opts="-a --add -d --delete -l --list -p --print -h --help -c --completion -v --version -f --file"
	
	local bfile="${SDIRS:-$HOME/.config/bm/bookmarks}"
	for ((i=1; i < ${#COMP_WORDS[@]}; i++)); do
		if [[ "${COMP_WORDS[i]}" == "-f" || "${COMP_WORDS[i]}" == "--file" ]]; then
			[[ -n "${COMP_WORDS[i+1]}" ]] && bfile="${COMP_WORDS[i+1]}"
			break
		fi
	done

	if [[ "$prev" == "-f" || "$prev" == "--file" ]]; then
		COMPREPLY=( $(compgen -f -- "$cur") )
		return 0
	fi

	local bookmarks=""
	if [[ -f "$bfile" ]]; then
		bookmarks=$(grep -oE 'DIR_[a-zA-Z0-9_]+' "$bfile" | cut -d_ -f2-)
	fi
	
	COMPREPLY=( $(compgen -W "$opts $bookmarks" -- "$cur") )
}
complete -F _bm_completion bm`)
		return
	}

	// Default: Jump (print path for shell wrapper to cd)
	if flag.NArg() > 0 {
		name := flag.Arg(0)
		if path, ok := s.Bookmarks[name]; ok {
			if info, err := os.Stat(path); err == nil && info.IsDir() {
				fmt.Print(path)
				return
			} else {
				ui.Err("Target directory '%s' no longer exists.", path)
				os.Exit(1)
			}
		} else {
			ui.Err("Unknown command or bookmark: '%s'", name)
			os.Exit(1)
		}
	}

	flag.Usage()
}

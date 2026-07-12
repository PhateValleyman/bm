package storage

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
)

type Storage struct {
	FilePath  string
	Bookmarks map[string]string
}

func NewStorage(path string) *Storage {
	return &Storage{
		FilePath:  path,
		Bookmarks: make(map[string]string),
	}
}

func (s *Storage) Load() error {
	file, err := os.Open(s.FilePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	defer file.Close()

	re := regexp.MustCompile(`^export\ DIR_([^=]+)="(.*)"$`)
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		matches := re.FindStringSubmatch(line)
		if len(matches) == 3 {
			s.Bookmarks[matches[1]] = matches[2]
		}
	}
	return scanner.Err()
}

func (s *Storage) Save() error {
	dir := filepath.Dir(s.FilePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	tmpFile := s.FilePath + ".tmp"
	file, err := os.Create(tmpFile)
	if err != nil {
		return err
	}
	defer file.Close()

	var names []string
	for name := range s.Bookmarks {
		names = append(names, name)
	}
	sort.Strings(names)

	for _, name := range names {
		_, err := fmt.Fprintf(file, "export DIR_%s=\"%s\"\n", name, s.Bookmarks[name])
		if err != nil {
			return err
		}
	}

	return os.Rename(tmpFile, s.FilePath)
}

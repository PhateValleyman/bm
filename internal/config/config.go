package config

import (
	"os"
	"path/filepath"
)

type Config struct {
	BookmarkFile string
}

func LoadConfig(customFile string) *Config {
	if customFile != "" {
		return &Config{BookmarkFile: customFile}
	}

	// Default from env or ~/.config/bm/bookmarks
	sdirs := os.Getenv("SDIRS")
	if sdirs != "" {
		return &Config{BookmarkFile: sdirs}
	}

	home, _ := os.UserHomeDir()
	return &Config{
		BookmarkFile: filepath.Join(home, ".config", "bm", "bookmarks"),
	}
}

package ui

import (
	"fmt"
	"os"
)

const (
	ColorRed    = "\033[01;31m"
	ColorGreen  = "\033[01;32m"
	ColorBlue   = "\033[01;34m"
	ColorYellow = "\033[01;33m"
	ColorCyan   = "\033[01;36m"
	ColorNone   = "\033[0m"
)

func Err(msg string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, ColorRed+"Error:"+ColorNone+" "+msg+"\n", args...)
}

func Warn(msg string, args ...interface{}) {
	fmt.Printf(ColorYellow+"Warning:"+ColorNone+" "+msg+"\n", args...)
}

func Info(msg string, args ...interface{}) {
	fmt.Printf(ColorBlue+msg+ColorNone+"\n", args...)
}

func Ok(msg string, args ...interface{}) {
	fmt.Printf(ColorGreen+msg+ColorNone+"\n", args...)
}

func Yellow(msg string) string {
	return ColorYellow + msg + ColorNone
}

func Green(msg string) string {
	return ColorGreen + msg + ColorNone
}

func Red(msg string) string {
	return ColorRed + msg + ColorNone
}

func Cyan(msg string) string {
	return ColorCyan + msg + ColorNone
}

func Blue(msg string) string {
	return ColorBlue + msg + ColorNone
}

package main

import (
	"bufio"
	"errors"
	"io"
	"os"
	"os/exec"
	"strings"
	"golang.org/x/term"
)

// fzfAvailable reports whether fzf is installed and we have a TTY to use it.
func fzfAvailable() bool {
	if !commandExists("fzf") {
		return false
	}
	return term.IsTerminal(int(os.Stdin.Fd()))
}

// fzfSelect shows items in fzf and returns the chosen line (multi=false) or lines.
func fzfSelect(items []string, prompt string, multi bool) ([]string, error) {
	if !fzfAvailable() {
		return nil, errors.New(getMsg(msgErrNoFzf))
	}
	args := []string{"--height=40%", "--layout=reverse", "--border", "--prompt=" + prompt}
	if multi {
		args = append(args, "--multi")
	}
	cmd := exec.Command("fzf", args...)
	cmd.Stdin = strings.NewReader(strings.Join(items, "\n"))
	cmd.Stderr = io.Discard
	out, err := cmd.Output()
	if err != nil {
		// fzf exits 130 on ESC/cancel; treat as no selection.
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
			return nil, nil
		}
		return nil, err
	}
	var selected []string
	sc := bufio.NewScanner(strings.NewReader(string(out)))
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line != "" {
			selected = append(selected, line)
		}
	}
	return selected, nil
}

// fzfSelectOne is a convenience wrapper returning a single selection or "".
func fzfSelectOne(items []string, prompt string) (string, error) {
	sel, err := fzfSelect(items, prompt, false)
	if err != nil || len(sel) == 0 {
		return "", err
	}
	return sel[0], nil
}

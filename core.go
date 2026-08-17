package main

import (
	"errors"
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

// Config holds resolved runtime configuration.
type Config struct {
	Workspace string
	Editor    string
	Lang      string // "tr" or "en"
	Msgs      map[msgKey]string
}

// Global config populated in main().
var cfg Config

// detectLang returns "tr" if the system locale looks Turkish, else "en".
func detectLang() string {
	lang := os.Getenv("LANG")
	if lang == "" {
		lang = os.Getenv("LC_ALL")
	}
	if strings.HasPrefix(strings.ToLower(lang), "tr") {
		return "tr"
	}
	return "en"
}

// getMsg formats a localized message. cmdType is used for name-missing errors.
func getMsg(key msgKey, args ...string) string {
	format, ok := cfg.Msgs[key]
	if !ok {
		return string(key)
	}
	if len(args) == 0 {
		return format
	}
	return fmt.Sprintf(format, stringSliceToIface(args)...)
}

func stringSliceToIface(s []string) []interface{} {
	out := make([]interface{}, len(s))
	for i, v := range s {
		out[i] = v
	}
	return out
}

// loadConfig resolves workspace, editor and language from config file then env vars.
func loadConfig() Config {
	// Start from the persisted config file, then let explicit env vars override.
	fileCfg, _ := readConfigFile()

	ws := os.Getenv("PROJECT_WORKSPACE")
	if ws == "" {
		if v, ok := fileCfg["workspace"]; ok && v != "" {
			ws = expandPath(v)
		}
	}
	if ws == "" {
		ws = filepath.Join(os.Getenv("HOME"), "workspace")
	}

	editor := os.Getenv("VISUAL")
	if editor == "" {
		editor = os.Getenv("EDITOR")
	}
	if editor == "" {
		if v, ok := fileCfg["editor"]; ok && v != "" {
			editor = v
		}
	}

	lang := detectLang()
	c := Config{
		Workspace: ws,
		Lang:      lang,
		Msgs:      messages(lang),
	}
	if editor != "" {
		c.Editor = editor
	} else {
		c.Editor = detectEditor()
	}
	return c
}

// detectEditor resolves the user's preferred editor, falling back to a list.
func detectEditor() string {
	for _, e := range []string{os.Getenv("VISUAL"), os.Getenv("EDITOR")} {
		if e != "" && commandExists(e) {
			return e
		}
	}
	for _, e := range []string{"code", "vim", "nvim", "nano", "gedit", "vi"} {
		if commandExists(e) {
			return e
		}
	}
	return "vi"
}

// commandExists reports whether name is on PATH.
func commandExists(name string) bool {
	if name == "" {
		return false
	}
	_, err := exec.LookPath(name)
	return err == nil
}

// ensureWorkspace creates the workspace directory if missing and returns an error otherwise.
func ensureWorkspace() error {
	if _, err := os.Stat(cfg.Workspace); err != nil {
		if os.IsNotExist(err) {
			return errors.New(getMsg(msgErrBaseDirNotExists))
		}
		return err
	}
	return nil
}

// listProjects returns project directory names sorted by modification time (newest first).
func listProjects() ([]string, error) {
	entries, err := os.ReadDir(cfg.Workspace)
	if err != nil {
		return nil, err
	}
	type proj struct {
		name string
		mod  int64
	}
	var projs []proj
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue
		}
		projs = append(projs, proj{name: e.Name(), mod: info.ModTime().Unix()})
	}
	sort.Slice(projs, func(i, j int) bool { return projs[i].mod > projs[j].mod })
	names := make([]string, len(projs))
	for i, p := range projs {
		names[i] = p.name
	}
	return names, nil
}

// printCDMarker prints the special marker the shell wrapper reads to change directories.
func printCDMarker(path string) {
	fmt.Printf("\n__PROJECT_TOOLKIT_CD__:%s\n", path)
}

// openEditor opens target in the user's editor. For GUI editors it backgrounds the process.
func openEditor(target string) error {
	ed := cfg.Editor
	if !commandExists(ed) {
		return errors.New(getMsg(msgErrCodeEditorNotFound, ed))
	}
	switch {
	case ed == "vim" || ed == "nvim" || ed == "nano" || ed == "vi":
		// Blocking terminal editor: run in foreground so the user edits then returns.
		cmd := exec.Command(ed, target)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	default:
		// GUI editor: launch detached.
		cmd := exec.Command(ed, target)
		cmd.Stdout = nil
		cmd.Stderr = nil
		if err := cmd.Start(); err != nil {
			return err
		}
		return nil
	}
}

// confirmYes reads a y/n answer from stdin.
func confirmYes(prompt string) bool {
	fmt.Print(prompt)
	reader := bufio.NewReader(os.Stdin)
	line, err := reader.ReadString('\n')
	if err != nil {
		return false
	}
	line = strings.TrimSpace(strings.ToLower(line))
	return line == "y" || line == "yes"
}

// validProjectName rejects path-hostile characters.
func validProjectName(name string) bool {
	return !strings.ContainsAny(name, "/\\:*?\"'[]")
}

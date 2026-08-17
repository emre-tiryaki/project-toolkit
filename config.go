package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// configFile returns the path to the toolkit config file.
func configFile() string {
	return filepath.Join(configHome(), "project-toolkit", "config")
}

// validConfigKeys are the keys accepted by `project config set`.
var validConfigKeys = map[string]bool{
	"workspace":     true,
	"github_user":   true,
	"github_token":  true,
	"editor":        true,
	"templates_dir": true,
}

// configEnvName maps a config key to the env var the toolkit reads.
var configEnvName = map[string]string{
	"workspace":     "PROJECT_WORKSPACE",
	"github_user":   "GITHUB_USER",
	"github_token":  "GITHUB_TOKEN",
	"editor":        "VISUAL",
	"templates_dir": "PROJECT_TEMPLATES_DIR",
}

// readConfigFile parses the config file into a key->value map.
func readConfigFile() (map[string]string, error) {
	m := map[string]string{}
	data, err := os.ReadFile(configFile())
	if err != nil {
		if os.IsNotExist(err) {
			return m, nil
		}
		return m, err
	}
	sc := bufio.NewScanner(strings.NewReader(string(data)))
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		k := strings.TrimSpace(parts[0])
		v := strings.TrimSpace(parts[1])
		v = strings.Trim(v, `"'`)
		m[k] = v
	}
	return m, sc.Err()
}

// writeConfigFile writes the key->value map back, preserving key order from validConfigKeys.
func writeConfigFile(m map[string]string) error {
	dir := filepath.Dir(configFile())
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	var b strings.Builder
	b.WriteString("# Project Toolkit configuration\n")
	b.WriteString("# Managed by `project config`. Keys: workspace, github_user, github_token, editor, templates_dir\n\n")
	// Preserve a stable order.
	order := []string{"workspace", "github_user", "github_token", "editor", "templates_dir"}
	for _, k := range order {
		if v, ok := m[k]; ok && v != "" {
			b.WriteString(fmt.Sprintf("%s=%s\n", k, v))
		}
	}
	// Any extra keys.
	for k, v := range m {
		if !validConfigKeys[k] {
			continue
		}
		found := false
		for _, ok := range order {
			if ok == k {
				found = true
				break
			}
		}
		if !found && v != "" {
			b.WriteString(fmt.Sprintf("%s=%s\n", k, v))
		}
	}
	return os.WriteFile(configFile(), []byte(b.String()), 0o644)
}

// cmdConfig implements `project config [get <key> | set <key> <val> | unset <key> | list]`.
func cmdConfig(args []string) error {
	if len(args) == 0 {
		return cmdConfigList()
	}
	switch args[0] {
	case "get":
		if len(args) < 2 {
			return errors.New(getMsg(msgErrNameMissing, "config get"))
		}
		key := args[1]
		if !validConfigKeys[key] {
			return errors.New(getMsg(msgErrInvalidParam, key))
		}
		m, err := readConfigFile()
		if err != nil {
			return err
		}
		if v, ok := m[key]; ok {
			fmt.Println(v)
		} else {
			fmt.Println(getMsg(msgConfigNotSet))
		}
		return nil
	case "set":
		if len(args) < 3 {
			return errors.New(getMsg(msgErrNameMissing, "config set"))
		}
		key, val := args[1], args[2]
		if !validConfigKeys[key] {
			return errors.New(getMsg(msgErrInvalidParam, key))
		}
		// Resolve special values.
		switch key {
		case "workspace":
			val = expandPath(val)
			if err := os.MkdirAll(val, 0o755); err != nil {
				return err
			}
		}
		m, err := readConfigFile()
		if err != nil {
			return err
		}
		m[key] = val
		if err := writeConfigFile(m); err != nil {
			return err
		}
		fmt.Println(getMsg(msgConfigSet, key, val))
		fmt.Println(getMsg(msgConfigHint))
		return nil
	case "unset":
		if len(args) < 2 {
			return errors.New(getMsg(msgErrNameMissing, "config unset"))
		}
		key := args[1]
		if !validConfigKeys[key] {
			return errors.New(getMsg(msgErrInvalidParam, key))
		}
		m, err := readConfigFile()
		if err != nil {
			return err
		}
		delete(m, key)
		if err := writeConfigFile(m); err != nil {
			return err
		}
		fmt.Println(getMsg(msgConfigUnset, key))
		return nil
	case "list":
		return cmdConfigList()
	default:
		return errors.New(getMsg(msgErrInvalidParam, args[0]))
	}
}

func cmdConfigList() error {
	m, err := readConfigFile()
	if err != nil {
		return err
	}
	fmt.Println(getMsg(msgConfigListTitle))
	for _, k := range []string{"workspace", "github_user", "github_token", "editor", "templates_dir"} {
		if v, ok := m[k]; ok && v != "" {
			// Mask the token.
			if k == "github_token" {
				v = "***" + v[len(v)-4:]
			}
			fmt.Printf("  %s = %s\n", k, v)
		} else {
			fmt.Printf("  %s = %s\n", k, getMsg(msgConfigNotSet))
		}
	}
	return nil
}

func expandPath(p string) string {
	if strings.HasPrefix(p, "~/") {
		return filepath.Join(os.Getenv("HOME"), p[2:])
	}
	return p
}

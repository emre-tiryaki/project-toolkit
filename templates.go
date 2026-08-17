package main

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

//go:embed templates
var templateFS embed.FS

// templateTypes maps a user-facing template name to its embedded directory.
var templateTypes = map[string]string{
	"go":         "go",
	"node":       "node",
	"npm":        "node",
	"js":         "node",
	"javascript": "node",
	"typescript": "typescript",
	"ts":         "typescript",
	"rust":       "rust",
	"python":     "python",
	"py":         "python",
}

// userTemplateDir returns the extra user templates location, if configured.
func userTemplateDir() string {
	if d := os.Getenv("PROJECT_TEMPLATES_DIR"); d != "" {
		return d
	}
	if m, err := readConfigFile(); err == nil {
		if d := m["templates_dir"]; d != "" {
			return expandPath(d)
		}
	}
	return filepath.Join(configHome(), "project-toolkit", "templates")
}

func configHome() string {
	if d := os.Getenv("XDG_CONFIG_HOME"); d != "" {
		return d
	}
	return filepath.Join(os.Getenv("HOME"), ".config")
}

// resolveTemplate resolves a template name to a directory on disk (user override wins).
func resolveTemplate(name string) (string, bool) {
	// User template directory first.
	ud := userTemplateDir()
	if d := filepath.Join(ud, name); isDir(d) {
		return d, true
	}
	// Embedded template.
	if dir, ok := templateTypes[strings.ToLower(name)]; ok {
		return filepath.Join("templates", dir), true
	}
	return "", false
}

func isDir(p string) bool {
	info, err := os.Stat(p)
	return err == nil && info.IsDir()
}

// renderTemplate copies a template directory into target, substituting {{PROJECT_NAME}}.
func renderTemplate(templateDir, target, projectName string) error {
	// If it's a user directory on disk, copy it directly.
	if strings.HasPrefix(templateDir, "templates"+string(os.PathSeparator)) || templateDir == "templates" {
		return renderEmbedded(templateDir, target, projectName)
	}
	return renderFromDisk(templateDir, target, projectName)
}

func renderEmbedded(templateDir, target, projectName string) error {
	return fs.WalkDir(templateFS, templateDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(templateDir, path)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}
		// Render the embedded Go module stub (mod.txt) as a real go.mod.
		if rel == "mod.txt" {
			rel = "go.mod"
		}
		dest := filepath.Join(target, rel)
		if d.IsDir() {
			return os.MkdirAll(dest, 0o755)
		}
		data, err := templateFS.ReadFile(path)
		if err != nil {
			return err
		}
		content := strings.ReplaceAll(string(data), "{{PROJECT_NAME}}", projectName)
		if err := os.MkdirAll(filepath.Dir(dest), 0o755); err != nil {
			return err
		}
		return os.WriteFile(dest, []byte(content), 0o644)
	})
}

func renderFromDisk(templateDir, target, projectName string) error {
	return filepath.Walk(templateDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(templateDir, path)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}
		dest := filepath.Join(target, rel)
		if info.IsDir() {
			return os.MkdirAll(dest, 0o755)
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		content := strings.ReplaceAll(string(data), "{{PROJECT_NAME}}", projectName)
		if err := os.MkdirAll(filepath.Dir(dest), 0o755); err != nil {
			return err
		}
		return os.WriteFile(dest, []byte(content), 0o644)
	})
}

// availableTemplates returns the set of known template names (for help output).
func availableTemplates() []string {
	seen := map[string]bool{}
	var out []string
	for name := range templateTypes {
		if !seen[name] {
			seen[name] = true
			out = append(out, name)
		}
	}
	return out
}

var _ = fmt.Sprintf

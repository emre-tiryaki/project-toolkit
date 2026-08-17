package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// cmdNew creates a project directory with optional template, git, editor, clone.
func cmdNew(args []string) error {
	var name string
	initGit := false
	openEd := false
	template := ""
	cloneURL := ""

	for i := 0; i < len(args); i++ {
		a := args[i]
		switch a {
		case "-g", "--git":
			initGit = true
		case "-e", "--editor":
			openEd = true
		case "-t", "--template":
			if i+1 < len(args) {
				template = args[i+1]
				i++
			} else {
				return errors.New(getMsg(msgErrTemplateMissing))
			}
		case "-c", "--clone":
			if i+1 < len(args) {
				cloneURL = args[i+1]
				i++
			} else {
				return errors.New(getMsg(msgErrNoRepoArg))
			}
		case "-h", "--help":
			cmdHelp()
			return nil
		default:
			if strings.HasPrefix(a, "-") {
				return errors.New(getMsg(msgErrUnknownFlag, a))
			}
			if name == "" {
				name = a
			}
		}
	}

	if name == "" {
		return errors.New(getMsg(msgErrNameMissing, "new"))
	}
	if !validProjectName(name) {
		return errors.New(getMsg(msgErrInvalidParam, name))
	}

	target := fmt.Sprintf("%s/%s", cfg.Workspace, name)
	if _, err := os.Stat(target); err == nil {
		return errors.New(getMsg(msgErrExists, name))
	}

	if cloneURL != "" {
		// Clone mode: name is optional; derive from URL if not given.
		if name == "" {
			name = repoNameFromURL(cloneURL)
			target = fmt.Sprintf("%s/%s", cfg.Workspace, name)
		}
		repo := githubRepo{Name: name, CloneURL: cloneURL}
		if err := cloneRepo(repo); err != nil {
			return err
		}
		if openEd {
			_ = openEditor(target)
		}
		return nil
	}

	if err := os.MkdirAll(target, 0o755); err != nil {
		return err
	}

	if template != "" {
		dir, ok := resolveTemplate(template)
		if !ok {
			// Clean up empty dir and report.
			_ = os.Remove(target)
			return errors.New(getMsg(msgErrInvalidParam, template))
		}
		if err := renderTemplate(dir, target, name); err != nil {
			return err
		}
	}

	if initGit {
		cmd := exec.Command("git", "init", "--initial-branch=main")
		cmd.Dir = target
		cmd.Stdout = os.Stderr
		cmd.Stderr = os.Stderr
		_ = cmd.Run()
	}

	fmt.Println(getMsg(msgSuccessNew, name))
	printCDMarker(target)

	if openEd {
		_ = openEditor(target)
	}
	return nil
}

func repoNameFromURL(url string) string {
	url = strings.TrimSuffix(url, "/")
	url = strings.TrimSuffix(url, ".git")
	parts := strings.Split(url, "/")
	return parts[len(parts)-1]
}

// cmdOpen opens an existing project (or selects via fzf) in the editor.
func cmdOpen(args []string) error {
	name := strings.Join(args, " ")
	if name == "" {
		projects, err := listProjects()
		if err != nil {
			return err
		}
		if len(projects) == 0 {
			return nil
		}
		sel, err := fzfSelectOne(projects, getMsg(msgInfoSelectProject))
		if err != nil || sel == "" {
			return err
		}
		name = sel
	}
	target := fmt.Sprintf("%s/%s", cfg.Workspace, name)
	if _, err := os.Stat(target); err != nil {
		return errors.New(getMsg(msgErrNotExists, name))
	}
	printCDMarker(target)
	if err := openEditor(target); err != nil {
		return errors.New(getMsg(msgErrOpenFailed, name))
	}
	return nil
}

// cmdRm removes one or more projects, with fzf selection and confirmation.
func cmdRm(args []string) error {
	force := false
	var names []string
	for _, a := range args {
		if a == "-f" || a == "--force" {
			force = true
		} else if strings.HasPrefix(a, "-") {
			return errors.New(getMsg(msgErrUnknownFlag, a))
		} else {
			names = append(names, a)
		}
	}

	if len(names) == 0 {
		projects, err := listProjects()
		if err != nil {
			return err
		}
		if len(projects) == 0 {
			return nil
		}
		sel, err := fzfSelect(projects, getMsg(msgPromptSelectRemove), true)
		if err != nil || len(sel) == 0 {
			return err
		}
		names = sel
	}

	if !force {
		fmt.Println(getMsg(msgInfoProjectsToRemove))
		for _, n := range names {
			fmt.Printf(" - %s\n", n)
		}
		if !confirmYes(getMsg(msgConfirmRm)) {
			for _, n := range names {
				fmt.Println(getMsg(msgCancelRm, n))
			}
			return nil
		}
	}

	for _, n := range names {
		target := fmt.Sprintf("%s/%s", cfg.Workspace, n)
		if _, err := os.Stat(target); err != nil {
			fmt.Println(getMsg(msgErrNotExists, n))
			continue
		}
		if err := os.RemoveAll(target); err != nil {
			return err
		}
		fmt.Println(getMsg(msgSuccessRm, n))
	}
	return nil
}

// cmdList lists projects (fzf to open, or plain column output).
func cmdList(_ []string) error {
	projects, err := listProjects()
	if err != nil {
		return err
	}
	if fzfAvailable() {
		sel, err := fzfSelectOne(projects, getMsg(msgInfoSelectProject))
		if err == nil && sel != "" {
			target := fmt.Sprintf("%s/%s", cfg.Workspace, sel)
			printCDMarker(target)
			_ = openEditor(target)
			return nil
		}
		// On fzf error (e.g. no TTY), fall through to plain listing.
	}
	if len(projects) == 0 {
		return nil
	}
	fmt.Println(strings.Join(projects, "\n"))
	return nil
}

// cmdFind searches projects by partial name.
func cmdFind(args []string) error {
	term := strings.Join(args, " ")
	if term == "" {
		return errors.New(getMsg(msgErrNameMissing, "find"))
	}
	projects, err := listProjects()
	if err != nil {
		return err
	}
	var matches []string
	for _, p := range projects {
		if strings.Contains(strings.ToLower(p), strings.ToLower(term)) {
			matches = append(matches, p)
		}
	}
	if len(matches) == 0 {
		return nil
	}
	if fzfAvailable() {
		sel, err := fzfSelectOne(matches, getMsg(msgInfoSelectProject))
		if err == nil && sel != "" {
			target := fmt.Sprintf("%s/%s", cfg.Workspace, sel)
			printCDMarker(target)
			_ = openEditor(target)
			return nil
		}
		// fzf unavailable or errored: fall through to plain list.
	}
	fmt.Println(strings.Join(matches, "\n"))
	return nil
}

// cmdRename renames a project directory.
func cmdRename(args []string) error {
	if len(args) < 2 {
		return errors.New(getMsg(msgErrNameMissing, "rename"))
	}
	old, new := args[0], args[1]
	if !validProjectName(new) {
		return errors.New(getMsg(msgErrInvalidParam, new))
	}
	oldPath := fmt.Sprintf("%s/%s", cfg.Workspace, old)
	newPath := fmt.Sprintf("%s/%s", cfg.Workspace, new)
	if _, err := os.Stat(oldPath); err != nil {
		return errors.New(getMsg(msgErrNotExists, old))
	}
	if _, err := os.Stat(newPath); err == nil {
		return errors.New(getMsg(msgErrExists, new))
	}
	if err := os.Rename(oldPath, newPath); err != nil {
		return err
	}
	fmt.Println(getMsg(msgSuccessRename))
	return nil
}

// cmdClone clones a repo. If no arg, lists the user's GitHub repos via fzf.
// If arg looks like a URL, clone directly. Otherwise treat arg as a search term.
func cmdClone(args []string) error {
	if err := ensureWorkspace(); err != nil {
		return err
	}

	if len(args) == 0 {
		user := githubUser()
		repos, err := fetchUserRepos(user)
		if err != nil {
			return err
		}
		if len(repos) == 0 {
			fmt.Println("No GitHub repositories found.")
			return nil
		}
		items := make([]string, len(repos))
		for i, r := range repos {
			items[i] = fmt.Sprintf("%s\t%s", r.FullName, r.CloneURL)
		}
		sel, err := fzfSelectOne(items, "Clone repo >> ")
		if err != nil || sel == "" {
			return err
		}
		url := strings.TrimSpace(strings.Split(sel, "\t")[1])
		return cloneRepo(githubRepo{Name: repoNameFromURL(url), CloneURL: url})
	}

	arg := args[0]
	if strings.HasPrefix(arg, "http://") || strings.HasPrefix(arg, "https://") ||
		strings.HasPrefix(arg, "git@") || strings.HasSuffix(arg, ".git") {
		name := repoNameFromURL(arg)
		return cloneRepo(githubRepo{Name: name, CloneURL: arg})
	}

	// Treat as a search term.
	repos, err := searchRepos(arg)
	if err != nil {
		return err
	}
	if len(repos) == 0 {
		fmt.Println("No repositories found for:", arg)
		return nil
	}
	items := make([]string, len(repos))
	for i, r := range repos {
		items[i] = fmt.Sprintf("%s\t%s", r.FullName, r.CloneURL)
	}
	sel, err := fzfSelectOne(items, "Clone repo >> ")
	if err != nil || sel == "" {
		return err
	}
	url := strings.TrimSpace(strings.Split(sel, "\t")[1])
	return cloneRepo(githubRepo{Name: repoNameFromURL(url), CloneURL: url})
}

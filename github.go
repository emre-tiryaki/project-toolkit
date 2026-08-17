package main

import (
	"errors"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

// githubRepo is a minimal GitHub repo representation.
type githubRepo struct {
	Name     string `json:"name"`
	FullName string `json:"full_name"`
	CloneURL string `json:"clone_url"`
	HTMLURL  string `json:"html_url"`
}

// githubAPI is overridable in tests.
var githubHTTPClient = &http.Client{Timeout: 15 * time.Second}

// githubUser returns the configured GitHub username (from env or config file or git config).
func githubUser() string {
	if u := os.Getenv("GITHUB_USER"); u != "" {
		return u
	}
	if m, err := readConfigFile(); err == nil {
		if u := m["github_user"]; u != "" {
			return u
		}
	}
	cmd := exec.Command("git", "config", "github.user")
	out, err := cmd.Output()
	if err == nil {
		u := strings.TrimSpace(string(out))
		if u != "" {
			return u
		}
	}
	// Fall back to the git user.name's handle guess is unsafe; leave empty.
	return ""
}

// githubToken returns the token from env, then from config file.
func githubToken() string {
	if t := os.Getenv("GITHUB_TOKEN"); t != "" {
		return t
	}
	if m, err := readConfigFile(); err == nil {
		if t := m["github_token"]; t != "" {
			return t
		}
	}
	return ""
}

// fetchUserRepos returns the authenticated user's repos, or public repos of user.
func fetchUserRepos(user string) ([]githubRepo, error) {
	token := githubToken()
	url := "https://api.github.com/user/repos?per_page=100&sort=updated"
	if user != "" {
		url = fmt.Sprintf("https://api.github.com/users/%s/repos?per_page=100&sort=updated", user)
	}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := githubHTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("github api status %d", resp.StatusCode)
	}
	var repos []githubRepo
	if err := json.NewDecoder(resp.Body).Decode(&repos); err != nil {
		return nil, err
	}
	return repos, nil
}

// searchRepos searches GitHub for public repositories matching query.
func searchRepos(query string) ([]githubRepo, error) {
	token := githubToken()
	url := "https://api.github.com/search/repositories?per_page=50&q=" + strings.ReplaceAll(query, " ", "+")
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := githubHTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("github api status %d", resp.StatusCode)
	}
	var body struct {
		Items []githubRepo `json:"items"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		return nil, err
	}
	return body.Items, nil
}

// cloneRepo clones cloneURL into workspace under name, then prints a CD marker.
func cloneRepo(repo githubRepo) error {
	target := fmt.Sprintf("%s/%s", cfg.Workspace, repo.Name)
	if _, err := os.Stat(target); err == nil {
		return errors.New(getMsg(msgErrExists, repo.Name))
	}
	fmt.Println(getMsg(msgCloning, repo.CloneURL))
	cmd := exec.Command("git", "clone", repo.CloneURL, target)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return errors.New(getMsg(msgErrCloneFailed, repo.CloneURL))
	}
	fmt.Println(getMsg(msgSuccessClone, repo.Name))
	printCDMarker(target)
	return nil
}

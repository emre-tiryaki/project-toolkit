package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestMessagesTr(t *testing.T) {
	cfg = Config{Lang: "tr", Msgs: messages("tr")}
	got := getMsg(msgErrExists, "x")
	want := "Hata: 'x' isimli bir proje zaten mevcut!"
	if got != want {
		t.Errorf("tr err_exists = %q, want %q", got, want)
	}
}

func TestMessagesEn(t *testing.T) {
	cfg = Config{Lang: "en", Msgs: messages("en")}
	got := getMsg(msgErrExists, "x")
	want := "Error: Project 'x' already exists!"
	if got != want {
		t.Errorf("en err_exists = %q, want %q", got, want)
	}
}

func TestRepoNameFromURL(t *testing.T) {
	cases := map[string]string{
		"https://github.com/user/repo.git": "repo",
		"https://github.com/user/repo/":    "repo",
		"git@github.com:user/repo.git":      "repo",
	}
	for in, want := range cases {
		if got := repoNameFromURL(in); got != want {
			t.Errorf("repoNameFromURL(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestValidProjectName(t *testing.T) {
	ok := []string{"my-app", "repo1", "Web_App"}
	bad := []string{"a/b", "a*b", "a:b"}
	for _, n := range ok {
		if !validProjectName(n) {
			t.Errorf("validProjectName(%q) = false, want true", n)
		}
	}
	for _, n := range bad {
		if validProjectName(n) {
			t.Errorf("validProjectName(%q) = true, want false", n)
		}
	}
}

func TestResolveTemplate(t *testing.T) {
	cfg = loadConfig()
	if _, ok := resolveTemplate("go"); !ok {
		t.Error("resolveTemplate(go) should find embedded template")
	}
	if _, ok := resolveTemplate("nonexistent"); ok {
		t.Error("resolveTemplate(nonexistent) should not resolve")
	}
}

func TestRenderTemplateGo(t *testing.T) {
	dir := t.TempDir()
	target := filepath.Join(dir, "demo")
	if err := os.MkdirAll(target, 0o755); err != nil {
		t.Fatal(err)
	}
	td, ok := resolveTemplate("go")
	if !ok {
		t.Fatal("go template missing")
	}
	if err := renderTemplate(td, target, "demo"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(target, "go.mod")); err != nil {
		t.Error("go.mod not rendered")
	}
	data, _ := os.ReadFile(filepath.Join(target, "main.go"))
	if string(data) == "" {
		t.Error("main.go empty")
	}
}

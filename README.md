# Project Toolkit

**Project Toolkit** is a lightweight, cross-platform CLI for managing your coding
projects. It creates, scaffolds, navigates, clones, and organizes projects from
the terminal. Written in Go (with a thin shell wrapper for directory changes) so
it works the same on Linux and macOS.

> Want the old pure-shell version? It's preserved in git history
> (`project-toolkit.sh` before the Go rewrite). The current version keeps a
> `project-toolkit.sh`, but it is now just a thin `cd` wrapper around the Go binary.

## Features

- **Workspace management** — a single directory (`~/workspace` by default) for all projects.
- **Boilerplate templates** — real project skeletons for Go, Node, TypeScript, Rust, Python
  (extensible: add your own under `~/.config/project-toolkit/templates/`).
- **Git integration** — init a repo on creation, or clone one directly.
- **GitHub clone** — `project clone` lists *your* GitHub repos (via fzf) when run with no
  argument; pass a URL to clone directly, or any text to search GitHub.
- **Smart editor detection** — opens your `$VISUAL`/`$EDITOR` (or a sensible default).
- **Fuzzy selection** — `open`/`list`/`find`/`rm` use `fzf` when available; fall back to plain
  lists when there is no TTY.
- **Safety** — `rm` confirms before deleting (unless `-f`).
- **Bilingual** — messages adapt to your system locale (Turkish / English).

## Install

### Option A — `go install`

```bash
go install github.com/emre-tiryaki/project-toolkit@latest
```

Make sure `$GOPATH/bin` (usually `~/go/bin`) is on your `PATH`.

### Option B — build from source

```bash
git clone https://github.com/emre-tiryaki/project-toolkit.git ~/.project-toolkit
cd ~/.project-toolkit
go build -o ~/.project-toolkit/project-toolkit .
```

### Load the shell wrapper

The `cd` behaviour requires sourcing the wrapper (a subprocess can't change your shell's
directory). Add to your `~/.bashrc` or `~/.zshrc`:

```bash
source "$HOME/.project-toolkit/project-toolkit.sh"
```

Then restart your shell or run `source ~/.bashrc`.

## Configuration

Set these **before** sourcing the wrapper:

| Variable | Default | Purpose |
| --- | --- | --- |
| `PROJECT_WORKSPACE` | `~/workspace` | Where projects live |
| `PROJECT_TEMPLATES_DIR` | `~/.config/project-toolkit/templates` | Your custom templates |
| `GITHUB_USER` | — | GitHub username for `project clone` (no-arg) |
| `GITHUB_TOKEN` | — | Token for higher GitHub API rate limits |
| `VISUAL` / `EDITOR` | auto | Editor to open projects in |

Tip: set `git config github.user <you>` instead of `GITHUB_USER`.

## Usage

```
project help                          Show help
project new <name> [opts]             Create a project
project open <name>                   Open a project (fzf if no name)
project list | ls                     List projects (fzf to open)
project find <term>                   Search projects by name
project rename <old> <new>            Rename a project
project rm <name> [-f]                Remove project(s)
project clone [search|url]            Clone a GitHub repo
```

### `project new` options

```
-g, --git          Initialize a git repository
-e, --editor       Open the project in your editor
-t, --template T   Scaffold with a template: go node npm js javascript ts typescript rust python py
-c, --clone URL    Clone a repository into the new project
```

### Examples

```bash
project new my-api -t go -g -e          # Go project, git init, open editor
project new web -t ts                   # TypeScript project
project new old -c https://github.com/user/repo.git   # clone into "old"
project clone                           # fzf list of YOUR GitHub repos -> clone
project clone vim                       # search GitHub for "vim" -> pick -> clone
project rename my-api my-service
project rm old -f
```

## Custom templates

Drop a folder under `~/.config/project-toolkit/templates/<name>/` containing any files.
Use `{{PROJECT_NAME}}` inside files and it will be replaced with the project name.
Reference it with `project new <name> -t <your-template-name>`.

## Dependencies

- **Go 1.24+** to build.
- **fzf** (optional) for interactive selection.
- **git** for clone / init.

## License

MIT — see [LICENSE](LICENSE).

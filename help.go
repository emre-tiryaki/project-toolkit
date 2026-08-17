package main

import "fmt"

func cmdHelp() {
	fmt.Printf(`Project Toolkit - Available Commands:

COMMANDS:

  project help
    Show this help message

  project list | project ls
    List all projects in the workspace (fzf to open)

  project new <name> [OPTIONS]
    Create a new project
    Options:
      -g, --git        Initialize a git repository
      -e, --editor     Open the project in your default editor
      -t, --template    Create a template: %v
      -c, --clone <url> Clone a git repository into the new project

  project rm <name> [OPTIONS]
    Remove an existing project
    Options:
      -f, --force      Skip confirmation prompt

  project open <name>
    Open an existing project in your default editor (fzf if no name)

  project find <term>
    Search for projects by name (partial match, fzf to open)

  project rename <old_name> <new_name>
    Rename an existing project

  project clone [search|url]
    Clone a GitHub repository. With no argument, lists your own
    repos (needs GITHUB_USER or git config github.user). A URL clones
    directly; any other text searches GitHub.

  project config [get <key> | set <key> <value> | unset <key> | list]
    Manage configuration (workspace, github_user, github_token, editor,
    templates_dir). Stored in ~/.config/project-toolkit/config.

ENVIRONMENT:
  PROJECT_WORKSPACE   Workspace directory (default: ~/workspace)
  PROJECT_TEMPLATES_DIR  Extra project templates directory
  GITHUB_USER / GITHUB_TOKEN  For GitHub repo listing
`, availableTemplates())
}

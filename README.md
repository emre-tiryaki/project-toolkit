# Project Toolkit

**Project Toolkit** is a lightweight, automated shell utility designed to streamline your development workflow on Linux. It simplifies creating, managing, navigating, and organizing your coding projects directly from the terminal.

Built for efficiency, it handles directory structures, Git initialization, and editor launching with simple, intuitive commands.

## Features

* **Smart Workspace Management:** Automatically manages a dedicated workspace directory (`~/workspace` by default).
* **Intelligent Editor Detection:** Automatically detects your system's default editor (VS Code, Vim, Neovim, Nano, etc.) via `$VISUAL` or `$EDITOR` environment variables.
* **Git Integration:** Initialize a new Git repository (`main` branch) instantly upon project creation.
* **Safety First:** Includes confirmation prompts for deletion to prevent accidents, with a "force" mode for power users.
* **Fuzzy Search:** Quickly find projects even if you don't remember the exact name.
* **Cross-Shell Support:** Fully compatible with both **Bash** and **Zsh**.
* **Bilingual Support:** Automatically adapts error messages and prompts based on your system language (English/Turkish).

## Installation

Since `project-toolkit` runs as a shell function to manage your current session (like changing directories), it must be `sourced` in your shell configuration.

### 1. Clone the Repository
Clone the tool to a location on your machine (e.g., your home directory):

```bash
git clone https://github.com/emre-tiryaki/project-toolkit.git ~/.project-toolkit

```
### 2. Configure Your Shell

You need to load the script when your terminal starts. Add the source command to your configuration file.

#### For Bash Users

Run the following commands:

```bash
echo 'source "$HOME/.project-toolkit/project-toolkit.sh"' >> ~/.bashrc
source ~/.bashrc

```

#### For Zsh Users

Run the following commands:

```bash
echo 'source "$HOME/.project-toolkit/project-toolkit.sh"' >> ~/.zshrc
source ~/.zshrc

```

## Configuration (Optional)

You can customize the behavior of Project Toolkit by setting environment variables in your `.bashrc` or `.zshrc` file **before** sourcing the script.

* **Custom Workspace Location:**
```bash
export PROJECT_WORKSPACE="$HOME/Development/MyProjects"

```


* **Force Specific Editor:**
```bash
export VISUAL="code" # or "nvim", "subl", etc.

```



## Usage

Once installed, use the `project` command to interact with the toolkit.

### Create a New Project

Creates a directory in your workspace.

```bash
project new <project-name>

```

**Options:**

* `-g` or `--git`: Initialize a Git repository immediately.
* `-e` or `--editor`: Open the project in your default editor immediately.

**Example:**

```bash
project new my-app -g -e

```

### Open an Existing Project

Navigates to the project directory and opens it in your configured editor.

```bash
project open <project-name>

```

### List Projects

Displays all projects currently in your workspace, sorted by modification time.

```bash
project list

```

### Find a Project

Search for a project by a partial name match.

```bash
project find <search-term>

```

### Rename a Project

Safely renames a project directory.

```bash
project rename <old-name> <new-name>

```

### Remove a Project

Deletes a project directory.

```bash
project rm <project-name>

```

**Options:**

* `-f` or `--force`: Skip the confirmation prompt (Use with caution).

## Roadmap

We are constantly working to improve Project Toolkit. Here are some features planned for future releases:

* [ ] **Project Templates:** Automatically scaffold projects for specific languages (Python, Node.js, Go, etc.).
* [ ] **Archive Mode:** Compress and archive old projects to save space without deleting them.
* [ ] **Project Statistics:** View disk usage and file counts for your workspace.
* [ ] **Self-Updater:** Easy command to pull the latest version of the toolkit.
* [ ] **Interactive Selection:** A TUI menu to select projects from a list when opening.

## Contributing

Contributions are welcome! If you'd like to improve this tool, please follow these steps:

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally.
3. **Create a new branch** for your feature or bug fix (`git checkout -b feature/amazing-feature`).
4. **Commit your changes** following clean coding practices.
5. **Push to the branch** (`git push origin feature/amazing-feature`).
6. **Open a Pull Request**.

Please ensure your code is clean, commented, and compatible with both Bash and Zsh.

## License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

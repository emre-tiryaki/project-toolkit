# project-toolkit

A lightweight, automated project initialization tool designed for Linux environments. This shell script streamlines the process of creating a new development workspace, setting up a Python virtual environment, and launching Visual Studio Code in a single command.

## Overview

This tool is designed for developers who value efficiency and clean workspace management. Instead of manually creating directories, navigating into them, and opening your editor, `project-toolkit` handles the entire workflow instantly.

## Features

- **Automated Directory Management:** Creates a project directory within your defined workspace path(default = `$HOME/workspace`).
- **IDE Integration:** Opens the newly created project directly in Visual Studio Code.
- **Error Handling:** Includes checks for missing arguments and existing directories to prevent overwrites or errors.
- **Cross-Shell Compatibility:** Works seamlessly with both Bash and Zsh.

## Supported Distributions

This tool is compatible with any Linux distribution that runs Bash or Zsh. It has been verified on:

- **Debian/Ubuntu-based:** KDE Neon, Ubuntu, Linux Mint, Pop!_OS, Kali Linux
- **Arch-based:** Arch Linux, Manjaro, EndeavourOS
- **Fedora/Red Hat:** Fedora Workstation, CentOS
- **OpenSUSE**

## Prerequisites

Before using this tool, ensure you have the following installed on your system:

1.  **Visual Studio Code:** The `code` command must be added to your PATH.
2.  **Git:** Required to clone the repository.

## Installation

To install `fast-project-setup` on your machine, follow these steps:

1.  **Clone the repository:**
    Download the script to a location of your choice (e.g., your home directory or a hidden folder).

    ```bash
    git clone [https://github.com/emre-tiryaki/fast-project-setup.git](https://github.com/emre-tiryaki/fast-project-setup.git) ~/.fast-project-setup
    ```

2.  **Configure your Shell:**
    Add the script to your shell configuration file (`.bashrc` or `.zshrc`).

    For **Zsh** users:
    ```bash
    echo "source ~/.fast-project-setup/project-manager.sh" >> ~/.zshrc
    source ~/.zshrc
    ```

    For **Bash** users:
    ```bash
    echo "source ~/.fast-project-setup/project-manager.sh" >> ~/.bashrc
    source ~/.bashrc
    ```

## Usage

Once installed, you can use the `project` command from any terminal window.

### Creating a New Project

To create a new project, use the `new` command followed by your desired project name:

```bash
project new my-awesome-project

**What happens next?**

1. The script checks if `~/workspace/my-awesome-project` exists.
2. It creates the directory if it does not exist.
3. It navigates into the directory.
5. It opens the folder in Visual Studio Code.

## Configuration

By default, the script creates projects in the `$HOME/workspace` directory. To change this location, edit the `project-manager.sh` file and modify the `workspace_path` variable:

```bash
local workspace_path="$HOME/your-custom-folder"

```

## Roadmap

The following features are planned for future releases to enhance the capabilities of this tool:

* [ ] **Delete Command:** Implementation of `project rm <name>` to safely remove project directories.
* [ ] **List Command:** Implementation of `project list` to view all active projects in the workspace.
* [ ] **Git Initialization:** Option to automatically run `git init` upon project creation.
* [ ] **Language Templates:** Automatically create language specific templates.
* [ ] **Archive Functionality:** Ability to compress and archive old projects to save space.
* [ ] **Language Specific Environment Setup:** Automatically initializes a Python virtual environment (`.venv`) using the standard `venv` module.

## License

This project is open-source and available under the MIT License. You are free to copy, modify, and distribute the code for personal or commercial use.

See the [LICENSE](https://www.google.com/search?q=LICENSE) file for more details.

```

```

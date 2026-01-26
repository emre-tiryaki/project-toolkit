project() {
    local command=$1
    local name=$2
    local workspace_path="$HOME/workspace"

    if [[ "$command" == "new" ]]; then
        if [[ -z "$name" ]]; then
            echo "Error: Project name is missing. Usage: project new <name>"
            return 1
        fi

        local target="$workspace_path/$name"
        mkdir -p "$target"
        cd "$target" || return
        
        # Open in VS Code
        code .
    else
        echo "Usage: project new <project_name>"
    fi
}
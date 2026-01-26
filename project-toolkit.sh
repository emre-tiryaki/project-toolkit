#for checking if a directory exists
_check_dir(){
    local target_dir=$1

    if [[ -d "$target_dir" ]]; then
        return 0
    else
        return 1
    fi
}

project() {
    local command=$1
    local name=$2
    local workspace_path="$HOME/workspace"

    #Project creation
    if [[ "$command" == "new" ]]; then
        if [[ -z "$name" ]]; then
            echo "Error: Project name is missing. Usage: project new <name>"
            return 1
        fi

        local target="$workspace_path/$name"

        if _check_dir "$target"; then
            echo "Error: Project with that name already exists"
            return 1
        fi

        echo -n "Do you want to initialize a git repository for the project? (y/n): "
        read init_git
        
        mkdir -p "$target"
        cd "$target" || return
        
        if [[ "$init_git" == "y"  || "$init_git" == "Y" ]]; then
            git init
        fi 
        
        code .
    #Project removal
    elif [[ "$command" == "rm" ]]; then
        if [[ -z "$name" ]]; then
            echo "Error: Project name is missing. Usage: project rm <name>"
            return 1
        fi

        local target="$workspace_path/$name"
        if _check_dir "$target"; then
            echo -n "Are you sure to remove the project '$name'? (y/n): "
            read confirm

            if [[ "$confirm" == "y"  || "$confirm" == "Y" ]]; then
                rm -r $target
            else
                return 0
            fi
        else
            echo "Error: There is no project to remove!"
            return 1
        fi
    #listing projects
    elif [[ "$command" == "list" ]]; then
        ls $workspace_path
    #Opening project
    elif [[ "$command" == "open" ]]; then
        target="$workspace_path/$name"
        if _check_dir "$target"; then
            code $target
        else
            echo "Error: Project does not exist"
        fi
    #Help
    elif [[ "$command" == "help" ]] || [[ -z "$command" ]]; then
        echo "Project Toolkit - Available Commands:"
        echo ""
        echo "  project help          Show this help message"
        echo "  project list          List all projects"
        echo "  project new <name>    Create a new project"
        echo "  project rm <name>     Remove an existing project"
        echo "  project open <name>   Open an existing project"
    else
        echo "Error: Invalid command"
    fi
}
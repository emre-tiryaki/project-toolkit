#for checking if a directory exists
_check_dir(){
    local target_dir=$1

    if [[ -d "$target_dir" ]]; then
        return 0
    else
        return 1
    fi
}

# For getting language specific messages
_get_msg() {
    local key=$1
    local param=$2
    local cmd_type=$3 # Opsiyonel: 'new' veya 'rm' gibi bağlamları taşımak için
    local lang="${LANG:0:2}"

    case "$lang" in
        tr)
            case "$key" in
                "err_name_missing") echo "Hata: Proje ismi eksik. Kullanım: project $cmd_type <isim>" ;;
                "err_exists")       echo "Hata: '$param' isimli bir proje zaten mevcut!" ;;
                "err_not_exists")   echo "Hata: '$param' isimli bir proje bulunamadı!" ;;
                "confirm_init_git") printf "Git repository'si oluşturmak ister misiniz? (y/n): " ;;
                "confirm_rm")       printf "'$param' projesini silmek istediğinize emin misiniz? (y/n): " ;;
                "success_rm")       echo "'$param' projesi başarıyla silindi." ;;
                "success_new")      echo "'$param' projesi başarıyla oluşturuldu." ;;
                *)                  echo "Bilinmeyen mesaj anahtarı: $key" ;;
            esac
            ;;
        *) # Default: English
            case "$key" in
                "err_name_missing") echo "Error: Project name is missing. Usage: project $cmd_type <name>" ;;
                "err_exists")       echo "Error: Project '$param' already exists!" ;;
                "err_not_exists")   echo "Error: Project '$param' not found!" ;;
                "confirm_init_git") printf "Do you want to initialize a git repository? (y/n): " ;;
                "confirm_rm")       printf "Are you sure you want to remove the project '$param'? (y/n): " ;;
                "success_rm")       echo "Project '$param' successfully removed." ;;
                "success_new")      echo "Project '$param' created successfully." ;;
                *)                  echo "Unknown message key: $key" ;;
            esac
            ;;
    esac
}

project() {
    local command=$1
    local name=$2
    local workspace_path="$HOME/workspace"

    #Project creation
    if [[ "$command" == "new" ]]; then
        if [[ -z "$name" ]]; then
            _get_msg "err_name_missing" "$command"
            return 1
        fi

        local target="$workspace_path/$name"

        if _check_dir "$target"; then
            _get_msg "err_exists" "$name"
            return 1
        fi

        _get_msg "confirm_init_git"
        read init_git
        
        mkdir -p "$target"
        cd "$target" || return
        
        if [[ "$init_git" == "y"  || "$init_git" == "Y" ]]; then
            git init
        fi 
        
        code .

        _get_msg "success_new" "$name"


    #Project removal
    elif [[ "$command" == "rm" ]]; then
        if [[ -z "$name" ]]; then
            _get_msg "err_name_missing" "$command"
            return 1
        fi

        local target="$workspace_path/$name"
        if _check_dir "$target"; then
            _get_msg "confirm_rm" "$name"
            read confirm

            if [[ "$confirm" == "y"  || "$confirm" == "Y" ]]; then
                rm -rf $target
            else
                return 0
            fi

            _get_msg "success_rm" "$name"
        else
            _get_msg "err_not_exists" "$name"
            return 1
        fi


    #listing projects
    elif [[ "$command" == "list" ]]; then
        ls -t $workspace_path | column


    #Opening project
    elif [[ "$command" == "open" ]]; then
        target="$workspace_path/$name"
        if _check_dir "$target"; then
            code $target
        else
            _get_msg "err_not_exists" "$name"
            return 1
        fi


    #Fuzzy searching projects
    elif [[ "$command" == "find" ]]; then
        local search_term=$2
        find "$workspace_path" -maxdepth 1 -type d -iname "*$search_term*" -printf "%f\n" | column


    #Help
    #TODO: This section will be language specific in the future
    elif [[ "$command" == "help" ]] || [[ -z "$command" ]]; then
        echo "Project Toolkit - Available Commands:"
        echo ""
        echo "  project help          Show this help message"
        echo "  project list          List all projects"
        echo "  project new <name>    Create a new project"
        echo "  project rm <name>     Remove an existing project"
        echo "  project open <name>   Open an existing project"
        echo "  project find <name>   List all projects with similar name"
    else
        echo "Error: Invalid command"
    fi
}
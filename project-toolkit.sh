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
                "err_invalid_param") echo "Hata: 'Geçersiz parametre: $param" ;;
                "confirm_init_git") printf "Git repository'si oluşturmak ister misiniz? (y/n): " ;;
                "confirm_rm")       printf "'$param' projesini silmek istediğinize emin misiniz? (y/n): " ;;
                "success_rm")       echo "'$param' projesi başarıyla silindi." ;;
                "success_new")      echo "'$param' projesi başarıyla oluşturuldu." ;;
                "success_rename")   echo "Proje ismi başarıyla değiştirildi." ;;
                *)                  echo "Bilinmeyen mesaj anahtarı: $key" ;;
            esac
            ;;
        *) # Default: English
            case "$key" in
                "err_name_missing") echo "Error: Project name is missing. Usage: project $cmd_type <name>" ;;
                "err_exists")       echo "Error: Project '$param' already exists!" ;;
                "err_not_exists")   echo "Error: Project '$param' not found!" ;;
                "err_invalid_param") echo "Error: 'Invalid parameter: $param" ;;
                "confirm_init_git") printf "Do you want to initialize a git repository? (y/n): " ;;
                "confirm_rm")       printf "Are you sure you want to remove the project '$param'? (y/n): " ;;
                "success_rm")       echo "Project '$param' successfully removed." ;;
                "success_new")      echo "Project '$param' created successfully." ;;
                "success_rename")   echo "Project name successfully changed." ;;
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


    #Renaming projects
    elif [[ "$command" == "rename" ]]; then
        local old_name=$2
        local new_name=$3
        
        if [[ -z "$old_name" ]] || [[ -z "$new_name" ]]; then
            _get_msg "err_name_missing" "rename"
            return 1
        fi
        
        if _check_dir "$workspace_path/$old_name"; then
            if _check_dir "$workspace_path/$new_name"; then
                _get_msg "err_exists" "$new_name"
                return 1
            fi

            if [[ "$new_name" =~ [/\\:\*\?\"\'\\[\\]] ]]; then
                _get_msg "err_invalid_param" "$new_name"
                return 1
            fi

            mv "$workspace_path/$old_name" "$workspace_path/$new_name"

            _get_msg "success_rename"
        else
            _get_msg "err_not_exists" "$old_name"
            return 1
        fi

    #Help
    #TODO: This section will be language specific in the future
    elif [[ "$command" == "help" ]] || [[ -z "$command" ]]; then
        echo "Project Toolkit - Available Commands:"
        echo ""
        echo "  project help                            Show this help message"
        echo "  project list                            List all projects"
        echo "  project new <name>                      Create a new project"
        echo "  project rm <name>                       Remove an existing project"
        echo "  project open <name>                     Open an existing project"
        echo "  project find <name>                     List all projects with similar name"
        echo "  project rename <old_name> <new_name>    rename projects"
    else
        echo "Error: Invalid command"
    fi
}
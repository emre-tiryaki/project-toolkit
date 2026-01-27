PROJECT_WORKSPACE="${PROJECT_WORKSPACE:-$HOME/workspace}"
EDITOR="code"

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
    local cmd_type=$3
    local lang="${LANG:0:2}"

    case "$lang" in
        tr)
            case "$key" in
                "err_name_missing") echo "Hata: Proje ismi eksik. Kullanım: project $cmd_type <isim>" ;;
                "err_exists")       echo "Hata: '$param' isimli bir proje zaten mevcut!" ;;
                "err_not_exists")   echo "Hata: '$param' isimli bir proje bulunamadı!" ;;
                "err_invalid_param") echo "Hata: 'Geçersiz parametre: $param" ;;
                "err_invalid_command") echo "Hata: Geçersiz komut: $cmd_type";;
                "confirm_rm")       printf "'$param' projesini silmek istediğinize emin misiniz? (y/n): " ;;
                "cancel_rm")        echo "$param projesi silinmedi";;
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
                "err_invalid_command") echo "Error: Invalid command: $cmd_type";;
                "confirm_rm")       printf "Are you sure you want to remove the project '$param'? (y/n): " ;;
                "cancel_rm")        echo "$param project did not removed";;
                "success_rm")       echo "Project '$param' successfully removed." ;;
                "success_new")      echo "Project '$param' created successfully." ;;
                "success_rename")   echo "Project name successfully changed." ;;
                *)                  echo "Unknown message key: $key" ;;
            esac
            ;;
    esac
}

#project creation command
_cmd_new() {
    local project_name=""
    local init_git=false
    local open_editor=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--git)
                init_git=true
                shift
            ;;
            -e|--editor)
                open_editor=true
                shift
            ;;
            -*)
                #error message
                return 1
            ;;
            *)
                project_name="$1"
                shift
            ;;
        esac
    done

    if [[ -z "$project_name" ]]; then
        _get_msg "err_name_missing" "" "new"
        return 1
    fi

    target="$PROJECT_WORKSPACE/$project_name"

    if _check_dir "$target"; then
        _get_msg "err_exists" "$project_name"
        return 1
    fi

    mkdir -p "$target"
    cd "$target" || return

    if [[ $init_git == true ]]; then
        git init
    fi

    if [[ $open_editor == true ]]; then
        "$EDITOR" .
    fi

    _get_msg "success_new" "$project_name"
}

#Remove Project Command
_cmd_rm() {
    local project_name=""
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                shift
            ;;
            -*)
                #error message
                return 1
            ;;
            *)
                project_name="$1"
                shift
            ;;
        esac
    done

    if [[ -z "$project_name" ]]; then
        _get_msg "err_name_missing" "" "rm"
        return 1
    fi

    local target="$PROJECT_WORKSPACE/$project_name"

    if _check_dir "$target"; then
        
        if [[ $force == false ]]; then
            _get_msg "confirm_rm" "$project_name"
            read confirm

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                rm -rf "$target"
            else
                _get_msg "cancel_rm" "$project_name"
                return 0
            fi
        else
            rm -rf "$target"
        fi

        _get_msg "success_rm" "$project_name"
    else
        _get_msg "err_not_exists" "$project_name"
        return 1
    fi
}

#listing projects command
_cmd_list() {
    ls -t $PROJECT_WORKSPACE | column
}

#Help Command
#TODO: This section will be language specific in the future
_cmd_help() {
    echo "Project Toolkit - Available Commands:"
        echo ""
        echo "  project help                            Show this help message"
        echo "  project list                            List all projects"
        echo "  project new <name>                      Create a new project"
        echo "  project rm <name>                       Remove an existing project"
        echo "  project open <name>                     Open an existing project"
        echo "  project find <name>                     List all projects with similar name"
        echo "  project rename <old_name> <new_name>    rename projects"
}

project() {
    local command=$1
    local name=$2
    local workspace_path="$PROJECT_WORKSPACE"
    shift

    case "$command" in
        new)
            _cmd_new "$@"
        ;;
        rm)
            _cmd_rm "$@"
        ;;
        list)
            _cmd_list
        ;;
        find)

        ;;
        rename)

        ;;
        help)
            _cmd_help
        ;;
        *)
            _get_msg "err_invalid_command" "$command"
            return 1
        ;;
    esac 

    #Opening project
    if [[ "$command" == "open" ]]; then
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
    else
        _get_msg "err_invalid_command" "$command"
        return 1
    fi
}
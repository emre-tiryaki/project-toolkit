#GLOBAL VARIABLES FOR HIS PROJECT
if [[ -z "${PROJECT_WORKSPACE}" ]]; then
    readonly PROJECT_WORKSPACE="${HOME}/workspace"
fi

# For getting the system default code editor
_get_editor() {
    if [[ -n "$VISUAL" ]] && command -v "$VISUAL" &> /dev/null; then
        echo "$VISUAL"
        return
    fi
    
    if [[ -n "$EDITOR" ]] && command -v "$EDITOR" &> /dev/null; then
        echo "$EDITOR"
        return
    fi
    
    for editor in code vim nvim nano gedit vi; do
        if command -v "$editor" &> /dev/null; then
            echo "$editor"
            return
        fi
    done
    
    echo "vi"
}

if [[ -z "${EDITOR_CMD}" ]]; then
    readonly EDITOR_CMD=$(_get_editor)
fi

#UTIL FUNCTIONS

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
    local lang="${LANG%_*}"
    [ -z "$lang" ] && lang="en"
    
    local message=""
    
    # Turkish messages
    if [ "$lang" = "tr" ]; then
        case "$key" in
            err_name_missing) message="Hata: Proje ismi eksik. Kullanım: project $cmd_type <isim>" ;;
            err_exists) message="Hata: '$param' isimli bir proje zaten mevcut!" ;;
            err_not_exists) message="Hata: '$param' isimli bir proje bulunamadı!" ;;
            err_base_dir_not_exists) message="Hata: Proje klasörü bulunamadı!" ;;
            err_invalid_param) message="Hata: Geçersiz parametre: $param" ;;
            err_invalid_command) message="Hata: Geçersiz komut: $cmd_type" ;;
            err_code_editor_not_found) message="Hata: '$param' editörü sistemde bulunamadı" ;;
            err_template_missing) message="Hata: Şablon tipi belirtilmedi. Kullanım: project new <isim> -t <tip>" ;;
            err_project_not_empty) message="Hata: Proje boş değil!" ;;
            err_program_not_exists) message="Hata: $param sistemde yüklü değil!" ;;
            confirm_rm) message="'$param' projesini silmek istediğinize emin misiniz? (y/n): " ;;
            cancel_rm) message="'$param' projesi silinmedi" ;;
            success_rm) message="'$param' projesi başarıyla silindi." ;;
            success_new) message="'$param' projesi başarıyla oluşturuldu." ;;
            success_rename) message="Proje ismi başarıyla değiştirildi." ;;
        esac
    else
        # English messages (default)
        case "$key" in
            err_name_missing) message="Error: Project name is missing. Usage: project $cmd_type <name>" ;;
            err_exists) message="Error: Project '$param' already exists!" ;;
            err_not_exists) message="Error: Project '$param' not found!" ;;
            err_base_dir_not_exists) message="Error: Project directory not found!" ;;
            err_invalid_param) message="Error: Invalid parameter: $param" ;;
            err_invalid_command) message="Error: Invalid command: $cmd_type" ;;
            err_code_editor_not_found) message="Error: '$param' editor not found in the system" ;;
            err_template_missing) message="Error: Template type not specified. Usage: project new <name> -t <type>" ;;
            err_project_not_empty) message="Error: Project is not empty!" ;;
            err_program_not_exists) message="Error: $param is not installed on the system!" ;;
            confirm_rm) message="Are you sure you want to remove the project '$param'? (y/n): " ;;
            cancel_rm) message="Project '$param' was not removed" ;;
            success_rm) message="Project '$param' successfully removed." ;;
            success_new) message="Project '$param' created successfully." ;;
            success_rename) message="Project name successfully changed." ;;
        esac
    fi

    # Output message
    if [ -n "$message" ]; then
        if [ "$key" = "confirm_rm" ]; then
            printf "%s" "$message"
        else
            echo "$message"
        fi
    else
        case "$lang" in
            tr)
                echo "Bilinmeyen mesaj anahtarı: $key" >&2
            ;;
            *)
                echo "Unknown message key: $key" >&2
            ;;
        esac
        
        return 1
    fi
}

#for opening system default code editor
_open_editor(){
    local target_dir="${1:-.}"

    if ! command -v "$EDITOR_CMD" >/dev/null 2>&1; then
        _get_msg "err_code_editor_not_found" "$EDITOR_CMD"
        return 1
    fi

    case "$EDITOR_CMD" in
        vim|nvim|nano|vi)
            "$EDITOR_CMD" "$target_dir"
            ;;
        *)
            (set +m; nohup "$EDITOR_CMD" "$target_dir" >/dev/null 2>&1 &)
            ;;
    esac
}

#for checking if a program/command exists in the system
_check_program_existence(){
    local program=$1
    
    command -v "$program" &> /dev/null
}

#for creating language specific templates
#TODO: will implement writing boilerplate code in the future
_create_template(){
    local project_name=$1
    local template_type=$2

    if [ "$(ls)" ]; then
        _get_msg "err_project_not_empty"
        return 1
    fi

    case "$template_type" in
        node|javascript|js)
            template_type="npm"
        ;;
    esac

    if ! _check_program_existence "$template_type"; then
        _get_msg "err_program_not_exists" "$template_type"
        return 1
    fi

    case "$template_type" in
        go)
            go mod init "$project_name"
        ;;
        npm)
            npm init -y
        ;;
        *)
            _get_msg "err_invalid_param" "$template_type"
            return 1
        ;;
    esac
}

#COMMAND FUNCTIONS 

#project creation command
_cmd_new() {
    local project_name=""
    local init_git=false
    local open_editor=false
    local create_template=false
    local template_type=""

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
            -t|--template)
                create_template=true
                template_type="$2"
                shift 2
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

    if [[ "$project_name" =~ [/\\:\*\?\"\'\\[\\]] ]]; then
        _get_msg "err_invalid_param" "$project_name"
        return 1
    fi

    target="$PROJECT_WORKSPACE/$project_name"

    if _check_dir "$target"; then
        _get_msg "err_exists" "$project_name"
        return 1
    fi

    mkdir -p "$target"
    cd "$target"

    if [[ $init_git == true ]]; then
        git init --initial-branch=main
    fi

    if [[ $create_template == true ]]; then
        if [[ -z "$template_type" ]]; then
            _get_msg "err_template_missing" "" "new"
            return 1
        fi

        _create_template "$project_name" "$template_type"
    fi  

    if [[ $open_editor == true ]]; then
        _open_editor
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
        _get_msg "err_name_missing" "$project_name"
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
    ls -t "$PROJECT_WORKSPACE" | column
}

#open project command
_cmd_open() {
    local project_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
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
        _get_msg "err_name_missing" "$project_name"
        return 1
    fi

    local target="$PROJECT_WORKSPACE/$project_name"

    if _check_dir "$target"; then
        cd "$target"
        _open_editor "$target"
    else
        _get_msg "err_not_exists" "$project_name"
        return 1
    fi
}

#Searching project by name command
_cmd_find() {
    local search_term=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
                #error message
                return 1
            ;;
            *)
                search_term="$1"
                shift
            ;;
        esac
    done
    
    find "$PROJECT_WORKSPACE" -maxdepth 1 -type d -iname "*$search_term*" -printf "%f\n" | column
}

_cmd_rename() {
    local old_name=$1
    local new_name=$2

    if [[ -z "$old_name" ]] || [[ -z "$new_name" ]]; then
        _get_msg "err_name_missing" "" "rename"
        return 1
    fi

    local old_project_path="$PROJECT_WORKSPACE/$old_name"
    local new_project_path="$PROJECT_WORKSPACE/$new_name"

    if _check_dir "$old_project_path"; then
        if _check_dir "$new_project_path"; then
            _get_msg "err_exists" "$new_name"
            return 1
        fi

        if [[ "$new_name" =~ [/\\:\*\?\"\'\\[\\]] ]]; then
            _get_msg "err_invalid_param" "$new_name"
            return 1
        fi

        mv "$old_project_path" "$new_project_path"

        _get_msg "success_rename"
    else
        _get_msg "err_not_exists" "$old_name"
        return 1
    fi
}

#Help Command
_cmd_help() {
    echo "Project Toolkit - Available Commands:"
    echo ""
    echo "COMMANDS:"
    echo ""
    echo "  project help"
    echo "    Show this help message"
    echo ""
    echo "  project list"
    echo "    List all projects in the workspace"
    echo ""
    echo "  project new <name> [OPTIONS]"
    echo "    Create a new project"
    echo "    Options:"
    echo "      -g, --git      Initialize a git repository"
    echo "      -e, --editor   Open the project in your default editor"
    echo ""
    echo "  project rm <name> [OPTIONS]"
    echo "    Remove an existing project"
    echo "    Options:"
    echo "      -f, --force    Skip confirmation prompt"
    echo ""
    echo "  project open <name>"
    echo "    Open an existing project in your default editor"
    echo ""
    echo "  project find <name>"
    echo "    Search for projects by name (partial match supported)"
    echo ""
    echo "  project rename <old_name> <new_name>"
    echo "    Rename an existing project"
}

#MAIN COMMAND
project() {
    local command="${1:-help}"
    [[ $# -gt 0 ]] && shift

    if [[ "$command" != "help" ]] && ! _check_dir "$PROJECT_WORKSPACE"; then
        _get_msg "err_base_dir_not_exists"
        return 1
    fi

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
        open)
            _cmd_open "$@"
        ;;
        find)
            _cmd_find "$@"
        ;;
        rename)
            _cmd_rename $1 $2
        ;;
        help)
            _cmd_help
        ;;
        *)
            _get_msg "err_invalid_command" "$command"
            return 1
        ;;
    esac
}
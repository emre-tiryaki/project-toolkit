#!/bin/zsh

# GLOBAL VARIABLES AND UTIL FUNCTIONS FOR THIS PROJECT
: "${PROJECT_WORKSPACE:="${HOME}/workspace"}"

_check_program_existence() {
    local program="$1"
    command -v "$program" >/dev/null 2>&1
}

_get_editor() {
    if [[ -n "$VISUAL" ]] && _check_program_existence "$VISUAL"; then
        echo "$VISUAL"
        return
    fi
    
    if [[ -n "$EDITOR" ]] && _check_program_existence "$EDITOR"; then
        echo "$EDITOR"
        return
    fi
    
    for editor in code codium vim nvim nano gedit vi; do
        if _check_program_existence "$editor"; then
            echo "$editor"
            return
        fi
    done
    
    echo "vi"
}

: "${EDITOR_CMD:=$(_get_editor)}"

_check_dir() {
    local target_dir="$1"
    [[ -d "$target_dir" ]]
}

_get_msg() {
    local key="$1"
    local param="$2"
    local cmd_type="$3"
    local lang="${LANG%_*}"
    [[ -z "$lang" ]] && lang="en"
    
    local message=""
    
    if [[ "$lang" == "tr" ]]; then
        case "$key" in
            err_name_missing) message="Hata: Proje ismi eksik. Kullanım: project $cmd_type <isim>" ;;
            err_exists) message="Hata: '$param' isimli bir proje zaten mevcut!" ;;
            err_not_exists) message="Hata: '$param' isimli bir proje bulunamadı!" ;;
            err_base_dir_not_exists) message="Hata: Proje klasörü bulunamadı ($PROJECT_WORKSPACE)!" ;;
            err_invalid_param) message="Hata: Geçersiz parametre: $param" ;;
            err_invalid_command) message="Hata: Geçersiz komut: $cmd_type" ;;
            err_code_editor_not_found) message="Hata: '$param' editörü sistemde bulunamadı" ;;
            err_template_missing) message="Hata: Şablon tipi belirtilmedi. Kullanım: project new <isim> -t <tip>" ;;
            err_project_not_empty) message="Hata: Proje boş değil!" ;;
            err_program_not_exists) message="Hata: $param sistemde yüklü değil!" ;;
            err_unknown_flag) message="Hata: bilinmeyen bayrak ($param)";;
            warning_downloading_neccecity) message="Uyarı: Gerekli $param paketleri/bağımlılıkları sessizce yükleniyor..." ;;
            info_select_project) message="Proje seç >>" ;;
            info_list_project) message="Proje listesi >>" ;;
            info_projects_to_remove) message="Silinecek projeler >>" ;;
            prompt_select_projects_to_remove) message="Silinecekleri TAB ile seçin, ENTER ile onaylayın > " ;;
            confirm_rm) message="Projeleri silmek istediğinize emin misiniz? (y/n): " ;;
            cancel_rm) message="'$param' silinmedi" ;;
            success_rm) message="'$param' başarıyla silindi." ;;
            success_new) message="'$param' projesi başarıyla oluşturuldu." ;;
            success_rename) message="Proje ismi başarıyla değiştirildi." ;;
        esac
    else
        case "$key" in
            err_name_missing) message="Error: Project name is missing. Usage: project $cmd_type <name>" ;;
            err_exists) message="Error: Project '$param' already exists!" ;;
            err_not_exists) message="Error: Project '$param' not found!" ;;
            err_base_dir_not_exists) message="Error: Project directory not found ($PROJECT_WORKSPACE)!" ;;
            err_invalid_param) message="Error: Invalid parameter: $param" ;;
            err_invalid_command) message="Error: Invalid command: $cmd_type" ;;
            err_code_editor_not_found) message="Error: '$param' editor not found in the system" ;;
            err_template_missing) message="Error: Template type not specified. Usage: project new <name> -t <type>" ;;
            err_project_not_empty) message="Error: Project is not empty!" ;;
            err_program_not_exists) message="Error: $param is not installed on the system!" ;;
            err_unknown_flag) message="Error: Unknown flag ($param)" ;;
            warning_downloading_neccecity) message="Warning: Required $param packages/dependencies are being installed silently..." ;;
            info_select_project) message="Select Project >>" ;;
            info_list_project) message="Project List >>" ;;
            info_projects_to_remove) message="Projects to remove >>" ;;
            prompt_select_projects_to_remove) message="Use TAB to select items, press ENTER to confirm > " ;;
            confirm_rm) message="Are you sure you want to remove the projects? (y/n): " ;;
            cancel_rm) message="Project '$param' was not removed" ;;
            success_rm) message="Project '$param' successfully removed." ;;
            success_new) message="Project '$param' created successfully." ;;
            success_rename) message="Project name successfully changed." ;;
        esac
    fi

    if [[ -n "$message" ]]; then
        if [[ "$key" == "confirm_rm" || "$key" == "prompt_select_projects_to_remove" ]]; then
            printf "%s" "$message"
        else
            echo "$message"
        fi
    else
        echo "Unknown message key: $key" >&2
        return 1
    fi
}

_open_editor() {
    local target_dir="${1:-.}"

    if ! _check_program_existence "$EDITOR_CMD"; then
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

_create_template() {
    local project_name="$1"
    local template_type="$2"

    if [[ -n "$(ls -A)" ]]; then
        _get_msg "err_project_not_empty"
        return 1
    fi

    case "$template_type" in
        go)
            _check_program_existence "go" || { _get_msg "err_program_not_exists" "go"; return 1; }
            go mod init "$project_name"
            ;;
        npm|node|js|javascript)
            _check_program_existence "npm" || { _get_msg "err_program_not_exists" "npm"; return 1; }
            npm init -y >/dev/null 2>&1
            ;;
        typescript|ts|npx)
            _check_program_existence "npm" || { _get_msg "err_program_not_exists" "npm"; return 1; }
            _check_program_existence "tsc" || { _get_msg "err_program_not_exists" "tsc"; return 1; }
            npm init -y >/dev/null 2>&1
            tsc --init >/dev/null 2>&1
            _get_msg "warning_downloading_neccecity" "typescript"
            npm install -D typescript ts-node @types/node >/dev/null 2>&1
            ;;
        rust)
            _check_program_existence "cargo" || { _get_msg "err_program_not_exists" "cargo"; return 1; }
            cargo init --bin --vcs none >/dev/null 2>&1
            ;;
        *)
            _get_msg "err_invalid_param" "$template_type"
            return 1
            ;;
    esac
}

_cmd_new() {
    local project_name=""
    local init_git=false
    local open_editor=false
    local create_template=false
    local template_type=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--git) init_git=true; shift ;;
            -e|--editor) open_editor=true; shift ;;
            -t|--template) create_template=true; template_type="$2"; shift 2 ;;
            -*) _get_msg "err_unknown_flag" "$1"; return 1 ;;
            *) project_name="$1"; shift ;;
        esac
    done

    if [[ -z "$project_name" ]]; then
        _get_msg "err_name_missing" "" "new"
        return 1
    fi

    local target="$PROJECT_WORKSPACE/$project_name"

    if _check_dir "$target"; then
        _get_msg "err_exists" "$project_name"
        return 1
    fi

    mkdir -p "$target" || return 1
    
    # Subshell içinde dizine geçip işlemleri yap
    (
        cd "$target" || exit 1
        if [[ $create_template == true ]]; then
            if [[ -z "$template_type" ]]; then
                _get_msg "err_template_missing" "" "new"
            else
                _create_template "$project_name" "$template_type"
            fi
        fi

        if [[ $init_git == true ]]; then
            git init --initial-branch=main >/dev/null 2>&1
        fi
    )

    if [[ $open_editor == true ]]; then
        _open_editor "$target"
    fi

    _get_msg "success_new" "$project_name"
}

_cmd_rm() {
    local projects_to_remove=()
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force) force=true; shift ;;
            -*) _get_msg "err_unknown_flag" "$1"; return 1 ;;
            *) projects_to_remove+=("$1"); shift ;;
        esac
    done

    if [[ ${#projects_to_remove[@]} -eq 0 ]]; then
        if ! _check_program_existence "fzf"; then
            _get_msg "err_program_not_exists" "fzf"
            return 1
        fi

        local selected_projects=""
        selected_projects=$(find "$PROJECT_WORKSPACE" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | fzf -m --height=40% --layout=reverse --border --prompt="$(_get_msg "prompt_select_projects_to_remove")")

        [[ -z "$selected_projects" ]] && return 0

        while IFS= read -r line; do
            [[ -n "${line// /}" ]] && projects_to_remove+=("$line")
        done <<< "$selected_projects"
    fi

    if [[ $force == false ]]; then
        _get_msg "info_projects_to_remove"
        for proj in "${projects_to_remove[@]}"; do
            echo " - $proj"
        done

        _get_msg "confirm_rm"
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            _get_msg "cancel_rm" "${projects_to_remove[*]}"
            return 0
        fi
    fi
        
    for proj in "${projects_to_remove[@]}"; do
        local target="$PROJECT_WORKSPACE/$proj"
        if _check_dir "$target"; then
            rm -rf "$target"
            _get_msg "success_rm" "$proj"
        else
            _get_msg "err_not_exists" "$proj"
        fi
    done
}

_cmd_list() {
    if ! _check_dir "$PROJECT_WORKSPACE"; then
        mkdir -p "$PROJECT_WORKSPACE"
    fi

    if _check_program_existence "fzf"; then
        local project_name=""
        project_name=$(ls -t "$PROJECT_WORKSPACE" 2>/dev/null | fzf --height=40% --layout=reverse --border --prompt="$(_get_msg "info_select_project")")

        if [[ -n "$project_name" ]]; then
            _open_editor "$PROJECT_WORKSPACE/$project_name"
        fi
    else
        ls -t "$PROJECT_WORKSPACE" 2>/dev/null | column
    fi
}

_cmd_open() {
    local project_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*) _get_msg "err_unknown_flag" "$1"; return 1 ;;
            *) project_name="$1"; shift ;;
        esac
    done

    if [[ -z "$project_name" ]]; then
        if ! _check_program_existence "fzf"; then
            _get_msg "err_program_not_exists" "fzf"
            return 1
        fi

        project_name=$(ls -1 "$PROJECT_WORKSPACE" 2>/dev/null | fzf --height=40% --layout=reverse --border --prompt="$(_get_msg "info_select_project")")
        [[ -z "$project_name" ]] && return 0
    fi

    local target="$PROJECT_WORKSPACE/$project_name"

    if _check_dir "$target"; then
        _open_editor "$target"
    else
        _get_msg "err_not_exists" "$project_name"
        return 1
    fi
}

_cmd_find() {
    local search_term="$1"

    if _check_program_existence "fzf"; then
        local project_name=""
        project_name=$(find "$PROJECT_WORKSPACE" -maxdepth 1 -type d -iname "*$search_term*" -exec basename {} \; 2>/dev/null | fzf --height=40% --layout=reverse --border --prompt="$(_get_msg "info_select_project")")

        if [[ -n "$project_name" ]]; then
            _open_editor "$PROJECT_WORKSPACE/$project_name"
        fi
    else
        find "$PROJECT_WORKSPACE" -maxdepth 1 -type d -iname "*$search_term*" -exec basename {} \; 2>/dev/null | column
    fi
}

_cmd_rename() {
    local old_name="$1"
    local new_name="$2"

    if [[ -z "$old_name" || -z "$new_name" ]]; then
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

        mv "$old_project_path" "$new_project_path"
        _get_msg "success_rename"
    else
        _get_msg "err_not_exists" "$old_name"
        return 1
    fi
}

_cmd_help() {
    echo "Project Toolkit - Available Commands:"
    echo ""
    echo "  project list | ls"
    echo "  project new <name> [-g|--git] [-e|--editor] [-t|--template <type>]"
    echo "  project rm <name> [-f|--force]"
    echo "  project open [name]"
    echo "  project find <search_term>"
    echo "  project rename <old_name> <new_name>"
}

project() {
    local command="${1:-help}"
    [[ $# -gt 0 ]] && shift

    if [[ "$command" != "help" ]] && ! _check_dir "$PROJECT_WORKSPACE"; then
        _get_msg "err_base_dir_not_exists"
        return 1
    fi

    case "$command" in
        new) _cmd_new "$@" ;;
        rm) _cmd_rm "$@" ;;
        list|ls) _cmd_list ;;
        open) _cmd_open "$@" ;;
        find) _cmd_find "$@" ;;
        rename) _cmd_rename "$1" "$2" ;;
        help) _cmd_help ;;
        *) _get_msg "err_invalid_command" "$command" ;;
    esac
}

_project_main() {
    project "$@"
}

if [[ "${ZSH_EVAL_CONTEXT:-}" =~ :file$ ]] || [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    :
else
    _project_main "$@"
fi
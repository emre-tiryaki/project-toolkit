#!/usr/bin/env bash
# Project Toolkit shell wrapper.
#
# This thin wrapper calls the Go binary (`project-toolkit`) and performs the
# one thing a separate process cannot: change the current shell's directory.
# The Go binary prints a magic marker line:
#     __PROJECT_TOOLKIT_CD__:/abs/path
# which we detect and `cd` into.
#
# Install:
#   go install github.com/emre-tiryaki/project-toolkit@latest
#   # or build locally and put the binary on PATH as `project-toolkit`
#   source this file from your ~/.bashrc or ~/.zshrc:
#       source "$HOME/.project-toolkit/project-toolkit.sh"

_project_toolkit_bin() {
    # Prefer a binary on PATH named project-toolkit; fall back to one next to this script.
    if command -v project-toolkit >/dev/null 2>&1; then
        command -v project-toolkit
        return 0
    fi
    local here="${BASH_SOURCE:-$0}"
    local dir
    dir="$(cd "$(dirname "$here")" && pwd)"
    if [ -x "$dir/project-toolkit" ]; then
        echo "$dir/project-toolkit"
        return 0
    fi
    return 1
}

project() {
    local bin
    if ! bin="$(_project_toolkit_bin)"; then
        echo "project-toolkit: binary not found. Install it or build it next to this script." >&2
        return 1
    fi

    # Apply persisted config (from ~/.config/project-toolkit/config) as env vars
    # so the Go binary sees the same settings the user set via `project config`.
    local cfgfile="${XDG_CONFIG_HOME:-$HOME/.config}/project-toolkit/config"
    if [ -f "$cfgfile" ]; then
        while IFS='=' read -r key val; do
            [ -z "$key" ] && continue
            case "$key" in
                \#*) continue ;;
            esac
            val="${val#\"}"; val="${val%\"}"; val="${val#\'}"; val="${val%\'}"
            case "$key" in
                workspace)     [ -z "$PROJECT_WORKSPACE" ] && export PROJECT_WORKSPACE="$val" ;;
                github_user)   [ -z "$GITHUB_USER" ] && export GITHUB_USER="$val" ;;
                github_token)  [ -z "$GITHUB_TOKEN" ] && export GITHUB_TOKEN="$val" ;;
                editor)        [ -z "$VISUAL" ] && export VISUAL="$val" ;;
                templates_dir) [ -z "$PROJECT_TEMPLATES_DIR" ] && export PROJECT_TEMPLATES_DIR="$val" ;;
            esac
        done < "$cfgfile"
    fi

    # Capture output, separate the CD marker.
    local output marker path
    output="$("$bin" "$@")"
    local rc=$?

    # Extract any CD marker line.
    marker="$(printf '%s\n' "$output" | grep -E '^__PROJECT_TOOLKIT_CD__:')"
    if [ -n "$marker" ]; then
        path="${marker#__PROJECT_TOOLKIT_CD__:}"
        # Print everything except the marker line.
        printf '%s\n' "$output" | grep -v -E '^__PROJECT_TOOLKIT_CD__:' >&2
        # shellcheck disable=SC2164
        cd "$path"
        return $rc
    fi

    printf '%s\n' "$output"
    return $rc
}

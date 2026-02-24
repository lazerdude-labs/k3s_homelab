#!/bin/bash

dependencies_present_main() {
    local missing=0

    if command -v apt >/dev/null 2>&1; then
        deps=(terraform vault ansible helm kubectl)
    elif command -v yum >/dev/null 2>&1; then
        deps=(terraform vault ansible helm kubectl)
    else
        echo "No known package manager found"
        return 1
    fi

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo " Missing Dependency: $dep"
            missing=1
        else
            echo "$dep found"
        fi
    done

    return $missing
}

dependencies_present_main "$@"

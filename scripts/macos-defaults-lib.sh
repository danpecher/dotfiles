#!/usr/bin/env bash

MACOS_DEFAULTS_POLICY="${MACOS_DEFAULTS_POLICY:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/macos-defaults.tsv}"

expand_default_value() {
    printf '%s' "${1//\{\{HOME\}\}/$HOME}"
}

normalized_default_value() {
    local type="$1" value="$2"
    case "$type" in
        bool)
            case "$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')" in
                true|yes|1) printf '1' ;;
                false|no|0) printf '0' ;;
                *) printf '%s' "$value" ;;
            esac
            ;;
        int) printf '%d' "$value" ;;
        float) awk -v value="$value" 'BEGIN { printf "%.8g", value + 0 }' ;;
        string)
            case "$value" in
                '~/'*) printf '%s/%s' "$HOME" "${value#\~/}" ;;
                *) printf '%s' "$value" ;;
            esac
            ;;
        *) return 2 ;;
    esac
}

for_each_managed_default() {
    local callback="$1"
    local scope domain key type value
    while IFS=$'\t' read -r scope domain key type value; do
        [[ -n "$scope" && "$scope" != \#* ]] || continue
        value="$(expand_default_value "$value")"
        "$callback" "$scope" "$domain" "$key" "$type" "$value"
    done < "$MACOS_DEFAULTS_POLICY"
}

apply_one_managed_default() {
    local scope="$1" domain="$2" key="$3" type="$4" value="$5"
    local -a command=(defaults write "$domain" "$key" "-$type" "$value")
    if [[ "$scope" == system ]]; then
        sudo "${command[@]}"
    else
        "${command[@]}"
    fi
}

prepare_managed_defaults() {
    local scope domain key type value
    while IFS=$'\t' read -r scope domain key type value; do
        [[ -n "$scope" && "$scope" != \#* ]] || continue
        if [[ "$domain" == com.apple.screencapture && "$key" == location ]]; then
            value="$(expand_default_value "$value")"
            mkdir -p "$value"
        fi
    done < "$MACOS_DEFAULTS_POLICY"
}

apply_managed_defaults() {
    prepare_managed_defaults
    for_each_managed_default apply_one_managed_default
}

audit_one_managed_default() {
    local scope="$1" domain="$2" key="$3" type="$4" expected="$5"
    local actual expected_normalized actual_normalized
    if ! actual="$(defaults read "$domain" "$key" 2>/dev/null)"; then
        printf '%s\t%s\tmissing\t%s\n' "$domain" "$key" "$expected"
        return 1
    fi
    expected_normalized="$(normalized_default_value "$type" "$expected")"
    actual_normalized="$(normalized_default_value "$type" "$actual")"
    if [[ "$actual_normalized" != "$expected_normalized" ]]; then
        printf '%s\t%s\t%s\t%s\n' "$domain" "$key" "$actual" "$expected"
        return 1
    fi
}

audit_managed_defaults() {
    local output="$1"
    : > "$output"
    local failures=0
    audit_one_to_file() {
        audit_one_managed_default "$@" >> "$output" || failures=1
    }
    for_each_managed_default audit_one_to_file
    unset -f audit_one_to_file
    return "$failures"
}

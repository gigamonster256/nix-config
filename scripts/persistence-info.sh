#!/usr/bin/env nix-shell
#! nix-shell -i bash -p jq

set -euo pipefail

# ── ansi coloring ─────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    GREEN=$'\033[32m'
    RED=$'\033[31m'
    YELLOW=$'\033[33m'
    RESET=$'\033[0m'
    BOLD=$'\033[1m'
else
    GREEN='' RED='' YELLOW='' RESET='' BOLD=''
fi

ENABLED="${GREEN}ENABLED${RESET}"
DISABLED="${RED}DISABLED${RESET}"
OFF="${RED}OFF${RESET}"

usage() {
    cat <<EOF
Usage: persistence-info.sh [hostname] [--all|--usage]

  No arguments    Show overview of all configs with persistence status
  <hostname>      Show detailed persistence paths for a specific host
  <hostname> --all  Show all module-defined persistence paths with enabled/disabled status
  --usage         Auto-detect hostname and show disk usage for OFF (stale) persistence data

EOF
    exit 1
}

# ── helpers ──────────────────────────────────────────────────────────

nix_eval() {
    nix eval "$@" 2>/dev/null
}

nix_eval_json() {
    nix eval --json "$@" 2>/dev/null || echo "[]"
}

# ── overview ─────────────────────────────────────────────────────────

overview() {
    echo "=== NixOS Configurations ==="
    echo

    local data
    data=$(nix_eval --json '.#nixosConfigurations' --apply '
      hosts: builtins.mapAttrs (name: cfg: {
        enabled = cfg.config.persistence.enable or false;
        sysDirs = builtins.length (cfg.config.persistence.directories or []);
        sysFiles = builtins.length (cfg.config.persistence.files or []);
        users = builtins.mapAttrs (u: uc: {
          dirs = builtins.length (uc.persistence.directories or []);
          files = builtins.length (uc.persistence.files or []);
        }) (cfg.config.home-manager.users or {});
      }) hosts
    ' 2>/dev/null || echo "{}")

    echo "$data" | jq -r '
      to_entries | sort_by(.key) | .[]
      | . as $h
      | $h.value as $v
      | if $v.enabled then
          ($h.key + ": ENABLED (" + ($v.sysDirs | tostring) + " system dirs, " + ($v.sysFiles | tostring) + " system files"
           + (if ($v.users | length) > 0 then ", " + ($v.users | to_entries | map(.key + ": " + (.value.dirs | tostring) + "H dirs " + (.value.files | tostring) + "H files") | join(", ")) else "" end)
           + ")")
        else $h.key + ": DISABLED"
        end
    ' | while read -r line; do
        # Replace ENABLED/DISABLED text with colored versions
        if echo "$line" | grep -q "ENABLED"; then
            printf "  %s\n" "$(echo "$line" | sed "s/ENABLED/${ENABLED}/")"
        else
            printf "  %s\n" "$(echo "$line" | sed "s/DISABLED/${DISABLED}/")"
        fi
    done

    echo
    echo "=== Home Configurations ==="
    echo

    local homes
    homes=$(nix_eval --json '.#homeConfigurations' --apply '
      homes: builtins.mapAttrs (name: cfg: {
        enabled = cfg.config.persistence.enable or false;
        dirs = builtins.length (cfg.config.persistence.directories or []);
        files = builtins.length (cfg.config.persistence.files or []);
      }) homes
    ' 2>/dev/null || echo "{}")

    if [ "$homes" = "{}" ]; then
        echo "  (none)"
    else
        echo "$homes" | jq -r '
          to_entries | .[]
          | if .value.enabled then
              "\(.key): ENABLED (\(.value.dirs) dirs, \(.value.files) files)"
            else
              "\(.key): DISABLED (\(.value.dirs) dirs defined but not active, \(.value.files) files)"
            end
        ' | while read -r line; do
            if echo "$line" | grep -q "ENABLED"; then
                printf "  %s\n" "$(echo "$line" | sed "s/ENABLED/${ENABLED}/")"
            else
                printf "  %s\n" "$(echo "$line" | sed "s/DISABLED/${DISABLED}/")"
            fi
        done
    fi
}

# ── detail ───────────────────────────────────────────────────────────

detail() {
    local host="$1"

    # Try nixos config first
    local enabled
    enabled=$(nix_eval ".#nixosConfigurations.${host}.config.persistence.enable" 2>/dev/null || echo "unknown")

    if [ "$enabled" != "unknown" ]; then
        detail_nixos "$host" "$enabled"
        return
    fi

    # Try home config
    enabled=$(nix_eval ".#homeConfigurations.\"${host}\".config.persistence.enable" 2>/dev/null || echo "unknown")

    if [ "$enabled" != "unknown" ]; then
        detail_home_standalone "$host" "$enabled"
        return
    fi

    echo "Error: unknown config '$host'"
    echo -n "Available nixos configs: "
    nix_eval ".#nixosConfigurations" --apply 'x: builtins.concatStringsSep ", " (builtins.attrNames x)' 2>/dev/null | tr -d '"'
    echo
    echo -n "Available home configs:  "
    nix_eval ".#homeConfigurations" --apply 'x: builtins.concatStringsSep ", " (builtins.attrNames x)' 2>/dev/null | tr -d '"'
    echo
    exit 1
}

detail_nixos() {
    local host="$1"
    local enabled="$2"

    echo "Host: $host (nixos)"
    echo "Persistence: $([ "$enabled" = "true" ] && echo -n "${ENABLED}" || echo -n "${DISABLED}")"
    echo

    if [ "$enabled" != "true" ]; then
        echo "Persistence is not enabled for this host."
        return
    fi

    # System-level persistence
    echo "── System Persistence (nixos) ──"
    echo
    local sys_dirs
    sys_dirs=$(nix_eval --json ".#nixosConfigurations.${host}.config.persistence.directories" 2>/dev/null || echo "[]")
    local sys_files
    sys_files=$(nix_eval --json ".#nixosConfigurations.${host}.config.persistence.files" 2>/dev/null || echo "[]")

    echo "  Directories:"
    if [ "$sys_dirs" = "[]" ]; then
        echo "    (none)"
    else
        echo "$sys_dirs" | jq -r '.[] | "    " + .'
    fi
    echo
    echo "  Files:"
    if [ "$sys_files" = "[]" ]; then
        echo "    (none)"
    else
        echo "$sys_files" | jq -r '.[] | "    " + .'
    fi

    # Home-manager persistence for each user
    local hm_users_json
    hm_users_json=$(nix_eval_json ".#nixosConfigurations.${host}.config.home-manager.users" --apply builtins.attrNames 2>/dev/null || echo "[]")

    echo "$hm_users_json" | jq -r '.[]' | while IFS= read -r user; do
        [ -z "$user" ] && continue

        echo
        echo "── Home Persistence (home-manager) for user '$user' ──"
        echo

        local hm_enabled
        hm_enabled=$(nix_eval ".#nixosConfigurations.${host}.config.home-manager.users.${user}.persistence.enable" 2>/dev/null || echo "true")

        local hm_dirs
        hm_dirs=$(nix_eval --json ".#nixosConfigurations.${host}.config.home-manager.users.${user}.persistence.directories" 2>/dev/null || echo "[]")
        local hm_files
        hm_files=$(nix_eval --json ".#nixosConfigurations.${host}.config.home-manager.users.${user}.persistence.files" 2>/dev/null || echo "[]")

        echo "  Directories:"
        if [ "$hm_dirs" = "[]" ]; then
            echo "    (none)"
        else
            echo "$hm_dirs" | jq -r '.[] | "    " + .'
        fi
        echo
        echo "  Files:"
        if [ "$hm_files" = "[]" ]; then
            echo "    (none)"
        else
            echo "$hm_files" | jq -r '.[] | "    " + .'
        fi
    done

    if [ "$hm_users_json" = "[]" ]; then
        echo
        echo "── Home Persistence ──"
        echo "  No home-manager users configured."
    fi
}

detail_home_standalone() {
    local host="$1"
    local enabled="$2"

    echo "Host: $host (home-manager standalone)"
    echo "Persistence: $([ "$enabled" = "true" ] && echo -n "${ENABLED}" || echo -n "${DISABLED}")"
    echo

    local dirs
    dirs=$(nix_eval --json ".#homeConfigurations.\"${host}\".config.persistence.directories" 2>/dev/null || echo "[]")
    local files
    files=$(nix_eval --json ".#homeConfigurations.\"${host}\".config.persistence.files" 2>/dev/null || echo "[]")

    echo "── Home Persistence ──"
    echo
    echo "  Directories:"
    if [ "$dirs" = "[]" ]; then
        echo "    (none)"
    else
        echo "$dirs" | jq -r '.[] | "    " + .'
    fi
    echo
    echo "  Files:"
    if [ "$files" = "[]" ]; then
        echo "    (none)"
    else
        echo "$files" | jq -r '.[] | "    " + .'
    fi
}

# ── all-paths mode ────────────────────────────────────────────────────

all_paths() {
    local host="$1"

    # Determine config type and get ground-truth persistence
    local config_type=""
    local enabled
    enabled=$(nix_eval ".#nixosConfigurations.${host}.config.persistence.enable" 2>/dev/null || echo "unknown")
    if [ "$enabled" != "unknown" ]; then
        config_type="nixos"
    else
        enabled=$(nix_eval ".#homeConfigurations.\"${host}\".config.persistence.enable" 2>/dev/null || echo "unknown")
        if [ "$enabled" != "unknown" ]; then
            config_type="home"
        else
            echo "Error: unknown config '$host'"
            exit 1
        fi
    fi

    echo "Host: $host ($config_type)"
    echo "Persistence: $([ "$enabled" = "true" ] && echo -n "${ENABLED}" || echo -n "${DISABLED}")"
    echo
    echo "Legend: [ENABLED] = paths found in host's evaluated persistence"
    echo "        [OFF]     = paths NOT found in host's evaluated persistence"
    echo

    if [ "$config_type" = "nixos" ]; then
        all_paths_nixos "$host"
    else
        all_paths_home_standalone "$host"
    fi
}

all_paths_nixos() {
    local host="$1"

    # Get the full programs catalog from flakeConfig
    local programs_json
    programs_json=$(nix_eval --json ".#flakeConfig.persistence.programs" 2>/dev/null || echo "{}")

    # Get wrappers
    local wrappers_json
    wrappers_json=$(nix_eval --json ".#flakeConfig.persistence.wrappers" 2>/dev/null || echo "{}")

    # Get host's actual system persistence paths
    local sys_dirs sys_files
    sys_dirs=$(nix_eval --json ".#nixosConfigurations.${host}.config.persistence.directories" 2>/dev/null || echo "[]")
    sys_files=$(nix_eval --json ".#nixosConfigurations.${host}.config.persistence.files" 2>/dev/null || echo "[]")

    # Batch-check all wrapper enable status in one nix eval
    local wrapper_status
    wrapper_status=$(build_and_check_wrappers "$host" "$wrappers_json")

    # Get host's home persistence for users
    echo
    echo "── System Persistence Programs (nixos) ──"
    echo
    echo "$programs_json" | jq -r --argjson sysDirs "$sys_dirs" --argjson sysFiles "$sys_files" '
      .nixos as $progs
      | $progs | keys_unsorted[] as $name
      | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | (if ($paths | length) > 0 and ([$paths[] | . as $path | ($sysDirs + $sysFiles) | index($path)] | all) then "[ENABLED]" else "[OFF]" end) as $status
      | ($p.directories | join(" ")) as $dirs
      | ($p.files | join(" ")) as $fls
      | "\($status)\t\($name)\t\($dirs) \($fls)"
    ' | while IFS=$'\t' read -r status name paths; do
        local color="${RED}"
        [ "$status" = "[ENABLED]" ] && color="${GREEN}"
        printf "  %s%-10s${RESET} %-24s %s\n" "$color" "$status" "$name" "$paths"
    done

    echo
    echo "── System Persistence Wrappers (nixos) ──"
    echo
    echo "$wrappers_json" | jq -r '.nixos[]? | .name' | while read -r name; do
        local enabled
        enabled=$(echo "$wrapper_status" | jq -r --arg n "$name" '.[$n] // false')
        local status="[OFF]" color="${RED}"
        if [ "$enabled" = "true" ]; then
            status="[ENABLED]" color="${GREEN}"
        fi
        printf "  %s%-10s${RESET} %-24s %s\n" "$color" "$status" "$name" "(wrapper)"
    done
    echo
    echo "── Home Persistence Programs (nixos-home) ──"
    echo
    local hm_dirs hm_files
    hm_dirs=$(get_hm_persistence "$host" "directories")
    hm_files=$(get_hm_persistence "$host" "files")

    echo "$programs_json" | jq -r --argjson hmDirs "$hm_dirs" --argjson hmFiles "$hm_files" '
      ."nixos-home" as $progs
      | $progs | keys_unsorted[] as $name
      | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | (if ($paths | length) > 0 and ([$paths[] | . as $path | ($hmDirs + $hmFiles) | index($path)] | all) then "[ENABLED]" else "[OFF]" end) as $status
      | ($p.directories | join(" ")) as $dirs
      | ($p.files | join(" ")) as $fls
      | "\($status)\t\($name)\t\($dirs) \($fls)"
    ' | while IFS=$'\t' read -r status name paths; do
        local color="${RED}"
        [ "$status" = "[ENABLED]" ] && color="${GREEN}"
        printf "  %s%-10s${RESET} %-24s %s\n" "$color" "$status" "$name" "$paths"
    done

    echo
    echo "── Home Persistence Programs (homeManager) ──"
    echo
    echo "$programs_json" | jq -r --argjson hmDirs "$hm_dirs" --argjson hmFiles "$hm_files" '
      .homeManager as $progs
      | $progs | keys_unsorted[] as $name
      | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | (if ($paths | length) > 0 and ([$paths[] | . as $path | ($hmDirs + $hmFiles) | index($path)] | all) then "[ENABLED]" else "[OFF]" end) as $status
      | ($p.directories | join(" ")) as $dirs
      | ($p.files | join(" ")) as $fls
      | "\($status)\t\($name)\t\($dirs) \($fls)"
    ' | while IFS=$'\t' read -r status name paths; do
        local color="${RED}"
        [ "$status" = "[ENABLED]" ] && color="${GREEN}"
        printf "  %s%-10s${RESET} %-24s %s\n" "$color" "$status" "$name" "$paths"
    done

    echo
    echo "── Home Persistence Wrappers (homeManager) ──"
    echo
    echo "$wrappers_json" | jq -r '.homeManager[]? | .name' | while read -r name; do
        local enabled
        enabled=$(echo "$wrapper_status" | jq -r --arg n "$name" '.[$n] // false')
        local status="[OFF]" color="${RED}"
        if [ "$enabled" = "true" ]; then
            status="[ENABLED]" color="${GREEN}"
        fi
        printf "  %s%-10s${RESET} %-24s %s\n" "$color" "$status" "$name" "(wrapper)"
    done
}

build_and_check_wrappers() {
    local host="$1"
    local wrappers_json="$2"

    local hm_user
    hm_user=$(first_hm_user "$host")

    # Build the --apply expression: cfg: { name = cfg.<path>.enable or false; ... }
    local expr="cfg: {"
    while IFS= read -r entry; do
        local name ns
        name=$(echo "$entry" | jq -r '.name')
        ns=$(echo "$entry" | jq -r '.namespace | join(".")')
        expr="$expr \"$name\" = cfg.${ns}.${name}.enable or false;"
    done < <(echo "$wrappers_json" | jq -c '.nixos[]')

    if [ -n "$hm_user" ]; then
        while IFS= read -r entry; do
            local name ns
            name=$(echo "$entry" | jq -r '.name')
            ns=$(echo "$entry" | jq -r '.namespace | join(".")')
            expr="$expr \"$name\" = cfg.home-manager.users.${hm_user}.${ns}.${name}.enable or false;"
        done < <(echo "$wrappers_json" | jq -c '.homeManager[]')
    fi

    expr="$expr }"

    nix_eval --json ".#nixosConfigurations.${host}.config" --apply "$expr" 2>/dev/null || echo "{}"
}

first_hm_user() {
    local host="$1"
    local users
    users=$(nix_eval_json ".#nixosConfigurations.${host}.config.home-manager.users" --apply builtins.attrNames 2>/dev/null || echo "[]")
    echo "$users" | jq -r '.[0] // empty' 2>/dev/null
}

all_paths_home_standalone() {
    local host="$1"

    local programs_json
    programs_json=$(nix_eval --json ".#flakeConfig.persistence.programs" 2>/dev/null || echo "{}")

    local hm_dirs hm_files
    hm_dirs=$(nix_eval --json ".#homeConfigurations.\"${host}\".config.persistence.directories" 2>/dev/null || echo "[]")
    hm_files=$(nix_eval --json ".#homeConfigurations.\"${host}\".config.persistence.files" 2>/dev/null || echo "[]")

    echo "── Home Persistence Programs ──"
    echo
    echo "$programs_json" | jq -r --argjson hmDirs "$hm_dirs" --argjson hmFiles "$hm_files" '
      .homeManager as $progs
      | $progs | keys_unsorted[] as $name
      | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | (if ($paths | length) > 0 and ([$paths[] | . as $path | ($hmDirs + $hmFiles) | index($path)] | all) then "[ENABLED]" else "[OFF]" end) as $status
      | ($p.directories | join(" ")) as $dirs
      | ($p.files | join(" ")) as $fls
      | "\($status)\t\($name)\t\($dirs) \($fls)"
    ' | while IFS=$'\t' read -r status name paths; do
        local color="${RED}"
        [ "$status" = "[ENABLED]" ] && color="${GREEN}"
        printf "  %s%-10s${RESET} %-24s %s\n" "$color" "$status" "$name" "$paths"
    done
}

get_hm_persistence() {
    local host="$1"
    local field="$2"  # directories or files

    # Get first user's home persistence (handles single-user hosts)
    local hm_users
    hm_users=$(nix_eval_json ".#nixosConfigurations.${host}.config.home-manager.users" --apply builtins.attrNames 2>/dev/null || echo "[]")

    local first_user
    first_user=$(echo "$hm_users" | jq -r '.[0] // empty' 2>/dev/null)

    if [ -z "$first_user" ]; then
        echo "[]"
        return
    fi

    nix_eval --json ".#nixosConfigurations.${host}.config.home-manager.users.${first_user}.persistence.${field}" 2>/dev/null || echo "[]"
}

# ── usage report ──────────────────────────────────────────────────────

usage_report() {
    local host
    host=$(hostname)

    # Check if this hostname matches a known nixos config
    if ! nix_eval ".#nixosConfigurations.${host}.config.persistence.enable" &>/dev/null; then
        echo "Error: hostname '$host' does not match any nixos config"
        echo "Known hosts: $(nix_eval ".#nixosConfigurations" --apply 'x: builtins.concatStringsSep ", " (builtins.attrNames x)' | tr -d '"')"
        exit 1
    fi

    local persist_path
    persist_path=$(nix_eval ".#nixosConfigurations.${host}.config.persistence.persistPath" 2>/dev/null | tr -d '"' || echo "/persist")

    local user
    user=$(first_hm_user "$host")

    echo "Host: $host (current machine)"
    echo "Persist root: ${persist_path}"
    echo

    local programs_json
    programs_json=$(nix_eval --json ".#flakeConfig.persistence.programs" 2>/dev/null || echo "{}")

    # Collect OFF programs with their paths
    local sys_dirs sys_files hm_dirs hm_files
    sys_dirs=$(nix_eval --json ".#nixosConfigurations.${host}.config.persistence.directories" 2>/dev/null || echo "[]")
    sys_files=$(nix_eval --json ".#nixosConfigurations.${host}.config.persistence.files" 2>/dev/null || echo "[]")

    if [ -n "$user" ]; then
        hm_dirs=$(nix_eval --json ".#nixosConfigurations.${host}.config.home-manager.users.${user}.persistence.directories" 2>/dev/null || echo "[]")
        hm_files=$(nix_eval --json ".#nixosConfigurations.${host}.config.home-manager.users.${user}.persistence.files" 2>/dev/null || echo "[]")
    else
        hm_dirs="[]" hm_files="[]"
    fi

    echo "Checking for stale data from OFF programs..."
    echo

    local found=0

    # System programs (nixos)
    while IFS=$'\t' read -r name dirs files; do
        output_stale_sys "$persist_path" "$name" "$dirs" "$files" && found=$((found + 1))
    done < <(echo "$programs_json" | jq -r --argjson sysDirs "$sys_dirs" --argjson sysFiles "$sys_files" '
      .nixos as $progs | $progs | keys_unsorted[] as $name | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | select(($paths | length) == 0 or ([$paths[] | . as $p | ($sysDirs + $sysFiles) | index($p)] | any | not))
      | "\($name)\t\($p.directories | join(" "))\t\($p.files | join(" "))"
    ')

    # nixos-home programs
    while IFS=$'\t' read -r name dirs files; do
        output_stale_home "$persist_path" "$user" "$name" "$dirs" "$files" && found=$((found + 1))
    done < <(echo "$programs_json" | jq -r --argjson hmDirs "$hm_dirs" --argjson hmFiles "$hm_files" '
      ."nixos-home" as $progs | $progs | keys_unsorted[] as $name | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | select(($paths | length) == 0 or ([$paths[] | . as $p | ($hmDirs + $hmFiles) | index($p)] | any | not))
      | "\($name)\t\($p.directories | join(" "))\t\($p.files | join(" "))"
    ')

    # homeManager programs
    while IFS=$'\t' read -r name dirs files; do
        output_stale_home "$persist_path" "$user" "$name" "$dirs" "$files" && found=$((found + 1))
    done < <(echo "$programs_json" | jq -r --argjson hmDirs "$hm_dirs" --argjson hmFiles "$hm_files" '
      .homeManager as $progs | $progs | keys_unsorted[] as $name | $progs[$name] as $p
      | ($p.directories + $p.files) as $paths
      | select(($paths | length) == 0 or ([$paths[] | . as $p | ($hmDirs + $hmFiles) | index($p)] | any | not))
      | "\($name)\t\($p.directories | join(" "))\t\($p.files | join(" "))"
    ')

    echo
    if [ "$found" -eq 0 ]; then
        echo "No stale persistence data found."
    else
        echo "Found stale data for ${found} program(s). Remove with: rm -rf <path>"
    fi
}

output_stale_sys() {
    local persist="$1" name="$2" dirs="$3" files="$4"
    local any=1

    for d in $dirs; do
        local p="${persist}${d}"
        if [ -d "$p" ]; then
            local sz
            sz=$(du -sk "$p" 2>/dev/null | cut -f1)
            [ -n "$sz" ] && [ "$sz" -gt 0 ] || continue
            printf "  ${YELLOW}%-24s${RESET} %s %s\n" "$name" "$(fmt_size "$sz")" "$p"
            any=0
        fi
    done
    for f in $files; do
        local p="${persist}${f}"
        if [ -f "$p" ]; then
            local sz
            sz=$(du -sk "$p" 2>/dev/null | cut -f1)
            [ -n "$sz" ] && [ "$sz" -gt 0 ] || continue
            printf "  ${YELLOW}%-24s${RESET} %s %s\n" "$name" "$(fmt_size "$sz")" "$p"
            any=0
        fi
    done
    return $any
}

output_stale_home() {
    local persist="$1" user="$2" name="$3" dirs="$4" files="$5"
    local any=1
    [ -z "$user" ] && return 1

    for d in $dirs; do
        local p="${persist}/home/${user}/${d}"
        if [ -d "$p" ]; then
            local sz
            sz=$(du -sk "$p" 2>/dev/null | cut -f1)
            [ -n "$sz" ] && [ "$sz" -gt 0 ] || continue
            printf "  ${YELLOW}%-24s${RESET} %s %s\n" "$name" "$(fmt_size "$sz")" "$p"
            any=0
        fi
    done
    for f in $files; do
        local p="${persist}/home/${user}/${f}"
        if [ -f "$p" ]; then
            local sz
            sz=$(du -sk "$p" 2>/dev/null | cut -f1)
            [ -n "$sz" ] && [ "$sz" -gt 0 ] || continue
            printf "  ${YELLOW}%-24s${RESET} %s %s\n" "$name" "$(fmt_size "$sz")" "$p"
            any=0
        fi
    done
    return $any
}

fmt_size() {
    local kb="$1"
    if [ "$kb" -ge 1048576 ]; then
        local gb=$((kb / 104857))
        echo "$((gb / 10)).$((gb % 10))G"
    elif [ "$kb" -ge 1024 ]; then
        local mb=$((kb / 102))
        echo "$((mb / 10)).$((mb % 10))M"
    else
        echo "${kb}K"
    fi
}

# ── main ──────────────────────────────────────────────────────────────

case "${1:-}" in
    --help|-h) usage ;;
    --usage)   usage_report ;;
    "")
        overview
        ;;
    *)
        if [ "${2:-}" = "--all" ]; then
            all_paths "$1"
        else
            detail "$1"
        fi
        ;;
esac

#!/usr/bin/env bash
# configure_nano.sh
# SYS-320-01 | Configure Nano
# Writes a ~/.nanorc with useful settings including line numbers.

set -euo pipefail

NANORC="${HOME}/.nanorc"

backup_existing() {
    if [[ -f "$NANORC" ]]; then
        cp "$NANORC" "${NANORC}.bak.$(date +%Y%m%d_%H%M%S)"
        echo "[*] Existing .nanorc backed up"
    fi
}

write_nanorc() {
    cat > "$NANORC" <<'EOF'
# ~/.nanorc — nano configuration
# SYS-320 Configure Nano assignment

## Display
set linenumbers          # show line numbers in left margin
set numbercolor yellow   # color of line number column
set titlecolor brightwhite,blue  # title bar color

## Editing behavior
set tabsize 4            # tab width
set tabstospaces         # expand tabs to spaces
set autoindent           # preserve indentation on new lines
set trimblanks           # trim trailing whitespace on save

## Interface
set constantshow         # always show cursor position in status bar
set softwrap             # wrap long lines at window boundary (display only)
set mouse                # enable mouse click for cursor positioning

## Backup
set backup               # create backup files (~filename)
set backupdir "~/.nano_backups"

## Syntax highlighting (uses system-provided highlight files)
include "/usr/share/nano/*.nanorc"
EOF
    echo "[*] Written: $NANORC"
}

create_backup_dir() {
    mkdir -p "${HOME}/.nano_backups"
    echo "[*] Backup dir: ~/.nano_backups"
}

verify() {
    echo ""
    echo "[*] Verifying nano opens with line numbers:"
    echo "    nano --linenumbers /etc/hostname"
    echo ""
    echo "[*] Or open the nanorc itself:"
    echo "    nano ~/.nanorc"
    echo ""
    echo "[*] Current .nanorc contents:"
    cat "$NANORC"
}

backup_existing
write_nanorc
create_backup_dir
verify

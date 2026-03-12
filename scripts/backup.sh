#!/usr/bin/env bash
# AI Team Framework — Project Backup
#
# Creates a timestamped tar.gz backup of the entire project.
#
# Usage:
#   backup.sh [project_path] [options]
#
# Options:
#   --dest DIR    Backup destination (overrides config and env)
#   --help        Show help
#
# Configuration (in order of priority):
#   1. --dest flag
#   2. BACKUP_DIR environment variable
#   3. backup_dir from .ai-team-config.yml
#   4. ./backups/ (default fallback)

set -euo pipefail

PROJECT_DIR="${1:-.}"
# Remove trailing slash and resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
DEST=""

# Parse options (skip first arg if it's a path)
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dest) DEST="$2"; shift 2 ;;
        --help|-h)
            echo "AI Team Framework — Project Backup"
            echo ""
            echo "Usage: $0 [project_path] [options]"
            echo ""
            echo "  project_path   Path to project (default: current directory)"
            echo ""
            echo "Options:"
            echo "  --dest DIR    Backup destination directory"
            echo "  --help        Show this help"
            echo ""
            echo "Configuration priority:"
            echo "  1. --dest flag"
            echo "  2. BACKUP_DIR environment variable"
            echo "  3. backup_dir from .ai-team-config.yml"
            echo "  4. ./backups/ (default)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ─────────────────────────────────────────────────────────────
# Determine backup destination
# ─────────────────────────────────────────────────────────────

if [ -z "$DEST" ] && [ -n "${BACKUP_DIR:-}" ]; then
    DEST="$BACKUP_DIR"
fi

# Try reading from .ai-team-config.yml
if [ -z "$DEST" ] && [ -f "$PROJECT_DIR/.ai-team-config.yml" ]; then
    config_dest=$(grep "^backup_dir:" "$PROJECT_DIR/.ai-team-config.yml" 2>/dev/null | \
        sed 's/^backup_dir: *//' | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//" | \
        tr -d '[:space:]' || true)
    if [ -n "$config_dest" ]; then
        DEST="$config_dest"
    fi
fi

# Default fallback
if [ -z "$DEST" ]; then
    DEST="$PROJECT_DIR/backups"
fi

# Expand ~ to home directory
DEST="${DEST/#\~/$HOME}"

# ─────────────────────────────────────────────────────────────
# Create backup
# ─────────────────────────────────────────────────────────────

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="backup_${PROJECT_NAME}_${DATE}.tar.gz"

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  AI Team Framework — Project Backup${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Project:     ${CYAN}$PROJECT_DIR${NC}"
echo -e "  Destination: ${CYAN}$DEST${NC}"
echo -e "  Filename:    ${CYAN}$FILENAME${NC}"
echo ""

# Create destination directory
mkdir -p "$DEST"

# Exclude common unnecessary dirs from backup
EXCLUDE_ARGS=""
for excl in node_modules .git __pycache__ .venv venv .tox .mypy_cache .pytest_cache dist build .next target backups .framework_backup_*; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$excl"
done

echo -e "${CYAN}Creating backup...${NC}"

# shellcheck disable=SC2086
tar -czf "$DEST/$FILENAME" \
    $EXCLUDE_ARGS \
    -C "$(dirname "$PROJECT_DIR")" \
    "$(basename "$PROJECT_DIR")"

# Show size
FILE_SIZE=$(du -h "$DEST/$FILENAME" | cut -f1)

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Backup complete!${NC}"
echo -e "  File: ${CYAN}$DEST/$FILENAME${NC}"
echo -e "  Size: ${CYAN}$FILE_SIZE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  To restore:"
echo "    tar -xzf $DEST/$FILENAME -C /destination/path/"
echo ""

#!/usr/bin/env bash
# AI Team Framework — Project Updater
#
# Updates an existing project's team files to match a newer framework version.
# Uses Claude --dangerously-skip-permissions to apply changes autonomously.
#
# Usage:
#   /path/to/ai-team-framework/scripts/update_project.sh [project_path]
#
#   project_path  Path to the project to update (default: current directory)
#
# Environment:
#   FRAMEWORK_DIR  Path to ai-team-framework repo (auto-detected from script location)
#   TEAM_DIR       Path to team files within project (default: docs/TEAM)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="${FRAMEWORK_DIR:-$SCRIPT_DIR/..}"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
TEAM_DIR="${TEAM_DIR:-docs/TEAM}"
TEAM_PATH="$PROJECT_DIR/$TEAM_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.framework_backup_$TIMESTAMP"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────
# Preflight checks
# ─────────────────────────────────────────────────────────────

if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: 'claude' command not found.${NC}"
    echo "Install Claude Code: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

if [ ! -f "$FRAMEWORK_DIR/VERSION" ]; then
    echo -e "${RED}Error: Framework VERSION file not found at $FRAMEWORK_DIR/VERSION${NC}"
    echo "Make sure FRAMEWORK_DIR points to the ai-team-framework repo."
    exit 1
fi

if [ ! -d "$TEAM_PATH" ]; then
    echo -e "${RED}Error: Team directory not found at $TEAM_PATH${NC}"
    echo "This project doesn't appear to have been initialized with the Wizard."
    echo "Run the Wizard first: ./start_role.sh wizard"
    exit 1
fi

if [ ! -f "$FRAMEWORK_DIR/update/UPDATE_PROMPT.md" ]; then
    echo -e "${RED}Error: Update prompt not found at $FRAMEWORK_DIR/update/UPDATE_PROMPT.md${NC}"
    echo "Your framework version may not support updates. Pull the latest version."
    exit 1
fi

# Get version info
NEW_VERSION="$(cat "$FRAMEWORK_DIR/VERSION" | tr -d '[:space:]')"
if [ -f "$TEAM_PATH/.framework_version" ]; then
    CURRENT_VERSION="$(cat "$TEAM_PATH/.framework_version" | tr -d '[:space:]')"
else
    CURRENT_VERSION="unknown"
fi

# ─────────────────────────────────────────────────────────────
# Disclaimer
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  AI Team Framework — Project Update${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Project:          ${CYAN}$PROJECT_DIR${NC}"
echo -e "  Team files:       ${CYAN}$TEAM_PATH${NC}"
echo -e "  Current version:  ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "  New version:      ${GREEN}$NEW_VERSION${NC}"
echo ""
echo -e "${YELLOW}┌──────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│  ⚠  WARNING — READ CAREFULLY                                       │${NC}"
echo -e "${YELLOW}│                                                                      │${NC}"
echo -e "${YELLOW}│  This operation updates your project's framework files.              │${NC}"
echo -e "${YELLOW}│  Your project is in an ACTIVE state — proceed at your own risk.      │${NC}"
echo -e "${YELLOW}│                                                                      │${NC}"
echo -e "${YELLOW}│  WHAT WILL BE UPDATED (static files — regenerated):                  │${NC}"
echo -e "${YELLOW}│    • Role definitions (PROJECT_DIRECTOR.md, etc.)                    │${NC}"
echo -e "${YELLOW}│    • Format references (DIRECTIVE_TEMPLATE.md, REPORT_TEMPLATE.md)   │${NC}"
echo -e "${YELLOW}│    • Launcher script (start_role.sh)                                 │${NC}"
echo -e "${YELLOW}│                                                                      │${NC}"
echo -e "${YELLOW}│  WHAT WILL NOT BE TOUCHED (stateful files — preserved):              │${NC}"
echo -e "${YELLOW}│    • PROJECT_STATUS.md (your project state)                          │${NC}"
echo -e "${YELLOW}│    • DECISIONS.md (technical memory)                                 │${NC}"
echo -e "${YELLOW}│    • TODO.md (task backlog)                                          │${NC}"
echo -e "${YELLOW}│    • ARCHITECTURE_VISION.md (technical vision)                       │${NC}"
echo -e "${YELLOW}│    • DIRECTIVES/, REPORTS/, ARCHIVE/ (project content)               │${NC}"
echo -e "${YELLOW}│    • Source code and tests                                           │${NC}"
echo -e "${YELLOW}│                                                                      │${NC}"
echo -e "${YELLOW}│  A full backup will be created before any changes are made.          │${NC}"
echo -e "${YELLOW}│  Backup location: .framework_backup_$TIMESTAMP/                     │${NC}"
echo -e "${YELLOW}│                                                                      │${NC}"
echo -e "${YELLOW}│  This script uses claude --dangerously-skip-permissions.             │${NC}"
echo -e "${YELLOW}│  Claude will make changes without asking for confirmation.           │${NC}"
echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────┘${NC}"
echo ""

read -rp "$(echo -e "${BOLD}Do you want to proceed? (yes/no): ${NC}")" CONFIRM

if [[ "$CONFIRM" != "yes" && "$CONFIRM" != "y" && "$CONFIRM" != "da" ]]; then
    echo ""
    echo "Update cancelled."
    exit 0
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Backup
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"

# Back up all team files
cp -r "$TEAM_PATH" "$BACKUP_DIR/TEAM"

# Back up launcher script if it exists
if [ -f "$PROJECT_DIR/start_role.sh" ]; then
    cp "$PROJECT_DIR/start_role.sh" "$BACKUP_DIR/start_role.sh"
fi

echo -e "${GREEN}  ✓ Backup created at $BACKUP_DIR/${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# Build the update prompt
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Preparing update...${NC}"

# Read the update prompt
UPDATE_PROMPT="$(cat "$FRAMEWORK_DIR/update/UPDATE_PROMPT.md")"

# Build the full instruction for Claude
FULL_PROMPT="$UPDATE_PROMPT

---

## Context for This Update

**Framework directory (new templates):** $FRAMEWORK_DIR/templates/
**Project directory:** $PROJECT_DIR
**Team files directory:** $TEAM_PATH
**Current framework version:** $CURRENT_VERSION
**New framework version:** $NEW_VERSION

## Your Task

1. Read all existing team files in \`$TEAM_PATH/\` to extract project-specific customizations
2. Read all new template files in \`$FRAMEWORK_DIR/templates/\`
3. Read the existing \`$PROJECT_DIR/start_role.sh\` (if it exists) to extract CLAUDE_FLAGS
4. Follow the Update Procedure from the instructions above
5. Write updated static files to \`$TEAM_PATH/\`
6. Write updated \`start_role.sh\` to \`$PROJECT_DIR/start_role.sh\`
7. Write \`$NEW_VERSION\` to \`$TEAM_PATH/.framework_version\`
8. Print the update report

**Start now. Read the existing files, then apply the update.**"

# ─────────────────────────────────────────────────────────────
# Run Claude
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Running update agent...${NC}"
echo ""

cd "$PROJECT_DIR"
claude --dangerously-skip-permissions "$FULL_PROMPT"

UPDATE_EXIT=$?

echo ""

# ─────────────────────────────────────────────────────────────
# Post-update
# ─────────────────────────────────────────────────────────────

if [ $UPDATE_EXIT -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Update completed successfully.${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Backup:  ${CYAN}$BACKUP_DIR/${NC}"
    echo -e "  Version: ${YELLOW}$CURRENT_VERSION${NC} → ${GREEN}$NEW_VERSION${NC}"
    echo ""
    echo "  To rollback, restore from the backup directory:"
    echo "    cp -r $BACKUP_DIR/TEAM/* $TEAM_PATH/"
    if [ -f "$BACKUP_DIR/start_role.sh" ]; then
        echo "    cp $BACKUP_DIR/start_role.sh $PROJECT_DIR/start_role.sh"
    fi
    echo ""
    echo "  Verify the update by starting a role session:"
    echo "    ./start_role.sh pd"
    echo ""
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  Update failed (exit code: $UPDATE_EXIT).${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Your original files are safe in the backup:"
    echo "    $BACKUP_DIR/"
    echo ""
    echo "  To restore:"
    echo "    cp -r $BACKUP_DIR/TEAM/* $TEAM_PATH/"
    if [ -f "$BACKUP_DIR/start_role.sh" ]; then
        echo "    cp $BACKUP_DIR/start_role.sh $PROJECT_DIR/start_role.sh"
    fi
    echo ""
    exit 1
fi

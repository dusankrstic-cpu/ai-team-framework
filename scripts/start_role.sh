#!/usr/bin/env bash
# AI Team Framework — Role Launcher
#
# Usage: ./start_role.sh <role> [options]
#   role: pd | dd | team | wizard
#
# This is the TEMPLATE version. The Wizard generates a project-specific
# version in the user's project root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAM_DIR="${TEAM_DIR:-docs/TEAM}"
ROLE="${1:-}"

# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Error: 'claude' command not found."
    echo "Install Claude Code: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

# Check if team directory exists
if [ ! -d "$TEAM_DIR" ]; then
    echo "Error: Team directory '$TEAM_DIR' not found."
    echo ""
    echo "Have you run the Wizard yet? If not:"
    echo "  claude \"\$(cat /path/to/ai-team-framework/wizard/WIZARD.md)\""
    echo ""
    echo "Or set TEAM_DIR to point to your team files:"
    echo "  TEAM_DIR=path/to/team ./start_role.sh pd"
    exit 1
fi

show_help() {
    echo "AI Team Framework — Role Launcher"
    echo ""
    echo "Usage: $0 <role>"
    echo ""
    echo "Roles:"
    echo "  pd      Project Director — strategic authority"
    echo "          Sets vision, priorities, milestones. Issues directives."
    echo ""
    echo "  dd      Development Director — technical authority"
    echo "          Translates directives to tasks, reviews code, makes technical decisions."
    echo ""
    echo "  team    Development Team — implementation"
    echo "          Writes code, tests, and reports."
    echo ""
    echo "  wizard  Initialization Wizard"
    echo "          Asks about your project and generates all team files."
    echo "          (Requires FRAMEWORK_DIR to be set or script to be in framework repo)"
    echo ""
    echo "Workflow:"
    echo "  1. $0 pd     → PD reviews state, issues directive"
    echo "  2. $0 dd     → DD reads directive, creates TODO tasks"
    echo "  3. $0 team   → Team implements, writes report"
    echo "  4. $0 dd     → DD reviews report, issues verdict"
    echo "  5. $0 pd     → PD updates status, next steps"
    echo ""
    echo "Environment:"
    echo "  TEAM_DIR       Path to team files (default: docs/TEAM)"
    echo "  FRAMEWORK_DIR  Path to ai-team-framework repo (for wizard)"
}

start_session() {
    local role_file="$1"
    local role_name="$2"

    if [ ! -f "$role_file" ]; then
        echo "Error: Role file not found: $role_file"
        exit 1
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Starting: $role_name"
    echo "  Loading:  $role_file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Tell Claude to follow the startup protocol in the role file."
    echo "Example: \"Read $role_file and follow your startup protocol.\""
    echo ""

    # Start Claude with the role file content as system context
    claude --print "$role_file"
}

case "$ROLE" in
    pd|director|project-director)
        start_session "$TEAM_DIR/PROJECT_DIRECTOR.md" "Project Director"
        ;;
    dd|dev-director|development-director)
        start_session "$TEAM_DIR/DEVELOPMENT_DIRECTOR.md" "Development Director"
        ;;
    team|dev|development-team)
        start_session "$TEAM_DIR/DEVELOPMENT_TEAM.md" "Development Team"
        ;;
    wizard)
        FRAMEWORK_DIR="${FRAMEWORK_DIR:-$SCRIPT_DIR/..}"
        WIZARD_FILE="$FRAMEWORK_DIR/wizard/WIZARD.md"
        if [ ! -f "$WIZARD_FILE" ]; then
            echo "Error: Wizard file not found: $WIZARD_FILE"
            echo "Set FRAMEWORK_DIR to point to the ai-team-framework repo."
            exit 1
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Starting: Initialization Wizard"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        claude --print "$WIZARD_FILE"
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_help
        exit 1
        ;;
    *)
        echo "Unknown role: $ROLE"
        echo ""
        show_help
        exit 1
        ;;
esac

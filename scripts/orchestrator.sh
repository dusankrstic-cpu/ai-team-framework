#!/usr/bin/env bash
# AI Team Framework — Orchestrator
#
# Watches project state and recommends (or auto-runs) the next role.
#
# Usage:
#   orchestrator.sh [mode] [options]
#
# Modes:
#   status   Show current state and recommendation (default)
#   suggest  Show what to run next with context message
#   auto     Run roles automatically with confirmation prompts
#
# Options:
#   --no-confirm   Skip confirmation for routine transitions (auto mode)
#   --dry-run      Show what would be run without executing
#   --help         Show help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAM_DIR="${TEAM_DIR:-docs/TEAM}"
MODE="${1:-status}"

# Shift mode argument if it's not an option
case "$MODE" in
    status|suggest|auto) shift || true ;;
    --*) MODE="status" ;; # Don't shift, it's an option
    help|--help|-h) MODE="help" ;;
    *) MODE="status" ;;
esac

NO_CONFIRM=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-confirm) NO_CONFIRM=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --team-dir) TEAM_DIR="$2"; shift 2 ;;
        --help|-h) MODE="help"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────

show_help() {
    echo "AI Team Framework — Orchestrator"
    echo ""
    echo "Usage: $0 [mode] [options]"
    echo ""
    echo "Modes:"
    echo "  status    Show current project state and recommendation (default)"
    echo "  suggest   Show what to run next with context message"
    echo "  auto      Run roles automatically with confirmation prompts"
    echo ""
    echo "Options:"
    echo "  --no-confirm   Skip confirmation for routine transitions (auto mode)"
    echo "  --dry-run      Show what would be run without executing"
    echo "  --team-dir DIR Override TEAM_DIR (default: docs/TEAM)"
    echo "  --help         Show this help"
    echo ""
    echo "Environment:"
    echo "  TEAM_DIR       Path to team files (default: docs/TEAM)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show status dashboard"
    echo "  $0 suggest            # Show next action"
    echo "  $0 auto               # Auto-run with confirmations"
    echo "  $0 auto --no-confirm  # Auto-run, confirm only at quality gates"
}

# ─────────────────────────────────────────────────────────────
# Preflight
# ─────────────────────────────────────────────────────────────

check_team_dir() {
    if [ ! -d "$TEAM_DIR" ]; then
        echo -e "${RED}Error: Team directory '$TEAM_DIR' not found.${NC}"
        echo "Run the Wizard first or set TEAM_DIR."
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────
# State Detection
# ─────────────────────────────────────────────────────────────

# Count directive files by status
count_directives() {
    local status="$1"
    local count=0
    if [ -d "$TEAM_DIR/DIRECTIVES" ]; then
        count=$(grep -rl "^\*\*Status:\*\* $status" "$TEAM_DIR/DIRECTIVES/" 2>/dev/null | wc -l)
    fi
    echo "$count"
}

# Get names of directives with a given status
get_directives_by_status() {
    local status="$1"
    if [ -d "$TEAM_DIR/DIRECTIVES" ]; then
        grep -rl "^\*\*Status:\*\* $status" "$TEAM_DIR/DIRECTIVES/" 2>/dev/null | sort || true
    fi
}

# Count total reports
count_reports() {
    if [ -d "$TEAM_DIR/REPORTS" ]; then
        find "$TEAM_DIR/REPORTS" -name "REPORT_*.md" 2>/dev/null | wc -l
    else
        echo 0
    fi
}

# Get the most recent report file
get_latest_report() {
    if [ -d "$TEAM_DIR/REPORTS" ]; then
        find "$TEAM_DIR/REPORTS" -name "REPORT_*.md" 2>/dev/null | sort | tail -1
    fi
}

# Count REVIEW entries in DECISIONS.md
count_reviews() {
    if [ -f "$TEAM_DIR/DECISIONS.md" ]; then
        grep -c "^### .*— REVIEW" "$TEAM_DIR/DECISIONS.md" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Get the latest review verdict from DECISIONS.md
get_latest_verdict() {
    if [ -f "$TEAM_DIR/DECISIONS.md" ]; then
        # Read file in reverse, find the first REVIEW block, extract verdict
        tac "$TEAM_DIR/DECISIONS.md" 2>/dev/null | \
            grep -m1 "^\*\*Decision:\*\*" 2>/dev/null | \
            sed 's/.*\*\*Decision:\*\* *//' | \
            sed 's/ *—.*//' | \
            tr -d '[:space:]' || echo ""
    fi
}

# Get the latest review type from DECISIONS.md
get_latest_decision_type() {
    if [ -f "$TEAM_DIR/DECISIONS.md" ]; then
        tac "$TEAM_DIR/DECISIONS.md" 2>/dev/null | \
            grep -m1 "^### .*—" 2>/dev/null | \
            sed 's/.*— *//' || echo ""
    fi
}

# Count unchecked TODO items for a specific phase (or all)
count_unchecked_todos() {
    local phase="${1:-}"
    if [ -f "$TEAM_DIR/TODO.md" ]; then
        if [ -n "$phase" ]; then
            # Count between "## Phase N" and next "## Phase"
            awk "/^## Phase $phase/,/^## Phase [^$phase]/" "$TEAM_DIR/TODO.md" 2>/dev/null | \
                grep -c "^- \[ \]" 2>/dev/null || echo 0
        else
            grep -c "^- \[ \]" "$TEAM_DIR/TODO.md" 2>/dev/null || echo 0
        fi
    else
        echo 0
    fi
}

# Count total TODO items
count_total_todos() {
    if [ -f "$TEAM_DIR/TODO.md" ]; then
        grep -c "^- \[.\]" "$TEAM_DIR/TODO.md" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Get current active phase from PROJECT_STATUS.md (first IN_PROGRESS)
get_active_phase() {
    if [ -f "$TEAM_DIR/PROJECT_STATUS.md" ]; then
        grep "IN_PROGRESS" "$TEAM_DIR/PROJECT_STATUS.md" 2>/dev/null | \
            head -1 | \
            sed 's/.*| *\([0-9]*\) *.*/\1/' | \
            tr -d '[:space:]' || echo ""
    fi
}

# Get active phase name
get_active_phase_name() {
    if [ -f "$TEAM_DIR/PROJECT_STATUS.md" ]; then
        grep "IN_PROGRESS" "$TEAM_DIR/PROJECT_STATUS.md" 2>/dev/null | \
            head -1 | \
            awk -F'|' '{print $3}' | \
            sed 's/^ *//;s/ *$//' || echo ""
    fi
}

# Count completed phases
count_completed_phases() {
    if [ -f "$TEAM_DIR/PROJECT_STATUS.md" ]; then
        grep -c "COMPLETED" "$TEAM_DIR/PROJECT_STATUS.md" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Count blocked phases
count_blocked_phases() {
    if [ -f "$TEAM_DIR/PROJECT_STATUS.md" ]; then
        grep -c "BLOCKED" "$TEAM_DIR/PROJECT_STATUS.md" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Check if DO role exists
has_do_role() {
    [ -f "$TEAM_DIR/DOC_OPTIMIZER.md" ]
}

# Check if DO should run (3+ completed phases since last optimization)
should_run_do() {
    if ! has_do_role; then
        return 1
    fi

    local completed
    completed=$(count_completed_phases)

    if [ -f "$TEAM_DIR/OPTIMIZATION_LOG.md" ]; then
        local last_opt_count
        last_opt_count=$(grep -c "^### " "$TEAM_DIR/OPTIMIZATION_LOG.md" 2>/dev/null || echo 0)
        if [ "$last_opt_count" -eq 0 ] && [ "$completed" -ge 3 ]; then
            return 0
        fi
        # Simple heuristic: if there are optimization entries and many completed phases,
        # suggest DO every 3 additional completed phases
        if [ "$completed" -ge 3 ]; then
            return 0
        fi
    elif [ "$completed" -ge 3 ]; then
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────
# Decision Engine
# ─────────────────────────────────────────────────────────────

# Returns: ROLE|CONTEXT_MSG|IS_QUALITY_GATE
# ROLE: pd, dd, dd-review, team, doc, none
# IS_QUALITY_GATE: yes/no (determines if --no-confirm still asks)
determine_next() {
    local new_directives unreviewed latest_verdict active_phase unchecked
    local total_reports total_reviews blocked

    new_directives=$(count_directives "NEW")
    total_reports=$(count_reports)
    total_reviews=$(count_reviews)
    latest_verdict=$(get_latest_verdict)
    active_phase=$(get_active_phase)
    active_phase_name=$(get_active_phase_name)
    blocked=$(count_blocked_phases)

    # Unreviewed = reports > reviews (simple heuristic)
    unreviewed=$((total_reports - total_reviews))
    if [ "$unreviewed" -lt 0 ]; then unreviewed=0; fi

    # Priority 1: BLOCKED phases need PD attention
    if [ "$blocked" -gt 0 ]; then
        echo "pd|Phase is BLOCKED — PD needs to resolve the blocker.|yes"
        return
    fi

    # Priority 2: Unreviewed reports → DD should review
    if [ "$unreviewed" -gt 0 ]; then
        local latest_report
        latest_report=$(get_latest_report)
        local report_name
        report_name=$(basename "$latest_report" 2>/dev/null || echo "report")
        echo "dd|Team submitted $report_name — please review.|yes"
        return
    fi

    # Priority 3: NEEDS_FIXES → Team should fix
    if [ "$latest_verdict" = "NEEDS_FIXES" ]; then
        echo "team|DD reviewed and found issues (NEEDS_FIXES). Check DECISIONS.md for specific items to fix.|no"
        return
    fi

    # Priority 4: NEW directives → DD should process
    if [ "$new_directives" -gt 0 ]; then
        local directive_file
        directive_file=$(get_directives_by_status "NEW" | head -1)
        local directive_name
        directive_name=$(basename "$directive_file" 2>/dev/null || echo "directive")
        echo "dd|New directive to process: $directive_name|no"
        return
    fi

    # Priority 5: Active phase with unchecked TODOs → Team should implement
    if [ -n "$active_phase" ]; then
        unchecked=$(count_unchecked_todos "$active_phase")
        if [ "$unchecked" -gt 0 ]; then
            echo "team|Phase $active_phase ($active_phase_name) has $unchecked unchecked tasks. Green light to implement.|no"
            return
        fi

        # All TODOs checked but no report yet? Team should write report
        local checked
        checked=$(count_unchecked_todos "$active_phase")
        if [ "$checked" -eq 0 ] && [ "$total_reports" -eq "$total_reviews" ]; then
            echo "team|All Phase $active_phase tasks are checked. Write the implementation report.|no"
            return
        fi
    fi

    # Priority 6: Phase just accepted → PD should update status
    if [ "$latest_verdict" = "ACCEPTED" ]; then
        echo "pd|Phase was ACCEPTED by DD. Update PROJECT_STATUS.md and decide next steps.|yes"
        return
    fi

    # Priority 7: No active phase → PD should issue new directive
    if [ -z "$active_phase" ]; then
        echo "pd|No active phase. Review project status and issue a new directive.|yes"
        return
    fi

    # Priority 8: DO suggestion
    if should_run_do; then
        echo "doc|Multiple phases completed. Consider running Documentation Optimizer.|no"
        return
    fi

    # Nothing to do
    echo "none|Project is in a steady state. No immediate action needed.|no"
}

# ─────────────────────────────────────────────────────────────
# Display: Status Dashboard
# ─────────────────────────────────────────────────────────────

show_status() {
    local new_dir proc_dir comp_dir total_reports total_reviews
    local unchecked_total total_todos completed blocked active_phase

    new_dir=$(count_directives "NEW")
    proc_dir=$(count_directives "PROCESSED")
    comp_dir=$(count_directives "COMPLETED")
    total_reports=$(count_reports)
    total_reviews=$(count_reviews)
    unchecked_total=$(count_unchecked_todos)
    total_todos=$(count_total_todos)
    completed=$(count_completed_phases)
    blocked=$(count_blocked_phases)
    active_phase=$(get_active_phase)
    active_phase_name=$(get_active_phase_name)
    latest_verdict=$(get_latest_verdict)

    local unreviewed=$((total_reports - total_reviews))
    if [ "$unreviewed" -lt 0 ]; then unreviewed=0; fi
    local checked=$((total_todos - unchecked_total))

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  AI Team Framework — Project Status${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Active phase
    if [ -n "$active_phase" ]; then
        echo -e "  Active Phase: ${CYAN}$active_phase — $active_phase_name${NC}"
    else
        echo -e "  Active Phase: ${DIM}none${NC}"
    fi
    echo ""

    # Document counts
    echo -e "  ${BOLD}Documents:${NC}"
    local dir_total=$((new_dir + proc_dir + comp_dir))
    echo -e "    Directives:  $dir_total total${new_dir:+ (${YELLOW}$new_dir NEW${NC})}${proc_dir:+, $proc_dir processed}${comp_dir:+, $comp_dir completed}"
    echo -e "    TODO items:  $checked checked / $total_todos total"
    echo -e "    Reports:     $total_reports total${unreviewed:+ (${YELLOW}$unreviewed unreviewed${NC})}"
    echo -e "    Phases:      $completed completed${blocked:+, ${RED}$blocked BLOCKED${NC}}"
    if [ -n "$latest_verdict" ]; then
        local verdict_color="$NC"
        case "$latest_verdict" in
            ACCEPTED) verdict_color="$GREEN" ;;
            NEEDS_FIXES) verdict_color="$YELLOW" ;;
            REJECTED) verdict_color="$RED" ;;
        esac
        echo -e "    Last verdict: ${verdict_color}$latest_verdict${NC}"
    fi
    echo ""

    # Signals
    local has_signals=false
    if [ "$new_dir" -gt 0 ]; then
        echo -e "  ${YELLOW}[!]${NC} $new_dir new directive(s) awaiting DD processing"
        has_signals=true
    fi
    if [ "$unreviewed" -gt 0 ]; then
        echo -e "  ${YELLOW}[!]${NC} $unreviewed unreviewed report(s)"
        has_signals=true
    fi
    if [ "$latest_verdict" = "NEEDS_FIXES" ]; then
        echo -e "  ${YELLOW}[!]${NC} Latest verdict is NEEDS_FIXES — Team must address issues"
        has_signals=true
    fi
    if [ "$blocked" -gt 0 ]; then
        echo -e "  ${RED}[!]${NC} $blocked phase(s) BLOCKED"
        has_signals=true
    fi
    if should_run_do 2>/dev/null; then
        echo -e "  ${CYAN}[i]${NC} Documentation Optimizer recommended ($completed phases completed)"
        has_signals=true
    fi
    if [ "$has_signals" = false ]; then
        echo -e "  ${GREEN}[✓]${NC} No pending signals"
    fi
    echo ""

    # Recommendation
    local result
    result=$(determine_next)
    local role context
    role=$(echo "$result" | cut -d'|' -f1)
    context=$(echo "$result" | cut -d'|' -f2)

    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ "$role" = "none" ]; then
        echo -e "  ${GREEN}Recommendation: No action needed${NC}"
    else
        local role_display=""
        case "$role" in
            pd) role_display="PD (Project Director)" ;;
            dd) role_display="DD (Development Director)" ;;
            team) role_display="Team (Development Team)" ;;
            doc) role_display="DO (Documentation Optimizer)" ;;
        esac
        echo -e "  Recommendation: ${CYAN}Run $role_display${NC}"
        echo ""
        echo -e "  Context: $context"
        echo ""
        echo -e "  Command: ${BOLD}./start_role.sh $role${NC}"
    fi
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ─────────────────────────────────────────────────────────────
# Display: Suggest Mode
# ─────────────────────────────────────────────────────────────

show_suggest() {
    local result
    result=$(determine_next)
    local role context
    role=$(echo "$result" | cut -d'|' -f1)
    context=$(echo "$result" | cut -d'|' -f2)

    echo ""
    if [ "$role" = "none" ]; then
        echo -e "${GREEN}No action needed.${NC} Project is in a steady state."
    else
        local role_display=""
        local role_file=""
        case "$role" in
            pd) role_display="PD (Project Director)"; role_file="PROJECT_DIRECTOR.md" ;;
            dd) role_display="DD (Development Director)"; role_file="DEVELOPMENT_DIRECTOR.md" ;;
            team) role_display="Team (Development Team)"; role_file="DEVELOPMENT_TEAM.md" ;;
            doc) role_display="DO (Documentation Optimizer)"; role_file="DOC_OPTIMIZER.md" ;;
        esac

        echo -e "  Next: ${BOLD}$role_display${NC}"
        echo ""
        echo -e "  ${DIM}$context${NC}"
        echo ""
        echo -e "  Tell the role: ${CYAN}\"Read $TEAM_DIR/$role_file and follow the startup protocol."
        echo -e "  $context\"${NC}"
        echo ""
        echo -e "  Run: ${BOLD}./start_role.sh $role${NC}"
    fi
    echo ""
}

# ─────────────────────────────────────────────────────────────
# Auto Mode
# ─────────────────────────────────────────────────────────────

run_auto() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  AI Team Framework — Auto Orchestrator${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    while true; do
        local result
        result=$(determine_next)
        local role context is_gate
        role=$(echo "$result" | cut -d'|' -f1)
        context=$(echo "$result" | cut -d'|' -f2)
        is_gate=$(echo "$result" | cut -d'|' -f3)

        if [ "$role" = "none" ]; then
            echo -e "${GREEN}No further actions needed.${NC} Project is in a steady state."
            echo ""
            break
        fi

        local role_display=""
        case "$role" in
            pd) role_display="PD (Project Director)" ;;
            dd) role_display="DD (Development Director)" ;;
            team) role_display="Team (Development Team)" ;;
            doc) role_display="DO (Documentation Optimizer)" ;;
        esac

        echo -e "  Next: ${CYAN}$role_display${NC}"
        echo -e "  ${DIM}$context${NC}"
        echo ""

        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[dry-run]${NC} Would run: ./start_role.sh $role"
            echo ""
            break
        fi

        # Determine if we need confirmation
        local needs_confirm=true
        if [ "$NO_CONFIRM" = true ] && [ "$is_gate" = "no" ]; then
            needs_confirm=false
        fi

        if [ "$needs_confirm" = true ]; then
            local prompt_text="Run $role_display? [Y/n/quit]: "
            read -rp "$(echo -e "  ${BOLD}$prompt_text${NC}")" answer
            answer="${answer:-y}"

            case "$answer" in
                y|Y|yes|da)
                    ;;
                q|quit|exit)
                    echo ""
                    echo "Orchestrator stopped."
                    break
                    ;;
                *)
                    echo ""
                    echo "Skipped. Re-evaluating..."
                    echo ""
                    continue
                    ;;
            esac
        else
            echo -e "  ${DIM}Auto-advancing (routine transition)...${NC}"
        fi

        echo ""

        # Run the role
        ./start_role.sh "$role" || true

        echo ""
        echo -e "${DIM}Session ended. Re-evaluating state...${NC}"
        echo ""
    done
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────

if [ "$MODE" = "help" ]; then
    show_help
    exit 0
fi

check_team_dir

case "$MODE" in
    status) show_status ;;
    suggest) show_suggest ;;
    auto) run_auto ;;
    *) show_help; exit 1 ;;
esac

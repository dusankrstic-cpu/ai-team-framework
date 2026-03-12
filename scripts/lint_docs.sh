#!/usr/bin/env bash
# AI Team Framework — Document Linter
#
# Validates the structure and format of team documents before role handoff.
# Catches common formatting issues that would confuse the next role.
#
# Usage:
#   lint_docs.sh [options]
#
# Options:
#   --fix        Auto-fix simple issues (trailing whitespace, missing newlines)
#   --strict     Treat warnings as errors
#   --quiet      Only show errors, not warnings
#   --team-dir   Override TEAM_DIR (default: docs/TEAM)
#   --help       Show help

set -euo pipefail

TEAM_DIR="${TEAM_DIR:-docs/TEAM}"
FIX=false
STRICT=false
QUIET=false
ERRORS=0
WARNINGS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix) FIX=true; shift ;;
        --strict) STRICT=true; shift ;;
        --quiet) QUIET=true; shift ;;
        --team-dir) TEAM_DIR="$2"; shift 2 ;;
        --help|-h)
            echo "AI Team Framework — Document Linter"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --fix        Auto-fix simple issues (trailing whitespace, missing newlines)"
            echo "  --strict     Treat warnings as errors"
            echo "  --quiet      Only show errors, not warnings"
            echo "  --team-dir   Override TEAM_DIR (default: docs/TEAM)"
            echo "  --help       Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

error() {
    echo -e "  ${RED}ERROR${NC}  $1: $2"
    ERRORS=$((ERRORS + 1))
}

warn() {
    if [ "$STRICT" = true ]; then
        error "$1" "$2"
        return
    fi
    if [ "$QUIET" = false ]; then
        echo -e "  ${YELLOW}WARN${NC}   $1: $2"
    fi
    WARNINGS=$((WARNINGS + 1))
}

info() {
    if [ "$QUIET" = false ]; then
        echo -e "  ${GREEN}OK${NC}     $1"
    fi
}

# ─────────────────────────────────────────────────────────────
# Preflight
# ─────────────────────────────────────────────────────────────

if [ ! -d "$TEAM_DIR" ]; then
    echo -e "${RED}Error: Team directory '$TEAM_DIR' not found.${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  AI Team Framework — Document Linter${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# Check: Required files exist
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking required files...${NC}"

required_files=(
    "PROJECT_DIRECTOR.md"
    "DEVELOPMENT_DIRECTOR.md"
    "DEVELOPMENT_TEAM.md"
    "PROJECT_STATUS.md"
    "DECISIONS.md"
    "TODO.md"
    "ARCHITECTURE_VISION.md"
    "DIRECTIVE_TEMPLATE.md"
    "REPORT_TEMPLATE.md"
)

for f in "${required_files[@]}"; do
    if [ ! -f "$TEAM_DIR/$f" ]; then
        error "$f" "Required file missing"
    else
        info "$f exists"
    fi
done

# Check required directories
for d in "DIRECTIVES" "REPORTS"; do
    if [ ! -d "$TEAM_DIR/$d" ]; then
        error "$d/" "Required directory missing"
    fi
done

# Check optional DO files (only warn if partial)
if [ -f "$TEAM_DIR/DOC_OPTIMIZER.md" ]; then
    for f in "OPTIMIZATION_LOG.md" "ARCHIVE_INDEX.md"; do
        if [ ! -f "$TEAM_DIR/$f" ]; then
            error "$f" "DOC_OPTIMIZER.md exists but $f is missing"
        fi
    done
    if [ ! -d "$TEAM_DIR/ARCHIVE" ]; then
        error "ARCHIVE/" "DOC_OPTIMIZER.md exists but ARCHIVE/ directory is missing"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Check: TODO.md checkbox format
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking TODO.md format...${NC}"

if [ -f "$TEAM_DIR/TODO.md" ]; then
    # Check for malformed checkboxes
    malformed=$(grep -n "^- \[" "$TEAM_DIR/TODO.md" | grep -v "^[0-9]*:- \[ \]" | grep -v "^[0-9]*:- \[x\]" | grep -v "^[0-9]*:- \[X\]" || true)
    if [ -n "$malformed" ]; then
        while IFS= read -r line; do
            error "TODO.md" "Malformed checkbox at line $(echo "$line" | cut -d: -f1): $(echo "$line" | cut -d: -f2-)"
        done <<< "$malformed"
    else
        info "TODO.md checkboxes are valid"
    fi

    # Check for phase headers
    phase_headers=$(grep -c "^## Phase" "$TEAM_DIR/TODO.md" || echo 0)
    if [ "$phase_headers" -eq 0 ]; then
        warn "TODO.md" "No phase headers found (expected '## Phase N')"
    else
        info "TODO.md has $phase_headers phase header(s)"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Check: DECISIONS.md entry format
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking DECISIONS.md format...${NC}"

if [ -f "$TEAM_DIR/DECISIONS.md" ]; then
    # Check entries have the correct header format
    entries=$(grep -c "^### " "$TEAM_DIR/DECISIONS.md" || echo 0)
    if [ "$entries" -gt 0 ]; then
        # Check for entries without type
        no_type=$(grep "^### " "$TEAM_DIR/DECISIONS.md" | grep -v "— \(REVIEW\|DECISION\|GUIDELINE\|VISION_CHANGE_PROPOSAL\)" || true)
        if [ -n "$no_type" ]; then
            while IFS= read -r line; do
                warn "DECISIONS.md" "Entry missing type: $line"
            done <<< "$no_type"
        else
            info "DECISIONS.md entries have correct types"
        fi

        # Check for entries without Context/Decision fields
        reviews=$(grep -c "^### .*— REVIEW" "$TEAM_DIR/DECISIONS.md" || echo 0)
        decisions_field=$(grep -c "^\*\*Decision:\*\*" "$TEAM_DIR/DECISIONS.md" || echo 0)
        if [ "$reviews" -gt 0 ] && [ "$decisions_field" -lt "$reviews" ]; then
            warn "DECISIONS.md" "Some REVIEW entries may be missing **Decision:** field ($decisions_field found for $reviews reviews)"
        fi
    fi
    info "DECISIONS.md has $entries entries"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Check: Directive files
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking directives...${NC}"

if [ -d "$TEAM_DIR/DIRECTIVES" ]; then
    directive_count=0
    for f in "$TEAM_DIR/DIRECTIVES"/DIRECTIVE_*.md; do
        [ -f "$f" ] || continue
        directive_count=$((directive_count + 1))
        fname=$(basename "$f")

        # Check for Status field
        if ! grep -q "^\*\*Status:\*\*" "$f"; then
            error "$fname" "Missing **Status:** field"
        else
            status=$(grep "^\*\*Status:\*\*" "$f" | head -1 | sed 's/.*\*\*Status:\*\* *//')
            case "$status" in
                NEW|PROCESSED|COMPLETED) ;;
                *) error "$fname" "Invalid status: '$status' (expected NEW/PROCESSED/COMPLETED)" ;;
            esac
        fi

        # Check for Date field
        if ! grep -q "^\*\*Date:\*\*" "$f"; then
            warn "$fname" "Missing **Date:** field"
        fi

        # Check naming convention
        if ! echo "$fname" | grep -qE "^DIRECTIVE_[0-9]{4}-[0-9]{2}-[0-9]{2}_"; then
            warn "$fname" "Doesn't follow naming convention DIRECTIVE_YYYY-MM-DD_topic.md"
        fi
    done
    info "Checked $directive_count directive(s)"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Check: Report files
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking reports...${NC}"

if [ -d "$TEAM_DIR/REPORTS" ]; then
    report_count=0
    for f in "$TEAM_DIR/REPORTS"/REPORT_*.md; do
        [ -f "$f" ] || continue
        report_count=$((report_count + 1))
        fname=$(basename "$f")

        # Check for Status field
        if ! grep -q "^\*\*Status:\*\*" "$f"; then
            error "$fname" "Missing **Status:** field"
        else
            status=$(grep "^\*\*Status:\*\*" "$f" | head -1 | sed 's/.*\*\*Status:\*\* *//')
            case "$status" in
                COMPLETED|PARTIAL|BLOCKED) ;;
                *) error "$fname" "Invalid status: '$status' (expected COMPLETED/PARTIAL/BLOCKED)" ;;
            esac
        fi

        # Check naming convention
        if ! echo "$fname" | grep -qE "^REPORT_[0-9]{4}-[0-9]{2}-[0-9]{2}_PHASE-[0-9]"; then
            warn "$fname" "Doesn't follow naming convention REPORT_YYYY-MM-DD_PHASE-N.md"
        fi
    done
    info "Checked $report_count report(s)"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Check: PROJECT_STATUS.md phase table
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking PROJECT_STATUS.md...${NC}"

if [ -f "$TEAM_DIR/PROJECT_STATUS.md" ]; then
    # Check for valid phase statuses
    invalid_status=$(grep "^|" "$TEAM_DIR/PROJECT_STATUS.md" | grep -v "^|.*|.*|" | grep -v "^|-" || true)
    if [ -n "$invalid_status" ]; then
        warn "PROJECT_STATUS.md" "Malformed table rows detected"
    fi

    # Check for known status values in table
    phase_lines=$(grep "^| [0-9]" "$TEAM_DIR/PROJECT_STATUS.md" || true)
    if [ -n "$phase_lines" ]; then
        while IFS= read -r line; do
            if ! echo "$line" | grep -qE "(NOT_STARTED|IN_PROGRESS|COMPLETED|BLOCKED)"; then
                warn "PROJECT_STATUS.md" "Phase row missing valid status: $line"
            fi
        done <<< "$phase_lines"
        info "PROJECT_STATUS.md phase table looks valid"
    else
        warn "PROJECT_STATUS.md" "No phase rows found in table"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Check: Cross-reference consistency
# ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Checking cross-references...${NC}"

# Count reports vs reviews
if [ -f "$TEAM_DIR/DECISIONS.md" ] && [ -d "$TEAM_DIR/REPORTS" ]; then
    report_count=$(find "$TEAM_DIR/REPORTS" -name "REPORT_*.md" 2>/dev/null | wc -l)
    review_count=$(grep -c "^### .*— REVIEW" "$TEAM_DIR/DECISIONS.md" 2>/dev/null || echo 0)
    if [ "$report_count" -gt "$review_count" ]; then
        warn "cross-ref" "$((report_count - review_count)) report(s) have no corresponding REVIEW in DECISIONS.md"
    else
        info "Reports and reviews are in sync ($report_count/$review_count)"
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Auto-fix (if --fix)
# ─────────────────────────────────────────────────────────────

if [ "$FIX" = true ]; then
    echo -e "${CYAN}Applying auto-fixes...${NC}"
    fix_count=0

    for f in "$TEAM_DIR"/*.md; do
        [ -f "$f" ] || continue

        # Fix trailing whitespace
        if grep -qP "[ \t]+$" "$f" 2>/dev/null; then
            sed -i 's/[[:space:]]*$//' "$f"
            fix_count=$((fix_count + 1))
            info "$(basename "$f"): removed trailing whitespace"
        fi

        # Fix missing final newline
        if [ -s "$f" ] && [ "$(tail -c1 "$f" | wc -l)" -eq 0 ]; then
            echo "" >> "$f"
            fix_count=$((fix_count + 1))
            info "$(basename "$f"): added final newline"
        fi
    done

    if [ "$fix_count" -eq 0 ]; then
        info "No auto-fixable issues found"
    fi
    echo ""
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "  ${GREEN}All checks passed.${NC}"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${YELLOW}$WARNINGS warning(s), 0 errors.${NC}"
else
    echo -e "  ${RED}$ERRORS error(s)${NC}, ${YELLOW}$WARNINGS warning(s)${NC}"
fi
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0

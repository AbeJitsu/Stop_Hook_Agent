#!/bin/bash

# Core utilities for stop hook validation
# Single source of truth for common operations

# Colors (defined once)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export NC='\033[0m'

# State management
export STATE_FILE=".claude/state.json"
export CLAUDE_DIR=".claude"

# Ensure .claude directory exists
mkdir -p "$CLAUDE_DIR"

# Git operations
git_status() {
    git status --porcelain 2>/dev/null
}

git_diff() {
    git diff --name-only 2>/dev/null
}

git_staged() {
    git diff --cached --name-only 2>/dev/null
}

git_log_recent() {
    git log --oneline -n "${1:-5}" 2>/dev/null
}

# JSON operations
read_json() {
    local file="$1"
    local key="$2"
    if [ -f "$file" ]; then
        if [ -n "$key" ]; then
            jq -r ".$key // empty" "$file" 2>/dev/null
        else
            cat "$file" 2>/dev/null
        fi
    else
        echo "{}"
    fi
}

write_json() {
    local file="$1"
    local content="$2"
    echo "$content" | jq '.' > "$file" 2>/dev/null
}

update_json() {
    local file="$1"
    local key="$2"
    local value="$3"
    local current=$(read_json "$file")
    echo "$current" | jq ".$key = $value" > "$file"
}

# Todo operations
get_todos() {
    read_json "$STATE_FILE" "todos" || echo "[]"
}

count_todos() {
    local todos=$(get_todos)
    echo "$todos" | jq 'length' 2>/dev/null || echo "0"
}

get_completed_todos() {
    local todos=$(get_todos)
    echo "$todos" | jq '[.[] | select(.status == "completed")]' 2>/dev/null || echo "[]"
}

# Test execution
run_tests() {
    local test_command="$1"
    if [ -n "$test_command" ]; then
        eval "$test_command" 2>&1
        return $?
    fi
    return 1
}

# Output utilities
print_header() {
    echo -e "${BLUE}$1${NC}"
    echo "=============================================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Validation result tracking
init_results() {
    echo '{"passed": 0, "total": 0, "details": []}' > "$STATE_FILE.tmp"
}

add_result() {
    local test_name="$1"
    local passed="$2"
    local message="$3"
    
    local current=$(cat "$STATE_FILE.tmp" 2>/dev/null || echo '{"passed": 0, "total": 0, "details": []}')
    local new_total=$(echo "$current" | jq '.total + 1')
    local new_passed=$(echo "$current" | jq ".passed + $([ "$passed" = "true" ] && echo 1 || echo 0)")
    
    echo "$current" | jq \
        --arg name "$test_name" \
        --arg pass "$passed" \
        --arg msg "$message" \
        '.total = '$new_total' | .passed = '$new_passed' | .details += [{"name": $name, "passed": ($pass == "true"), "message": $msg}]' \
        > "$STATE_FILE.tmp"
}

get_results_summary() {
    local results=$(cat "$STATE_FILE.tmp" 2>/dev/null || echo '{"passed": 0, "total": 0}')
    local passed=$(echo "$results" | jq '.passed')
    local total=$(echo "$results" | jq '.total')
    echo "$passed/$total"
}

# Error handling
handle_error() {
    local exit_code=$?
    local error_msg="$1"
    if [ $exit_code -ne 0 ]; then
        print_error "$error_msg (exit code: $exit_code)"
        return $exit_code
    fi
    return 0
}
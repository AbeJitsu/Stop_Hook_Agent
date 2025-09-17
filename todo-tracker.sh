#!/bin/bash

# Todo State Tracking System for Claude Code
# Captures and compares todo states to validate work completion

TODO_DIR=".claude"
TODO_CURRENT="$TODO_DIR/todos-current.json"
TODO_SNAPSHOT="$TODO_DIR/todos-snapshot.json"
TODO_VALIDATION="$TODO_DIR/todos-validation.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure .claude directory exists
mkdir -p "$TODO_DIR"

# Function to capture current todo state
capture_todo_snapshot() {
    echo -e "${BLUE}📸 Capturing todo state snapshot...${NC}"
    
    # Check if we can extract todos from Claude's session
    # This would typically come from Claude's internal state
    # For now, we'll create a mock structure to demonstrate
    
    if [ ! -f "$TODO_CURRENT" ]; then
        echo "[]" > "$TODO_CURRENT"
    fi
    
    # Copy current state to snapshot for comparison
    cp "$TODO_CURRENT" "$TODO_SNAPSHOT"
    echo -e "${GREEN}✅ Todo snapshot captured${NC}"
}

# Function to extract todos from Claude's session (mock implementation)
extract_current_todos() {
    echo -e "${BLUE}🔍 Extracting current todo state...${NC}"
    
    # In a real implementation, this would interface with Claude's todo system
    # For demonstration, we'll check for a todos file or create a sample
    
    cat > "$TODO_CURRENT" << 'EOF'
[
  {
    "id": "1",
    "content": "Implement todo state tracking system with snapshots",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "id": "2", 
    "content": "Create todo-git change mapping validation",
    "status": "pending",
    "priority": "high"
  },
  {
    "id": "3",
    "content": "Build comprehensive validation logic for todos", 
    "status": "pending",
    "priority": "high"
  }
]
EOF
    
    echo -e "${GREEN}✅ Current todos extracted${NC}"
}

# Function to compare todo states
compare_todo_states() {
    echo -e "${BLUE}⚖️  Comparing todo states...${NC}"
    
    if [ ! -f "$TODO_SNAPSHOT" ] || [ ! -f "$TODO_CURRENT" ]; then
        echo -e "${YELLOW}⚠️  Missing todo files for comparison${NC}"
        return 1
    fi
    
    # Extract completed todos from this iteration
    local completed_todos=$(node -e "
    const before = JSON.parse(require('fs').readFileSync('$TODO_SNAPSHOT', 'utf8'));
    const after = JSON.parse(require('fs').readFileSync('$TODO_CURRENT', 'utf8'));
    
    const beforeMap = new Map(before.map(t => [t.id, t.status]));
    const completed = after.filter(todo => 
        beforeMap.has(todo.id) && 
        beforeMap.get(todo.id) !== 'completed' && 
        todo.status === 'completed'
    );
    
    console.log(JSON.stringify(completed, null, 2));
    " 2>/dev/null)
    
    # Save completed todos for validation
    echo "$completed_todos" > "$TODO_VALIDATION"
    
    local count=$(echo "$completed_todos" | jq length 2>/dev/null || echo "0")
    
    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $count newly completed todos${NC}"
        echo "$completed_todos" | jq -r '.[] | "  - " + .content' 2>/dev/null || echo "  Error parsing todos"
    else
        echo -e "${YELLOW}⚠️  No todos marked as completed this iteration${NC}"
    fi
    
    return 0
}

# Function to get pending/in-progress todos
get_incomplete_todos() {
    echo -e "${BLUE}📋 Checking incomplete todos...${NC}"
    
    local incomplete=$(jq '[.[] | select(.status=="pending" or .status=="in_progress")]' "$TODO_CURRENT" 2>/dev/null || echo "[]")
    local count=$(echo "$incomplete" | jq length 2>/dev/null || echo "0")
    
    if [ "$count" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $count todos still incomplete:${NC}"
        echo "$incomplete" | jq -r '.[] | "  - [" + .status + "] " + .content' 2>/dev/null || echo "  Error parsing incomplete todos"
        return 1
    else
        echo -e "${GREEN}✅ All todos completed!${NC}"
        return 0
    fi
}

# Function to validate todo completion against git changes
validate_todos_against_git() {
    echo -e "${BLUE}🔍 Validating completed todos against git changes...${NC}"
    
    if [ ! -f "$TODO_VALIDATION" ]; then
        echo -e "${YELLOW}⚠️  No completed todos to validate${NC}"
        return 0
    fi
    
    local git_changes=$(git status --porcelain 2>/dev/null || echo "")
    local git_diff=$(git diff HEAD 2>/dev/null || echo "")
    
    if [ -z "$git_changes" ] && [ -z "$git_diff" ]; then
        echo -e "${YELLOW}⚠️  No git changes detected but todos marked complete${NC}"
        return 1
    fi
    
    # Get completed todos
    local completed_todos=$(cat "$TODO_VALIDATION" 2>/dev/null || echo "[]")
    local count=$(echo "$completed_todos" | jq length 2>/dev/null || echo "0")
    
    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}✅ Validating $count completed todos against changes:${NC}"
        
        # List git changes
        echo -e "${BLUE}📁 Git changes detected:${NC}"
        if [ -n "$git_changes" ]; then
            echo "$git_changes" | sed 's/^/  /'
        fi
        
        # Store validation data for AI review
        cat > "$TODO_DIR/validation-context.json" << EOF
{
  "completed_todos": $completed_todos,
  "git_status": "$(echo "$git_changes" | sed 's/"/\\"/g')",
  "git_diff": "$(echo "$git_diff" | sed 's/"/\\"/g' | head -100)",
  "validation_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        
        echo -e "${GREEN}✅ Validation context prepared${NC}"
        return 0
    else
        echo -e "${GREEN}✅ No completed todos to validate${NC}"
        return 0
    fi
}

# Function to generate summary report
generate_summary_report() {
    echo -e "\n${BLUE}📊 TODO VALIDATION SUMMARY${NC}"
    echo "=================================="
    
    # Count todos by status
    local total=$(jq length "$TODO_CURRENT" 2>/dev/null || echo "0")
    local completed=$(jq '[.[] | select(.status=="completed")] | length' "$TODO_CURRENT" 2>/dev/null || echo "0")
    local in_progress=$(jq '[.[] | select(.status=="in_progress")] | length' "$TODO_CURRENT" 2>/dev/null || echo "0")
    local pending=$(jq '[.[] | select(.status=="pending")] | length' "$TODO_CURRENT" 2>/dev/null || echo "0")
    
    echo "Total todos: $total"
    echo "Completed: $completed"
    echo "In progress: $in_progress" 
    echo "Pending: $pending"
    
    # Calculate completion percentage
    if [ "$total" -gt 0 ]; then
        local percentage=$((completed * 100 / total))
        echo "Completion rate: $percentage%"
        
        if [ "$percentage" -eq 100 ]; then
            echo -e "${GREEN}🎉 All todos completed!${NC}"
            return 0
        elif [ "$percentage" -gt 75 ]; then
            echo -e "${GREEN}✅ Nearly complete!${NC}"
            return 0
        elif [ "$percentage" -gt 50 ]; then
            echo -e "${YELLOW}⚠️  Making good progress${NC}"
            return 1
        else
            echo -e "${RED}❌ Significant work remaining${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  No todos found${NC}"
        return 1
    fi
}

# Main execution function
main() {
    local action=${1:-"validate"}
    
    case $action in
        "capture")
            capture_todo_snapshot
            ;;
        "extract")
            extract_current_todos
            ;;
        "compare")
            compare_todo_states
            ;;
        "validate")
            echo -e "${BLUE}🚀 Running todo validation...${NC}\n"
            capture_todo_snapshot
            extract_current_todos
            compare_todo_states
            validate_todos_against_git
            local incomplete_result
            get_incomplete_todos
            incomplete_result=$?
            generate_summary_report
            local summary_result=$?
            
            # Return success only if all todos are complete and validation passes
            if [ $incomplete_result -eq 0 ] && [ $summary_result -eq 0 ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            echo "Usage: $0 [capture|extract|compare|validate]"
            echo "  capture - Take snapshot of current todo state"
            echo "  extract - Extract current todos from session"
            echo "  compare - Compare snapshots to find completed todos"
            echo "  validate - Run full validation (default)"
            exit 1
            ;;
    esac
}

# Run with provided arguments
main "$@"
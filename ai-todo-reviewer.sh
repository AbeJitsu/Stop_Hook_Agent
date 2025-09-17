#!/bin/bash

# AI-Powered Todo Validation Script
# Uses Claude Code to intelligently review todo completion against actual changes

TODO_DIR=".claude"
REVIEW_CONTEXT="$TODO_DIR/ai-review-context.json"
REVIEW_RESULT="$TODO_DIR/ai-review-result.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to prepare AI review context
prepare_review_context() {
    echo -e "${BLUE}📋 Preparing context for AI review...${NC}"
    
    # Get current todos
    local current_todos="[]"
    if [ -f "$TODO_DIR/todos-current.json" ]; then
        current_todos=$(cat "$TODO_DIR/todos-current.json")
    fi
    
    # Get completed todos from validation context
    local completed_todos="[]"
    if [ -f "$TODO_DIR/validation-context.json" ]; then
        completed_todos=$(jq '.completed_todos // []' "$TODO_DIR/validation-context.json" 2>/dev/null || echo "[]")
    fi
    
    # Get git information
    local git_status=$(git status --porcelain 2>/dev/null || echo "")
    local git_diff=$(git diff HEAD 2>/dev/null | head -200 || echo "")
    local changed_files=$(git diff --name-only HEAD 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
    
    # Get todo mapping results if available
    local mapping_data="{}"
    if [ -f "$TODO_DIR/todo-git-mapping.json" ]; then
        mapping_data=$(cat "$TODO_DIR/todo-git-mapping.json")
    fi
    
    # Create comprehensive context for AI review
    cat > "$REVIEW_CONTEXT" << EOF
{
  "review_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_todos": $current_todos,
  "completed_todos": $completed_todos,
  "git_context": {
    "status": "$(echo "$git_status" | sed 's/"/\\"/g')",
    "changed_files": "$changed_files",
    "diff_preview": "$(echo "$git_diff" | sed 's/"/\\"/g')"
  },
  "mapping_analysis": $mapping_data,
  "review_criteria": {
    "todo_completion_accuracy": "Do completed todos actually match the code changes?",
    "change_completeness": "Are all necessary changes present for each todo?",
    "code_quality": "Do the changes represent good quality implementation?",
    "missing_work": "What work might be missing or incomplete?",
    "false_completions": "Are any todos marked complete incorrectly?"
  }
}
EOF
    
    echo -e "${GREEN}✅ AI review context prepared${NC}"
}

# Function to run AI review using Claude Code
run_ai_review() {
    echo -e "${BLUE}🤖 Running AI-powered todo review...${NC}"
    
    if [ ! -f "$REVIEW_CONTEXT" ]; then
        echo -e "${RED}❌ No review context available${NC}"
        return 1
    fi
    
    # Create AI review prompt
    local ai_prompt="You are a code review expert analyzing todo completion accuracy.

Review Context:
$(cat "$REVIEW_CONTEXT")

Please analyze:

1. **Todo Completion Accuracy**: For each completed todo, verify if the git changes actually fulfill the requirements
2. **Missing Implementation**: Identify any todos marked complete but lacking corresponding code changes
3. **Code Quality**: Assess if changes represent proper implementation
4. **Incomplete Work**: Find any remaining work or partial implementations
5. **Overall Assessment**: Rate completion accuracy (0-100%)

Respond with JSON in this format:
{
  \"overall_score\": <0-100>,
  \"completion_status\": \"PASS|PARTIAL|FAIL\",
  \"todo_reviews\": [
    {
      \"todo_id\": \"<id>\",
      \"todo_content\": \"<content>\", 
      \"accuracy_score\": <0-100>,
      \"status\": \"ACCURATE|PARTIAL|INACCURATE\",
      \"feedback\": \"<specific feedback>\"
    }
  ],
  \"missing_work\": [\"<description of missing work>\"],
  \"recommendations\": [\"<actionable recommendations>\"],
  \"summary\": \"<brief summary of findings>\"
}"
    
    # Use Claude Code to perform the review
    echo "$ai_prompt" | claude-code --non-interactive > "$REVIEW_RESULT" 2>/dev/null || {
        # Fallback: create a basic review if Claude Code fails
        echo -e "${YELLOW}⚠️  AI review unavailable, using basic analysis${NC}"
        create_fallback_review
        return $?
    }
    
    # Validate AI response
    if jq empty "$REVIEW_RESULT" 2>/dev/null; then
        echo -e "${GREEN}✅ AI review completed successfully${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  AI review returned invalid JSON, using fallback${NC}"
        create_fallback_review
        return $?
    fi
}

# Function to create fallback review when AI is unavailable
create_fallback_review() {
    echo -e "${BLUE}🔧 Creating fallback analysis...${NC}"
    
    local total_todos=$(jq '.completed_todos | length' "$REVIEW_CONTEXT" 2>/dev/null || echo "0")
    local changed_files_count=$(git diff --name-only HEAD 2>/dev/null | wc -l)
    
    # Basic scoring logic
    local score=50  # Start with neutral score
    
    if [ "$total_todos" -gt 0 ] && [ "$changed_files_count" -gt 0 ]; then
        score=$((score + 30))  # Has both todos and changes
    fi
    
    if [ "$changed_files_count" -ge "$total_todos" ]; then
        score=$((score + 20))  # Reasonable file-to-todo ratio
    fi
    
    local completion_status="PARTIAL"
    if [ "$score" -ge 80 ]; then
        completion_status="PASS"
    elif [ "$score" -lt 50 ]; then
        completion_status="FAIL"
    fi
    
    cat > "$REVIEW_RESULT" << EOF
{
  "overall_score": $score,
  "completion_status": "$completion_status",
  "todo_reviews": [],
  "missing_work": ["AI review unavailable - manual verification needed"],
  "recommendations": [
    "Verify todos manually against git changes",
    "Check code quality and completeness",
    "Ensure all requirements are met"
  ],
  "summary": "Fallback analysis: $total_todos todos completed, $changed_files_count files changed. Score: $score/100"
}
EOF
    
    return 0
}

# Function to display AI review results
display_review_results() {
    echo -e "\n${BLUE}🤖 AI REVIEW RESULTS${NC}"
    echo "========================================"
    
    if [ ! -f "$REVIEW_RESULT" ]; then
        echo -e "${RED}❌ No AI review results available${NC}"
        return 1
    fi
    
    # Parse and display results
    local overall_score=$(jq -r '.overall_score // 0' "$REVIEW_RESULT" 2>/dev/null)
    local completion_status=$(jq -r '.completion_status // "UNKNOWN"' "$REVIEW_RESULT" 2>/dev/null)
    local summary=$(jq -r '.summary // "No summary available"' "$REVIEW_RESULT" 2>/dev/null)
    
    echo "Overall Score: $overall_score/100"
    echo "Status: $completion_status"
    echo ""
    echo "Summary:"
    echo "$summary" | fold -w 70 | sed 's/^/  /'
    
    # Display individual todo reviews
    local todo_count=$(jq '.todo_reviews | length' "$REVIEW_RESULT" 2>/dev/null || echo "0")
    if [ "$todo_count" -gt 0 ]; then
        echo -e "\n${PURPLE}📋 Individual Todo Reviews:${NC}"
        jq -r '.todo_reviews[] | 
            "Todo: " + .todo_content + 
            "\n  Accuracy: " + (.accuracy_score | tostring) + "/100" +
            "\n  Status: " + .status +
            "\n  Feedback: " + .feedback + "\n"' \
            "$REVIEW_RESULT" 2>/dev/null || echo "Error parsing todo reviews"
    fi
    
    # Display missing work
    local missing_count=$(jq '.missing_work | length' "$REVIEW_RESULT" 2>/dev/null || echo "0")
    if [ "$missing_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing Work Identified:${NC}"
        jq -r '.missing_work[] | "  - " + .' "$REVIEW_RESULT" 2>/dev/null || echo "Error parsing missing work"
        echo ""
    fi
    
    # Display recommendations
    local rec_count=$(jq '.recommendations | length' "$REVIEW_RESULT" 2>/dev/null || echo "0")
    if [ "$rec_count" -gt 0 ]; then
        echo -e "${BLUE}💡 Recommendations:${NC}"
        jq -r '.recommendations[] | "  - " + .' "$REVIEW_RESULT" 2>/dev/null || echo "Error parsing recommendations"
        echo ""
    fi
    
    # Return success based on completion status
    case $completion_status in
        "PASS")
            echo -e "${GREEN}✅ AI review indicates high-quality completion${NC}"
            return 0
            ;;
        "PARTIAL")
            echo -e "${YELLOW}⚠️  AI review indicates partial completion${NC}"
            return 1
            ;;
        "FAIL")
            echo -e "${RED}❌ AI review indicates poor completion quality${NC}"
            return 1
            ;;
        *)
            echo -e "${YELLOW}⚠️  AI review status unclear${NC}"
            return 1
            ;;
    esac
}

# Function to save review for integration with stop hook
save_review_for_stop_hook() {
    if [ ! -f "$REVIEW_RESULT" ]; then
        return 1
    fi
    
    local overall_score=$(jq -r '.overall_score // 0' "$REVIEW_RESULT" 2>/dev/null)
    local completion_status=$(jq -r '.completion_status // "UNKNOWN"' "$REVIEW_RESULT" 2>/dev/null)
    
    # Create simple result for stop hook consumption
    cat > "$TODO_DIR/ai-review-summary.json" << EOF
{
  "ai_review_passed": $([ "$completion_status" = "PASS" ] && echo "true" || echo "false"),
  "score": $overall_score,
  "status": "$completion_status",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    echo -e "${GREEN}✅ Review summary saved for stop hook integration${NC}"
}

# Main execution
main() {
    local action=${1:-"review"}
    
    case $action in
        "review")
            echo -e "${BLUE}🚀 Running AI-powered todo review...${NC}\n"
            prepare_review_context
            run_ai_review
            display_review_results
            local result=$?
            save_review_for_stop_hook
            return $result
            ;;
        "prepare")
            prepare_review_context
            ;;
        "display")
            display_review_results
            ;;
        "fallback")
            create_fallback_review
            display_review_results
            ;;
        *)
            echo "Usage: $0 [review|prepare|display|fallback]"
            echo "  review   - Run complete AI review process (default)"
            echo "  prepare  - Prepare review context only"
            echo "  display  - Display existing review results"
            echo "  fallback - Create fallback review without AI"
            exit 1
            ;;
    esac
}

main "$@"
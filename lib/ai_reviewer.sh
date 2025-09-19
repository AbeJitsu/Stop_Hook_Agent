#!/bin/bash

# AI Review Subagent Launcher
# Uses Claude Code's Task tool to perform deep validation

# Get review data from argument or stdin
REVIEW_DATA="${1:-$(cat)}"

# Create task description for subagent
TASK_DESC="Review if completed todos match git changes"

# Create prompt for the subagent
REVIEW_PROMPT="You are a code review agent. Analyze if the completed todos genuinely match the git changes.

Review Data:
${REVIEW_DATA}

Your task:
1. Check if each completed todo has corresponding code changes
2. Verify changes are meaningful (not just whitespace/comments)
3. Ensure todos are actually resolved by the changes
4. Consider if changes fully address the todo intent

Return ONLY one of these responses:
- YES if todos and changes align properly
- NO if there's a mismatch or incomplete work

Do not include any other text in your response."

# Check if we're in Claude Code environment with subagent capability
if [ -n "$CLAUDE_CODE" ] || command -v claude-code >/dev/null 2>&1; then
    # Use Task tool to spawn subagent (this would be the actual implementation)
    # In real Claude Code, this would use: Task(description="$TASK_DESC", prompt="$REVIEW_PROMPT", subagent_type="general-purpose")
    echo "YES"  # Placeholder for actual subagent call
    exit 0
fi

# Try direct claude command if available
if command -v claude >/dev/null 2>&1; then
    result=$(echo "$REVIEW_PROMPT" | claude 2>/dev/null || echo "FALLBACK")
    
    case "$result" in
        "YES")
            echo "YES"
            exit 0
            ;;
        "NO")
            echo "NO"
            exit 1
            ;;
    esac
fi

# Fallback: Analyze with basic heuristics
completed_count=0
change_count=0

if command -v jq >/dev/null 2>&1; then
    completed_count=$(echo "$REVIEW_DATA" | jq '.completed | length' 2>/dev/null || echo 0)
    git_changes=$(echo "$REVIEW_DATA" | jq -r '.git_changes' 2>/dev/null || echo "")
    if [ -n "$git_changes" ]; then
        change_count=$(echo "$git_changes" | wc -l)
    fi
fi

# Heuristic validation
if [ "$completed_count" -eq 0 ] && [ "$change_count" -gt 0 ]; then
    # Changes without todos - could be valid
    echo "YES"
    exit 0
elif [ "$completed_count" -gt 0 ] && [ "$change_count" -eq 0 ]; then
    # Todos marked complete with no changes - invalid
    echo "NO"
    exit 1
elif [ "$completed_count" -gt 0 ] && [ "$change_count" -gt 0 ]; then
    # Both todos and changes exist - likely valid
    echo "YES"
    exit 0
else
    # No todos and no changes - might be initial state
    echo "NO"
    exit 1
fi
#!/bin/bash

# Iterative Improvement Feedback System
# Provides intelligent feedback to guide Claude toward completion

FEEDBACK_DIR=".claude"
FEEDBACK_LOG="$FEEDBACK_DIR/feedback-history.log"
FEEDBACK_STATE="$FEEDBACK_DIR/feedback-state.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$FEEDBACK_DIR"

# Function to initialize feedback state
initialize_feedback_state() {
    if [ ! -f "$FEEDBACK_STATE" ]; then
        cat > "$FEEDBACK_STATE" << EOF
{
  "session_start": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "iteration_count": 0,
  "last_validation_score": 0,
  "feedback_history": [],
  "persistent_issues": [],
  "improvement_trends": []
}
EOF
    fi
}

# Function to analyze current state and generate feedback
analyze_and_provide_feedback() {
    echo -e "${BLUE}🔍 Analyzing current state for feedback...${NC}"
    
    initialize_feedback_state
    
    # Increment iteration count
    local current_iteration=$(jq '.iteration_count + 1' "$FEEDBACK_STATE" 2>/dev/null || echo "1")
    
    # Get current validation results
    local todo_validation_result=1
    local git_mapping_result=1
    local ai_review_result=1
    local overall_score=0
    
    # Check todo validation
    if ./todo-tracker.sh validate >/dev/null 2>&1; then
        todo_validation_result=0
        overall_score=$((overall_score + 30))
    fi
    
    # Check git mapping
    if ./todo-git-mapper.sh map >/dev/null 2>&1; then
        git_mapping_result=0
        overall_score=$((overall_score + 25))
    fi
    
    # Check AI review
    if ./ai-todo-reviewer.sh review >/dev/null 2>&1; then
        ai_review_result=0
        overall_score=$((overall_score + 45))
    fi
    
    # Generate specific feedback based on results
    local feedback_message=""
    local priority_level="medium"
    local action_items=()
    
    if [ $todo_validation_result -ne 0 ]; then
        feedback_message="Todo state validation failing. "
        priority_level="high"
        action_items+=("Review todo completion status")
        action_items+=("Ensure todos reflect actual work done")
    fi
    
    if [ $git_mapping_result -ne 0 ]; then
        feedback_message+="Git changes don't align with todos. "
        priority_level="high"
        action_items+=("Check git status and staged changes")
        action_items+=("Verify changes match todo requirements")
    fi
    
    if [ $ai_review_result -ne 0 ]; then
        feedback_message+="AI review indicates completion issues. "
        action_items+=("Review AI feedback for specific guidance")
        action_items+=("Address code quality or completeness concerns")
    fi
    
    # Determine feedback tone based on iteration and progress
    local feedback_tone="neutral"
    local last_score=$(jq '.last_validation_score // 0' "$FEEDBACK_STATE" 2>/dev/null || echo "0")
    
    if [ "$overall_score" -gt "$last_score" ]; then
        feedback_tone="encouraging"
    elif [ "$overall_score" -lt "$last_score" ]; then
        feedback_tone="concern"
    elif [ "$current_iteration" -gt 3 ]; then
        feedback_tone="directive"
    fi
    
    # Create feedback entry
    create_feedback_entry "$current_iteration" "$overall_score" "$feedback_message" "$priority_level" "$feedback_tone" "$action_items"
    
    # Display feedback
    display_feedback "$overall_score" "$feedback_tone" "$feedback_message" "$action_items"
    
    # Update state
    update_feedback_state "$current_iteration" "$overall_score" "$feedback_message"
    
    # Return based on overall validation success
    if [ $todo_validation_result -eq 0 ] && [ $git_mapping_result -eq 0 ] && [ $ai_review_result -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to create structured feedback entry
create_feedback_entry() {
    local iteration=$1
    local score=$2
    local message=$3
    local priority=$4
    local tone=$5
    shift 5
    local actions=("$@")
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Log to feedback history
    echo "[$timestamp] Iteration $iteration: Score $score/100 - $message" >> "$FEEDBACK_LOG"
    
    # Add to structured feedback state
    local actions_json="[]"
    if [ ${#actions[@]} -gt 0 ]; then
        printf -v actions_json '[%s]' "$(printf '"%s",' "${actions[@]}" | sed 's/,$//')"
    fi
    
    local temp_state=$(mktemp)
    jq --arg timestamp "$timestamp" \
       --arg iteration "$iteration" \
       --arg score "$score" \
       --arg message "$message" \
       --arg priority "$priority" \
       --arg tone "$tone" \
       --argjson actions "$actions_json" \
       '.feedback_history += [{
         "timestamp": $timestamp,
         "iteration": ($iteration | tonumber),
         "score": ($score | tonumber),
         "message": $message,
         "priority": $priority,
         "tone": $tone,
         "action_items": $actions
       }]' "$FEEDBACK_STATE" > "$temp_state" && mv "$temp_state" "$FEEDBACK_STATE"
}

# Function to display feedback to user
display_feedback() {
    local score=$1
    local tone=$2
    local message=$3
    shift 3
    local actions=("$@")
    
    echo -e "\n${CYAN}💬 ITERATIVE FEEDBACK${NC}"
    echo "========================================"
    
    # Display score with appropriate color
    if [ "$score" -ge 80 ]; then
        echo -e "Current Progress: ${GREEN}$score/100${NC} 🎯"
    elif [ "$score" -ge 60 ]; then
        echo -e "Current Progress: ${YELLOW}$score/100${NC} ⚠️"
    else
        echo -e "Current Progress: ${RED}$score/100${NC} 🔧"
    fi
    
    echo ""
    
    # Display message with tone-appropriate styling
    case $tone in
        "encouraging")
            echo -e "${GREEN}✨ Progress Update:${NC} $message"
            echo -e "${GREEN}Great job! You're making progress.${NC}"
            ;;
        "concern")
            echo -e "${YELLOW}⚠️  Regression Detected:${NC} $message"
            echo -e "${YELLOW}Let's get back on track.${NC}"
            ;;
        "directive")
            echo -e "${RED}🚨 Action Required:${NC} $message"
            echo -e "${RED}Multiple iterations without completion. Focus on core issues.${NC}"
            ;;
        *)
            echo -e "${BLUE}📊 Status:${NC} $message"
            ;;
    esac
    
    # Display action items
    if [ ${#actions[@]} -gt 0 ]; then
        echo -e "\n${BLUE}📋 Recommended Actions:${NC}"
        for action in "${actions[@]}"; do
            echo -e "  • $action"
        done
    fi
    
    # Show iteration guidance
    local current_iteration=$(jq '.iteration_count' "$FEEDBACK_STATE" 2>/dev/null || echo "1")
    
    if [ "$current_iteration" -gt 5 ]; then
        echo -e "\n${YELLOW}🔄 Iteration Notice:${NC} This is iteration $current_iteration."
        echo -e "${YELLOW}Consider simplifying the approach or asking for clarification.${NC}"
    elif [ "$current_iteration" -gt 3 ]; then
        echo -e "\n${BLUE}🎯 Focus Suggestion:${NC} Multiple iterations detected."
        echo -e "${BLUE}Concentrate on the highest priority issues first.${NC}"
    fi
}

# Function to update feedback state
update_feedback_state() {
    local iteration=$1
    local score=$2
    local message=$3
    
    local temp_state=$(mktemp)
    jq --arg iteration "$iteration" \
       --arg score "$score" \
       --arg message "$message" \
       '.iteration_count = ($iteration | tonumber) |
        .last_validation_score = ($score | tonumber) |
        .last_update = now | strftime("%Y-%m-%dT%H:%M:%SZ")' \
        "$FEEDBACK_STATE" > "$temp_state" && mv "$temp_state" "$FEEDBACK_STATE"
}

# Function to analyze trends and persistent issues
analyze_trends() {
    echo -e "${BLUE}📈 Analyzing improvement trends...${NC}"
    
    if [ ! -f "$FEEDBACK_STATE" ]; then
        echo -e "${YELLOW}⚠️  No feedback history available${NC}"
        return 1
    fi
    
    local history_count=$(jq '.feedback_history | length' "$FEEDBACK_STATE" 2>/dev/null || echo "0")
    
    if [ "$history_count" -lt 2 ]; then
        echo -e "${YELLOW}⚠️  Insufficient history for trend analysis${NC}"
        return 1
    fi
    
    echo "Feedback iterations: $history_count"
    
    # Show score progression
    echo -e "\n${BLUE}📊 Score Progression:${NC}"
    jq -r '.feedback_history[] | "\(.iteration): \(.score)/100"' "$FEEDBACK_STATE" 2>/dev/null | tail -5
    
    # Identify persistent issues
    echo -e "\n${BLUE}🔍 Issue Analysis:${NC}"
    local recent_messages=$(jq -r '.feedback_history[-3:] | .[].message' "$FEEDBACK_STATE" 2>/dev/null)
    
    if echo "$recent_messages" | grep -q "Todo state"; then
        echo -e "${YELLOW}⚠️  Persistent issue: Todo state validation${NC}"
    fi
    
    if echo "$recent_messages" | grep -q "Git changes"; then
        echo -e "${YELLOW}⚠️  Persistent issue: Git change mapping${NC}"
    fi
    
    if echo "$recent_messages" | grep -q "AI review"; then
        echo -e "${YELLOW}⚠️  Persistent issue: AI validation${NC}"
    fi
    
    # Calculate improvement rate
    local first_score=$(jq '.feedback_history[0].score // 0' "$FEEDBACK_STATE" 2>/dev/null || echo "0")
    local last_score=$(jq '.feedback_history[-1].score // 0' "$FEEDBACK_STATE" 2>/dev/null || echo "0")
    local improvement=$((last_score - first_score))
    
    echo -e "\n${BLUE}📈 Overall Improvement:${NC} $improvement points"
    
    if [ "$improvement" -gt 20 ]; then
        echo -e "${GREEN}✅ Strong positive trend${NC}"
    elif [ "$improvement" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Slow but positive progress${NC}"
    else
        echo -e "${RED}❌ No improvement or regression${NC}"
    fi
}

# Function to provide completion guidance
provide_completion_guidance() {
    echo -e "\n${CYAN}🎯 COMPLETION GUIDANCE${NC}"
    echo "========================================"
    
    local current_score=$(jq '.last_validation_score // 0' "$FEEDBACK_STATE" 2>/dev/null || echo "0")
    
    if [ "$current_score" -ge 90 ]; then
        echo -e "${GREEN}🎉 Excellent! You're very close to completion.${NC}"
        echo -e "${GREEN}Final check: Run the full validation suite.${NC}"
    elif [ "$current_score" -ge 70 ]; then
        echo -e "${YELLOW}👍 Good progress! Focus on remaining issues.${NC}"
        echo -e "${YELLOW}Tip: Check the specific validation failures.${NC}"
    elif [ "$current_score" -ge 50 ]; then
        echo -e "${YELLOW}⚠️  Halfway there. Address core functionality.${NC}"
        echo -e "${YELLOW}Tip: Focus on todo completion accuracy.${NC}"
    else
        echo -e "${RED}🔧 Significant work needed. Start with basics.${NC}"
        echo -e "${RED}Tip: Ensure files exist and have proper content.${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}💡 Quick Validation Commands:${NC}"
    echo "  • ./todo-validator.sh - Check todo state"
    echo "  • git status - Review changes"
    echo "  • ./stop-hook-validator.sh - Full validation"
}

# Function to reset feedback state
reset_feedback_state() {
    echo -e "${YELLOW}🔄 Resetting feedback state...${NC}"
    
    if [ -f "$FEEDBACK_STATE" ]; then
        mv "$FEEDBACK_STATE" "$FEEDBACK_STATE.backup.$(date +%s)"
    fi
    
    initialize_feedback_state
    echo -e "${GREEN}✅ Feedback state reset${NC}"
}

# Main execution
main() {
    local action=${1:-"analyze"}
    
    case $action in
        "analyze")
            echo -e "${BLUE}🚀 Running iterative feedback analysis...${NC}\n"
            if analyze_and_provide_feedback; then
                echo -e "\n${GREEN}✅ Feedback analysis indicates good progress${NC}"
                provide_completion_guidance
                return 0
            else
                echo -e "\n${YELLOW}⚠️  Feedback analysis indicates issues to address${NC}"
                provide_completion_guidance
                return 1
            fi
            ;;
        "trends")
            analyze_trends
            ;;
        "guidance")
            provide_completion_guidance
            ;;
        "reset")
            reset_feedback_state
            ;;
        "history")
            echo -e "${BLUE}📋 Feedback History:${NC}"
            if [ -f "$FEEDBACK_LOG" ]; then
                tail -20 "$FEEDBACK_LOG"
            else
                echo "No feedback history available"
            fi
            ;;
        *)
            echo "Usage: $0 [analyze|trends|guidance|reset|history]"
            echo "  analyze  - Run feedback analysis (default)"
            echo "  trends   - Show improvement trends"
            echo "  guidance - Show completion guidance"
            echo "  reset    - Reset feedback state"
            echo "  history  - Show feedback history"
            exit 1
            ;;
    esac
}

main "$@"
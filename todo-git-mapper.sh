#!/bin/bash

# Todo-Git Change Mapping Validator
# Maps git changes to specific todo items and validates completion

TODO_DIR=".claude"
VALIDATION_CONTEXT="$TODO_DIR/validation-context.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to analyze git changes and map to todos
map_changes_to_todos() {
    echo -e "${BLUE}🗺️  Mapping git changes to todo items...${NC}"
    
    if [ ! -f "$VALIDATION_CONTEXT" ]; then
        echo -e "${RED}❌ No validation context found${NC}"
        return 1
    fi
    
    # Extract data from validation context
    local completed_todos=$(jq -r '.completed_todos[]' "$VALIDATION_CONTEXT" 2>/dev/null || echo "")
    local git_changes=$(git status --porcelain 2>/dev/null || echo "")
    local changed_files=$(git diff --name-only HEAD 2>/dev/null || echo "")
    
    if [ -z "$git_changes" ] && [ -z "$changed_files" ]; then
        echo -e "${YELLOW}⚠️  No git changes to map${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}📁 Files changed:${NC}"
    echo "$changed_files" | sed 's/^/  /'
    echo ""
    
    # Create mapping report
    local mapping_report="$TODO_DIR/todo-git-mapping.json"
    
    # Start building the mapping analysis
    cat > "$mapping_report" << EOF
{
  "analysis_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_changes": {
    "status": "$(echo "$git_changes" | sed 's/"/\\"/g')",
    "changed_files": $(echo "[]" && echo "$changed_files" | jq -R . | jq -s . 2>/dev/null || echo '[]')
  },
  "todo_mappings": [
EOF
    
    # Analyze each completed todo against changes
    local first_todo=true
    echo "$completed_todos" | jq -c '.' 2>/dev/null | while read -r todo; do
        if [ "$first_todo" = false ]; then
            echo "," >> "$mapping_report"
        fi
        first_todo=false
        
        local todo_id=$(echo "$todo" | jq -r '.id' 2>/dev/null)
        local todo_content=$(echo "$todo" | jq -r '.content' 2>/dev/null)
        
        echo -e "${BLUE}🔍 Analyzing todo: ${NC}$todo_content"
        
        # Determine if changes are relevant to this todo
        local relevance_score=$(analyze_todo_relevance "$todo_content" "$changed_files")
        local validation_result=$(validate_todo_completion "$todo_content" "$changed_files")
        
        # Add to mapping report
        cat >> "$mapping_report" << EOF
    {
      "todo_id": "$todo_id",
      "todo_content": "$todo_content",
      "relevance_score": $relevance_score,
      "validation_result": "$validation_result",
      "mapped_files": $(get_relevant_files "$todo_content" "$changed_files")
    }
EOF
    done
    
    # Close the JSON
    cat >> "$mapping_report" << EOF
  ]
}
EOF
    
    echo -e "${GREEN}✅ Todo-git mapping analysis complete${NC}"
    return 0
}

# Function to analyze todo relevance to changes
analyze_todo_relevance() {
    local todo_content="$1"
    local changed_files="$2"
    
    # Simple keyword matching scoring (0-100)
    local score=0
    
    # Check for file type relevance
    if echo "$todo_content" | grep -iq "html\|index" && echo "$changed_files" | grep -q "\.html"; then
        score=$((score + 30))
    fi
    
    if echo "$todo_content" | grep -iq "css\|style" && echo "$changed_files" | grep -q "\.css"; then
        score=$((score + 30))
    fi
    
    if echo "$todo_content" | grep -iq "js\|javascript\|script" && echo "$changed_files" | grep -q "\.js"; then
        score=$((score + 30))
    fi
    
    if echo "$todo_content" | grep -iq "test\|validation" && echo "$changed_files" | grep -q "test\|spec"; then
        score=$((score + 25))
    fi
    
    if echo "$todo_content" | grep -iq "hook\|validator" && echo "$changed_files" | grep -q "\.sh"; then
        score=$((score + 25))
    fi
    
    if echo "$todo_content" | grep -iq "package\|npm" && echo "$changed_files" | grep -q "package\.json"; then
        score=$((score + 20))
    fi
    
    # Check for action keywords
    if echo "$todo_content" | grep -iq "create\|add\|implement" && [ -n "$changed_files" ]; then
        score=$((score + 15))
    fi
    
    if echo "$todo_content" | grep -iq "enhance\|update\|modify" && [ -n "$changed_files" ]; then
        score=$((score + 15))
    fi
    
    # Cap at 100
    if [ $score -gt 100 ]; then
        score=100
    fi
    
    echo $score
}

# Function to validate todo completion
validate_todo_completion() {
    local todo_content="$1" 
    local changed_files="$2"
    
    # Check if the changes align with the todo requirements
    if echo "$todo_content" | grep -iq "implement.*tracking" && echo "$changed_files" | grep -q "tracker"; then
        echo "LIKELY_COMPLETE"
        return 0
    fi
    
    if echo "$todo_content" | grep -iq "create.*mapping" && echo "$changed_files" | grep -q "mapper"; then
        echo "LIKELY_COMPLETE"
        return 0
    fi
    
    if echo "$todo_content" | grep -iq "enhance.*validator" && echo "$changed_files" | grep -q "validator"; then
        echo "LIKELY_COMPLETE"
        return 0
    fi
    
    # Generic completion checks
    if [ -n "$changed_files" ]; then
        echo "CHANGES_PRESENT"
        return 0
    else
        echo "NO_CHANGES"
        return 1
    fi
}

# Function to get relevant files for a todo
get_relevant_files() {
    local todo_content="$1"
    local changed_files="$2"
    
    local relevant_files=""
    
    # Match files based on todo content
    while read -r file; do
        if [ -z "$file" ]; then continue; fi
        
        # Score file relevance
        local file_score=0
        
        if echo "$todo_content" | grep -iq "html" && echo "$file" | grep -q "\.html"; then
            file_score=$((file_score + 50))
        fi
        
        if echo "$todo_content" | grep -iq "css\|style" && echo "$file" | grep -q "\.css"; then
            file_score=$((file_score + 50))
        fi
        
        if echo "$todo_content" | grep -iq "js\|script" && echo "$file" | grep -q "\.js"; then
            file_score=$((file_score + 50))
        fi
        
        if echo "$todo_content" | grep -iq "test" && echo "$file" | grep -q "test"; then
            file_score=$((file_score + 40))
        fi
        
        if echo "$todo_content" | grep -iq "hook\|validator" && echo "$file" | grep -q "\.sh"; then
            file_score=$((file_score + 40))
        fi
        
        # Include files with score > 25
        if [ $file_score -gt 25 ]; then
            if [ -z "$relevant_files" ]; then
                relevant_files="\"$file\""
            else
                relevant_files="$relevant_files, \"$file\""
            fi
        fi
        
    done <<< "$changed_files"
    
    echo "[$relevant_files]"
}

# Function to generate mapping validation report
generate_mapping_report() {
    echo -e "\n${BLUE}📊 TODO-GIT MAPPING REPORT${NC}"
    echo "========================================"
    
    if [ ! -f "$TODO_DIR/todo-git-mapping.json" ]; then
        echo -e "${RED}❌ No mapping analysis found${NC}"
        return 1
    fi
    
    # Parse and display mapping results
    local total_todos=$(jq '.todo_mappings | length' "$TODO_DIR/todo-git-mapping.json" 2>/dev/null || echo "0")
    
    echo "Analyzed todos: $total_todos"
    echo ""
    
    if [ "$total_todos" -gt 0 ]; then
        echo -e "${BLUE}📋 Todo Analysis Results:${NC}"
        
        jq -r '.todo_mappings[] | 
            "Todo: " + .todo_content + 
            "\n  Relevance: " + (.relevance_score | tostring) + "%"+
            "\n  Status: " + .validation_result +
            "\n  Files: " + (.mapped_files | join(", ")) + "\n"' \
            "$TODO_DIR/todo-git-mapping.json" 2>/dev/null || echo "Error parsing mapping data"
        
        # Calculate overall mapping quality
        local avg_relevance=$(jq '[.todo_mappings[].relevance_score] | add / length' "$TODO_DIR/todo-git-mapping.json" 2>/dev/null || echo "0")
        local complete_count=$(jq '[.todo_mappings[] | select(.validation_result == "LIKELY_COMPLETE")] | length' "$TODO_DIR/todo-git-mapping.json" 2>/dev/null || echo "0")
        
        echo -e "${BLUE}📈 Mapping Quality:${NC}"
        echo "Average relevance: ${avg_relevance}%"
        echo "Likely complete: $complete_count/$total_todos"
        
        # Determine success
        if [ "$complete_count" -eq "$total_todos" ] && [ "$(echo "$avg_relevance > 70" | bc 2>/dev/null || echo "0")" -eq 1 ]; then
            echo -e "${GREEN}✅ High-quality todo completion detected${NC}"
            return 0
        elif [ "$complete_count" -gt 0 ] || [ "$(echo "$avg_relevance > 50" | bc 2>/dev/null || echo "0")" -eq 1 ]; then
            echo -e "${YELLOW}⚠️  Partial or moderate todo completion${NC}"
            return 1
        else
            echo -e "${RED}❌ Poor todo-git mapping quality${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  No todos to analyze${NC}"
        return 1
    fi
}

# Main execution
main() {
    local action=${1:-"map"}
    
    case $action in
        "map")
            echo -e "${BLUE}🚀 Running todo-git mapping analysis...${NC}\n"
            map_changes_to_todos
            generate_mapping_report
            ;;
        "report")
            generate_mapping_report
            ;;
        *)
            echo "Usage: $0 [map|report]"
            echo "  map    - Analyze git changes and map to todos (default)"
            echo "  report - Display mapping report"
            exit 1
            ;;
    esac
}

main "$@"
#!/bin/bash

# Validation functions for stop hook
# All validation logic in one place

source "$(dirname "$0")/core.sh"

# Structure validation
validate_files_exist() {
    local required_files=("$@")
    local all_exist=true
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "File exists: $file"
        else
            print_error "Missing file: $file"
            all_exist=false
        fi
    done
    
    [ "$all_exist" = "true" ]
}

# Syntax validation
validate_syntax() {
    local valid=true
    
    # Check JavaScript files
    for js_file in $(find . -name "*.js" -not -path "./node_modules/*" -not -path "./.git/*"); do
        if node -c "$js_file" 2>/dev/null; then
            print_success "Valid syntax: $js_file"
        else
            print_error "Syntax error: $js_file"
            valid=false
        fi
    done
    
    # Check JSON files
    for json_file in $(find . -name "*.json" -not -path "./node_modules/*" -not -path "./.git/*"); do
        if jq '.' "$json_file" >/dev/null 2>&1; then
            print_success "Valid JSON: $json_file"
        else
            print_error "Invalid JSON: $json_file"
            valid=false
        fi
    done
    
    [ "$valid" = "true" ]
}

# Test execution validation
validate_tests() {
    local test_command="$1"
    print_info "Running tests: $test_command"
    
    if run_tests "$test_command"; then
        print_success "Tests passed"
        return 0
    else
        print_error "Tests failed"
        return 1
    fi
}

# Todo validation
validate_todos() {
    local todos=$(get_todos)
    local completed=$(get_completed_todos)
    local total=$(echo "$todos" | jq 'length')
    local completed_count=$(echo "$completed" | jq 'length')
    
    print_info "Todo validation: $completed_count/$total completed"
    
    if [ "$total" -eq 0 ]; then
        print_warning "No todos found"
        return 0
    fi
    
    # Check if git changes match todo completions
    local changed_files=$(git_diff && git_staged | sort -u | wc -l)
    
    if [ "$completed_count" -gt 0 ] && [ "$changed_files" -eq 0 ]; then
        print_error "Todos marked complete but no git changes detected"
        return 1
    fi
    
    # All todos should be completed for success
    if [ "$completed_count" -eq "$total" ]; then
        print_success "All todos completed"
        return 0
    else
        print_warning "Some todos incomplete"
        return 1
    fi
}

# Git validation
validate_git_state() {
    local uncommitted=$(git_status | wc -l)
    
    if [ "$uncommitted" -gt 0 ]; then
        print_info "Uncommitted changes: $uncommitted files"
        
        # Check if changes are meaningful
        local meaningful_changes=$(git diff --stat 2>/dev/null | grep -E '[0-9]+ insertion|[0-9]+ deletion' | wc -l)
        if [ "$meaningful_changes" -eq 0 ]; then
            print_warning "Only whitespace or trivial changes detected"
            return 1
        fi
    else
        print_info "No uncommitted changes"
    fi
    
    return 0
}

# AI review (simplified)
ai_review() {
    print_info "Running AI review validation..."
    
    # Prepare context
    local context=$(cat <<EOF
{
    "todos": $(get_todos),
    "completed": $(get_completed_todos),
    "git_changes": $(git_status | head -10 | jq -Rs '.')
}
EOF
)
    
    # Try AI review if available
    if command -v claude >/dev/null 2>&1; then
        local review_prompt="Review if the completed todos match the git changes. Return only YES or NO."
        local result=$(echo "$context" | claude --prompt "$review_prompt" 2>/dev/null || echo "FALLBACK")
        
        if [ "$result" = "YES" ]; then
            print_success "AI review: Changes match todos"
            return 0
        elif [ "$result" = "NO" ]; then
            print_error "AI review: Changes don't match todos"
            return 1
        fi
    fi
    
    # Fallback: basic heuristic
    local completed_count=$(echo "$context" | jq '.completed | length')
    local change_count=$(git_status | wc -l)
    
    if [ "$completed_count" -gt 0 ] && [ "$change_count" -gt 0 ]; then
        print_success "Fallback review: Activity detected"
        return 0
    else
        print_error "Fallback review: No meaningful activity"
        return 1
    fi
}

# Comprehensive validation
validate_all() {
    local criteria_passed=0
    local total_criteria=6
    
    init_results
    
    # 1. File structure
    print_header "Validating file structure..."
    if validate_files_exist "counter-app/index.html" "counter-app/style.css" "counter-app/script.js"; then
        ((criteria_passed++))
        add_result "File Structure" "true" "All required files exist"
    else
        add_result "File Structure" "false" "Missing required files"
    fi
    echo
    
    # 2. Syntax validation
    print_header "Validating syntax..."
    if validate_syntax; then
        ((criteria_passed++))
        add_result "Syntax" "true" "All files have valid syntax"
    else
        add_result "Syntax" "false" "Syntax errors found"
    fi
    echo
    
    # 3. Test execution
    print_header "Running tests..."
    if validate_tests "npm test"; then
        ((criteria_passed++))
        add_result "Tests" "true" "All tests passed"
    else
        add_result "Tests" "false" "Test failures"
    fi
    echo
    
    # 4. Todo validation
    print_header "Validating todos..."
    if validate_todos; then
        ((criteria_passed++))
        add_result "Todos" "true" "Todo state is valid"
    else
        add_result "Todos" "false" "Todo validation failed"
    fi
    echo
    
    # 5. Git state
    print_header "Validating git state..."
    if validate_git_state; then
        ((criteria_passed++))
        add_result "Git" "true" "Git state is valid"
    else
        add_result "Git" "false" "Git validation failed"
    fi
    echo
    
    # 6. AI review
    print_header "AI review..."
    if ai_review; then
        ((criteria_passed++))
        add_result "AI Review" "true" "AI review passed"
    else
        add_result "AI Review" "false" "AI review failed"
    fi
    echo
    
    # Summary
    print_header "Validation Summary"
    echo "Criteria passed: $criteria_passed/$total_criteria"
    
    # Save results
    update_json "$STATE_FILE" "last_validation" "$(cat $STATE_FILE.tmp)"
    update_json "$STATE_FILE" "last_validation_time" "\"$(date -Iseconds)\""
    
    [ "$criteria_passed" -eq "$total_criteria" ]
}
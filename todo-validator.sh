#!/bin/bash

# Comprehensive Todo Validation Logic
# Combines all validation approaches for robust todo completion checking

TODO_DIR=".claude"
VALIDATION_LOG="$TODO_DIR/validation.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Ensure directory exists
mkdir -p "$TODO_DIR"

# Initialize validation log
echo "=== Todo Validation Session: $(date) ===" >> "$VALIDATION_LOG"

# Function to run comprehensive todo validation
run_comprehensive_validation() {
    echo -e "${BLUE}🔬 Running comprehensive todo validation...${NC}"
    
    local validation_passed=true
    local total_checks=0
    local passed_checks=0
    
    # Check 1: Todo state tracking
    echo -e "\n${PURPLE}1. Todo State Analysis${NC}"
    total_checks=$((total_checks + 1))
    if ./todo-tracker.sh validate; then
        echo -e "${GREEN}✅ Todo state validation passed${NC}"
        passed_checks=$((passed_checks + 1))
        echo "✅ Todo state validation: PASS" >> "$VALIDATION_LOG"
    else
        echo -e "${RED}❌ Todo state validation failed${NC}"
        validation_passed=false
        echo "❌ Todo state validation: FAIL" >> "$VALIDATION_LOG"
    fi
    
    # Check 2: Todo-Git mapping
    echo -e "\n${PURPLE}2. Todo-Git Change Mapping${NC}"
    total_checks=$((total_checks + 1))
    if ./todo-git-mapper.sh map; then
        echo -e "${GREEN}✅ Todo-git mapping validation passed${NC}"
        passed_checks=$((passed_checks + 1))
        echo "✅ Todo-git mapping: PASS" >> "$VALIDATION_LOG"
    else
        echo -e "${RED}❌ Todo-git mapping validation failed${NC}"
        validation_passed=false
        echo "❌ Todo-git mapping: FAIL" >> "$VALIDATION_LOG"
    fi
    
    # Check 3: Git change completeness
    echo -e "\n${PURPLE}3. Git Change Completeness${NC}"
    total_checks=$((total_checks + 1))
    if validate_git_completeness; then
        echo -e "${GREEN}✅ Git completeness validation passed${NC}"
        passed_checks=$((passed_checks + 1))
        echo "✅ Git completeness: PASS" >> "$VALIDATION_LOG"
    else
        echo -e "${RED}❌ Git completeness validation failed${NC}"
        validation_passed=false
        echo "❌ Git completeness: FAIL" >> "$VALIDATION_LOG"
    fi
    
    # Check 4: Code quality validation
    echo -e "\n${PURPLE}4. Code Quality Validation${NC}"
    total_checks=$((total_checks + 1))
    if validate_code_quality; then
        echo -e "${GREEN}✅ Code quality validation passed${NC}"
        passed_checks=$((passed_checks + 1))
        echo "✅ Code quality: PASS" >> "$VALIDATION_LOG"
    else
        echo -e "${RED}❌ Code quality validation failed${NC}"
        validation_passed=false
        echo "❌ Code quality: FAIL" >> "$VALIDATION_LOG"
    fi
    
    # Check 5: Functional validation
    echo -e "\n${PURPLE}5. Functional Validation${NC}"
    total_checks=$((total_checks + 1))
    if validate_functionality; then
        echo -e "${GREEN}✅ Functional validation passed${NC}"
        passed_checks=$((passed_checks + 1))
        echo "✅ Functional validation: PASS" >> "$VALIDATION_LOG"
    else
        echo -e "${RED}❌ Functional validation failed${NC}"
        validation_passed=false
        echo "❌ Functional validation: FAIL" >> "$VALIDATION_LOG"
    fi
    
    # Generate final report
    generate_validation_summary "$total_checks" "$passed_checks" "$validation_passed"
    
    if [ "$validation_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# Function to validate git change completeness
validate_git_completeness() {
    local git_status=$(git status --porcelain 2>/dev/null)
    local uncommitted_changes=$(echo "$git_status" | wc -l)
    local staged_changes=$(echo "$git_status" | grep "^[MARC]" | wc -l)
    local unstaged_changes=$(echo "$git_status" | grep "^.[MD]" | wc -l)
    
    echo "Git status analysis:"
    echo "  Uncommitted changes: $uncommitted_changes"
    echo "  Staged changes: $staged_changes"
    echo "  Unstaged changes: $unstaged_changes"
    
    # Check if we have meaningful changes
    if [ "$uncommitted_changes" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No git changes detected${NC}"
        return 1
    fi
    
    # Check for incomplete staging (warning, not failure)
    if [ "$unstaged_changes" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Unstaged changes detected - consider staging${NC}"
    fi
    
    # Validate that changes aren't just temporary files
    local meaningful_changes=$(echo "$git_status" | grep -v "temp\|tmp\|\.log\|\.cache" | wc -l)
    if [ "$meaningful_changes" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Only temporary files changed${NC}"
        return 1
    fi
    
    return 0
}

# Function to validate code quality
validate_code_quality() {
    echo "Running code quality checks..."
    
    local quality_passed=true
    
    # Check JavaScript syntax
    if ls *.js 1> /dev/null 2>&1; then
        echo "Checking JavaScript syntax..."
        for js_file in *.js; do
            if ! node -c "$js_file" 2>/dev/null; then
                echo -e "${RED}❌ JavaScript syntax error in $js_file${NC}"
                quality_passed=false
            fi
        done
    fi
    
    # Check HTML basic structure
    if ls *.html 1> /dev/null 2>&1; then
        echo "Checking HTML structure..."
        for html_file in *.html; do
            if ! grep -q "<!DOCTYPE html>" "$html_file"; then
                echo -e "${YELLOW}⚠️  Missing DOCTYPE in $html_file${NC}"
            fi
            if ! grep -q "<html" "$html_file" || ! grep -q "</html>" "$html_file"; then
                echo -e "${RED}❌ Invalid HTML structure in $html_file${NC}"
                quality_passed=false
            fi
        done
    fi
    
    # Check CSS basic validity
    if ls *.css 1> /dev/null 2>&1; then
        echo "Checking CSS basic validity..."
        for css_file in *.css; do
            # Basic check for balanced braces
            local open_braces=$(grep -o "{" "$css_file" | wc -l)
            local close_braces=$(grep -o "}" "$css_file" | wc -l)
            if [ "$open_braces" -ne "$close_braces" ]; then
                echo -e "${RED}❌ Unbalanced braces in $css_file${NC}"
                quality_passed=false
            fi
        done
    fi
    
    # Check shell scripts
    if ls *.sh 1> /dev/null 2>&1; then
        echo "Checking shell script syntax..."
        for sh_file in *.sh; do
            if ! bash -n "$sh_file" 2>/dev/null; then
                echo -e "${RED}❌ Shell script syntax error in $sh_file${NC}"
                quality_passed=false
            fi
        done
    fi
    
    if [ "$quality_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# Function to validate functionality
validate_functionality() {
    echo "Running functionality validation..."
    
    local func_passed=true
    
    # Run existing functionality tests if available
    if [ -f "test-functionality.js" ]; then
        echo "Running functionality tests..."
        if ! node test-functionality.js 2>/dev/null; then
            echo -e "${RED}❌ Functionality tests failed${NC}"
            func_passed=false
        fi
    fi
    
    # Run structure tests if available
    if [ -f "test-structure.js" ]; then
        echo "Running structure tests..."
        if ! node test-structure.js 2>/dev/null; then
            echo -e "${RED}❌ Structure tests failed${NC}"
            func_passed=false
        fi
    fi
    
    # Check if package.json scripts work
    if [ -f "package.json" ]; then
        echo "Validating package.json scripts..."
        
        # Check if key scripts are defined
        local has_test=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
        local has_build=$(jq -r '.scripts.build // empty' package.json 2>/dev/null)
        
        if [ -n "$has_test" ]; then
            echo "Test script defined: $has_test"
        fi
        
        if [ -n "$has_build" ]; then
            echo "Build script defined: $has_build"
        fi
    fi
    
    if [ "$func_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# Function to generate validation summary
generate_validation_summary() {
    local total_checks=$1
    local passed_checks=$2
    local validation_passed=$3
    
    echo -e "\n${BLUE}📊 COMPREHENSIVE VALIDATION SUMMARY${NC}"
    echo "=================================================="
    
    local percentage=$((passed_checks * 100 / total_checks))
    
    echo "Total validation checks: $total_checks"
    echo "Passed checks: $passed_checks"
    echo "Failed checks: $((total_checks - passed_checks))"
    echo "Success rate: $percentage%"
    
    echo "Validation result: $([ "$validation_passed" = true ] && echo "PASS" || echo "FAIL")" >> "$VALIDATION_LOG"
    echo "Success rate: $percentage%" >> "$VALIDATION_LOG"
    
    if [ "$validation_passed" = true ]; then
        echo -e "${GREEN}🎉 ALL VALIDATION CHECKS PASSED!${NC}"
        echo -e "${GREEN}✅ Todos appear to be genuinely complete${NC}"
        
        # Generate success recommendations
        echo -e "\n${BLUE}🚀 Next Steps:${NC}"
        echo "1. Consider committing these changes"
        echo "2. Review the todo completion quality"
        echo "3. Test the application functionality"
        echo "4. Update documentation if needed"
        
    elif [ "$percentage" -ge 80 ]; then
        echo -e "${YELLOW}⚠️  MOSTLY COMPLETE - Minor issues detected${NC}"
        echo -e "${YELLOW}💡 Consider addressing remaining issues before proceeding${NC}"
        
    elif [ "$percentage" -ge 60 ]; then
        echo -e "${YELLOW}⚠️  PARTIALLY COMPLETE - Significant issues remain${NC}"
        echo -e "${YELLOW}💡 More work needed to meet completion criteria${NC}"
        
    else
        echo -e "${RED}❌ VALIDATION FAILED - Major issues detected${NC}"
        echo -e "${RED}💡 Substantial work required before completion${NC}"
    fi
    
    # Show most recent log entries
    echo -e "\n${BLUE}📋 Recent Validation Log:${NC}"
    tail -10 "$VALIDATION_LOG" | sed 's/^/  /'
}

# Function to get specific validation feedback
get_validation_feedback() {
    echo -e "\n${BLUE}💡 SPECIFIC VALIDATION FEEDBACK${NC}"
    echo "============================================"
    
    # Check for specific common issues
    if [ -f "$TODO_DIR/todos-current.json" ]; then
        local incomplete_todos=$(jq '[.[] | select(.status!="completed")] | length' "$TODO_DIR/todos-current.json" 2>/dev/null || echo "0")
        
        if [ "$incomplete_todos" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  $incomplete_todos todos still not marked complete${NC}"
            echo "Consider reviewing:"
            jq -r '.[] | select(.status!="completed") | "  - [" + .status + "] " + .content' "$TODO_DIR/todos-current.json" 2>/dev/null || echo "  Error reading todos"
        fi
    fi
    
    # Check git status for guidance
    local git_changes=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$git_changes" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No git changes detected${NC}"
        echo "  - Are you working in the right directory?"
        echo "  - Have the intended changes been made?"
        echo "  - Consider running 'git status' to check"
    fi
    
    echo -e "\n${BLUE}🔧 Recommended Actions:${NC}"
    echo "1. Review failed validation checks above"
    echo "2. Address any code quality issues"
    echo "3. Ensure todos accurately reflect completion status"
    echo "4. Verify git changes align with todo requirements"
    echo "5. Re-run validation: ./todo-validator.sh"
}

# Main execution
main() {
    local action=${1:-"validate"}
    
    case $action in
        "validate")
            echo -e "${BLUE}🚀 Running comprehensive todo validation...${NC}\n"
            if run_comprehensive_validation; then
                echo -e "\n${GREEN}✅ Comprehensive validation PASSED${NC}"
                return 0
            else
                get_validation_feedback
                echo -e "\n${RED}❌ Comprehensive validation FAILED${NC}"
                return 1
            fi
            ;;
        "quick")
            echo -e "${BLUE}⚡ Running quick validation...${NC}\n"
            ./todo-tracker.sh validate
            ;;
        "feedback")
            get_validation_feedback
            ;;
        *)
            echo "Usage: $0 [validate|quick|feedback]"
            echo "  validate - Run comprehensive validation (default)"
            echo "  quick    - Run quick todo state validation only"
            echo "  feedback - Show specific validation feedback"
            exit 1
            ;;
    esac
}

main "$@"
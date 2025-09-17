#!/bin/bash

# Enhanced Stop Hook Validator with Todo Intelligence
# This script runs after Claude Code finishes a task to validate success criteria
# Includes todo tracking, git analysis, and AI-powered review

echo "🔍 Enhanced Stop Hook Validator - Checking success criteria..."
echo "=============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Success criteria tracking
CRITERIA_PASSED=0
TOTAL_CRITERIA=9  # Increased from 6 to include new validations

echo -e "${BLUE}Running enhanced validation checks...${NC}\n"

# NEW: Check 0 - Todo State Validation
echo -e "${PURPLE}🎯 Validating todo completion state...${NC}"
if ./todo-tracker.sh validate 2>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: Todo state validation${NC}"
else
    echo -e "${RED}❌ FAIL: Todo state validation failed${NC}"
fi
echo ""

# NEW: Check 0.5 - Todo-Git Mapping 
echo -e "${PURPLE}🗺️ Validating todo-git change mapping...${NC}"
if ./todo-git-mapper.sh map 2>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: Todo-git mapping validation${NC}"
else
    echo -e "${RED}❌ FAIL: Todo-git mapping validation failed${NC}"
fi
echo ""

# NEW: Check 0.7 - AI-Powered Review
echo -e "${PURPLE}🤖 Running AI-powered todo review...${NC}"
if ./ai-todo-reviewer.sh review 2>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: AI review validation${NC}"
else
    echo -e "${RED}❌ FAIL: AI review validation failed${NC}"
fi
echo ""

# Check 1: Files exist
echo "📁 Checking if all required files exist..."
REQUIRED_FILES=("index.html" "style.css" "script.js" "package.json")
FILES_EXIST=true

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ✅ $file exists"
    else
        echo -e "  ❌ $file is missing"
        FILES_EXIST=false
    fi
done

if [ "$FILES_EXIST" = true ]; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: All required files exist${NC}"
else
    echo -e "${RED}❌ FAIL: Some required files are missing${NC}"
fi

echo ""

# Check 2: HTML validation
echo "🌐 Validating HTML structure..."
if node -e "
const fs = require('fs');
try {
    const html = fs.readFileSync('index.html', 'utf8');
    const required = ['<!DOCTYPE html>', '<html', '<head>', '<body>', 'counter-value', 'increment-btn', 'reset-btn'];
    const missing = required.filter(item => !html.includes(item));
    if (missing.length === 0) {
        console.log('HTML validation passed');
        process.exit(0);
    } else {
        console.log('Missing:', missing.join(', '));
        process.exit(1);
    }
} catch (e) {
    console.log('Error reading HTML file');
    process.exit(1);
}
" 2>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: HTML structure is valid${NC}"
else
    echo -e "${RED}❌ FAIL: HTML structure validation failed${NC}"
fi

echo ""

# Check 3: CSS validation
echo "🎨 Validating CSS content..."
if node -e "
const fs = require('fs');
try {
    const css = fs.readFileSync('style.css', 'utf8');
    const required = ['.container', '.counter-display', '.btn', 'background'];
    const missing = required.filter(item => !css.includes(item));
    if (missing.length === 0) {
        console.log('CSS validation passed');
        process.exit(0);
    } else {
        console.log('Missing CSS elements:', missing.join(', '));
        process.exit(1);
    }
} catch (e) {
    console.log('Error reading CSS file');
    process.exit(1);
}
" 2>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: CSS content is valid${NC}"
else
    echo -e "${RED}❌ FAIL: CSS content validation failed${NC}"
fi

echo ""

# Check 4: JavaScript validation
echo "⚡ Validating JavaScript functionality..."
if node -e "
const fs = require('fs');
try {
    const js = fs.readFileSync('script.js', 'utf8');
    const required = ['increment', 'reset', 'updateDisplay', 'addEventListener'];
    const missing = required.filter(item => !js.includes(item));
    if (missing.length === 0) {
        console.log('JavaScript validation passed');
        process.exit(0);
    } else {
        console.log('Missing JS functionality:', missing.join(', '));
        process.exit(1);
    }
} catch (e) {
    console.log('Error reading JavaScript file');
    process.exit(1);
}
" 2>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: JavaScript functionality is present${NC}"
else
    echo -e "${RED}❌ FAIL: JavaScript functionality validation failed${NC}"
fi

echo ""

# Check 5: Run functionality tests
echo "🧪 Running functionality tests..."
if npm run test:functionality 2>/dev/null 1>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: Functionality tests passed${NC}"
else
    echo -e "${RED}❌ FAIL: Functionality tests failed${NC}"
fi

echo ""

# Check 6: Run structure tests  
echo "🏗️  Running structure tests..."
if npm run test:structure 2>/dev/null 1>/dev/null; then
    ((CRITERIA_PASSED++))
    echo -e "${GREEN}✅ PASS: Structure tests passed${NC}"
else
    echo -e "${RED}❌ FAIL: Structure tests failed${NC}"
fi

echo ""
echo "=================================================="
echo -e "${BLUE}VALIDATION SUMMARY${NC}"
echo "=================================================="
echo -e "Criteria passed: ${CRITERIA_PASSED}/${TOTAL_CRITERIA}"

if [ $CRITERIA_PASSED -eq $TOTAL_CRITERIA ]; then
    echo -e "${GREEN}🎉 ALL SUCCESS CRITERIA MET!${NC}"
    echo -e "${GREEN}The task has been completed successfully.${NC}"
    echo ""
    
    # Generate commit if criteria are met
    echo -e "${BLUE}📝 Generating commit for completed work...${NC}"
    
    # Check if there are changes to commit
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        # Stage all changes
        git add . 2>/dev/null
        
        # Generate commit message based on completed todos
        local completed_todos=""
        if [ -f ".claude/todos-current.json" ]; then
            completed_todos=$(jq -r '[.[] | select(.status=="completed")] | map(.content) | join("; ")' .claude/todos-current.json 2>/dev/null || echo "Enhanced stop hook validation system")
        fi
        
        if [ -z "$completed_todos" ]; then
            completed_todos="Enhanced stop hook validation system with todo intelligence"
        fi
        
        # Create commit with proper attribution
        git commit -m "$(cat <<EOF
$completed_todos

Enhanced the stop hook validation system with:
- Todo state tracking and validation
- Git change mapping to todo items  
- AI-powered completion review
- Comprehensive validation logic

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)" 2>/dev/null && echo -e "${GREEN}✅ Changes committed successfully${NC}" || echo -e "${YELLOW}⚠️  Commit failed or no changes to commit${NC}"
    else
        echo -e "${YELLOW}⚠️  No git changes to commit${NC}"
    fi
    
    echo ""
    echo "You can now:"
    echo "- Run 'npm start' to view the app in your browser"
    echo "- Test the counter functionality"
    echo "- Experiment with different prompts to Claude Code"
    echo "- Use the enhanced validation system for other projects"
    exit 0
else
    echo -e "${RED}❌ SUCCESS CRITERIA NOT MET${NC}"
    echo -e "${YELLOW}The task is not complete. Please fix the failing criteria and continue.${NC}"
    echo ""
    
    # Enhanced feedback based on todo validation
    echo -e "${BLUE}📋 Enhanced Feedback:${NC}"
    
    # Check specific failure points
    if [ $CRITERIA_PASSED -lt 3 ]; then
        echo -e "${YELLOW}💡 Todo and validation infrastructure issues detected${NC}"
        echo "   - Check todo state tracking setup"
        echo "   - Verify git changes align with todos"
        echo "   - Review AI validation feedback"
    elif [ $CRITERIA_PASSED -lt 6 ]; then
        echo -e "${YELLOW}💡 Basic file structure issues detected${NC}"
        echo "   - Ensure all HTML, CSS, and JS files are created"
        echo "   - Verify file content meets requirements"
    elif [ $CRITERIA_PASSED -lt 9 ]; then
        echo -e "${YELLOW}💡 Functionality issues detected${NC}"
        echo "   - Check that code actually works as expected"
        echo "   - Run tests manually to identify specific failures"
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Review the failed criteria above"
    echo "2. Check todo completion accuracy with: ./todo-validator.sh"
    echo "3. Review git changes with: git status && git diff"
    echo "4. Get AI feedback with: ./ai-todo-reviewer.sh review"
    echo "5. Fix issues and re-run validation"
    
    exit 1
fi
#!/bin/bash

# Main Stop Hook Validator
# Simple orchestrator that uses lib functions

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/validators.sh"

# Main validation flow
main() {
    print_header "🔍 Stop Hook Validator"
    echo "Running validation to ensure work is complete..."
    echo
    
    # Run comprehensive validation
    if validate_all; then
        echo
        print_header "✨ VALIDATION PASSED"
        print_success "All success criteria met!"
        
        # Auto-commit if validation passes
        if [ "$1" = "--auto-commit" ] && [ $(git_status | wc -l) -gt 0 ]; then
            print_info "Auto-committing changes..."
            git add -A
            git commit -m "✅ All validation criteria passed

$(get_results_summary) criteria met
- File structure valid
- Syntax checks passed
- Tests successful
- Todos completed
- Git state clean
- AI review approved

🤖 Generated with Claude Code"
            print_success "Changes committed!"
        fi
        
        exit 0
    else
        echo
        print_header "❌ VALIDATION FAILED"
        print_error "Some criteria not met. Continue working."
        
        # Show what needs fixing
        echo
        print_warning "Next steps:"
        cat "$STATE_FILE.tmp" 2>/dev/null | jq -r '.details[] | select(.passed == false) | "- Fix: " + .name + " (" + .message + ")"'
        
        exit 1
    fi
}

# Run main with all arguments
main "$@"
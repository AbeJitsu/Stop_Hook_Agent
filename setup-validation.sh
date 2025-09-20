#!/bin/bash

# Setup script to enforce validation through Git hooks

echo "Setting up validation enforcement..."

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "Running validation before commit..."

# Run tests
if ! npm test; then
    echo "❌ Tests failed! Fix issues before committing."
    exit 1
fi

echo "✅ All tests passed!"
EOF

# Make hook executable
chmod +x .git/hooks/pre-commit

# Create pre-push hook for extra safety
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

echo "Running final validation before push..."

# Run tests again
if ! npm test; then
    echo "❌ Cannot push: Tests are failing!"
    exit 1
fi

echo "✅ Validation complete, pushing..."
EOF

chmod +x .git/hooks/pre-push

echo "✅ Git hooks installed!"
echo "📝 Validation will now run automatically before commits and pushes"
echo ""
echo "To test: Try making a change and committing it"
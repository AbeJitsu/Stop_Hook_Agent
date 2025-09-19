# Stop Hook Agent - Simplified

A DRY, orthogonal validation system that ensures Claude Code completes work before stopping.

## Structure (7 files, ~500 lines)

```
├── counter-app/          # Test application
│   ├── index.html
│   ├── style.css
│   └── script.js
├── lib/                  # Shared utilities
│   ├── core.sh          # Common functions
│   └── validators.sh    # Validation logic
├── validator.sh         # Main entry point
├── test-suite.js        # All tests
├── package.json         # NPM scripts
└── .claude/
    ├── settings.json    # Hook configuration
    └── state.json       # Single state file
```

## How It Works

1. **Stop Hook** - `validator.sh` runs after each Claude Code task
2. **Validation** - 6 criteria checked (files, syntax, tests, todos, git, AI)
3. **Auto-commit** - Only when ALL criteria pass

## Usage

```bash
# Run tests
npm test

# Manual validation
./validator.sh

# Start counter app
npm start
```

## Testing the System

Ask Claude to break something, then request a fix:
```
"Remove the reset button from the counter app"
"Now add it back and ensure all tests pass"
```

The stop hook will ensure work isn't marked complete until validation passes.

## Key Design Principles

- **DRY** - No duplicate code across files
- **Orthogonal** - Each component has one clear purpose
- **Functional** - Every test validates actual functionality
- **Simple** - 500 lines vs 2,700+ in original
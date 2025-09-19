# Stop Hook Agent

A validation system that ensures Claude Code completes work before declaring tasks done.

## What It Does

Prevents AI assistants from stopping work prematurely by running 6 validation checks:
- File structure exists
- Syntax is valid  
- Tests pass
- Todos match code changes
- Git has meaningful changes
- AI review confirms completion

## Quick Start

```bash
# Test the validator
./validator.sh

# Run tests
npm test

# Start counter app
npm start
```

## Project Structure

```
├── counter-app/       # Test application
├── lib/              # Validation logic
├── validator.sh      # Main stop hook
├── test-suite.js     # All tests
└── .claude/
    └── settings.json # Hook configuration
```

## How It Works

See [HOW_IT_WORKS.md](HOW_IT_WORKS.md) for technical details.

## Testing

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for test scenarios.

## Success

✅ 7 core files (~500 lines) down from 24 files (2,700+ lines)  
✅ Catches incomplete work that traditional validation misses  
✅ Forces genuine task completion with auto-commit on success  
# Copilot Instructions for xpath

XPath expression evaluation library for Noir (ZK proof DSL).

## Project Structure

This is a Noir workspace with:
- **`xpath/`**: Main library package with XPath implementation
- **`test_packages/`**: Auto-generated test packages for XPath functions - **never edit manually**
- **`scripts/`**: Test generation and benchmarking tools

## Architecture Overview

- **`xpath/src/`**: Core XPath implementation with function evaluations, operators, and datetime handling
- **`scripts/generate_tests.py`**: Generates test packages for XPath operations from test data

## Noir Language Constraints

- **No early returns**: Use conditional assignment patterns; all paths must reach function end
- **Fixed-width integers**: `u1`, `u8`, `u16`, `u32`, `u64` only
- **Shift operand type matching**: Both operands in `value >> shift` must have same width
- **No floating-point primitives**: All FP arithmetic uses integer math
- **`pub` required**: Functions used across modules need `pub` keyword

## Key Implementation Patterns

### XPath Operations
The library implements various XPath functions and operators including:
- Numeric operations (add, subtract, multiply, divide, integer-divide, mod, equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal)
- Datetime operations (equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal)
- Datetime extraction functions (year, month, day, hours, minutes, seconds, timezone)
- Duration operations (add, subtract, multiply, divide, equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal)
- Boolean operations (not, and, or, equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal)
- Math functions (abs, round, ceiling, floor)
- Comparison utilities (equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal)

## Common Bug Patterns

- **Type constraints**: Ensure proper type conversions for numeric operations
- **Boundary conditions**: Handle edge cases for datetime operations (leap years, month boundaries)
- **Overflow handling**: Be careful with integer arithmetic overflow in operations

## Developer Commands

```bash
# Run test packages locally
python3 scripts/generate_tests.py  # Generate test packages

# Run manual unit tests only (from project root)
nargo test --package xpath_unit_tests

# Run specific test packages
nargo test --package xpath_test_fnabs
nargo test --package xpath_test_opnumeric_add
```

## Supported Operations

| Category | Operations | Test Generation |
|----------|-----------|-----------------|
| Numeric | add, subtract, multiply, divide, integer-divide, mod, equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal | ✅ |
| Datetime | equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal | ✅ |
| Datetime Extraction | year, month, day, hours, minutes, seconds, timezone | ✅ |
| Duration | add, subtract, multiply, divide, equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal | ✅ |
| Boolean | not, and, or, equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal | ✅ |
| Math | abs, round, ceiling, floor | ✅ |
| Comparison | equal, less-than, greater-than, less-than-or-equal, greater-than-or-equal | ✅ |

## Future Extensions

1. **String operations**: String functions from XPath spec
2. **Additional datetime functions**: timezone-from-datetime, etc.
3. **Node operations**: Node set operations from XPath

## Critical Files

| File | Purpose |
|------|---------|
| `xpath/src/` | All XPath function implementations |
| `scripts/generate_tests.py` | Test generation from test data |
| `test_packages/` | Generated test packages (one per test suite) |

## Code Quality

**Always run `nargo fmt` at the end of each run** to automatically format all Noir code and resolve linting errors. This ensures code style consistency across the project.

```bash
nargo fmt
```

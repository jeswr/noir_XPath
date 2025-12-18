# noir_XPath

A Noir library implementing XPath 2.0 functions and operators required by SPARQL 1.1.

## 📚 Documentation

- **[SPARQL_COVERAGE.md](./SPARQL_COVERAGE.md)** - Complete mapping of SPARQL 1.1 functions to implementation status
- **[TESTING.md](./TESTING.md)** - Testing strategy, how to run tests, and coverage details
- **[IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md)** - Phased implementation roadmap (now complete)
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical architecture and design decisions
- **[scripts/README.md](./scripts/README.md)** - Test generation from qt3tests

> [!NOTE]
> **Implementation Status**: All implementable XPath 2.0 functions and operators required by SPARQL 1.1 are now complete. The library is feature-complete for the zero-knowledge context.

> [!CAUTION]
> **Security Warning**: This library has not been security reviewed and should not be used in production systems without a thorough audit.

> [!WARNING]
> **AI-Generated Code**: This library is largely AI-generated. While it has been tested, there may be edge cases or subtle bugs that have not been discovered.

> [!NOTE]
> **Test Coverage**: 
> - Tests are derived from W3C qt3tests covering all implemented functions
> - Float/double operations fully implemented via noir_IEEE754 (v0.1.0)
> - String and regex operations are intentionally deferred (complex in ZK circuits)
> - See [SPARQL_COVERAGE.md](./SPARQL_COVERAGE.md) for complete status

## Overview

This library provides Noir implementations of XPath/XQuery functions as defined in [XQuery 1.0 and XPath 2.0 Functions and Operators](https://www.w3.org/TR/xpath-functions/) that are required by [SPARQL 1.1 Query Language](https://www.w3.org/TR/sparql11-query/).

## Installation

Add to your `Nargo.toml`:

```toml
[dependencies]
xpath = { git = "https://github.com/jeswr/noir_XPath", tag = "v0.1.0", directory = "xpath" }
```

## Features

### Currently Implemented

- **Boolean Operations**: `fn:not`, `op:boolean-equal`, `op:boolean-less-than`, `op:boolean-greater-than`, logical AND/OR
- **Numeric Operations**: 
  - **Integer**: add, subtract, multiply, divide, mod, abs, round, ceil, floor, min, max
  - **Float/Double**: add, subtract, multiply, divide, abs (via noir_IEEE754)
  - **Type Operations**: type promotion, mixed-type comparisons, type casting
  - **Comparisons**: equal, less-than, greater-than (all types)
- **DateTime Operations**: 
  - Construction: from epoch microseconds, from components (with/without timezone)
  - Component extraction: year, month, day, hours, minutes, seconds, microseconds, timezone
  - Comparisons: equal, less-than, greater-than (timezone-aware)
  - Efficient single-Field representation (epoch microseconds)
- **Duration Operations**:
  - Construction: from microseconds, from components
  - Extraction: days, hours, minutes, seconds
  - Arithmetic: add, subtract, multiply, divide, negate
  - DateTime arithmetic: add/subtract duration, compute difference
  - Comparisons: equal, less-than, greater-than
- **Sequence/Aggregate Functions**:
  - Tests: is_empty, exists, count
  - Aggregates: sum, avg, min, max (for integer arrays)
  - Boolean aggregates: all_true, any_true, count_true
  - Partial array operations (with explicit length)
- **Comparison Utilities**: Generic value comparison with Eq/Ord traits

### 🔮 Future (Deferred - Complex in ZK)

- String functions (STRLEN, SUBSTR, CONCAT, UCASE, LCASE, etc.)
- Regex functions (REGEX, REPLACE)
- Hash functions (MD5, SHA256, etc.)
- Decimal type support
- Advanced float rounding (round, ceil, floor for floats)

## SPARQL 1.1 Coverage

This library implements XPath 2.0 functions and operators required by SPARQL 1.1. 

**Quick Summary:**
- ✅ **80+ functions fully implemented** (boolean, numeric [int/float/double], datetime, duration, aggregates)
- 🔮 **String/regex/hash deferred** (complex in ZK circuits)
- ❌ **RAND/NOW not feasible** (non-deterministic in ZK)

For complete function mapping, see **[SPARQL_COVERAGE.md](./SPARQL_COVERAGE.md)**

### ✅ Fully Implemented
- **Boolean operations**: All boolean functions and operators (fn:not, logical-and, logical-or, comparisons)
- **Numeric operations**: All arithmetic and comparison operators for integers, floats, and doubles (via noir_IEEE754)
- **DateTime operations**: Component extraction (year, month, day, hours, minutes, seconds, timezone), comparisons, and arithmetic
- **Duration operations**: All dayTimeDuration operations including arithmetic and comparisons
- **Aggregate functions**: COUNT, SUM, AVG, MIN, MAX for integer sequences

### ⚠️ Partial Support
- **Advanced float rounding**: Basic float operations complete; round/ceil/floor for floats planned
- **Timezone**: TIMEZONE() function implemented; TZ() requires string formatting (deferred)

### ❌ Not Implemented (Deferred)
The following SPARQL 1.1 functions are deferred due to complexity in zero-knowledge circuits:

- **String functions**: All string operations (STRLEN, SUBSTR, CONCAT, UCASE, LCASE, STRSTARTS, STRENDS, CONTAINS, STRBEFORE, STRAFTER, ENCODE_FOR_URI, REGEX, REPLACE, etc.)
  - Reason: Variable-length data and UTF-8 encoding are complex in ZK circuits
- **Hash functions**: MD5, SHA1, SHA256, SHA384, SHA512
  - Reason: Require string output formatting
- **RDF term functions**: isIRI, isBlank, isLiteral, str, lang, datatype, IRI, BNODE, etc.
  - Reason: Out of scope for XPath function library
- **Non-deterministic functions**: RAND(), NOW()
  - Reason: Not meaningful in deterministic zero-knowledge proof context
  - Alternative: These values should be provided as inputs to the circuit
- **Advanced aggregates**: GROUP_CONCAT, SAMPLE
  - Reason: Require string support or more complex logic

See [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) for detailed planning of future features.

For a complete mapping of all SPARQL 1.1 functions to their implementation status, see [SPARQL_COVERAGE.md](./SPARQL_COVERAGE.md).

## Usage

### Boolean Operations

```noir
use dep::xpath::{fn_not, logical_and, logical_or, boolean_equal};

fn example() {
    let result = logical_and(true, fn_not(false));  // true
    assert(boolean_equal(result, true));
}
```

### Numeric Operations

```noir
use dep::xpath::{
    numeric_add_int, 
    numeric_multiply_int,
    numeric_mod_int,
    abs_int,
    min_int,
    max_int,
};

fn example() {
    // Integer operations
    let sum = numeric_add_int(5, 3);  // 8
    let product = numeric_multiply_int(-5, 3);  // -15
    let remainder = numeric_mod_int(7, 3);  // 1
    let absolute = abs_int(-42);  // 42
    let minimum = min_int(5, 3);  // 3
    let maximum = max_int(5, 3);  // 5
}
```

### DateTime Operations

```noir
use dep::xpath::{
    XsdDateTime,
    datetime_from_components,
    datetime_from_components_with_tz,
    year_from_datetime,
    month_from_datetime,
    datetime_less_than,
    timezone_from_datetime,
};

fn example() {
    // Create a DateTime: 2024-06-15T14:30:45.123456Z (UTC)
    let dt = datetime_from_components(2024, 6, 15, 14, 30, 45, 123456);
    
    // Create a DateTime with timezone: 2024-06-15T14:30:45.123456-05:00
    let dt_tz = datetime_from_components_with_tz(2024, 6, 15, 14, 30, 45, 123456, -300);
    
    // Extract components
    assert(year_from_datetime(dt) == 2024);
    assert(month_from_datetime(dt) == 6);
    
    // Extract timezone as duration (SPARQL TIMEZONE function)
    let tz = timezone_from_datetime(dt_tz);
    // tz represents -PT5H (negative 5 hours)
    
    // Compare dates
    let dt_earlier = datetime_from_components(2024, 1, 1, 0, 0, 0, 0);
    assert(datetime_less_than(dt_earlier, dt));
}
```

### Duration Operations

```noir
use dep::xpath::{
    duration_from_components,
    datetime_add_duration,
    datetime_difference,
    days_from_duration,
};

fn example() {
    // Create a duration: 1 day, 2 hours, 30 minutes
    let dur = duration_from_components(false, 1, 2, 30, 0, 0);
    
    // Add duration to datetime
    let dt = datetime_from_components(2024, 1, 1, 0, 0, 0, 0);
    let dt_later = datetime_add_duration(dt, dur);
    
    // Compute difference between datetimes
    let diff = datetime_difference(dt_later, dt);
    assert(days_from_duration(diff) == 1);
}
```

### Sequence/Aggregate Operations

```noir
use dep::xpath::{sum_int, avg_int, min_int_seq, max_int_seq, count};

fn example() {
    let values: [i64; 5] = [10, 20, 30, 40, 50];
    
    assert(count(values) == 5);
    assert(sum_int(values) == 150);
    assert(avg_int(values) == 30);
    assert(min_int_seq(values) == 10);
    assert(max_int_seq(values) == 50);
}
```

## Architecture

The library uses efficient representations optimized for zero-knowledge circuits:

- **DateTime**: Single `Field` storing UTC epoch microseconds
  - Minimizes constraint count
  - Efficient single-field comparisons
  - Component extraction computed on-demand

- **Floats**: IEEE 754 bit representation via noir_IEEE754

See [ARCHITECTURE.md](./ARCHITECTURE.md) for details.

## Project Structure

```
noir_XPath/
├── xpath/                    # Main library
│   └── src/
│       ├── lib.nr           # Module exports
│       ├── types.nr         # Type definitions (XsdDateTime, XsdDayTimeDuration)
│       ├── boolean.nr       # Boolean operations
│       ├── numeric.nr       # Numeric operations
│       ├── datetime.nr      # DateTime operations
│       ├── duration.nr      # Duration operations
│       ├── sequence.nr      # Sequence/aggregate functions
│       └── comparison.nr    # Comparison utilities
├── xpath_unit_tests/        # Unit tests
├── test_packages/           # Auto-generated tests from qt3tests
└── scripts/                 # Test generation scripts
    ├── generate_tests.py    # Generate Noir tests from W3C qt3tests
    └── README.md            # Script documentation
```

## Testing

Run tests:

```bash
# Test all packages in workspace
nargo test

# Test main library only
nargo test --package xpath

# Test unit tests only
nargo test --package xpath_unit_tests
```

For detailed testing information, see [TESTING.md](./TESTING.md).

## Test Generation

Generate Noir tests from the W3C qt3tests suite:

```bash
cd scripts
python generate_tests.py

# Or for specific functions
python generate_tests.py --functions "fn:abs,op:numeric-add"
```

See [scripts/README.md](./scripts/README.md) for details.

## Dependencies

None currently. Float operations via [noir_IEEE754](https://github.com/jeswr/noir_IEEE754) planned for future integration.

## References

- [SPARQL 1.1 Query Language](https://www.w3.org/TR/sparql11-query/)
- [XQuery 1.0 and XPath 2.0 Functions and Operators](https://www.w3.org/TR/xpath-functions/)
- [W3C QT3 Test Suite](https://github.com/w3c/qt3tests)

## Extending for Additional Functions

To add support for additional XPath/SPARQL functions:

1. **Implement the function** in the appropriate module (numeric.nr, datetime.nr, etc.)
2. **Export from lib.nr** to make it part of the public API
3. **Add tests:**
   - Inline tests in the module
   - Comprehensive tests in xpath_unit_tests/
   - Map to qt3tests in scripts/generate_tests.py (if applicable)
4. **Update documentation:**
   - Add to SPARQL_COVERAGE.md
   - Add example to README.md
   - Update TESTING.md

See [TESTING.md](./TESTING.md) for detailed testing guidelines.

## License

MIT

# noir_XPath

A Noir library implementing XPath 2.0 functions and operators required by SPARQL 1.1.

## Overview

This library provides Noir implementations of XPath/XQuery functions as defined in [XQuery 1.0 and XPath 2.0 Functions and Operators](https://www.w3.org/TR/xpath-functions/) that are required by [SPARQL 1.1 Query Language](https://www.w3.org/TR/sparql11-query/).

## Installation

Add to your `Nargo.toml`:

```toml
[dependencies]
xpath = { git = "https://github.com/jeswr/noir_XPath", tag = "v0.1.0" }
```

## Features

### Currently Implemented

- **Boolean Operations**: `fn:not`, `op:boolean-equal`, `op:boolean-less-than`, `op:boolean-greater-than`, logical AND/OR
- **Numeric Operations**: 
  - Integer: add, subtract, multiply, divide, mod, abs, round, ceil, floor, min, max
  - Comparisons: equal, less-than, greater-than
- **DateTime Operations**: 
  - Construction: from epoch microseconds, from components
  - Component extraction: year, month, day, hours, minutes, seconds, microseconds
  - Comparisons: equal, less-than, greater-than
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

### 🔮 Future (Planned)

- Float operations via [noir_IEEE754](https://github.com/jeswr/noir_IEEE754)
- String functions (STRLEN, SUBSTR, CONCAT, etc.)
- Regex functions (REGEX, REPLACE)
- Hash functions (MD5, SHA256, etc.)
- Decimal type support

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
    year_from_datetime,
    month_from_datetime,
    datetime_less_than,
};

fn example() {
    // Create a DateTime: 2024-06-15T14:30:45.123456Z
    let dt = datetime_from_components(2024, 6, 15, 14, 30, 45, 123456);
    
    // Extract components
    assert(year_from_datetime(dt) == 2024);
    assert(month_from_datetime(dt) == 6);
    
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

## License

MIT

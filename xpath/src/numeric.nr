//! Numeric functions and operators for XPath/SPARQL
//!
//! Implements numeric operations for integers.
//! Float operations require the ieee754 dependency (future).
//!
//! XPath operators implemented:
//! - op:numeric-add, op:numeric-subtract, op:numeric-multiply, op:numeric-divide
//! - op:numeric-unary-plus, op:numeric-unary-minus
//! - op:numeric-equal, op:numeric-less-than, op:numeric-greater-than
//! - fn:abs

// ============================================================================
// Integer Operations (using i64)
// ============================================================================

/// op:numeric-add for integers
pub fn numeric_add_int(a: i64, b: i64) -> i64 {
    a + b
}

/// op:numeric-subtract for integers
pub fn numeric_subtract_int(a: i64, b: i64) -> i64 {
    a - b
}

/// op:numeric-multiply for integers
pub fn numeric_multiply_int(a: i64, b: i64) -> i64 {
    a * b
}

/// op:numeric-integer-divide for integers
/// Note: Division by zero will cause an assertion failure
pub fn numeric_divide_int(a: i64, b: i64) -> i64 {
    assert(b != 0, "Division by zero");
    a / b
}

/// op:numeric-unary-plus for integers
/// Returns the value unchanged (identity operation)
pub fn numeric_unary_plus_int(a: i64) -> i64 {
    a
}

/// op:numeric-unary-minus for integers
/// Returns the negation of the value
pub fn numeric_unary_minus_int(a: i64) -> i64 {
    -a
}

/// op:numeric-equal for integers
pub fn numeric_equal_int(a: i64, b: i64) -> bool {
    a == b
}

/// op:numeric-less-than for integers
pub fn numeric_less_than_int(a: i64, b: i64) -> bool {
    a < b
}

/// op:numeric-greater-than for integers
pub fn numeric_greater_than_int(a: i64, b: i64) -> bool {
    a > b
}

/// op:numeric-less-than-or-equal for integers
pub fn numeric_le_int(a: i64, b: i64) -> bool {
    a <= b
}

/// op:numeric-greater-than-or-equal for integers
pub fn numeric_ge_int(a: i64, b: i64) -> bool {
    a >= b
}

/// fn:abs for integers
/// Returns the absolute value
pub fn abs_int(a: i64) -> i64 {
    if a < 0 {
        -a
    } else {
        a
    }
}

/// op:numeric-mod for integers
/// Returns the remainder of integer division
pub fn numeric_mod_int(a: i64, b: i64) -> i64 {
    assert(b != 0, "Modulo by zero");
    a % b
}

/// fn:round for integers
/// Returns the value unchanged (identity operation for integers)
pub fn round_int(a: i64) -> i64 {
    a
}

/// fn:ceiling for integers
/// Returns the value unchanged (identity operation for integers)
pub fn ceil_int(a: i64) -> i64 {
    a
}

/// fn:floor for integers
/// Returns the value unchanged (identity operation for integers)
pub fn floor_int(a: i64) -> i64 {
    a
}

/// Minimum of two integers
pub fn min_int(a: i64, b: i64) -> i64 {
    if a < b {
        a
    } else {
        b
    }
}

/// Maximum of two integers
pub fn max_int(a: i64, b: i64) -> i64 {
    if a > b {
        a
    } else {
        b
    }
}

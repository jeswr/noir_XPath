//! Boolean functions and operators for XPath/SPARQL
//!
//! Implements:
//! - fn:not (logical NOT)
//! - Logical AND and OR
//! - Boolean comparison operators

/// XPath fn:not - Logical NOT
/// Returns true if the argument is false, and false if the argument is true.
pub fn fn_not(a: bool) -> bool {
    !a
}

/// Logical AND operation
/// Returns true if both arguments are true.
pub fn logical_and(a: bool, b: bool) -> bool {
    a & b
}

/// Logical OR operation
/// Returns true if at least one argument is true.
pub fn logical_or(a: bool, b: bool) -> bool {
    a | b
}

/// op:boolean-equal
/// Returns true if both arguments have the same boolean value.
pub fn boolean_equal(a: bool, b: bool) -> bool {
    a == b
}

/// op:boolean-less-than
/// Returns true if the first argument is less than the second.
/// In XPath boolean ordering: false < true
pub fn boolean_less_than(a: bool, b: bool) -> bool {
    // false (0) < true (1)
    // Only true when a is false and b is true
    (!a) & b
}

/// op:boolean-greater-than
/// Returns true if the first argument is greater than the second.
/// In XPath boolean ordering: true > false
pub fn boolean_greater_than(a: bool, b: bool) -> bool {
    // true (1) > false (0)
    // Only true when a is true and b is false
    a & (!b)
}

// ============================================================================
// Tests
// ============================================================================

#[test]
fn test_fn_not() {
    assert(fn_not(true) == false);
    assert(fn_not(false) == true);
}

#[test]
fn test_logical_and() {
    assert(logical_and(true, true) == true);
    assert(logical_and(true, false) == false);
    assert(logical_and(false, true) == false);
    assert(logical_and(false, false) == false);
}

#[test]
fn test_logical_or() {
    assert(logical_or(true, true) == true);
    assert(logical_or(true, false) == true);
    assert(logical_or(false, true) == true);
    assert(logical_or(false, false) == false);
}

#[test]
fn test_boolean_equal() {
    assert(boolean_equal(true, true) == true);
    assert(boolean_equal(false, false) == true);
    assert(boolean_equal(true, false) == false);
    assert(boolean_equal(false, true) == false);
}

#[test]
fn test_boolean_less_than() {
    // false < true
    assert(boolean_less_than(false, true) == true);
    assert(boolean_less_than(true, false) == false);
    assert(boolean_less_than(true, true) == false);
    assert(boolean_less_than(false, false) == false);
}

#[test]
fn test_boolean_greater_than() {
    // true > false
    assert(boolean_greater_than(true, false) == true);
    assert(boolean_greater_than(false, true) == false);
    assert(boolean_greater_than(true, true) == false);
    assert(boolean_greater_than(false, false) == false);
}

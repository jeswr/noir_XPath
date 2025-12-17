//! Additional tests for boolean operations

use dep::xpath::{
    fn_not,
    logical_and,
    logical_or,
    boolean_equal,
    boolean_less_than,
    boolean_greater_than,
};

// ============================================================================
// Tests moved from xpath/src/boolean.nr
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

// ============================================================================
// Additional tests
// ============================================================================

#[test]
fn test_boolean_chained_operations() {
    // Complex expressions
    assert(logical_and(logical_or(true, false), true) == true);
    assert(logical_or(logical_and(false, false), true) == true);
    assert(fn_not(logical_and(true, false)) == true);
}

#[test]
fn test_boolean_comparison_all_combinations() {
    // Truth table for boolean_less_than (false < true)
    // a=false, b=false -> false (not less than)
    // a=false, b=true  -> true  (false < true)
    // a=true,  b=false -> false (not less than)
    // a=true,  b=true  -> false (not less than)
    
    let results = [
        boolean_less_than(false, false),  // false
        boolean_less_than(false, true),   // true
        boolean_less_than(true, false),   // false
        boolean_less_than(true, true),    // false
    ];
    
    assert(results[0] == false);
    assert(results[1] == true);
    assert(results[2] == false);
    assert(results[3] == false);
}

#[test]
fn test_boolean_greater_than_all_combinations() {
    // Truth table for boolean_greater_than (true > false)
    let results = [
        boolean_greater_than(false, false),  // false
        boolean_greater_than(false, true),   // false
        boolean_greater_than(true, false),   // true
        boolean_greater_than(true, true),    // false
    ];
    
    assert(results[0] == false);
    assert(results[1] == false);
    assert(results[2] == true);
    assert(results[3] == false);
}

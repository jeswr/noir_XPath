//! Additional tests for numeric operations

use dep::xpath::{
    numeric_add_int,
    numeric_subtract_int,
    numeric_multiply_int,
    numeric_divide_int,
    numeric_equal_int,
    numeric_less_than_int,
    numeric_greater_than_int,
    abs_int,
};

#[test]
fn test_integer_edge_cases() {
    // Test with larger numbers
    assert(numeric_add_int(1000000, 2000000) == 3000000);
    assert(numeric_multiply_int(10000, 10000) == 100000000);
    
    // Test division truncation
    assert(numeric_divide_int(10, 3) == 3);
    assert(numeric_divide_int(10, 4) == 2);
    assert(numeric_divide_int(-10, 3) == -3);
}

#[test]
fn test_integer_comparison_edge_cases() {
    // Test with negative numbers
    assert(numeric_less_than_int(-100, -50) == true);
    assert(numeric_less_than_int(-50, -100) == false);
    assert(numeric_greater_than_int(-50, -100) == true);
    
    // Test zero
    assert(numeric_less_than_int(-1, 0) == true);
    assert(numeric_less_than_int(0, 1) == true);
    assert(numeric_equal_int(0, 0) == true);
}

#[test]
fn test_abs_edge_cases() {
    // Large values
    assert(abs_int(1000000000) == 1000000000);
    assert(abs_int(-1000000000) == 1000000000);
}

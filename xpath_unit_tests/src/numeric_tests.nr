//! Additional tests for numeric operations

use dep::xpath::{
    numeric_add_int,
    numeric_subtract_int,
    numeric_multiply_int,
    numeric_divide_int,
    numeric_equal_int,
    numeric_less_than_int,
    numeric_greater_than_int,
    numeric_unary_plus_int,
    numeric_unary_minus_int,
    numeric_mod_int,
    abs_int,
    round_int,
    ceil_int,
    floor_int,
    min_int,
    max_int,
    NumericType,
    get_common_type,
    XsdFloat,
    XsdDouble,
    numeric_add_float,
    numeric_equal_float,
    numeric_less_than_float,
    numeric_greater_than_float,
    numeric_add_double,
    numeric_equal_double,
    numeric_less_than_double,
    numeric_greater_than_double,
    cast_integer_to_float,
    cast_integer_to_double,
    cast_float_to_integer,
    cast_double_to_integer,
    cast_double_to_float,
};

// ============================================================================
// Tests moved from xpath/src/numeric.nr
// ============================================================================

#[test]
fn test_numeric_add_int() {
    assert(numeric_add_int(2, 3) == 5);
    assert(numeric_add_int(-2, 3) == 1);
    assert(numeric_add_int(-2, -3) == -5);
    assert(numeric_add_int(0, 0) == 0);
}

#[test]
fn test_numeric_subtract_int() {
    assert(numeric_subtract_int(5, 3) == 2);
    assert(numeric_subtract_int(3, 5) == -2);
    assert(numeric_subtract_int(-2, -3) == 1);
}

#[test]
fn test_numeric_multiply_int() {
    assert(numeric_multiply_int(2, 3) == 6);
    assert(numeric_multiply_int(-2, 3) == -6);
    assert(numeric_multiply_int(-2, -3) == 6);
    assert(numeric_multiply_int(0, 100) == 0);
}

#[test]
fn test_numeric_divide_int() {
    assert(numeric_divide_int(6, 3) == 2);
    assert(numeric_divide_int(7, 3) == 2);  // Integer division truncates
    assert(numeric_divide_int(-6, 3) == -2);
}

#[test]
fn test_numeric_unary_plus_int() {
    assert(numeric_unary_plus_int(5) == 5);
    assert(numeric_unary_plus_int(-5) == -5);
}

#[test]
fn test_numeric_unary_minus_int() {
    assert(numeric_unary_minus_int(5) == -5);
    assert(numeric_unary_minus_int(-5) == 5);
}

#[test]
fn test_numeric_equal_int() {
    assert(numeric_equal_int(5, 5) == true);
    assert(numeric_equal_int(5, 3) == false);
    assert(numeric_equal_int(-5, -5) == true);
}

#[test]
fn test_numeric_less_than_int() {
    assert(numeric_less_than_int(3, 5) == true);
    assert(numeric_less_than_int(5, 3) == false);
    assert(numeric_less_than_int(5, 5) == false);
    assert(numeric_less_than_int(-5, 3) == true);
}

#[test]
fn test_numeric_greater_than_int() {
    assert(numeric_greater_than_int(5, 3) == true);
    assert(numeric_greater_than_int(3, 5) == false);
    assert(numeric_greater_than_int(5, 5) == false);
    assert(numeric_greater_than_int(3, -5) == true);
}

#[test]
fn test_abs_int() {
    assert(abs_int(5) == 5);
    assert(abs_int(-5) == 5);
    assert(abs_int(0) == 0);
}

#[test]
fn test_numeric_mod_int() {
    assert(numeric_mod_int(7, 3) == 1);
    assert(numeric_mod_int(6, 3) == 0);
    assert(numeric_mod_int(-7, 3) == -1);
    assert(numeric_mod_int(7, -3) == 1);
}

#[test]
fn test_rounding_functions_int() {
    // For integers, these are identity operations
    assert(round_int(5) == 5);
    assert(round_int(-5) == -5);
    assert(ceil_int(5) == 5);
    assert(floor_int(5) == 5);
}

#[test]
fn test_min_max_int() {
    assert(min_int(3, 5) == 3);
    assert(min_int(5, 3) == 3);
    assert(min_int(-3, 5) == -3);
    assert(max_int(3, 5) == 5);
    assert(max_int(5, 3) == 5);
    assert(max_int(-3, 5) == 5);
}

// ============================================================================
// Tests moved from xpath/src/numeric_types.nr
// ============================================================================

#[test]
fn test_numeric_type_constructors() {
    assert(NumericType::integer().is_integer());
    assert(NumericType::decimal().is_decimal());
    assert(NumericType::float().is_float());
    assert(NumericType::double().is_double());
}

#[test]
fn test_get_common_type() {
    // Integer + Integer = Integer
    assert(get_common_type(NumericType::integer(), NumericType::integer()).is_integer());
    
    // Integer + Decimal = Decimal
    assert(get_common_type(NumericType::integer(), NumericType::decimal()).is_decimal());
    
    // Float + Integer = Double (promoted)
    assert(get_common_type(NumericType::float(), NumericType::integer()).is_double());
    
    // Double + anything = Double
    assert(get_common_type(NumericType::double(), NumericType::integer()).is_double());
    assert(get_common_type(NumericType::double(), NumericType::float()).is_double());
}

#[test]
fn test_float_zero() {
    let zero = XsdFloat::zero();
    let neg_zero = XsdFloat::neg_zero();
    
    // +0 == -0 per IEEE 754
    assert(numeric_equal_float(zero, neg_zero));
}

#[test]
fn test_float_nan() {
    let nan = XsdFloat::nan();
    
    // NaN != NaN per IEEE 754
    assert(!numeric_equal_float(nan, nan));
    assert(!numeric_less_than_float(nan, nan));
    assert(!numeric_greater_than_float(nan, nan));
}

#[test]
fn test_float_infinity() {
    let inf = XsdFloat::infinity();
    let neg_inf = XsdFloat::neg_infinity();
    let one = XsdFloat::from_bits(0x3F800000); // 1.0f
    
    assert(numeric_less_than_float(neg_inf, one));
    assert(numeric_less_than_float(one, inf));
    assert(numeric_greater_than_float(inf, neg_inf));
}

#[test]
fn test_double_zero() {
    let zero = XsdDouble::zero();
    let neg_zero = XsdDouble::neg_zero();
    
    // +0 == -0 per IEEE 754
    assert(numeric_equal_double(zero, neg_zero));
}

#[test]
fn test_double_nan() {
    let nan = XsdDouble::nan();
    
    // NaN != NaN per IEEE 754
    assert(!numeric_equal_double(nan, nan));
    assert(!numeric_less_than_double(nan, nan));
    assert(!numeric_greater_than_double(nan, nan));
}

#[test]
fn test_float_arithmetic() {
    // Use known bit patterns for 2.0 and 3.0
    let two = XsdFloat::from_bits(0x40000000);   // 2.0f
    let three = XsdFloat::from_bits(0x40400000); // 3.0f
    let five = XsdFloat::from_bits(0x40A00000);  // 5.0f
    
    let sum = numeric_add_float(two, three);
    assert(numeric_equal_float(sum, five));
}

#[test]
fn test_double_arithmetic() {
    // Use known bit patterns for 2.0 and 3.0
    let two = XsdDouble::from_bits(0x4000000000000000);   // 2.0
    let three = XsdDouble::from_bits(0x4008000000000000); // 3.0
    let five = XsdDouble::from_bits(0x4014000000000000);  // 5.0
    
    let sum = numeric_add_double(two, three);
    assert(numeric_equal_double(sum, five));
}

#[test]
fn test_float_to_double_promotion() {
    // Promote 1.0f to double
    let one_float = XsdFloat::from_bits(0x3F800000); // 1.0f
    let one_double = XsdDouble::from_float(one_float);
    let expected = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    
    assert(numeric_equal_double(one_double, expected));
}

#[test]
fn test_small_int_to_float() {
    let one = XsdFloat::from_small_int(1);
    let expected = XsdFloat::from_bits(0x3F800000); // 1.0f
    assert(numeric_equal_float(one, expected));
}

#[test]
fn test_small_int_to_double() {
    let one = XsdDouble::from_small_int(1);
    let expected = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    assert(numeric_equal_double(one, expected));
}

// ============================================================================
// Type Casting Tests
// ============================================================================

#[test]
fn test_cast_integer_to_float_zero() {
    let result = cast_integer_to_float(0);
    assert(numeric_equal_float(result, XsdFloat::zero()));
}

#[test]
fn test_cast_integer_to_float_one() {
    let result = cast_integer_to_float(1);
    let expected = XsdFloat::from_bits(0x3F800000); // 1.0f
    assert(numeric_equal_float(result, expected));
}

#[test]
fn test_cast_integer_to_float_negative() {
    let result = cast_integer_to_float(-1);
    let expected = XsdFloat::from_bits(0xBF800000); // -1.0f
    assert(numeric_equal_float(result, expected));
}

#[test]
fn test_cast_integer_to_float_ten() {
    let result = cast_integer_to_float(10);
    let expected = XsdFloat::from_bits(0x41200000); // 10.0f
    assert(numeric_equal_float(result, expected));
}

#[test]
fn test_cast_integer_to_double_zero() {
    let result = cast_integer_to_double(0);
    assert(numeric_equal_double(result, XsdDouble::zero()));
}

#[test]
fn test_cast_integer_to_double_one() {
    let result = cast_integer_to_double(1);
    let expected = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    assert(numeric_equal_double(result, expected));
}

#[test]
fn test_cast_integer_to_double_negative() {
    let result = cast_integer_to_double(-1);
    let expected = XsdDouble::from_bits(0xBFF0000000000000); // -1.0
    assert(numeric_equal_double(result, expected));
}

#[test]
fn test_cast_integer_to_double_hundred() {
    // Test with 100, which is within i8 range
    let result = cast_integer_to_double(100);
    let expected = XsdDouble::from_bits(0x4059000000000000); // 100.0
    assert(numeric_equal_double(result, expected));
}

#[test]
fn test_cast_float_to_integer_zero() {
    let f = XsdFloat::zero();
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == 0);
}

#[test]
fn test_cast_float_to_integer_one() {
    let f = XsdFloat::from_bits(0x3F800000); // 1.0f
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == 1);
}

#[test]
fn test_cast_float_to_integer_negative() {
    let f = XsdFloat::from_bits(0xC0A00000); // -5.0f
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == -5);
}

#[test]
fn test_cast_float_to_integer_truncates() {
    let f = XsdFloat::from_bits(0x40133333); // 2.3f
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == 2);
}

#[test]
fn test_cast_float_to_integer_nan() {
    let f = XsdFloat::nan();
    let result = cast_float_to_integer(f);
    assert(result.is_none());
}

#[test]
fn test_cast_float_to_integer_infinity() {
    let f = XsdFloat::infinity();
    let result = cast_float_to_integer(f);
    assert(result.is_none());
}

#[test]
fn test_cast_double_to_integer_zero() {
    let d = XsdDouble::zero();
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == 0);
}

#[test]
fn test_cast_double_to_integer_one() {
    let d = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == 1);
}

#[test]
fn test_cast_double_to_integer_negative() {
    let d = XsdDouble::from_bits(0xC014000000000000); // -5.0
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == -5);
}

#[test]
fn test_cast_double_to_integer_truncates() {
    let d = XsdDouble::from_bits(0x4002666666666666); // 2.3
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == 2);
}

#[test]
fn test_cast_double_to_integer_nan() {
    let d = XsdDouble::nan();
    let result = cast_double_to_integer(d);
    assert(result.is_none());
}

#[test]
fn test_cast_double_to_integer_infinity() {
    let d = XsdDouble::infinity();
    let result = cast_double_to_integer(d);
    assert(result.is_none());
}

#[test]
fn test_cast_double_to_float_zero() {
    let d = XsdDouble::zero();
    let result = cast_double_to_float(d);
    assert(numeric_equal_float(result, XsdFloat::zero()));
}

#[test]
fn test_cast_double_to_float_one() {
    let d = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    let result = cast_double_to_float(d);
    let expected = XsdFloat::from_bits(0x3F800000); // 1.0f
    assert(numeric_equal_float(result, expected));
}

#[test]
fn test_cast_double_to_float_nan() {
    let d = XsdDouble::nan();
    let result = cast_double_to_float(d);
    assert(result.is_nan());
}

#[test]
fn test_cast_double_to_float_infinity() {
    let d = XsdDouble::infinity();
    let result = cast_double_to_float(d);
    assert(numeric_equal_float(result, XsdFloat::infinity()));
}

#[test]
fn test_cast_double_to_float_neg_infinity() {
    let d = XsdDouble::neg_infinity();
    let result = cast_double_to_float(d);
    assert(numeric_equal_float(result, XsdFloat::neg_infinity()));
}

// ============================================================================
// Additional tests
// ============================================================================

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


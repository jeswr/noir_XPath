//! Test chunk 0 for xs:integer-from-double

use dep::xpath::{cast_double_to_integer, XsdDouble};

#[test]
fn cast_zero() {
    let d = XsdDouble::from_bits(0); // 0.0
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == 0);
}

#[test]
fn cast_one() {
    let d = XsdDouble::from_bits(4607182418800017408); // 1.0
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == 1);
}

#[test]
fn cast_negative_one() {
    let d = XsdDouble::from_bits(13830554455654793216); // -1.0
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == -1);
}

#[test]
fn cast_truncates_positive() {
    let d = XsdDouble::from_bits(4617315517961601024); // 5.5
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == 5); // Truncates toward zero
}

#[test]
fn cast_truncates_negative() {
    let d = XsdDouble::from_bits(13840687554816376832); // -5.5
    let result = cast_double_to_integer(d);
    assert(result.is_some());
    assert(result.unwrap() == -5); // Truncates toward zero
}

#[test]
fn cast_nan_returns_none() {
    let d = XsdDouble::from_bits(0x7FF8000000000000); // NaN
    let result = cast_double_to_integer(d);
    assert(result.is_none());
}

#[test]
fn cast_infinity_returns_none() {
    let d = XsdDouble::from_bits(0x7FF0000000000000); // +Infinity
    let result = cast_double_to_integer(d);
    assert(result.is_none());
}

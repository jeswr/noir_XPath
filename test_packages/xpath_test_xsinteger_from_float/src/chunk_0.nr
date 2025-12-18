//! Test chunk 0 for xs:integer-from-float

use dep::xpath::{cast_float_to_integer, XsdFloat};

#[test]
fn cast_zero() {
    let f = XsdFloat::from_bits(0); // 0.0
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == 0);
}

#[test]
fn cast_one() {
    let f = XsdFloat::from_bits(1065353216); // 1.0
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == 1);
}

#[test]
fn cast_negative_one() {
    let f = XsdFloat::from_bits(3212836864); // -1.0
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == -1);
}

#[test]
fn cast_truncates_positive() {
    let f = XsdFloat::from_bits(1084227584); // 5.5
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == 5); // Truncates toward zero
}

#[test]
fn cast_truncates_negative() {
    let f = XsdFloat::from_bits(3231711232); // -5.5
    let result = cast_float_to_integer(f);
    assert(result.is_some());
    assert(result.unwrap() == -5); // Truncates toward zero
}

#[test]
fn cast_nan_returns_none() {
    let f = XsdFloat::from_bits(0x7FC00000); // NaN
    let result = cast_float_to_integer(f);
    assert(result.is_none());
}

#[test]
fn cast_infinity_returns_none() {
    let f = XsdFloat::from_bits(0x7F800000); // +Infinity
    let result = cast_float_to_integer(f);
    assert(result.is_none());
}

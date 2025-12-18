//! Test chunk 0 for xs:float-from-double

use dep::xpath::{cast_double_to_float, XsdDouble};

#[test]
fn cast_zero() {
    let d = XsdDouble::from_bits(0); // 0.0
    let result = cast_double_to_float(d);
    assert(result.to_bits() == 0);
}

#[test]
fn cast_one() {
    let d = XsdDouble::from_bits(4607182418800017408); // 1.0
    let result = cast_double_to_float(d);
    // 1.0 as float32: 0x3F800000 = 1065353216
    assert(result.to_bits() == 1065353216);
}

#[test]
fn cast_nan() {
    let d = XsdDouble::from_bits(0x7FF8000000000000); // NaN
    let result = cast_double_to_float(d);
    // NaN as float32: 0x7FC00000 = 2143289344
    assert(result.to_bits() == 2143289344);
}

#[test]
fn cast_infinity() {
    let d = XsdDouble::from_bits(0x7FF0000000000000); // +Infinity
    let result = cast_double_to_float(d);
    // +Infinity as float32: 0x7F800000 = 2139095040
    assert(result.to_bits() == 2139095040);
}

#[test]
fn cast_neg_infinity() {
    let d = XsdDouble::from_bits(0xFFF0000000000000); // -Infinity
    let result = cast_double_to_float(d);
    // -Infinity as float32: 0xFF800000 = 4286578688
    assert(result.to_bits() == 4286578688);
}

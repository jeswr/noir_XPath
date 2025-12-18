//! Test chunk 0 for xs:double-from-int

use dep::xpath::cast_integer_to_double;

#[test]
fn cast_zero() {
    let result = cast_integer_to_double(0);
    assert(result.to_bits() == 0);
}

#[test]
fn cast_one() {
    let result = cast_integer_to_double(1);
    // 1.0 in IEEE 754 float64: 0x3FF0000000000000 = 4607182418800017408
    assert(result.to_bits() == 4607182418800017408);
}

#[test]
fn cast_negative_one() {
    let result = cast_integer_to_double(-1);
    // -1.0 in IEEE 754 float64: 0xBFF0000000000000 = 13830554455654793216
    assert(result.to_bits() == 13830554455654793216);
}

#[test]
fn cast_hundred() {
    let result = cast_integer_to_double(100);
    // 100.0 in IEEE 754 float64: 0x4059000000000000 = 4636737291354636288
    assert(result.to_bits() == 4636737291354636288);
}

#[test]
fn cast_negative_hundred() {
    let result = cast_integer_to_double(-100);
    // -100.0 in IEEE 754 float64: 0xC059000000000000 = 13860109328209412096
    assert(result.to_bits() == 13860109328209412096);
}

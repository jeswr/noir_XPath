//! Test chunk 0 for xs:float-from-int

use dep::xpath::cast_integer_to_float;

#[test]
fn cast_zero() {
    let result = cast_integer_to_float(0);
    assert(result.to_bits() == 0);
}

#[test]
fn cast_one() {
    let result = cast_integer_to_float(1);
    // 1.0 in IEEE 754 float32: sign=0, exp=127 (biased), mantissa=0
    // bits: 0x3F800000 = 1065353216
    assert(result.to_bits() == 1065353216);
}

#[test]
fn cast_negative_one() {
    let result = cast_integer_to_float(-1);
    // -1.0 in IEEE 754 float32: sign=1, exp=127, mantissa=0
    // bits: 0xBF800000 = 3212836864
    assert(result.to_bits() == 3212836864);
}

#[test]
fn cast_ten() {
    let result = cast_integer_to_float(10);
    // 10.0 in IEEE 754 float32: 0x41200000 = 1092616192
    assert(result.to_bits() == 1092616192);
}

#[test]
fn cast_negative_ten() {
    let result = cast_integer_to_float(-10);
    // -10.0 in IEEE 754 float32: 0xC1200000 = 3240099840
    assert(result.to_bits() == 3240099840);
}

#[test]
fn cast_max_small_int() {
    let result = cast_integer_to_float(127);
    // 127.0 in IEEE 754 float32: 0x42FE0000 = 1123942400
    assert(result.to_bits() == 1123942400);
}

#[test]
fn cast_min_small_int() {
    let result = cast_integer_to_float(-127);
    // -127.0 in IEEE 754 float32: 0xC2FE0000 = 3271426048
    assert(result.to_bits() == 3271426048);
}

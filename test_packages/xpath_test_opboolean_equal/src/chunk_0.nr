//! Test chunk 0 for op:boolean-equal
//! Contains 41 tests

use dep::xpath::{
    boolean_equal,
};

#[test]
fn op_boolean_equal2args_1() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal2args_2() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal2args_3() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal2args_4() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal2args_5() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal_1() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_2() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal_3() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_4() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_5() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_6() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_7() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_8() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_9() {
    //  ******************************************************* Tes
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_10() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_11() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_15() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_16() {
    //  ******************************************************* Tes
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_19() {
    // Only one comparison allowed per expression, unless parenthes
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_001() {
    //  *******************************************************  Te
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_more_args_002() {
    //  *******************************************************  Te
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_more_args_003() {
    //  *******************************************************  Te
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal_more_args_004() {
    //  *******************************************************  Te
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal_more_args_005() {
    //  *******************************************************  Te
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_more_args_006() {
    //  *******************************************************  Te
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_more_args_007() {
    //  *******************************************************  Te
    assert(boolean_equal(false, false) == true);
}

#[test]
fn op_boolean_equal_more_args_008() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_009() {
    //  *******************************************************  Te
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_more_args_010() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_011() {
    //  *******************************************************  Te
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_more_args_012() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_013() {
    //  *******************************************************  Te
    assert(boolean_equal(false, true) == false);
}

#[test]
fn op_boolean_equal_more_args_014() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_015() {
    //  *******************************************************  Te
    assert(boolean_equal(true, false) == false);
}

#[test]
fn op_boolean_equal_more_args_016() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_017() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_018() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn op_boolean_equal_more_args_019() {
    //  *******************************************************  Te
    assert(boolean_equal(true, false) == false);
}

#[test]
fn k_booleanequal_1() {
    //  *******************************************************  Te
    assert(boolean_equal(false, false) == true);
}

#[test]
fn k_booleanequal_2() {
    //  *******************************************************  Te
    assert(boolean_equal(true, true) == true);
}

#[test]
fn k_booleanequal_5() {
    //  *******************************************************  Te
    assert(boolean_equal(false, false) == true);
}

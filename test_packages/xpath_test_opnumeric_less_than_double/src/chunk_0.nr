//! Test chunk 0 for op:numeric-less-than-double
//! Contains 8 tests

use dep::xpath::{numeric_less_than_double, XsdDouble};

#[test]
fn op_numeric_less_thandbl2args_1() {
    //  ******************************************************* Tes
    let a = XsdDouble::from_bits(18442240474082181119);
    let b = XsdDouble::from_bits(18442240474082181119);
    assert(numeric_less_than_double(a, b) == false);
}

#[test]
fn op_numeric_less_thandbl2args_2() {
    //  ******************************************************* Tes
    let a = XsdDouble::from_bits(0);
    let b = XsdDouble::from_bits(18442240474082181119);
    assert(numeric_less_than_double(a, b) == false);
}

#[test]
fn op_numeric_less_thandbl2args_3() {
    //  ******************************************************* Tes
    let a = XsdDouble::from_bits(9218868437227405311);
    let b = XsdDouble::from_bits(18442240474082181119);
    assert(numeric_less_than_double(a, b) == false);
}

#[test]
fn op_numeric_less_thandbl2args_4() {
    //  ******************************************************* Tes
    let a = XsdDouble::from_bits(18442240474082181119);
    let b = XsdDouble::from_bits(0);
    assert(numeric_less_than_double(a, b) == true);
}

#[test]
fn op_numeric_less_thandbl2args_5() {
    //  ******************************************************* Tes
    let a = XsdDouble::from_bits(18442240474082181119);
    let b = XsdDouble::from_bits(9218868437227405311);
    assert(numeric_less_than_double(a, b) == true);
}

#[test]
fn k_numericlt_5() {
    //  *******************************************************  Te
    let a = XsdDouble::from_bits(0);
    let b = XsdDouble::from_bits(9218868437227405312);
    assert(numeric_less_than_double(a, b) == true);
}

#[test]
fn k_numericlt_6() {
    //  *******************************************************  Te
    let a = XsdDouble::from_bits(18442240474082181120);
    let b = XsdDouble::from_bits(0);
    assert(numeric_less_than_double(a, b) == true);
}

#[test]
fn k_numericlt_7() {
    //  *******************************************************  Te
    let a = XsdDouble::from_bits(13830554455654793216);
    let b = XsdDouble::from_bits(4607182418800017408);
    assert(numeric_less_than_double(a, b) == true);
}

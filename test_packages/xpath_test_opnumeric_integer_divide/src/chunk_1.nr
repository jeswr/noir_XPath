//! Test chunk 1 for op:numeric-integer-divide
//! Contains 1 tests

use dep::xpath::numeric_divide_int;

#[test]
fn cbcl_numeric_idivide_007() {
    //  Test idiv by one on an xs:double
    assert(numeric_divide_int(1, 1) == 1);
}

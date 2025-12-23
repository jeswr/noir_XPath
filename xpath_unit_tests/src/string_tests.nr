//! Unit tests for XPath string functions
//!
//! NOTE: Due to Noir's limitations, only functions that return boolean or numeric
//! values can be tested. Functions that create new strings (substring, upper_case,
//! lower_case, concat, etc.) cannot work correctly in Noir as there's no runtime
//! byte-to-string conversion.

use dep::xpath::{contains, ends_with, starts_with, string_length};

// Tests for string_length (fn:string-length / STRLEN)
// This works because it returns a number, not a string
#[test]
fn test_string_length_empty() {
    let s: str<0> = "";
    assert(string_length::<0>(s) == 0);
}

#[test]
fn test_string_length_word() {
    let s: str<5> = "hello";
    assert(string_length::<5>(s) == 5);
}

#[test]
fn test_string_length_phrase() {
    let s: str<11> = "Hello World";
    assert(string_length::<11>(s) == 11);
}

// Tests for starts_with (fn:starts-with / STRSTARTS)
// This works because it returns a boolean
#[test]
fn test_starts_with_true() {
    let s: str<11> = "Hello World";
    let prefix: str<5> = "Hello";
    assert(starts_with::<11, 5>(s, prefix));
}

#[test]
fn test_starts_with_false() {
    let s: str<11> = "Hello World";
    let prefix: str<5> = "World";
    assert(!starts_with::<11, 5>(s, prefix));
}

#[test]
fn test_starts_with_partial() {
    let s: str<7> = "testing";
    let prefix: str<4> = "test";
    assert(starts_with::<7, 4>(s, prefix));
}

// Tests for ends_with (fn:ends-with / STRENDS)
// This works because it returns a boolean
#[test]
fn test_ends_with_true() {
    let s: str<11> = "Hello World";
    let suffix: str<5> = "World";
    assert(ends_with::<11, 5>(s, suffix));
}

#[test]
fn test_ends_with_false() {
    let s: str<11> = "Hello World";
    let suffix: str<5> = "Hello";
    assert(!ends_with::<11, 5>(s, suffix));
}

#[test]
fn test_ends_with_partial() {
    let s: str<7> = "testing";
    let suffix: str<3> = "ing";
    assert(ends_with::<7, 3>(s, suffix));
}

// Tests for contains (fn:contains / CONTAINS)
// This works because it returns a boolean
#[test]
fn test_contains_middle() {
    let s: str<11> = "Hello World";
    let sub: str<5> = "lo Wo";
    assert(contains::<11, 5>(s, sub));
}

#[test]
fn test_contains_beginning() {
    let s: str<11> = "Hello World";
    let sub: str<5> = "Hello";
    assert(contains::<11, 5>(s, sub));
}

#[test]
fn test_contains_end() {
    let s: str<11> = "Hello World";
    let sub: str<5> = "World";
    assert(contains::<11, 5>(s, sub));
}

#[test]
fn test_contains_not_found() {
    let s: str<11> = "Hello World";
    let sub: str<3> = "xyz";
    assert(!contains::<11, 3>(s, sub));
}

// NOTE: Tests for substring, upper_case, lower_case, concat, substring_before,
// substring_after are not included because these functions cannot work correctly
// in Noir due to the inability to convert byte arrays back to strings at runtime.

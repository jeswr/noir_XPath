//! Unit tests for XPath string functions

use dep::xpath::{
    concat, concat3, contains, ends_with, lower_case, starts_with, string_length, substring,
    substring_after, substring_before, upper_case,
};

// Tests for string_length (fn:string-length / STRLEN)
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

// Tests for substring (fn:substring / SUBSTR)
#[test]
fn test_substring_beginning() {
    let s: str<11> = "Hello World";
    let result: str<5> = substring::<11, 5>(s, 0, 5);
    assert(result == "Hello");
}

// Tests for upper_case (fn:upper-case / UCASE)
#[test]
fn test_upper_case_lowercase() {
    let s: str<5> = "hello";
    assert(upper_case::<5>(s) == "HELLO");
}

// Tests for lower_case (fn:lower-case / LCASE)
#[test]
fn test_lower_case_uppercase() {
    let s: str<5> = "HELLO";
    assert(lower_case::<5>(s) == "hello");
}

// Tests for starts_with (fn:starts-with / STRSTARTS)
#[test]
fn test_starts_with_true() {
    let s: str<11> = "Hello World";
    let prefix: str<5> = "Hello";
    assert(starts_with::<11, 5>(s, prefix));
}

// Tests for ends_with (fn:ends-with / STRENDS)
#[test]
fn test_ends_with_true() {
    let s: str<11> = "Hello World";
    let suffix: str<5> = "World";
    assert(ends_with::<11, 5>(s, suffix));
}

// Tests for contains (fn:contains / CONTAINS)
#[test]
fn test_contains_middle() {
    let s: str<11> = "Hello World";
    let sub: str<5> = "lo Wo";
    assert(contains::<11, 5>(s, sub));
}

// Tests for concat (fn:concat / CONCAT)
#[test]
fn test_concat_simple() {
    let s1: str<5> = "Hello";
    let s2: str<5> = "World";
    let result: str<10> = concat::<5, 5, 10>(s1, s2);
    assert(result == "HelloWorld");
}

// Tests for concat3
#[test]
fn test_concat3_simple() {
    let s1: str<5> = "Hello";
    let s2: str<1> = " ";
    let s3: str<5> = "World";
    let result: str<11> = concat3::<5, 1, 5, 11>(s1, s2, s3);
    assert(result == "Hello World");
}

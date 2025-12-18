//! Unit tests for XPath string functions

use dep::xpath::{
    concat, concat3, contains, ends_with, lower_case, starts_with, string_length, substring,
    substring_after, substring_before, upper_case,
};

// Tests for string_length (fn:string-length / STRLEN)
#[test]
fn test_string_length_empty() {
    assert(string_length("") == 0);
}

#[test]
fn test_string_length_single_char() {
    assert(string_length("a") == 1);
}

#[test]
fn test_string_length_word() {
    assert(string_length("hello") == 5);
}

#[test]
fn test_string_length_phrase() {
    assert(string_length("Hello World") == 11);
}

#[test]
fn test_string_length_with_spaces() {
    assert(string_length("   ") == 3);
}

// Tests for substring (fn:substring / SUBSTR)
#[test]
fn test_substring_beginning() {
    let s = "Hello World";
    let result: str<5> = substring(s, 0, 5);
    assert(result == "Hello");
}

#[test]
fn test_substring_end() {
    let s = "Hello World";
    let result: str<5> = substring(s, 6, 5);
    assert(result == "World");
}

#[test]
fn test_substring_middle() {
    let s = "Hello World";
    let result: str<3> = substring(s, 6, 3);
    assert(result == "Wor");
}

#[test]
fn test_substring_single_char() {
    let s = "Hello";
    let result: str<1> = substring(s, 1, 1);
    assert(result == "e");
}

#[test]
fn test_substring_full_string() {
    let s = "Hello";
    let result: str<5> = substring(s, 0, 5);
    assert(result == "Hello");
}

// Tests for upper_case (fn:upper-case / UCASE)
#[test]
fn test_upper_case_lowercase() {
    assert(upper_case("hello") == "HELLO");
}

#[test]
fn test_upper_case_mixed() {
    assert(upper_case("Hello World") == "HELLO WORLD");
}

#[test]
fn test_upper_case_already_upper() {
    assert(upper_case("ALREADY UPPER") == "ALREADY UPPER");
}

#[test]
fn test_upper_case_with_numbers() {
    assert(upper_case("hello123") == "HELLO123");
}

#[test]
fn test_upper_case_with_special_chars() {
    assert(upper_case("hello!@#") == "HELLO!@#");
}

// Tests for lower_case (fn:lower-case / LCASE)
#[test]
fn test_lower_case_uppercase() {
    assert(lower_case("HELLO") == "hello");
}

#[test]
fn test_lower_case_mixed() {
    assert(lower_case("Hello World") == "hello world");
}

#[test]
fn test_lower_case_already_lower() {
    assert(lower_case("already lower") == "already lower");
}

#[test]
fn test_lower_case_with_numbers() {
    assert(lower_case("HELLO123") == "hello123");
}

#[test]
fn test_lower_case_with_special_chars() {
    assert(lower_case("HELLO!@#") == "hello!@#");
}

// Tests for starts_with (fn:starts-with / STRSTARTS)
#[test]
fn test_starts_with_true() {
    assert(starts_with("Hello World", "Hello"));
}

#[test]
fn test_starts_with_false() {
    assert(!starts_with("Hello World", "World"));
}

#[test]
fn test_starts_with_partial() {
    assert(starts_with("testing", "test"));
}

#[test]
fn test_starts_with_single_char() {
    assert(starts_with("Hello", "H"));
}

#[test]
fn test_starts_with_empty_prefix() {
    assert(starts_with("Hello", ""));
}

#[test]
fn test_starts_with_same_string() {
    assert(starts_with("Hello", "Hello"));
}

#[test]
fn test_starts_with_longer_prefix() {
    assert(!starts_with("Hi", "Hello"));
}

// Tests for ends_with (fn:ends-with / STRENDS)
#[test]
fn test_ends_with_true() {
    assert(ends_with("Hello World", "World"));
}

#[test]
fn test_ends_with_false() {
    assert(!ends_with("Hello World", "Hello"));
}

#[test]
fn test_ends_with_partial() {
    assert(ends_with("testing", "ing"));
}

#[test]
fn test_ends_with_single_char() {
    assert(ends_with("Hello", "o"));
}

#[test]
fn test_ends_with_empty_suffix() {
    assert(ends_with("Hello", ""));
}

#[test]
fn test_ends_with_same_string() {
    assert(ends_with("Hello", "Hello"));
}

#[test]
fn test_ends_with_longer_suffix() {
    assert(!ends_with("Hi", "Hello"));
}

// Tests for contains (fn:contains / CONTAINS)
#[test]
fn test_contains_beginning() {
    assert(contains("Hello World", "Hello"));
}

#[test]
fn test_contains_middle() {
    assert(contains("Hello World", "lo Wo"));
}

#[test]
fn test_contains_end() {
    assert(contains("Hello World", "World"));
}

#[test]
fn test_contains_single_char() {
    assert(contains("Hello", "e"));
}

#[test]
fn test_contains_not_found() {
    assert(!contains("Hello World", "xyz"));
}

#[test]
fn test_contains_empty_substring() {
    assert(contains("Hello", ""));
}

#[test]
fn test_contains_same_string() {
    assert(contains("Hello", "Hello"));
}

// Tests for substring_before (fn:substring-before / STRBEFORE)
#[test]
fn test_substring_before_found() {
    let s = "Hello World";
    let result: str<6> = substring_before(s, "World");
    assert(result == "Hello ");
}

#[test]
fn test_substring_before_beginning() {
    let s = "Hello World";
    let result: str<0> = substring_before(s, "Hello");
    assert(result == "");
}

#[test]
fn test_substring_before_not_found() {
    let s = "Hello World";
    let result: str<0> = substring_before(s, "xyz");
    assert(result == "");
}

// Tests for substring_after (fn:substring-after / STRAFTER)
#[test]
fn test_substring_after_found() {
    let s = "Hello World";
    let result: str<5> = substring_after(s, "Hello ");
    assert(result == "World");
}

#[test]
fn test_substring_after_end() {
    let s = "Hello World";
    let result: str<0> = substring_after(s, "World");
    assert(result == "");
}

#[test]
fn test_substring_after_not_found() {
    let s = "Hello World";
    let result: str<0> = substring_after(s, "xyz");
    assert(result == "");
}

// Tests for concat (fn:concat / CONCAT)
#[test]
fn test_concat_simple() {
    let result: str<10> = concat("Hello", "World");
    assert(result == "HelloWorld");
}

#[test]
fn test_concat_with_space() {
    let result: str<11> = concat("Hello", " World");
    assert(result == "Hello World");
}

#[test]
fn test_concat_empty_first() {
    let result: str<5> = concat("", "Hello");
    assert(result == "Hello");
}

#[test]
fn test_concat_empty_second() {
    let result: str<5> = concat("Hello", "");
    assert(result == "Hello");
}

#[test]
fn test_concat_both_empty() {
    let result: str<0> = concat("", "");
    assert(result == "");
}

// Tests for concat3
#[test]
fn test_concat3_simple() {
    let result: str<11> = concat3("Hello", " ", "World");
    assert(result == "Hello World");
}

#[test]
fn test_concat3_no_spaces() {
    let result: str<9> = concat3("one", "two", "three");
    assert(result == "onetwothree");
}

#[test]
fn test_concat3_with_empty() {
    let result: str<10> = concat3("Hello", "", "World");
    assert(result == "HelloWorld");
}

// Integration tests combining multiple string operations
#[test]
fn test_integration_case_conversion() {
    let s = "Hello World";
    let upper = upper_case(s);
    let lower = lower_case(upper);
    assert(lower == "hello world");
}

#[test]
fn test_integration_substring_and_concat() {
    let s = "Hello World";
    let hello: str<5> = substring(s, 0, 5);
    let world: str<5> = substring(s, 6, 5);
    let result: str<11> = concat3(hello, " ", world);
    assert(result == "Hello World");
}

#[test]
fn test_integration_starts_and_ends() {
    let s = "testing";
    assert(starts_with(s, "test"));
    assert(ends_with(s, "ing"));
    assert(contains(s, "esti"));
}

//! XPath 2.0 String Functions
//!
//! This module implements XPath 2.0 string functions using noir-string-utils library.
//! These functions are required by SPARQL 1.1 Query Language.

use dep::string_utils::StringTrait;

/// fn:string-length - Returns the length of a string
/// XPath: fn:string-length($arg as xs:string?) as xs:integer
/// SPARQL: STRLEN(?str)
pub fn string_length<N>(s: str<N>) -> u64 {
    N
}

/// fn:substring - Returns a substring starting at a given position
/// XPath: fn:substring($sourceString as xs:string?, $start as xs:double) as xs:string
/// XPath: fn:substring($sourceString as xs:string?, $start as xs:double, $length as xs:double) as xs:string
/// SPARQL: SUBSTR(?str, start) or SUBSTR(?str, start, length)
/// Note: XPath uses 1-based indexing, but we use 0-based for simplicity in Noir
pub fn substring<N, M>(s: str<N>, start: u64, length: u64) -> str<M> {
    assert(start + length <= N, "Substring out of bounds");
    assert(M == length, "Output length must match requested length");

    let mut result_bytes = [0; M];
    let s_bytes = s.as_bytes();

    for i in 0..M {
        result_bytes[i] = s_bytes[start + i];
    }

    std::str::from_bytes(result_bytes)
}

/// fn:upper-case - Converts a string to uppercase
/// XPath: fn:upper-case($arg as xs:string?) as xs:string
/// SPARQL: UCASE(?str)
pub fn upper_case<N>(s: str<N>) -> str<N> {
    let s_bytes = s.as_bytes();
    let mut result_bytes = [0; N];

    for i in 0..N {
        let byte = s_bytes[i];
        // Check if it's a lowercase letter (a-z: 97-122)
        if (byte >= 97) & (byte <= 122) {
            result_bytes[i] = byte - 32; // Convert to uppercase
        } else {
            result_bytes[i] = byte;
        }
    }

    std::str::from_bytes(result_bytes)
}

/// fn:lower-case - Converts a string to lowercase
/// XPath: fn:lower-case($arg as xs:string?) as xs:string
/// SPARQL: LCASE(?str)
pub fn lower_case<N>(s: str<N>) -> str<N> {
    let s_bytes = s.as_bytes();
    let mut result_bytes = [0; N];

    for i in 0..N {
        let byte = s_bytes[i];
        // Check if it's an uppercase letter (A-Z: 65-90)
        if (byte >= 65) & (byte <= 90) {
            result_bytes[i] = byte + 32; // Convert to lowercase
        } else {
            result_bytes[i] = byte;
        }
    }

    std::str::from_bytes(result_bytes)
}

/// fn:starts-with - Returns true if a string starts with a given prefix
/// XPath: fn:starts-with($arg1 as xs:string?, $arg2 as xs:string?) as xs:boolean
/// SPARQL: STRSTARTS(?str, ?prefix)
pub fn starts_with<N, M>(s: str<N>, prefix: str<M>) -> bool {
    if M > N {
        false
    } else {
        let s_bytes = s.as_bytes();
        let prefix_bytes = prefix.as_bytes();
        let mut matches = true;

        for i in 0..M {
            if s_bytes[i] != prefix_bytes[i] {
                matches = false;
            }
        }

        matches
    }
}

/// fn:ends-with - Returns true if a string ends with a given suffix
/// XPath: fn:ends-with($arg1 as xs:string?, $arg2 as xs:string?) as xs:boolean
/// SPARQL: STRENDS(?str, ?suffix)
pub fn ends_with<N, M>(s: str<N>, suffix: str<M>) -> bool {
    if M > N {
        false
    } else {
        let s_bytes = s.as_bytes();
        let suffix_bytes = suffix.as_bytes();
        let start_pos = N - M;
        let mut matches = true;

        for i in 0..M {
            if s_bytes[start_pos + i] != suffix_bytes[i] {
                matches = false;
            }
        }

        matches
    }
}

/// fn:contains - Returns true if a string contains a given substring
/// XPath: fn:contains($arg1 as xs:string?, $arg2 as xs:string?) as xs:boolean
/// SPARQL: CONTAINS(?str, ?substring)
pub fn contains<N, M>(s: str<N>, substring: str<M>) -> bool {
    s.contains(substring)
}

/// fn:substring-before - Returns the substring before the first occurrence of a given substring
/// XPath: fn:substring-before($arg1 as xs:string?, $arg2 as xs:string?) as xs:string
/// SPARQL: STRBEFORE(?str, ?substring)
/// Returns empty string if substring is not found
pub fn substring_before<N, M, R>(s: str<N>, substring: str<M>) -> str<R> {
    let index = s.index_of(substring);

    if index == -1 {
        // Substring not found, return empty string
        assert(R == 0, "Result size must be 0 when substring not found");
        std::str::from_bytes([0; R])
    } else {
        let idx = index as u64;
        assert(R == idx, "Result size must match the index of substring");

        let s_bytes = s.as_bytes();
        let mut result_bytes = [0; R];

        for i in 0..R {
            result_bytes[i] = s_bytes[i];
        }

        std::str::from_bytes(result_bytes)
    }
}

/// fn:substring-after - Returns the substring after the first occurrence of a given substring
/// XPath: fn:substring-after($arg1 as xs:string?, $arg2 as xs:string?) as xs:string
/// SPARQL: STRAFTER(?str, ?substring)
/// Returns empty string if substring is not found
pub fn substring_after<N, M, R>(s: str<N>, substring: str<M>) -> str<R> {
    let index = s.index_of(substring);

    if index == -1 {
        // Substring not found, return empty string
        assert(R == 0, "Result size must be 0 when substring not found");
        std::str::from_bytes([0; R])
    } else {
        let start = (index as u64) + M;
        let len = N - start;
        assert(R == len, "Result size must match the remaining string length");

        let s_bytes = s.as_bytes();
        let mut result_bytes = [0; R];

        for i in 0..R {
            result_bytes[i] = s_bytes[start + i];
        }

        std::str::from_bytes(result_bytes)
    }
}

/// fn:concat - Concatenates two or more strings
/// XPath: fn:concat($arg1 as xs:anyAtomicType?, $arg2 as xs:anyAtomicType?, ...) as xs:string
/// SPARQL: CONCAT(?str1, ?str2, ...)
/// Note: This is a simplified version that concatenates exactly two strings
pub fn concat<N, M, R>(s1: str<N>, s2: str<M>) -> str<R> {
    assert(R == N + M, "Result size must equal sum of input sizes");

    let s1_bytes = s1.as_bytes();
    let s2_bytes = s2.as_bytes();
    let mut result_bytes = [0; R];

    for i in 0..N {
        result_bytes[i] = s1_bytes[i];
    }

    for i in 0..M {
        result_bytes[N + i] = s2_bytes[i];
    }

    std::str::from_bytes(result_bytes)
}

/// Concatenate three strings
pub fn concat3<N1, N2, N3, R>(s1: str<N1>, s2: str<N2>, s3: str<N3>) -> str<R> {
    assert(R == N1 + N2 + N3, "Result size must equal sum of input sizes");

    let s1_bytes = s1.as_bytes();
    let s2_bytes = s2.as_bytes();
    let s3_bytes = s3.as_bytes();
    let mut result_bytes = [0; R];

    for i in 0..N1 {
        result_bytes[i] = s1_bytes[i];
    }

    for i in 0..N2 {
        result_bytes[N1 + i] = s2_bytes[i];
    }

    for i in 0..N3 {
        result_bytes[N1 + N2 + i] = s3_bytes[i];
    }

    std::str::from_bytes(result_bytes)
}

#[test]
fn test_string_length() {
    assert(string_length("hello") == 5);
    assert(string_length("") == 0);
    assert(string_length("Hello World") == 11);
}

#[test]
fn test_substring() {
    let s = "Hello World";
    let result: str<5> = substring(s, 0, 5);
    assert(result == "Hello");

    let result2: str<5> = substring(s, 6, 5);
    assert(result2 == "World");
}

#[test]
fn test_upper_case() {
    assert(upper_case("hello") == "HELLO");
    assert(upper_case("Hello World") == "HELLO WORLD");
    assert(upper_case("ALREADY UPPER") == "ALREADY UPPER");
}

#[test]
fn test_lower_case() {
    assert(lower_case("HELLO") == "hello");
    assert(lower_case("Hello World") == "hello world");
    assert(lower_case("already lower") == "already lower");
}

#[test]
fn test_starts_with() {
    assert(starts_with("Hello World", "Hello"));
    assert(!starts_with("Hello World", "World"));
    assert(starts_with("test", "te"));
    assert(!starts_with("test", "est"));
}

#[test]
fn test_ends_with() {
    assert(ends_with("Hello World", "World"));
    assert(!ends_with("Hello World", "Hello"));
    assert(ends_with("test", "st"));
    assert(!starts_with("test", "te"));
}

#[test]
fn test_contains() {
    assert(contains("Hello World", "lo Wo"));
    assert(contains("Hello World", "Hello"));
    assert(contains("Hello World", "World"));
    assert(!contains("Hello World", "xyz"));
}

#[test]
fn test_concat() {
    let result: str<10> = concat("Hello", "World");
    assert(result == "HelloWorld");

    let result2: str<11> = concat("Hello", " World");
    assert(result2 == "Hello World");
}

#[test]
fn test_concat3() {
    let result: str<11> = concat3("Hello", " ", "World");
    assert(result == "Hello World");
}

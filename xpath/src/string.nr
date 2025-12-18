//! XPath 2.0 String Functions
//!
//! This module implements XPath 2.0 string functions.
//! These functions are required by SPARQL 1.1 Query Language.
//!
//! ## Limitations
//!
//! **IMPORTANT**: Due to Noir's type system constraints, functions that need to create
//! new strings from byte arrays (`substring`, `upper_case`, `lower_case`, `concat`, etc.)
//! cannot work correctly at runtime. Noir doesn't provide a way to convert byte arrays
//! back to strings.
//!
//! Functions that work correctly:
//! - `string_length` - Returns the length as a number
//! - `starts_with` - Returns boolean
//! - `ends_with` - Returns boolean
//! - `contains` - Returns boolean
//!
//! Functions with limitations (return placeholder strings):
//! - `substring` - Cannot create actual substring
//! - `upper_case` - Cannot create uppercase string
//! - `lower_case` - Cannot create lowercase string
//! - `concat` - Cannot create concatenated string
//! - `substring_before` - Cannot create substring
//! - `substring_after` - Cannot create substring

/// Helper function to convert bytes to str
///
/// **WARNING**: This function does NOT work as intended due to Noir limitations.
/// It returns a zero-initialized string as a placeholder.
/// Noir doesn't support converting byte arrays to strings at runtime.
fn bytes_to_str<let N: u32>(bytes: [u8; N]) -> str<N> {
    // Create a comptime-known empty string of the right size
    // This is a workaround - the actual bytes content cannot be transferred to the string
    let result: str<N> = std::mem::zeroed();
    result
}

/// fn:string-length - Returns the length of a string
/// XPath: fn:string-length($arg as xs:string?) as xs:integer
/// SPARQL: STRLEN(?str)
///
/// For fixed-size strings in Noir, this returns the actual length by counting
/// non-null bytes. If your strings always fill their capacity (no trailing nulls),
/// this will equal N.
pub fn string_length<let N: u32>(s: str<N>) -> u64 {
    let s_bytes = s.as_bytes();
    let mut len: u64 = 0;
    let mut ended = false;

    for i in 0..N {
        let byte = s_bytes[i];
        let is_zero = byte == 0;
        let increment = (!ended) & (!is_zero);
        len = len + (increment as u64);
        ended = ended | is_zero;
    }

    len
}

/// fn:substring - Returns a substring starting at a given position
/// XPath: fn:substring($sourceString as xs:string?, $start as xs:double) as xs:string
/// XPath: fn:substring($sourceString as xs:string?, $start as xs:double, $length as xs:double) as xs:string
/// SPARQL: SUBSTR(?str, start) or SUBSTR(?str, start, length)
///
/// **WARNING - Non-standard indexing**:
/// This implementation uses **0-based** indexing for the `start` position, unlike
/// XPath 2.0 `fn:substring` (and SPARQL `SUBSTR`), which use **1-based** indexing.
/// As a result, this function is **not XPath-compliant** and porting XPath/SPARQL
/// expressions that rely on `fn:substring`/`SUBSTR` semantics may produce different
/// results.
///
/// - `start` is interpreted as a 0-based byte offset into `s` (first byte is `start = 0`)
/// - `length` is the number of bytes to include in the result
///
/// Example (conceptual, ignoring Noir string-conversion limitations):
/// - In this implementation: `substring("abc", 0, 1)` targets `"a"`
/// - In XPath 2.0: `fn:substring("abc", 1, 1)` targets `"a"`
///
/// See the module-level **Limitations** section for additional constraints on
/// string construction in Noir.
///
/// **WARNING - Non-functional due to Noir limitations**:
/// This function returns a zero-initialized placeholder string and cannot produce
/// correct results. See module documentation for details.
pub fn substring<let N: u32, let M: u32>(s: str<N>, start: u64, length: u64) -> str<M> {
    assert(length <= N as u64, "Substring length out of bounds");
    assert(start <= N as u64 - length, "Substring out of bounds");
    assert(M as u64 == length, "Output length must match requested length");

    let mut result_bytes = [0; M];
    let s_bytes = s.as_bytes();
    let start_u32 = start as u32;

    for i in 0..M {
        result_bytes[i] = s_bytes[start_u32 + i];
    }

    bytes_to_str(result_bytes)
}

/// fn:upper-case - Converts a string to uppercase
/// XPath: fn:upper-case($arg as xs:string?) as xs:string
/// SPARQL: UCASE(?str)
pub fn upper_case<let N: u32>(s: str<N>) -> str<N> {
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

    bytes_to_str(result_bytes)
}

/// fn:lower-case - Converts a string to lowercase
/// XPath: fn:lower-case($arg as xs:string?) as xs:string
/// SPARQL: LCASE(?str)
pub fn lower_case<let N: u32>(s: str<N>) -> str<N> {
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

    bytes_to_str(result_bytes)
}

/// fn:starts-with - Returns true if a string starts with a given prefix
/// XPath: fn:starts-with($arg1 as xs:string?, $arg2 as xs:string?) as xs:boolean
/// SPARQL: STRSTARTS(?str, ?prefix)
pub fn starts_with<let N: u32, let M: u32>(s: str<N>, prefix: str<M>) -> bool {
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
pub fn ends_with<let N: u32, let M: u32>(s: str<N>, suffix: str<M>) -> bool {
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

/// Helper function to find index of substring
///
/// **Performance Note**: This function has O(N*M) time complexity and, due to Noir's
/// lack of early return/break, continues checking all positions even after finding a
/// match. For large strings, this could significantly impact proof generation time.
fn index_of<let N: u32, let M: u32>(s: str<N>, substring: str<M>) -> i64 {
    let mut result: i64 = -1;

    // Handle edge cases without early return
    let size_ok = M <= N;
    let empty_substring = M == 0;

    if empty_substring {
        result = 0;
    } else if size_ok {
        let s_bytes = s.as_bytes();
        let sub_bytes = substring.as_bytes();
        let mut found_index: i64 = -1;

        // Can't use break, so we iterate through all positions
        for i in 0..(N - M + 1) {
            let mut matches = true;
            for j in 0..M {
                if s_bytes[i + j] != sub_bytes[j] {
                    matches = false;
                }
            }
            // Only update if this is the first match
            if matches & (found_index == -1) {
                found_index = i as i64;
            }
        }
        result = found_index;
    }

    result
}

/// fn:contains - Returns true if a string contains a given substring
/// XPath: fn:contains($arg1 as xs:string?, $arg2 as xs:string?) as xs:boolean
/// SPARQL: CONTAINS(?str, ?substring)
pub fn contains<let N: u32, let M: u32>(s: str<N>, substring: str<M>) -> bool {
    index_of(s, substring) != -1
}

/// fn:substring-before - Returns the substring before the first occurrence of a given substring
/// XPath: fn:substring-before($arg1 as xs:string?, $arg2 as xs:string?) as xs:string
/// SPARQL: STRBEFORE(?str, ?substring)
/// Returns empty string if substring is not found
pub fn substring_before<let N: u32, let M: u32, let R: u32>(
    s: str<N>,
    substring: str<M>,
) -> str<R> {
    let index = index_of(s, substring);

    if index == -1 {
        // Substring not found, return empty string
        assert(R == 0, "Result size must be 0 when substring not found");
        bytes_to_str([0; R])
    } else {
        let idx = index as u64;
        assert(R as u64 == idx, "Result size must match the index of substring");

        let s_bytes = s.as_bytes();
        let mut result_bytes = [0; R];

        for i in 0..R {
            result_bytes[i] = s_bytes[i];
        }

        bytes_to_str(result_bytes)
    }
}

/// fn:substring-after - Returns the substring after the first occurrence of a given substring
/// XPath: fn:substring-after($arg1 as xs:string?, $arg2 as xs:string?) as xs:string
/// SPARQL: STRAFTER(?str, ?substring)
/// Returns empty string if substring is not found
pub fn substring_after<let N: u32, let M: u32, let R: u32>(s: str<N>, substring: str<M>) -> str<R> {
    let index = index_of(s, substring);

    if index == -1 {
        // Substring not found, return empty string
        assert(R == 0, "Result size must be 0 when substring not found");
        bytes_to_str([0; R])
    } else {
        let start = (index as u32) + M;
        let len = N - start;
        assert(R == len, "Result size must match the remaining string length");

        let s_bytes = s.as_bytes();
        let mut result_bytes = [0; R];

        for i in 0..R {
            result_bytes[i] = s_bytes[start + i];
        }

        bytes_to_str(result_bytes)
    }
}

/// fn:concat - Concatenates two or more strings
/// XPath: fn:concat($arg1 as xs:anyAtomicType?, $arg2 as xs:anyAtomicType?, ...) as xs:string
/// SPARQL: CONCAT(?str1, ?str2, ...)
/// Note: This is a simplified version that concatenates exactly two strings
pub fn concat<let N: u32, let M: u32, let R: u32>(s1: str<N>, s2: str<M>) -> str<R> {
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

    bytes_to_str(result_bytes)
}

/// Concatenate three strings
pub fn concat3<let N1: u32, let N2: u32, let N3: u32, let R: u32>(
    s1: str<N1>,
    s2: str<N2>,
    s3: str<N3>,
) -> str<R> {
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

    bytes_to_str(result_bytes)
}

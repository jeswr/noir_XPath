//! XPath 2.0 String Functions
//!
//! This module implements XPath 2.0 string functions that work correctly in Noir.
//! These functions are required by SPARQL 1.1 Query Language.
//!
//! ## Working Functions
//!
//! The following functions work correctly and are exported:
//! - `string_length` - Returns the length as a number
//! - `starts_with` - Returns boolean
//! - `ends_with` - Returns boolean
//! - `contains` - Returns boolean
//!
//! ## Limitations
//!
//! **IMPORTANT**: Functions that need to create new strings from byte arrays
//! (substring, upper-case, lower-case, concat, etc.) cannot be implemented in Noir
//! because Noir doesn't provide a way to convert byte arrays back to strings at runtime.
//! These functions have been removed from this implementation.

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

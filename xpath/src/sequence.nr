//! Sequence and aggregate functions for XPath/SPARQL
//!
//! Implements functions that operate on sequences of values.
//! In SPARQL context, these are typically used with GROUP BY.
//!
//! XPath functions implemented:
//! - fn:empty, fn:exists (sequence tests)
//! - fn:count (cardinality)
//! - fn:sum, fn:avg, fn:min, fn:max (aggregates for integers)
//!
//! Note: These work on fixed-size arrays in Noir. For variable-length
//! sequences, the caller must track the actual length.

// ============================================================================
// Sequence Test Functions
// ============================================================================

/// fn:empty for arrays
/// Returns true if the sequence is empty (length is 0)
pub fn is_empty<T, let N: u32>(arr: [T; N]) -> bool {
    N == 0
}

/// fn:exists for arrays
/// Returns true if the sequence is not empty (has at least one item)
pub fn exists<T, let N: u32>(arr: [T; N]) -> bool {
    N > 0
}

/// fn:count for arrays
/// Returns the number of items in the sequence
pub fn count<T, let N: u32>(_arr: [T; N]) -> u32 {
    N
}

// ============================================================================
// Integer Aggregate Functions
// ============================================================================

/// fn:sum for integer arrays
/// Returns the sum of all values
pub fn sum_int<let N: u32>(arr: [i64; N]) -> i64 {
    let mut total: i64 = 0;
    for i in 0..N {
        total += arr[i];
    }
    total
}

/// fn:avg for integer arrays (truncated to integer)
/// Returns the average value (integer division)
/// Panics if array is empty
pub fn avg_int<let N: u32>(arr: [i64; N]) -> i64 {
    assert(N > 0, "Cannot compute average of empty sequence");
    sum_int(arr) / (N as i64)
}

/// fn:min for integer arrays
/// Returns the minimum value
/// Panics if array is empty
pub fn min_int_seq<let N: u32>(arr: [i64; N]) -> i64 {
    assert(N > 0, "Cannot compute minimum of empty sequence");
    let mut result = arr[0];
    for i in 1..N {
        if arr[i] < result {
            result = arr[i];
        }
    }
    result
}

/// fn:max for integer arrays
/// Returns the maximum value
/// Panics if array is empty
pub fn max_int_seq<let N: u32>(arr: [i64; N]) -> i64 {
    assert(N > 0, "Cannot compute maximum of empty sequence");
    let mut result = arr[0];
    for i in 1..N {
        if arr[i] > result {
            result = arr[i];
        }
    }
    result
}

// ============================================================================
// Partial Sequence Functions (with explicit length)
// ============================================================================

/// Sum for arrays with explicit length
/// Only sums the first `len` elements
pub fn sum_int_partial<let N: u32>(arr: [i64; N], len: u32) -> i64 {
    assert(len <= N, "Length exceeds array size");
    let mut total: i64 = 0;
    for i in 0..N {
        if i < len {
            total += arr[i];
        }
    }
    total
}

/// Average for arrays with explicit length
pub fn avg_int_partial<let N: u32>(arr: [i64; N], len: u32) -> i64 {
    assert(len > 0, "Cannot compute average of empty sequence");
    assert(len <= N, "Length exceeds array size");
    sum_int_partial(arr, len) / (len as i64)
}

/// Minimum for arrays with explicit length
pub fn min_int_partial<let N: u32>(arr: [i64; N], len: u32) -> i64 {
    assert(len > 0, "Cannot compute minimum of empty sequence");
    assert(len <= N, "Length exceeds array size");
    let mut result = arr[0];
    for i in 1..N {
        if (i < len) & (arr[i] < result) {
            result = arr[i];
        }
    }
    result
}

/// Maximum for arrays with explicit length
pub fn max_int_partial<let N: u32>(arr: [i64; N], len: u32) -> i64 {
    assert(len > 0, "Cannot compute maximum of empty sequence");
    assert(len <= N, "Length exceeds array size");
    let mut result = arr[0];
    for i in 1..N {
        if (i < len) & (arr[i] > result) {
            result = arr[i];
        }
    }
    result
}

// ============================================================================
// Boolean Aggregate Functions
// ============================================================================

/// Returns true if all values are true (universal quantification)
pub fn all_true<let N: u32>(arr: [bool; N]) -> bool {
    let mut result = true;
    for i in 0..N {
        result &= arr[i];
    }
    result
}

/// Returns true if any value is true (existential quantification)
pub fn any_true<let N: u32>(arr: [bool; N]) -> bool {
    let mut result = false;
    for i in 0..N {
        result |= arr[i];
    }
    result
}

/// Count of true values in array
pub fn count_true<let N: u32>(arr: [bool; N]) -> u32 {
    let mut count: u32 = 0;
    for i in 0..N {
        if arr[i] {
            count += 1;
        }
    }
    count
}

// ============================================================================
// Tests
// ============================================================================

#[test]
fn test_sequence_empty_exists() {
    let empty: [i64; 0] = [];
    let non_empty: [i64; 3] = [1, 2, 3];

    assert(is_empty(empty) == true);
    assert(is_empty(non_empty) == false);

    assert(exists(empty) == false);
    assert(exists(non_empty) == true);
}

#[test]
fn test_count() {
    let arr: [i64; 5] = [1, 2, 3, 4, 5];
    assert(count(arr) == 5);

    let empty: [i64; 0] = [];
    assert(count(empty) == 0);
}

#[test]
fn test_sum_int() {
    let arr: [i64; 5] = [1, 2, 3, 4, 5];
    assert(sum_int(arr) == 15);

    let negative: [i64; 3] = [-1, -2, 3];
    assert(sum_int(negative) == 0);
}

#[test]
fn test_avg_int() {
    let arr: [i64; 5] = [10, 20, 30, 40, 50];
    assert(avg_int(arr) == 30);

    // Integer division truncates
    let arr2: [i64; 3] = [1, 2, 3];
    assert(avg_int(arr2) == 2); // (1+2+3)/3 = 2
}

#[test]
fn test_min_max_int_seq() {
    let arr: [i64; 5] = [3, 1, 4, 1, 5];
    assert(min_int_seq(arr) == 1);
    assert(max_int_seq(arr) == 5);

    let negative: [i64; 3] = [-5, 0, 5];
    assert(min_int_seq(negative) == -5);
    assert(max_int_seq(negative) == 5);
}

#[test]
fn test_partial_aggregates() {
    let arr: [i64; 5] = [10, 20, 30, 40, 50];

    // Sum first 3 elements
    assert(sum_int_partial(arr, 3) == 60);

    // Average of first 2
    assert(avg_int_partial(arr, 2) == 15);

    // Min/max of first 3
    assert(min_int_partial(arr, 3) == 10);
    assert(max_int_partial(arr, 3) == 30);
}

#[test]
fn test_boolean_aggregates() {
    let all_t: [bool; 3] = [true, true, true];
    let some_t: [bool; 3] = [true, false, true];
    let all_f: [bool; 3] = [false, false, false];

    assert(all_true(all_t) == true);
    assert(all_true(some_t) == false);
    assert(all_true(all_f) == false);

    assert(any_true(all_t) == true);
    assert(any_true(some_t) == true);
    assert(any_true(all_f) == false);

    assert(count_true(all_t) == 3);
    assert(count_true(some_t) == 2);
    assert(count_true(all_f) == 0);
}

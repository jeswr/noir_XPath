//! XPath 2.0 Functions and Operators for SPARQL 1.1
//!
//! This library provides Noir implementations of XPath/XQuery functions
//! as defined in XQuery 1.0 and XPath 2.0 Functions and Operators
//! that are required by SPARQL 1.1 Query Language.

mod types;
mod boolean;
mod numeric;
mod datetime;
mod duration;
mod sequence;
mod comparison;

// Re-export types
pub use types::{XsdDateTime, XsdDayTimeDuration};

// Re-export boolean functions
pub use boolean::{
    fn_not,
    logical_and,
    logical_or,
    boolean_equal,
    boolean_less_than,
    boolean_greater_than,
};

// Re-export numeric functions (integer only for now)
pub use numeric::{
    numeric_add_int,
    numeric_subtract_int,
    numeric_multiply_int,
    numeric_divide_int,
    numeric_mod_int,
    numeric_unary_plus_int,
    numeric_unary_minus_int,
    numeric_equal_int,
    numeric_less_than_int,
    numeric_greater_than_int,
    abs_int,
    round_int,
    ceil_int,
    floor_int,
    min_int,
    max_int,
};

// Re-export datetime functions
pub use datetime::{
    datetime_from_epoch_microseconds,
    datetime_from_components,
    datetime_to_epoch_microseconds,
    year_from_datetime,
    month_from_datetime,
    day_from_datetime,
    hours_from_datetime,
    minutes_from_datetime,
    seconds_from_datetime,
    microseconds_from_datetime,
    datetime_equal,
    datetime_less_than,
    datetime_greater_than,
};

// Re-export duration functions
pub use duration::{
    duration_from_microseconds,
    duration_from_components,
    duration_zero,
    duration_to_microseconds,
    duration_is_negative,
    days_from_duration,
    hours_from_duration,
    minutes_from_duration,
    seconds_from_duration,
    duration_add,
    duration_subtract,
    duration_multiply,
    duration_divide,
    duration_divide_by_duration,
    duration_negate,
    datetime_add_duration,
    datetime_subtract_duration,
    datetime_difference,
    duration_equal,
    duration_less_than,
    duration_greater_than,
};

// Re-export sequence/aggregate functions
pub use sequence::{
    is_empty,
    exists,
    count,
    sum_int,
    avg_int,
    min_int_seq,
    max_int_seq,
    sum_int_partial,
    avg_int_partial,
    min_int_partial,
    max_int_partial,
    all_true,
    any_true,
    count_true,
};

// Re-export comparison functions
pub use comparison::{
    value_equal,
    value_less_than,
    value_greater_than,
};

//! Core type definitions for XPath datatypes
//!
//! Provides Noir representations of XML Schema datatypes used in SPARQL.

/// DateTime representation using a single Field for circuit efficiency.
/// Stores microseconds since Unix epoch (1970-01-01T00:00:00Z) as UTC.
///
/// Using a single Field minimizes constraints while allowing all
/// component extraction operations (year, month, day, etc.) to be
/// computed on-demand.
pub struct XsdDateTime {
    /// Microseconds since Unix epoch (UTC)
    pub epoch_microseconds: Field,
}

impl XsdDateTime {
    /// Create a new DateTime from epoch microseconds
    pub fn new(epoch_microseconds: Field) -> Self {
        XsdDateTime { epoch_microseconds }
    }
}

impl Eq for XsdDateTime {
    fn eq(self, other: Self) -> bool {
        self.epoch_microseconds == other.epoch_microseconds
    }
}

/// Duration representation for timezone offsets and intervals.
/// Uses microseconds with a sign flag for negative durations.
pub struct XsdDayTimeDuration {
    /// Total microseconds (absolute value)
    pub microseconds: Field,
    /// Whether duration is negative
    pub negative: bool,
}

impl XsdDayTimeDuration {
    /// Create a new duration
    pub fn new(microseconds: Field, negative: bool) -> Self {
        XsdDayTimeDuration { microseconds, negative }
    }

    /// Create a zero duration
    pub fn zero() -> Self {
        XsdDayTimeDuration { microseconds: 0, negative: false }
    }

    /// Create from signed microseconds (i64)
    pub fn from_signed_micros(micros: i64) -> Self {
        if micros < 0 {
            let abs_val: u64 = (-micros) as u64;
            XsdDayTimeDuration { microseconds: abs_val as Field, negative: true }
        } else {
            let abs_val: u64 = micros as u64;
            XsdDayTimeDuration { microseconds: abs_val as Field, negative: false }
        }
    }

    /// Convert to signed microseconds (i64)
    pub fn to_signed_micros(self) -> i64 {
        let abs_micros: i64 = self.microseconds as i64;
        if self.negative { -abs_micros } else { abs_micros }
    }
}

impl Eq for XsdDayTimeDuration {
    fn eq(self, other: Self) -> bool {
        (self.microseconds == other.microseconds) & (self.negative == other.negative)
    }
}

// ============================================================================
// Tests
// ============================================================================

#[test]
fn test_datetime_creation() {
    let dt = XsdDateTime::new(1000000);
    assert(dt.epoch_microseconds == 1000000);
}

#[test]
fn test_datetime_equality() {
    let dt1 = XsdDateTime::new(1000000);
    let dt2 = XsdDateTime::new(1000000);
    let dt3 = XsdDateTime::new(2000000);
    assert(dt1 == dt2);
    assert(dt1 != dt3);
}

#[test]
fn test_duration_creation() {
    let dur = XsdDayTimeDuration::new(3600000000, false);
    assert(dur.microseconds == 3600000000);
    assert(dur.negative == false);
}

#[test]
fn test_duration_zero() {
    let dur = XsdDayTimeDuration::zero();
    assert(dur.microseconds == 0);
    assert(dur.negative == false);
}

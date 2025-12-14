//! Additional tests for datetime operations

use dep::xpath::{
    XsdDateTime,
    datetime_from_components,
    datetime_from_components_with_tz,
    datetime_from_epoch_microseconds,
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
    datetime_timezone_offset,
    timezone_from_datetime,
    duration_to_microseconds,
};

#[test]
fn test_datetime_year_boundaries() {
    // Start of year
    let dt1 = datetime_from_components(2024, 1, 1, 0, 0, 0, 0);
    assert(year_from_datetime(dt1) == 2024);
    assert(month_from_datetime(dt1) == 1);
    assert(day_from_datetime(dt1) == 1);
    
    // End of year
    let dt2 = datetime_from_components(2024, 12, 31, 23, 59, 59, 999999);
    assert(year_from_datetime(dt2) == 2024);
    assert(month_from_datetime(dt2) == 12);
    assert(day_from_datetime(dt2) == 31);
    assert(hours_from_datetime(dt2) == 23);
    assert(minutes_from_datetime(dt2) == 59);
    assert(seconds_from_datetime(dt2) == 59);
    assert(microseconds_from_datetime(dt2) == 999999);
}

#[test]
fn test_datetime_different_years() {
    let dt2000 = datetime_from_components(2000, 6, 15, 12, 0, 0, 0);
    let dt2024 = datetime_from_components(2024, 6, 15, 12, 0, 0, 0);
    
    assert(datetime_less_than(dt2000, dt2024) == true);
    assert(datetime_greater_than(dt2024, dt2000) == true);
    assert(datetime_equal(dt2000, dt2024) == false);
}

#[test]
fn test_datetime_microsecond_precision() {
    let dt1 = datetime_from_components(2024, 6, 15, 12, 0, 0, 0);
    let dt2 = datetime_from_components(2024, 6, 15, 12, 0, 0, 1);
    
    // One microsecond difference
    assert(datetime_less_than(dt1, dt2) == true);
    assert(datetime_equal(dt1, dt2) == false);
}

#[test]
fn test_datetime_from_epoch() {
    // 1 second after epoch
    let dt = datetime_from_epoch_microseconds(1_000_000);
    assert(year_from_datetime(dt) == 1970);
    assert(month_from_datetime(dt) == 1);
    assert(day_from_datetime(dt) == 1);
    assert(hours_from_datetime(dt) == 0);
    assert(minutes_from_datetime(dt) == 0);
    assert(seconds_from_datetime(dt) == 1);
}

#[test]
fn test_timezone_from_datetime() {
    // Test UTC timezone (offset 0)
    let dt_utc = datetime_from_components_with_tz(2024, 6, 15, 12, 0, 0, 0, 0);
    assert(datetime_timezone_offset(dt_utc) == 0);
    let tz_utc = timezone_from_datetime(dt_utc);
    assert(duration_to_microseconds(tz_utc) == 0);
    
    // Test negative timezone offset: -05:00 (EST)
    // -5 hours = -300 minutes
    let dt_est = datetime_from_components_with_tz(2024, 6, 15, 12, 0, 0, 0, -300);
    assert(datetime_timezone_offset(dt_est) == -300);
    let tz_est = timezone_from_datetime(dt_est);
    // -300 minutes = -18,000 seconds = -18,000,000,000 microseconds
    assert(duration_to_microseconds(tz_est) == -18_000_000_000);
    
    // Test positive timezone offset: +05:30 (IST)
    // +5.5 hours = +330 minutes
    let dt_ist = datetime_from_components_with_tz(2024, 6, 15, 12, 0, 0, 0, 330);
    assert(datetime_timezone_offset(dt_ist) == 330);
    let tz_ist = timezone_from_datetime(dt_ist);
    // +330 minutes = +19,800 seconds = +19,800,000,000 microseconds
    assert(duration_to_microseconds(tz_ist) == 19_800_000_000);
    
    // Test negative timezone offset: -08:00 (PST)
    // -8 hours = -480 minutes
    let dt_pst = datetime_from_components_with_tz(2024, 6, 15, 12, 0, 0, 0, -480);
    assert(datetime_timezone_offset(dt_pst) == -480);
    let tz_pst = timezone_from_datetime(dt_pst);
    // -480 minutes = -28,800 seconds = -28,800,000,000 microseconds
    assert(duration_to_microseconds(tz_pst) == -28_800_000_000);
}

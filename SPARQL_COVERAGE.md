# SPARQL 1.1 Function Coverage

This document details the implementation status of SPARQL 1.1 functions in noir_XPath.

## Implementation Status Legend

- ✅ **Fully Implemented**: Function is implemented and tested
- ⚠️ **Partial**: Function is partially implemented (e.g., integers only, not floats)
- 🔮 **Planned**: Function is planned for future implementation
- ❌ **Not Feasible**: Function cannot be implemented in ZK context
- 🚫 **Out of Scope**: Function is not part of XPath/XQuery operators

## 17.4.1 Functional Forms

| Function | Status | Notes |
|----------|--------|-------|
| BOUND | 🚫 | SPARQL-specific, not an XPath function |
| IF | 🚫 | SPARQL-specific, not an XPath function |
| COALESCE | 🚫 | SPARQL-specific, not an XPath function |
| NOT EXISTS | 🚫 | SPARQL query operator, not a function |
| EXISTS | ✅ | Implemented as `exists` for sequences |
| logical-or (`||`) | ✅ | Implemented as `logical_or` |
| logical-and (`&&`) | ✅ | Implemented as `logical_and` |
| RDFterm-equal (`=`) | 🚫 | RDF-specific comparison |
| sameTerm | 🚫 | RDF-specific function |
| IN | 🚫 | SPARQL-specific operator |
| NOT IN | 🚫 | SPARQL-specific operator |

## 17.4.2 Functions on RDF Terms

| Function | Status | Notes |
|----------|--------|-------|
| isIRI | 🚫 | RDF-specific function |
| isBlank | 🚫 | RDF-specific function |
| isLiteral | 🚫 | RDF-specific function |
| isNumeric | 🚫 | RDF-specific function |
| str | 🚫 | RDF-specific function |
| lang | 🚫 | RDF-specific function |
| datatype | 🚫 | RDF-specific function |
| IRI | 🚫 | RDF-specific function |
| BNODE | 🚫 | RDF-specific function |
| STRDT | 🚫 | RDF-specific function |
| STRLANG | 🚫 | RDF-specific function |
| UUID | 🚫 | RDF-specific function |
| STRUUID | 🚫 | RDF-specific function |

## 17.4.3 Functions on Strings

| SPARQL Function | XPath Function | Status | Notes |
|----------------|----------------|--------|-------|
| STRLEN | fn:string-length | 🔮 | Deferred - string handling complex in ZK |
| SUBSTR | fn:substring | 🔮 | Deferred - string handling complex in ZK |
| UCASE | fn:upper-case | 🔮 | Deferred - string handling complex in ZK |
| LCASE | fn:lower-case | 🔮 | Deferred - string handling complex in ZK |
| STRSTARTS | fn:starts-with | 🔮 | Deferred - string handling complex in ZK |
| STRENDS | fn:ends-with | 🔮 | Deferred - string handling complex in ZK |
| CONTAINS | fn:contains | 🔮 | Deferred - string handling complex in ZK |
| STRBEFORE | fn:substring-before | 🔮 | Deferred - string handling complex in ZK |
| STRAFTER | fn:substring-after | 🔮 | Deferred - string handling complex in ZK |
| ENCODE_FOR_URI | fn:encode-for-uri | 🔮 | Deferred - string handling complex in ZK |
| CONCAT | fn:concat | 🔮 | Deferred - string handling complex in ZK |
| langMatches | fn:lang-matches | 🔮 | Deferred - string handling complex in ZK |
| REGEX | fn:matches | 🔮 | Deferred - regex complex in ZK |
| REPLACE | fn:replace | 🔮 | Deferred - regex complex in ZK |

## 17.4.4 Functions on Numerics

| SPARQL Function | XPath Function | Status | Notes |
|----------------|----------------|--------|-------|
| abs | fn:abs | ✅ | Implemented for integers and floats/doubles (via noir_IEEE754 v0.1.0) |
| round | fn:round | ⚠️ | Implemented for integers; float rounding planned |
| ceil | fn:ceiling | ⚠️ | Implemented for integers; float ceiling planned |
| floor | fn:floor | ⚠️ | Implemented for integers; float floor planned |
| RAND | - | ❌ | Not feasible in deterministic ZK context |

### Numeric Operators

| Operator | XPath Operator | Status | Notes |
|----------|----------------|--------|-------|
| `+` (addition) | op:numeric-add | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |
| `-` (subtraction) | op:numeric-subtract | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |
| `*` (multiplication) | op:numeric-multiply | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |
| `/` (division) | op:numeric-divide | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |
| unary `+` | op:numeric-unary-plus | ✅ | Implemented for integers |
| unary `-` | op:numeric-unary-minus | ✅ | Implemented for integers |
| `=` (equal) | op:numeric-equal | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |
| `<` (less than) | op:numeric-less-than | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |
| `>` (greater than) | op:numeric-greater-than | ✅ | Implemented for integers, floats, and doubles (via noir_IEEE754 v0.1.0) |

## 17.4.5 Functions on Dates and Times

| SPARQL Function | XPath Function | Status | Notes |
|----------------|----------------|--------|-------|
| now | - | ❌ | Not feasible in ZK - no concept of current time |
| year | fn:year-from-dateTime | ✅ | Implemented as `year_from_datetime` |
| month | fn:month-from-dateTime | ✅ | Implemented as `month_from_datetime` |
| day | fn:day-from-dateTime | ✅ | Implemented as `day_from_datetime` |
| hours | fn:hours-from-dateTime | ✅ | Implemented as `hours_from_datetime` |
| minutes | fn:minutes-from-dateTime | ✅ | Implemented as `minutes_from_datetime` |
| seconds | fn:seconds-from-dateTime | ✅ | Implemented as `seconds_from_datetime` |
| timezone | fn:timezone-from-dateTime | ✅ | Implemented as `timezone_from_datetime` |
| tz | - | 🔮 | Requires string formatting (e.g., "Z", "-05:00") |

### DateTime Operators

| Operator | XPath Operator | Status | Notes |
|----------|----------------|--------|-------|
| `=` (equal) | op:dateTime-equal | ✅ | Implemented as `datetime_equal` |
| `<` (less than) | op:dateTime-less-than | ✅ | Implemented as `datetime_less_than` |
| `>` (greater than) | op:dateTime-greater-than | ✅ | Implemented as `datetime_greater_than` |

## 17.4.6 Hash Functions

| Function | Status | Notes |
|----------|--------|-------|
| MD5 | 🔮 | Deferred - requires string output formatting |
| SHA1 | 🔮 | Deferred - requires string output formatting |
| SHA256 | 🔮 | Deferred - requires string output formatting |
| SHA384 | 🔮 | Deferred - requires string output formatting |
| SHA512 | 🔮 | Deferred - requires string output formatting |

## Boolean Operators

| Operator | XPath Function | Status | Notes |
|----------|----------------|--------|-------|
| fn:not | fn:not | ✅ | Implemented as `fn_not` |
| `&&` (and) | op:and | ✅ | Implemented as `logical_and` |
| `\|\|` (or) | op:or | ✅ | Implemented as `logical_or` |
| `=` (equal) | op:boolean-equal | ✅ | Implemented as `boolean_equal` |
| `<` (less than) | op:boolean-less-than | ✅ | Implemented as `boolean_less_than` |
| `>` (greater than) | op:boolean-greater-than | ✅ | Implemented as `boolean_greater_than` |

## Duration Operations

| Operator | XPath Operator | Status | Notes |
|----------|----------------|--------|-------|
| duration + duration | op:add-dayTimeDurations | ✅ | Implemented as `duration_add` |
| duration - duration | op:subtract-dayTimeDurations | ✅ | Implemented as `duration_subtract` |
| duration * number | op:multiply-dayTimeDuration | ✅ | Implemented as `duration_multiply` |
| duration / number | op:divide-dayTimeDuration | ✅ | Implemented as `duration_divide` |
| duration / duration | op:divide-dayTimeDuration-by-dayTimeDuration | ✅ | Implemented as `duration_divide_by_duration` |
| dateTime + duration | op:add-dayTimeDuration-to-dateTime | ✅ | Implemented as `datetime_add_duration` |
| dateTime - duration | op:subtract-dayTimeDuration-from-dateTime | ✅ | Implemented as `datetime_subtract_duration` |
| dateTime - dateTime | op:subtract-dateTimes | ✅ | Implemented as `datetime_difference` |
| `=` (equal) | op:dayTimeDuration-equal | ✅ | Implemented as `duration_equal` |
| `<` (less than) | op:dayTimeDuration-less-than | ✅ | Implemented as `duration_less_than` |
| `>` (greater than) | op:dayTimeDuration-greater-than | ✅ | Implemented as `duration_greater_than` |

## Aggregate Functions

| SPARQL Function | Status | Notes |
|----------------|--------|-------|
| COUNT | ✅ | Implemented as `count` |
| SUM | ⚠️ | Implemented as `sum_int` for integers only |
| MIN | ⚠️ | Implemented as `min_int_seq` for integers only |
| MAX | ⚠️ | Implemented as `max_int_seq` for integers only |
| AVG | ⚠️ | Implemented as `avg_int` for integers only |
| GROUP_CONCAT | 🔮 | Requires string support |
| SAMPLE | 🔮 | Requires more complex logic |

## Summary

### Fully Implemented (✅)
- All boolean operations
- All integer numeric operations
- All datetime component extraction and comparison
- All duration operations
- Integer aggregate functions (COUNT, SUM, MIN, MAX, AVG)
- Sequence operations (is_empty, exists, count)

### Partial Implementation (⚠️)
- Advanced float rounding: Basic float arithmetic complete (via noir_IEEE754 v0.1.0); round/ceil/floor for floats planned
- Aggregates: integers only (float aggregates planned for future)

### Deferred/Future (🔮)
- All string functions (complex in ZK)
- All regex functions (complex in ZK)
- Hash functions (require string output)
- TZ() function (requires string formatting)

### Not Feasible (❌)
- RAND() - not meaningful in deterministic ZK proofs
- NOW() - no concept of current time in proofs

### Out of Scope (🚫)
- RDF term functions (not XPath functions)
- SPARQL-specific operators (BOUND, IF, COALESCE, IN, NOT IN, etc.)

## Notes for Users

When using this library for SPARQL 1.1 query verification in zero-knowledge:

1. **Determinism**: Functions like RAND() and NOW() must be provided as public/private inputs rather than computed
2. **String Operations**: All string-based operations must be performed outside the circuit or deferred to future versions
3. **Numeric Types**: Float and double operations will be added when noir_IEEE754 integration is complete
4. **RDF Terms**: RDF-specific functionality is outside the scope of this XPath function library and should be implemented separately

## Testing

All implemented functions have corresponding test cases generated from the W3C qt3tests suite. See the `test_packages/` directory for auto-generated tests.

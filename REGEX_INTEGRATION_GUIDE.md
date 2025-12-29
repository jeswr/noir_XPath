# Regex Integration Guide for zk-regex

This document provides guidance for integrating the [zk-regex](https://github.com/zkemail/zk-regex) library once it adds Noir support.

## Current Status

As of December 2024:
- ✅ Placeholder API structure is implemented in `xpath/src/regex.nr`
- ⏳ Waiting for zk-regex library to add Noir support (currently Circom-only)
- 🚧 Functions return placeholder values: `false` for matches, zeroed strings for replacements

## Integration Checklist

### Step 1: Update Dependencies

1. Uncomment the zk-regex dependency in `xpath/Nargo.toml`:

```toml
[dependencies]
ieee754 = { tag = "v0.1.0", git = "https://github.com/jeswr/noir_IEEE754", directory = "ieee754" }
zk-regex = { git = "https://github.com/zkemail/zk-regex" }  # Uncomment this line
```

2. Adjust the dependency path/tag as appropriate based on zk-regex's Noir package structure

### Step 2: Import zk-regex Functionality

Update `xpath/src/regex.nr` to import the necessary types and functions:

```noir
// Add imports from zk-regex
use dep::zk_regex::{/* import appropriate types/functions */};
```

### Step 3: Implement fn:matches

Replace the placeholder implementation with actual regex matching:

```noir
pub fn fn_matches<let N: u32, let M: u32>(_input: str<N>, _pattern: str<M>) -> bool {
    // TODO: Implement using zk-regex API
    // Key considerations:
    // - Pattern must be compiled to DFA at compile time
    // - May require compile-time constants or procedural macros
    // - Consult zk-regex Noir documentation for exact API
    false
}
```

#### Implementation Notes

- **Compile-time patterns**: zk-regex works by compiling regex patterns into DFAs. Check if patterns can be:
  - Passed as string literals that get compiled at Noir compile time
  - Pre-compiled externally and imported as data structures
  
- **Pattern complexity**: Complex regex patterns increase circuit size. Document any limitations.

- **Character sets**: Verify support for international characters and special Unicode categories.

### Step 4: Implement fn:matches_with_flags

Add support for regex flags (case-insensitive, multiline, etc.):

```noir
pub fn fn_matches_with_flags<let N: u32, let M: u32, let F: u32>(
    _input: str<N>,
    _pattern: str<M>,
    _flags: str<F>
) -> bool {
    // TODO: Parse flags and apply to regex matching
    // Standard XPath flags:
    // - "i" = case-insensitive
    // - "m" = multiline (^ and $ match line boundaries)
    // - "s" = dot-all (. matches newline)
    // - "x" = comments (ignore whitespace, allow # comments)
    false
}
```

### Step 5: Implement fn:replace (if feasible)

**Warning**: This function faces a fundamental Noir limitation - converting byte arrays back to strings at runtime is not supported.

Two possible approaches:

#### Option A: Fixed-size output (practical for some use cases)

```noir
pub fn fn_replace<let N: u32, let M: u32, let R: u32, let O: u32>(
    _input: str<N>,
    _pattern: str<M>,
    _replacement: str<R>
) -> str<O> {
    // If output size O is known and fixed:
    // 1. Create byte array of size O
    // 2. Perform replacement logic
    // 3. Convert to str<O> if possible
    
    // However, Noir may still not support byte array -> string conversion
    unsafe {
        std::mem::zeroed()
    }
}
```

#### Option B: Document as not implementable

If Noir's string limitations persist:

1. Keep the placeholder implementation
2. Update documentation to clearly state the function cannot be fully implemented
3. Suggest workarounds:
   - Perform replacement outside the circuit
   - Use witness generation to provide the replaced string
   - Prove relationship between input and output separately

### Step 6: Update Tests

1. **Remove placeholder tests** in `xpath/src/regex.nr`:
   - Delete `test_fn_matches_placeholder`
   - Delete `test_fn_matches_with_flags_placeholder`
   - Delete `test_fn_replace_placeholder`
   - Delete `test_fn_replace_with_flags_placeholder`

2. **Add real unit tests**:

```noir
#[test]
fn test_fn_matches_simple() {
    // Simple literal pattern
    let result = fn_matches::<5, 5>("hello", "hello");
    assert(result == true);
    
    let result2 = fn_matches::<5, 5>("hello", "world");
    assert(result2 == false);
}

#[test]
fn test_fn_matches_pattern() {
    // Regex pattern with metacharacters
    let result = fn_matches::<11, 7>("hello world", "hello.*");
    assert(result == true);
}

#[test]
fn test_fn_matches_case_insensitive() {
    let result = fn_matches_with_flags::<5, 5, 1>("HELLO", "hello", "i");
    assert(result == true);
}
```

3. **Generate tests from qt3tests**:

Update `scripts/generate_tests.py` to properly handle regex test cases:

```python
# In convert_xpath_expr function, add handling for fn:matches and fn:replace
if symbol == "matches" and noir_func == "fn_matches":
    # Parse the test expression to extract input and pattern
    # Generate appropriate Noir test code
    ...
```

### Step 7: Update Documentation

1. **README.md**: Move regex from "🚧 Placeholder" to "✅ Implemented"
2. **ARCHITECTURE.md**: Update regex module section to describe actual implementation
3. **SPARQL_COVERAGE.md**: Change status from 🚧 to ✅ for REGEX and REPLACE (or ⚠️ if limited)
4. Add usage examples with real patterns

### Step 8: Benchmark and Optimize

1. **Measure circuit size** for various regex patterns:
   - Simple literals
   - Character classes `[a-z]`, `[0-9]`
   - Quantifiers `+`, `*`, `?`, `{n,m}`
   - Alternation `(a|b)`
   - Anchors `^`, `$`

2. **Document complexity guidelines**:
   - Which patterns are efficient
   - Which patterns should be avoided
   - Maximum recommended pattern complexity

3. **Add performance notes** to function documentation

## Testing Strategy

### Test Categories

1. **Unit Tests** (in `regex.nr`):
   - Basic pattern matching
   - Edge cases (empty strings, special characters)
   - Flag combinations
   - Error conditions

2. **Integration Tests** (in `xpath_unit_tests`):
   - Complex multi-pattern matching
   - Integration with other XPath functions
   - Real-world use cases

3. **W3C qt3tests**:
   - Generate tests from `fn/matches.xml`
   - Generate tests from `fn/replace.xml`
   - May need to filter tests based on pattern complexity

### Expected Test Coverage

From the qt3tests suite:
- `fn/matches.xml`: Contains numerous test cases for `fn:matches`
- `fn/replace.xml`: Contains test cases for `fn:replace`

Filter criteria:
- Skip tests with patterns not supported by zk-regex
- Skip tests requiring features not implemented (e.g., backreferences if unsupported)
- Document any skipped test categories

## Common Issues and Solutions

### Issue 1: Pattern Not Compile-Time Constant

**Problem**: zk-regex requires patterns to be known at compile time, but XPath allows dynamic patterns.

**Solution**: 
- Document that this implementation only supports compile-time constant patterns
- For dynamic patterns, users must generate separate circuits for each pattern

### Issue 2: Pattern Complexity Limits

**Problem**: Complex patterns create large circuits.

**Solution**:
- Document maximum recommended pattern complexity
- Provide tools/scripts to estimate circuit size for a given pattern
- Suggest breaking complex patterns into simpler alternatives

### Issue 3: Unicode Support

**Problem**: Full Unicode regex support may not be available.

**Solution**:
- Document supported character ranges
- Test ASCII, Latin-1, and common Unicode ranges
- Provide fallback suggestions for unsupported ranges

### Issue 4: fn:replace String Creation

**Problem**: Noir cannot create strings from byte arrays at runtime.

**Solution** (pick one):
- **Option A**: Keep as placeholder, document limitation
- **Option B**: Implement for fixed-size outputs only
- **Option C**: Use witness generation to provide result, prove correctness separately

## Reference Links

- [zk-regex GitHub](https://github.com/zkemail/zk-regex)
- [zk-regex Blog Post](https://zk.email/blog/zkregex)
- [XPath 2.0 fn:matches spec](https://www.w3.org/TR/xpath-functions/#func-matches)
- [XPath 2.0 fn:replace spec](https://www.w3.org/TR/xpath-functions/#func-replace)
- [W3C qt3tests](https://github.com/w3c/qt3tests)

## Questions for zk-regex Maintainers

When Noir support is announced, clarify:

1. **API Design**: How are patterns specified? (string literals, macros, external files?)
2. **DFA Generation**: Is it compile-time or runtime? How to integrate with Noir's compilation?
3. **Limitations**: Which regex features are supported? (lookahead, backreferences, etc.)
4. **Performance**: What are the constraint costs for common patterns?
5. **String Output**: Any solutions for the string creation problem in `fn:replace`?
6. **Examples**: Are there Noir examples available?

## Contact

For questions about this integration:
- Open an issue at: https://github.com/jeswr/noir_XPath/issues
- Reference this guide and the placeholder implementation in `xpath/src/regex.nr`

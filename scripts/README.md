# Test Generation Scripts

This directory contains scripts for generating Noir tests from the W3C qt3tests test suite.

## generate_tests.py

Generates Noir test packages from the [qt3tests](https://github.com/w3c/qt3tests) repository.

### Usage

```bash
# Generate tests for all implemented functions
python generate_tests.py

# Generate tests for specific functions
python generate_tests.py --functions "fn:abs,op:numeric-add"

# List available functions
python generate_tests.py --list-functions

# Skip cloning qt3tests (if already present)
python generate_tests.py --skip-clone

# Custom output directory
python generate_tests.py --output-dir ../custom_tests
```

### Options

| Option | Description |
|--------|-------------|
| `--output-dir` | Output directory for generated test packages (default: `../test_packages`) |
| `--qt3-dir` | Directory for qt3tests repository (default: `./qt3tests`) |
| `--functions` | Comma-separated list of XPath functions to generate tests for |
| `--skip-clone` | Skip cloning/updating the qt3tests repository |
| `--list-functions` | List available functions and exit |

### Supported Functions

The script currently supports generating tests for:

**Numeric Functions:**
- `fn:abs`, `fn:ceiling`, `fn:floor`, `fn:round`
- `op:numeric-add`, `op:numeric-subtract`, `op:numeric-multiply`
- `op:numeric-divide`, `op:numeric-integer-divide`, `op:numeric-mod`
- `op:numeric-equal`, `op:numeric-less-than`, `op:numeric-greater-than`

**DateTime Functions:**
- `fn:year-from-dateTime`, `fn:month-from-dateTime`, `fn:day-from-dateTime`
- `fn:hours-from-dateTime`, `fn:minutes-from-dateTime`, `fn:seconds-from-dateTime`
- `fn:timezone-from-dateTime`
- `op:dateTime-equal`, `op:dateTime-less-than`, `op:dateTime-greater-than`

**Boolean Functions:**
- `fn:not`, `op:boolean-equal`

**String Functions:**
- `fn:string-length`, `fn:starts-with`, `fn:ends-with`, `fn:contains`

**Regex Functions (Placeholder):**
- `fn:matches`, `fn:replace` - Placeholder mappings added; full test generation awaits zk-regex Noir support

**Type Casting Functions:**
- `xs:float-from-int`, `xs:double-from-int`
- `xs:integer-from-float`, `xs:integer-from-double`
- `xs:float-from-double`

Note: Type casting functions are mapped in the script but tests from qt3tests cannot be auto-generated because they use cast expression syntax rather than function call syntax. Manual test packages have been created for these functions.

### Generated Test Structure

For each function, the script generates a test package:

```
test_packages/
├── xpath_test_fn_abs/
│   ├── Nargo.toml
│   └── src/
│       ├── lib.nr
│       └── chunk_0.nr
├── xpath_test_op_numeric_add/
│   └── ...
```

Tests are split into chunks of 50 tests per file for manageability.

### Limitations

The script can only convert simple test cases. Complex expressions involving:
- Variables and external references
- Multiple function calls
- String operations
- Schema validation

...will be skipped and noted in the output.

### After Generation

After generating tests, add the new packages to your workspace `Nargo.toml`:

```toml
[workspace]
members = [
    "xpath",
    "xpath_unit_tests",
    "test_packages/xpath_test_fn_abs",
    # ... other generated packages
]
```

#!/usr/bin/env python3
"""
Generate Noir test code from W3C qt3tests test suite.

This script parses the qt3tests XML test files and generates Noir test packages
for the XPath functions implemented in noir_XPath.

Usage:
    python generate_tests.py [--output-dir PATH] [--functions FUNC1,FUNC2,...]

Requirements:
    - Python 3.8+
    - qt3tests repository (will be cloned if not present)
"""

import argparse
import os
import re
import subprocess
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Tuple

# XML namespace for qt3tests
QT3_NS = "{http://www.w3.org/2010/09/qt-fots-catalog}"

# Map XPath functions to their test file locations in qt3tests
FUNCTION_TEST_FILES = {
    # Numeric functions
    "fn:abs": "fn/abs.xml",
    "fn:ceiling": "fn/ceiling.xml",
    "fn:floor": "fn/floor.xml",
    "fn:round": "fn/round.xml",
    # Numeric operators
    "op:numeric-add": "op/numeric-add.xml",
    "op:numeric-subtract": "op/numeric-subtract.xml",
    "op:numeric-multiply": "op/numeric-multiply.xml",
    "op:numeric-divide": "op/numeric-divide.xml",
    "op:numeric-integer-divide": "op/numeric-integer-divide.xml",
    "op:numeric-mod": "op/numeric-mod.xml",
    "op:numeric-equal": "op/numeric-equal.xml",
    "op:numeric-less-than": "op/numeric-less-than.xml",
    "op:numeric-greater-than": "op/numeric-greater-than.xml",
    # DateTime functions
    "fn:year-from-dateTime": "fn/year-from-dateTime.xml",
    "fn:month-from-dateTime": "fn/month-from-dateTime.xml",
    "fn:day-from-dateTime": "fn/day-from-dateTime.xml",
    "fn:hours-from-dateTime": "fn/hours-from-dateTime.xml",
    "fn:minutes-from-dateTime": "fn/minutes-from-dateTime.xml",
    "fn:seconds-from-dateTime": "fn/seconds-from-dateTime.xml",
    # DateTime operators
    "op:dateTime-equal": "op/dateTime-equal.xml",
    "op:dateTime-less-than": "op/dateTime-less-than.xml",
    "op:dateTime-greater-than": "op/dateTime-greater-than.xml",
    # Boolean
    "fn:not": "fn/not.xml",
    "op:boolean-equal": "op/boolean-equal.xml",
}

# Map XPath functions to Noir function names
FUNCTION_MAP = {
    # Numeric
    "fn:abs": "abs_int",
    "fn:ceiling": "ceil_int",
    "fn:floor": "floor_int",
    "fn:round": "round_int",
    "op:numeric-add": "numeric_add_int",
    "op:numeric-subtract": "numeric_subtract_int",
    "op:numeric-multiply": "numeric_multiply_int",
    "op:numeric-divide": "numeric_divide_int",
    "op:numeric-integer-divide": "numeric_divide_int",
    "op:numeric-mod": "numeric_mod_int",
    "op:numeric-equal": "numeric_equal_int",
    "op:numeric-less-than": "numeric_less_than_int",
    "op:numeric-greater-than": "numeric_greater_than_int",
    # DateTime
    "fn:year-from-dateTime": "year_from_datetime",
    "fn:month-from-dateTime": "month_from_datetime",
    "fn:day-from-dateTime": "day_from_datetime",
    "fn:hours-from-dateTime": "hours_from_datetime",
    "fn:minutes-from-dateTime": "minutes_from_datetime",
    "fn:seconds-from-dateTime": "seconds_from_datetime",
    "op:dateTime-equal": "datetime_equal",
    "op:dateTime-less-than": "datetime_less_than",
    "op:dateTime-greater-than": "datetime_greater_than",
    # Boolean
    "fn:not": "fn_not",
    "op:boolean-equal": "boolean_equal",
}

# Functions currently implemented
IMPLEMENTED_FUNCTIONS = list(FUNCTION_MAP.keys())


@dataclass
class TestCase:
    """Represents a single test case from qt3tests."""
    name: str
    description: str
    test_expr: str
    expected_result: str
    result_type: str  # 'assert-eq', 'assert-true', 'assert-false', 'error', etc.
    dependencies: list = field(default_factory=list)


def clone_or_update_qt3tests(qt3_dir: Path) -> None:
    """Clone or update the qt3tests repository."""
    if qt3_dir.exists():
        print(f"qt3tests exists at {qt3_dir}, pulling latest...")
        subprocess.run(["git", "pull"], cwd=qt3_dir, check=True)
    else:
        print(f"Cloning qt3tests to {qt3_dir}...")
        subprocess.run(
            ["git", "clone", "--depth", "1",
             "https://github.com/w3c/qt3tests.git", str(qt3_dir)],
            check=True
        )


def parse_test_file(xml_path: Path) -> list[TestCase]:
    """Parse a qt3tests XML file and extract test cases."""
    if not xml_path.exists():
        print(f"Warning: Test file not found: {xml_path}")
        return []

    tree = ET.parse(xml_path)
    root = tree.getroot()

    tests = []
    for test_case in root.findall(f".//{QT3_NS}test-case"):
        name = test_case.get("name", "unknown")

        # Get dependencies (skip tests with unsupported features)
        deps = []
        for dep in test_case.findall(f".//{QT3_NS}dependency"):
            dep_type = dep.get("type", "")
            dep_value = dep.get("value", "")
            deps.append(f"{dep_type}:{dep_value}")

        # Get description
        desc_elem = test_case.find(f"{QT3_NS}description")
        description = desc_elem.text if desc_elem is not None and desc_elem.text else ""

        # Get test expression
        test_elem = test_case.find(f"{QT3_NS}test")
        if test_elem is None or test_elem.text is None:
            continue
        test_expr = test_elem.text.strip()

        # Get expected result
        result_elem = test_case.find(f"{QT3_NS}result")
        if result_elem is None:
            continue

        # Handle different result types
        result_type = "unknown"
        expected_result = ""

        for child in result_elem:
            tag = child.tag.replace(QT3_NS, "")
            if tag == "assert-eq":
                result_type = "assert-eq"
                expected_result = child.text.strip() if child.text else ""
            elif tag == "assert-true":
                result_type = "assert-true"
                expected_result = "true"
            elif tag == "assert-false":
                result_type = "assert-false"
                expected_result = "false"
            elif tag == "error":
                result_type = "error"
                expected_result = child.get("code", "")
            elif tag in ("all-of", "any-of"):
                result_type = "complex"
            break

        if result_type not in ("unknown", "complex", "error"):
            tests.append(TestCase(
                name=name,
                description=description,
                test_expr=test_expr,
                expected_result=expected_result,
                result_type=result_type,
                dependencies=deps,
            ))

    return tests


def sanitize_test_name(name: str) -> str:
    """Convert test name to valid Noir identifier."""
    name = re.sub(r"[-.]", "_", name)
    name = re.sub(r"[^a-zA-Z0-9_]", "", name)
    if name and name[0].isdigit():
        name = "test_" + name
    return name.lower()


def parse_integer(value: str) -> Optional[int]:
    """Parse an XPath integer literal."""
    value = value.strip()
    # Remove type suffix like 'xs:integer(...)'
    match = re.match(r"xs:integer\s*\(\s*['\"]?(-?\d+)['\"]?\s*\)", value)
    if match:
        return int(match.group(1))
    # Plain integer
    if re.match(r"^-?\d+$", value):
        return int(value)
    return None


def parse_boolean(value: str) -> Optional[bool]:
    """Parse an XPath boolean literal."""
    value = value.strip().lower()
    if value in ("true", "true()", "fn:true()"):
        return True
    if value in ("false", "false()", "fn:false()"):
        return False
    match = re.match(r"xs:boolean\s*\(['\"]?(true|false)['\"]?\)", value)
    if match:
        return match.group(1) == "true"
    return None


def parse_datetime(value: str) -> Optional[int]:
    """Parse an XPath dateTime literal and return microseconds since epoch.
    
    Returns None if parsing fails.
    """
    value = value.strip()
    
    # Extract from xs:dateTime('...')
    match = re.match(r"xs:dateTime\s*\(['\"](.+?)['\"]\)", value)
    if match:
        value = match.group(1)
    
    # Parse ISO 8601 datetime
    # Format: YYYY-MM-DDTHH:MM:SS[.ssssss][Z|+-HH:MM]
    dt_pattern = r"(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:\d{2})?"
    match = re.match(dt_pattern, value)
    if not match:
        return None
    
    year, month, day = int(match.group(1)), int(match.group(2)), int(match.group(3))
    hour, minute, second = int(match.group(4)), int(match.group(5)), int(match.group(6))
    
    # Microseconds
    frac = match.group(7)
    microseconds = 0
    if frac:
        # Pad or truncate to 6 digits
        frac = frac[:6].ljust(6, '0')
        microseconds = int(frac)
    
    # Timezone (normalize to UTC)
    tz_offset_seconds = 0
    tz_str = match.group(8)
    if tz_str and tz_str != 'Z':
        tz_match = re.match(r"([+-])(\d{2}):(\d{2})", tz_str)
        if tz_match:
            sign = 1 if tz_match.group(1) == '+' else -1
            tz_hours = int(tz_match.group(2))
            tz_mins = int(tz_match.group(3))
            tz_offset_seconds = sign * (tz_hours * 3600 + tz_mins * 60)
    
    # Convert to epoch microseconds
    try:
        dt = datetime(year, month, day, hour, minute, second, microseconds, tzinfo=timezone.utc)
        epoch = datetime(1970, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
        delta = dt - epoch
        total_micros = int(delta.total_seconds() * 1_000_000) - (tz_offset_seconds * 1_000_000)
        return total_micros
    except (ValueError, OverflowError):
        return None


def convert_xpath_expr(expr: str, function_name: str) -> Optional[Tuple[str, str]]:
    """Convert an XPath expression to Noir code.
    
    Returns tuple of (setup_code, test_expression) or None if cannot convert.
    """
    expr = expr.strip()
    noir_func = FUNCTION_MAP.get(function_name)
    if not noir_func:
        return None
    
    # Handle different patterns
    
    # Pattern: fn:abs(-5) or abs(-5)
    abs_match = re.match(r"(?:fn:)?abs\s*\(\s*(-?\d+)\s*\)", expr)
    if abs_match and "abs" in function_name:
        val = abs_match.group(1)
        return ("", f"{noir_func}({val})")
    
    # Pattern: fn:not(expr)
    not_match = re.match(r"(?:fn:)?not\s*\(\s*(true|false)\s*(?:\(\s*\))?\s*\)", expr, re.IGNORECASE)
    if not_match and "not" in function_name:
        val = not_match.group(1).lower()
        return ("", f"{noir_func}({val})")
    
    # Pattern: binary operators like: 1 + 2, 1 - 2, etc.
    op_patterns = {
        r"(-?\d+)\s*\+\s*(-?\d+)": ("numeric_add_int", "+"),
        r"(-?\d+)\s*-\s*(-?\d+)": ("numeric_subtract_int", "-"),
        r"(-?\d+)\s*\*\s*(-?\d+)": ("numeric_multiply_int", "*"),
        r"(-?\d+)\s*idiv\s+(-?\d+)": ("numeric_divide_int", "idiv"),
        r"(-?\d+)\s*div\s+(-?\d+)": ("numeric_divide_int", "div"),
        r"(-?\d+)\s*mod\s+(-?\d+)": ("numeric_mod_int", "mod"),
        r"(-?\d+)\s*eq\s+(-?\d+)": ("numeric_equal_int", "eq"),
        r"(-?\d+)\s*lt\s+(-?\d+)": ("numeric_less_than_int", "lt"),
        r"(-?\d+)\s*gt\s+(-?\d+)": ("numeric_greater_than_int", "gt"),
    }
    
    for pattern, (func, _) in op_patterns.items():
        match = re.match(pattern, expr, re.IGNORECASE)
        if match and func == noir_func:
            a, b = match.group(1), match.group(2)
            return ("", f"{noir_func}({a}, {b})")
    
    # Pattern: comparison operators (= < >)
    cmp_patterns = {
        r"(-?\d+)\s*=\s*(-?\d+)": "numeric_equal_int",
        r"(-?\d+)\s*<\s*(-?\d+)": "numeric_less_than_int",
        r"(-?\d+)\s*>\s*(-?\d+)": "numeric_greater_than_int",
    }
    
    for pattern, func in cmp_patterns.items():
        match = re.match(pattern, expr)
        if match and func == noir_func:
            a, b = match.group(1), match.group(2)
            return ("", f"{noir_func}({a}, {b})")
    
    # Pattern: dateTime component extraction
    dt_funcs = {
        "fn:year-from-dateTime": "year_from_datetime",
        "fn:month-from-dateTime": "month_from_datetime",
        "fn:day-from-dateTime": "day_from_datetime",
        "fn:hours-from-dateTime": "hours_from_datetime",
        "fn:minutes-from-dateTime": "minutes_from_datetime",
        "fn:seconds-from-dateTime": "seconds_from_datetime",
    }
    
    for xpath_func, noir_fn in dt_funcs.items():
        short_name = xpath_func.split(":")[-1]
        pattern = rf"(?:fn:)?{re.escape(short_name)}\s*\(\s*xs:dateTime\s*\(['\"](.+?)['\"]\)\s*\)"
        match = re.match(pattern, expr)
        if match and noir_fn == noir_func:
            dt_str = match.group(1)
            micros = parse_datetime(f"xs:dateTime('{dt_str}')")
            if micros is not None:
                setup = f"let dt = datetime_from_epoch_microseconds({micros});"
                return (setup, f"{noir_fn}(dt)")
    
    # Pattern: dateTime comparison
    dt_cmp_pattern = r"xs:dateTime\s*\(['\"](.+?)['\"]\)\s*(eq|lt|gt|=|<|>)\s*xs:dateTime\s*\(['\"](.+?)['\"]\)"
    match = re.match(dt_cmp_pattern, expr)
    if match:
        dt1_str, op, dt2_str = match.group(1), match.group(2), match.group(3)
        micros1 = parse_datetime(f"xs:dateTime('{dt1_str}')")
        micros2 = parse_datetime(f"xs:dateTime('{dt2_str}')")
        
        if micros1 is not None and micros2 is not None:
            op_map = {
                "eq": "datetime_equal", "=": "datetime_equal",
                "lt": "datetime_less_than", "<": "datetime_less_than",
                "gt": "datetime_greater_than", ">": "datetime_greater_than",
            }
            noir_fn = op_map.get(op)
            if noir_fn and noir_fn == noir_func:
                setup = f"let dt1 = datetime_from_epoch_microseconds({micros1});\n    let dt2 = datetime_from_epoch_microseconds({micros2});"
                return (setup, f"{noir_fn}(dt1, dt2)")
    
    return None


def generate_noir_test(test: TestCase, function_name: str) -> Optional[str]:
    """Generate Noir test code for a test case.
    
    Returns None if the test cannot be converted to Noir.
    """
    test_name = sanitize_test_name(test.name)
    
    # Skip tests with unsupported dependencies
    unsupported_deps = ["schemaValidation", "schemaImport", "staticTyping"]
    for dep in test.dependencies:
        for unsup in unsupported_deps:
            if unsup in dep:
                return None
    
    # Try to convert the expression
    conversion = convert_xpath_expr(test.test_expr, function_name)
    if conversion is None:
        # Generate placeholder
        desc = test.description.replace("\n", " ").replace('"', "'")[:80]
        return f"""// SKIP: {test_name}
// Cannot auto-convert: {test.test_expr}
// Expected: {test.expected_result}
"""
    
    setup_code, test_expr = conversion
    
    # Generate assertion based on result type
    if test.result_type == "assert-true":
        assertion = f"assert({test_expr} == true);"
    elif test.result_type == "assert-false":
        assertion = f"assert({test_expr} == false);"
    elif test.result_type == "assert-eq":
        # Parse expected value
        expected = test.expected_result
        int_val = parse_integer(expected)
        bool_val = parse_boolean(expected)
        
        if int_val is not None:
            assertion = f"assert({test_expr} == {int_val});"
        elif bool_val is not None:
            assertion = f"assert({test_expr} == {str(bool_val).lower()});"
        else:
            # Cannot parse expected value
            return f"""// SKIP: {test_name}
// Cannot parse expected: {expected}
"""
    else:
        return None
    
    # Build test function
    desc = test.description.replace("\n", " ").replace('"', "'")[:60] if test.description else ""
    lines = [f"#[test]", f"fn {test_name}() {{"]
    if desc:
        lines.append(f"    // {desc}")
    if setup_code:
        for line in setup_code.split("\n"):
            lines.append(f"    {line}")
    lines.append(f"    {assertion}")
    lines.append("}")
    
    return "\n".join(lines)


def generate_test_package(
    function_name: str,
    tests: list[TestCase],
    output_dir: Path,
    chunk_size: int = 50,
) -> int:
    """Generate a Noir test package for a function. Returns count of generated tests."""
    # Create package directory
    pkg_name = f"xpath_test_{sanitize_test_name(function_name)}"
    pkg_dir = output_dir / pkg_name
    src_dir = pkg_dir / "src"
    src_dir.mkdir(parents=True, exist_ok=True)

    # Generate Nargo.toml
    nargo_toml = f"""[package]
name = "{pkg_name}"
type = "lib"
authors = ["auto-generated"]

[dependencies]
xpath = {{ path = "../../xpath" }}
"""
    (pkg_dir / "Nargo.toml").write_text(nargo_toml)

    # Convert tests
    converted_tests = []
    skipped = 0
    for test in tests:
        noir_test = generate_noir_test(test, function_name)
        if noir_test and not noir_test.startswith("// SKIP"):
            converted_tests.append(noir_test)
        else:
            skipped += 1

    if not converted_tests:
        print(f"  No tests converted for {function_name} (skipped {skipped})")
        return 0

    # Split tests into chunks
    chunks = [converted_tests[i:i + chunk_size] for i in range(0, len(converted_tests), chunk_size)]

    # Determine required imports
    imports = ["use dep::xpath::{"]
    noir_func = FUNCTION_MAP.get(function_name)
    if noir_func:
        imports.append(f"    {noir_func},")
    
    # Add datetime imports if needed
    if "datetime" in function_name.lower():
        imports.append("    datetime_from_epoch_microseconds,")
    
    imports.append("};")

    # Generate lib.nr
    lib_lines = [
        f"//! Auto-generated tests for {function_name}",
        f"//! Source: https://github.com/w3c/qt3tests",
        f"//! Generated: {datetime.now().isoformat()}",
        "",
    ]
    for i in range(len(chunks)):
        lib_lines.append(f"mod chunk_{i};")

    (src_dir / "lib.nr").write_text("\n".join(lib_lines))

    # Generate chunk files
    for i, chunk in enumerate(chunks):
        chunk_lines = [
            f"//! Test chunk {i} for {function_name}",
            f"//! Contains {len(chunk)} tests",
            "",
        ] + imports + [""]

        for test_code in chunk:
            chunk_lines.append(test_code)
            chunk_lines.append("")

        (src_dir / f"chunk_{i}.nr").write_text("\n".join(chunk_lines))

    print(f"  Generated: {pkg_name} ({len(converted_tests)} tests, {skipped} skipped)")
    return len(converted_tests)


def update_workspace_toml(workspace_dir: Path) -> None:
    """Update the workspace Nargo.toml to include generated test packages."""
    nargo_path = workspace_dir / "Nargo.toml"
    if not nargo_path.exists():
        return

    test_packages_dir = workspace_dir / "test_packages"
    if not test_packages_dir.exists():
        return

    # Find all generated packages
    packages = []
    for pkg_dir in sorted(test_packages_dir.iterdir()):
        if pkg_dir.is_dir() and (pkg_dir / "Nargo.toml").exists():
            packages.append(f"test_packages/{pkg_dir.name}")

    if not packages:
        return

    # Read existing Nargo.toml
    content = nargo_path.read_text()

    # Check if packages are already listed
    new_members = []
    for pkg in packages:
        if f'"{pkg}"' not in content:
            new_members.append(pkg)

    if new_members:
        print(f"\nAdd these packages to workspace Nargo.toml members:")
        for pkg in new_members:
            print(f'    "{pkg}",')


def main():
    parser = argparse.ArgumentParser(description="Generate Noir tests from qt3tests")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).parent.parent / "test_packages",
        help="Output directory for generated test packages",
    )
    parser.add_argument(
        "--qt3-dir",
        type=Path,
        default=Path(__file__).parent / "qt3tests",
        help="Directory for qt3tests repository",
    )
    parser.add_argument(
        "--functions",
        type=str,
        default=None,
        help="Comma-separated list of functions to generate tests for",
    )
    parser.add_argument(
        "--skip-clone",
        action="store_true",
        help="Skip cloning/updating qt3tests",
    )
    parser.add_argument(
        "--list-functions",
        action="store_true",
        help="List available functions and exit",
    )
    args = parser.parse_args()

    if args.list_functions:
        print("Available functions:")
        for func in sorted(IMPLEMENTED_FUNCTIONS):
            print(f"  {func}")
        return

    # Clone/update qt3tests
    if not args.skip_clone:
        clone_or_update_qt3tests(args.qt3_dir)

    # Determine which functions to process
    if args.functions:
        functions = [f.strip() for f in args.functions.split(",")]
    else:
        functions = IMPLEMENTED_FUNCTIONS

    # Process each function
    total_tests = 0
    print("\nGenerating tests...")
    for func in functions:
        if func not in FUNCTION_TEST_FILES:
            print(f"  Warning: No test file mapping for {func}")
            continue

        test_file = args.qt3_dir / FUNCTION_TEST_FILES[func]
        tests = parse_test_file(test_file)

        if tests:
            count = generate_test_package(func, tests, args.output_dir)
            total_tests += count
        else:
            print(f"  No tests found for {func}")

    # Update workspace Nargo.toml
    update_workspace_toml(args.output_dir.parent)

    print(f"\nTest generation complete! Total: {total_tests} tests generated")


if __name__ == "__main__":
    main()

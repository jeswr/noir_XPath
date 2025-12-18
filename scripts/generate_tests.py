#!/usr/bin/env python3
"""
Generate Noir test code from W3C qt3tests test suite.

This script parses the qt3tests XML test files and generates Noir test packages
for the XPath functions implemented in noir_XPath.

Usage:
    python generate_tests.py [--output-dir PATH] [--functions FUNC1,FUNC2,...]

Requirements:
    - Python 3.8+
    - elementpath (for XPath 2.0 parsing and evaluation)
    - qt3tests repository (will be cloned if not present)
"""

import argparse
import os
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Optional, Tuple, Any

# Import elementpath for XPath 2.0 parsing
from elementpath import XPath2Parser
from elementpath.datatypes import DateTime10

# XML namespace for qt3tests
QT3_NS = "{http://www.w3.org/2010/09/qt-fots-catalog}"

# Map XPath functions to their test file locations in qt3tests
FUNCTION_TEST_FILES = {
    # Numeric functions
    "fn:abs": "fn/abs.xml",
    "fn:ceiling": "fn/ceiling.xml",
    "fn:floor": "fn/floor.xml",
    "fn:round": "fn/round.xml",
    # Numeric operators (integer)
    "op:numeric-add": "op/numeric-add.xml",
    "op:numeric-subtract": "op/numeric-subtract.xml",
    "op:numeric-multiply": "op/numeric-multiply.xml",
    "op:numeric-divide": "op/numeric-divide.xml",
    "op:numeric-integer-divide": "op/numeric-integer-divide.xml",
    "op:numeric-mod": "op/numeric-mod.xml",
    "op:numeric-equal": "op/numeric-equal.xml",
    "op:numeric-less-than": "op/numeric-less-than.xml",
    "op:numeric-greater-than": "op/numeric-greater-than.xml",
    # Numeric operators (float)
    "op:numeric-add-float": "op/numeric-add.xml",
    "op:numeric-subtract-float": "op/numeric-subtract.xml",
    "op:numeric-multiply-float": "op/numeric-multiply.xml",
    "op:numeric-divide-float": "op/numeric-divide.xml",
    "op:numeric-equal-float": "op/numeric-equal.xml",
    "op:numeric-less-than-float": "op/numeric-less-than.xml",
    "op:numeric-greater-than-float": "op/numeric-greater-than.xml",
    # Numeric operators (double)
    "op:numeric-add-double": "op/numeric-add.xml",
    "op:numeric-subtract-double": "op/numeric-subtract.xml",
    "op:numeric-multiply-double": "op/numeric-multiply.xml",
    "op:numeric-divide-double": "op/numeric-divide.xml",
    "op:numeric-equal-double": "op/numeric-equal.xml",
    "op:numeric-less-than-double": "op/numeric-less-than.xml",
    "op:numeric-greater-than-double": "op/numeric-greater-than.xml",
    # Type casting
    "xs:float-from-int": "prod/CastExpr.xml",
    "xs:double-from-int": "prod/CastExpr.xml",
    "xs:integer-from-float": "prod/CastExpr.xml",
    "xs:integer-from-double": "prod/CastExpr.xml",
    "xs:float-from-double": "prod/CastExpr.xml",
    # DateTime functions
    "fn:year-from-dateTime": "fn/year-from-dateTime.xml",
    "fn:month-from-dateTime": "fn/month-from-dateTime.xml",
    "fn:day-from-dateTime": "fn/day-from-dateTime.xml",
    "fn:hours-from-dateTime": "fn/hours-from-dateTime.xml",
    "fn:minutes-from-dateTime": "fn/minutes-from-dateTime.xml",
    "fn:seconds-from-dateTime": "fn/seconds-from-dateTime.xml",
    "fn:timezone-from-dateTime": "fn/timezone-from-dateTime.xml",
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
    # Numeric (integer)
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
    # Numeric (float)
    "op:numeric-add-float": "numeric_add_float",
    "op:numeric-subtract-float": "numeric_subtract_float",
    "op:numeric-multiply-float": "numeric_multiply_float",
    "op:numeric-divide-float": "numeric_divide_float",
    "op:numeric-equal-float": "numeric_equal_float",
    "op:numeric-less-than-float": "numeric_less_than_float",
    "op:numeric-greater-than-float": "numeric_greater_than_float",
    # Numeric (double)
    "op:numeric-add-double": "numeric_add_double",
    "op:numeric-subtract-double": "numeric_subtract_double",
    "op:numeric-multiply-double": "numeric_multiply_double",
    "op:numeric-divide-double": "numeric_divide_double",
    "op:numeric-equal-double": "numeric_equal_double",
    "op:numeric-less-than-double": "numeric_less_than_double",
    "op:numeric-greater-than-double": "numeric_greater_than_double",
    # Type casting
    "xs:float-from-int": "cast_integer_to_float",
    "xs:double-from-int": "cast_integer_to_double",
    "xs:integer-from-float": "cast_float_to_integer",
    "xs:integer-from-double": "cast_double_to_integer",
    "xs:float-from-double": "cast_double_to_float",
    # DateTime
    "fn:year-from-dateTime": "year_from_datetime",
    "fn:month-from-dateTime": "month_from_datetime",
    "fn:day-from-dateTime": "day_from_datetime",
    "fn:hours-from-dateTime": "hours_from_datetime",
    "fn:minutes-from-dateTime": "minutes_from_datetime",
    "fn:seconds-from-dateTime": "seconds_from_datetime",
    "fn:timezone-from-dateTime": "timezone_from_datetime",
    "op:dateTime-equal": "datetime_equal",
    "op:dateTime-less-than": "datetime_less_than",
    "op:dateTime-greater-than": "datetime_greater_than",
    # Boolean
    "fn:not": "fn_not",
    "op:boolean-equal": "boolean_equal",
}

# Float type filter - which function variants accept which types
FLOAT_FUNCTION_TYPES = {
    "op:numeric-add-float": "float",
    "op:numeric-subtract-float": "float",
    "op:numeric-multiply-float": "float",
    "op:numeric-divide-float": "float",
    "op:numeric-equal-float": "float",
    "op:numeric-less-than-float": "float",
    "op:numeric-greater-than-float": "float",
    "op:numeric-add-double": "double",
    "op:numeric-subtract-double": "double",
    "op:numeric-multiply-double": "double",
    "op:numeric-divide-double": "double",
    "op:numeric-equal-double": "double",
    "op:numeric-less-than-double": "double",
    "op:numeric-greater-than-double": "double",
}

# Cast expression patterns - which casts from what types
CAST_FUNCTION_PATTERNS = {
    # Pattern: (source_type, target_type)
    "xs:float-from-int": ("int", "float"),       # xs:float(integer_expr)
    "xs:double-from-int": ("int", "double"),     # xs:double(integer_expr)
    "xs:integer-from-float": ("float", "int"),   # xs:integer(xs:float(...))
    "xs:integer-from-double": ("double", "int"), # xs:integer(xs:double(...))
    "xs:float-from-double": ("double", "float"), # xs:float(xs:double(...))
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
            elif tag == "assert-string-value":
                result_type = "assert-eq"  # Treat same as assert-eq
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


import struct

def float_to_bits(f: float) -> int:
    """Convert a Python float to IEEE 754 single precision bits."""
    packed = struct.pack('>f', f)
    return struct.unpack('>I', packed)[0]


def double_to_bits(f: float) -> int:
    """Convert a Python float to IEEE 754 double precision bits."""
    packed = struct.pack('>d', f)
    return struct.unpack('>Q', packed)[0]


def parse_float(value: str) -> Optional[Tuple[float, str]]:
    """Parse an XPath float or double literal.
    
    Returns (float_value, type) where type is 'float' or 'double', or None if parsing fails.
    """
    value = value.strip()
    
    # Check for xs:float(...) or xs:double(...)
    float_match = re.match(r"xs:float\s*\(\s*['\"]?([^'\")\s]+)['\"]?\s*\)", value)
    double_match = re.match(r"xs:double\s*\(\s*['\"]?([^'\")\s]+)['\"]?\s*\)", value)
    
    if float_match:
        try:
            val = float(float_match.group(1))
            return (val, 'float')
        except ValueError:
            # Handle special values
            inner = float_match.group(1).upper()
            if inner == 'NAN':
                return (float('nan'), 'float')
            elif inner == 'INF':
                return (float('inf'), 'float')
            elif inner == '-INF':
                return (float('-inf'), 'float')
            return None
    
    if double_match:
        try:
            val = float(double_match.group(1))
            return (val, 'double')
        except ValueError:
            inner = double_match.group(1).upper()
            if inner == 'NAN':
                return (float('nan'), 'double')
            elif inner == 'INF':
                return (float('inf'), 'double')
            elif inner == '-INF':
                return (float('-inf'), 'double')
            return None
    
    # Try plain float/double literals (with E notation)
    if re.match(r'^-?\d+\.?\d*[eE][+-]?\d+$', value) or re.match(r'^-?\d+\.\d+$', value):
        try:
            return (float(value), 'double')  # Default to double for plain literals
        except ValueError:
            return None
    
    return None


def detect_operand_type(expr: str) -> Optional[str]:
    """Detect the numeric type from an XPath expression.
    
    Returns 'int', 'float', 'double', or None if cannot determine.
    """
    expr = expr.strip()
    
    # Check for explicit type casts
    if 'xs:float' in expr:
        return 'float'
    if 'xs:double' in expr:
        return 'double'
    if 'xs:decimal' in expr or 'xs:integer' in expr or 'xs:int' in expr or 'xs:long' in expr:
        return 'int'
    
    # Check for floating point literals
    if re.search(r'\d+[eE][+-]?\d+', expr) or re.search(r'\d+\.\d+', expr):
        return 'double'
    
    return 'int'  # Default to int


def parse_datetime(value: str) -> Optional[Tuple[int, int]]:
    """Parse an XPath dateTime literal using elementpath.
    
    Returns (UTC microseconds, tz_offset_minutes) or None if parsing fails.
    """
    value = value.strip()
    
    # Ensure it's wrapped in xs:dateTime() if not already
    if not value.startswith("xs:dateTime"):
        value = f"xs:dateTime('{value}')"
    
    try:
        parser = XPath2Parser()
        token = parser.parse(value)
        dt = token.evaluate()
        
        if not isinstance(dt, DateTime10):
            return None
        
        # Get timezone offset in minutes
        tz_offset_minutes = 0
        if dt.tzinfo is not None:
            offset = dt.tzinfo.offset
            tz_offset_minutes = int(offset.total_seconds() / 60)
        
        # Build a Python datetime from the components and convert to epoch
        # dt contains local time components with timezone info
        py_tz = timezone(timedelta(minutes=tz_offset_minutes))
        py_dt = datetime(
            dt.year, dt.month, dt.day,
            dt.hour, dt.minute, int(dt.second),
            dt.microsecond,
            tzinfo=py_tz
        )
        
        # Convert to UTC epoch microseconds
        epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
        utc_dt = py_dt.astimezone(timezone.utc)
        delta = utc_dt - epoch
        utc_micros = int(delta.total_seconds() * 1_000_000)
        
        return (utc_micros, tz_offset_minutes)
    except Exception:
        return None


# i64 bounds
I64_MIN = -9223372036854775808
I64_MAX = 9223372036854775807


def _fits_in_i64(val: int) -> bool:
    """Check if an integer fits in Noir's i64 range."""
    return I64_MIN <= val <= I64_MAX


def _get_function_name(token) -> Optional[str]:
    """Extract the function name from an elementpath token, handling namespace prefixes."""
    symbol = token.symbol
    
    # If there's a namespace prefix (symbol is ':'), get the actual function name
    if symbol == ':' and len(token) >= 2:
        # The function name is in the second child
        return token[1].symbol
    
    # Otherwise the symbol is the function name
    return symbol


def _get_function_args(token) -> list:
    """Get the function arguments from a token, handling namespace prefixes."""
    # If there's a namespace prefix (symbol is ':'), get args from the function token
    if token.symbol == ':' and len(token) >= 2:
        return list(token[1])
    # Otherwise args are direct children
    return list(token)


def convert_xpath_expr(expr: str, function_name: str) -> Optional[Tuple[str, str, Optional[str]]]:
    """Convert an XPath expression to Noir code using elementpath for parsing.
    
    Returns tuple of (setup_code, test_expression, embedded_expected) or None if cannot convert.
    The embedded_expected is set when the XPath expression contains a comparison (e.g., `x eq 5`)
    and the expected value is extracted from the expression itself.
    """
    expr = expr.strip()
    noir_func = FUNCTION_MAP.get(function_name)
    if not noir_func:
        return None
    
    # Check if this is a float/double variant
    expected_type = FLOAT_FUNCTION_TYPES.get(function_name)
    detected_type = detect_operand_type(expr)
    
    # For float/double variants, filter to only matching type tests
    if expected_type is not None:
        if expected_type != detected_type:
            return None
    # For integer variants, skip float/double tests
    elif detected_type in ('float', 'double'):
        return None
    
    parser = XPath2Parser()
    
    # Try to parse and evaluate the expression with elementpath
    try:
        token = parser.parse(expr)
    except Exception:
        return None
    
    # Get the effective function/operator name (handling namespace prefixes)
    symbol = _get_function_name(token)
    if symbol is None:
        return None
    
    # Map XPath function names to Noir functions
    xpath_to_noir_dt_funcs = {
        "year-from-dateTime": "year_from_datetime",
        "month-from-dateTime": "month_from_datetime",
        "day-from-dateTime": "day_from_datetime",
        "hours-from-dateTime": "hours_from_datetime",
        "minutes-from-dateTime": "minutes_from_datetime",
        "seconds-from-dateTime": "seconds_from_datetime",
    }
    
    # Handle datetime component extraction functions
    if symbol in xpath_to_noir_dt_funcs:
        expected_noir_fn = xpath_to_noir_dt_funcs[symbol]
        if expected_noir_fn != noir_func:
            return None
        
        # Get function arguments (handling namespace prefix)
        args = _get_function_args(token)
        
        # The argument should be a dateTime - try to extract it
        if len(args) >= 1:
            arg = args[0]
            # Try to evaluate the datetime argument
            try:
                dt_val = arg.evaluate()
                if isinstance(dt_val, DateTime10):
                    result = _datetime_to_epoch(dt_val)
                    if result is None:
                        return None
                    utc_micros, tz_offset = result
                    # Skip dates before 1970 (negative epoch) - not supported
                    if utc_micros < 0:
                        return None
                    setup = f"let dt = datetime_from_epoch_microseconds_with_tz({utc_micros}, {tz_offset});"
                    return (setup, f"{noir_func}(dt)", None)
            except Exception:
                pass
        return None
    
    # Handle datetime comparison operators (eq, lt, gt)
    if symbol in ("eq", "lt", "gt", "=", "<", ">"):
        op_map = {
            "eq": "datetime_equal", "=": "datetime_equal",
            "lt": "datetime_less_than", "<": "datetime_less_than",
            "gt": "datetime_greater_than", ">": "datetime_greater_than",
        }
        expected_noir_fn = op_map.get(symbol)
        
        if expected_noir_fn == noir_func and len(token) >= 2:
            # Both operands should be dateTimes
            try:
                dt1 = token[0].evaluate()
                dt2 = token[1].evaluate()
                
                if isinstance(dt1, DateTime10) and isinstance(dt2, DateTime10):
                    result1 = _datetime_to_epoch(dt1)
                    result2 = _datetime_to_epoch(dt2)
                    
                    if result1 is not None and result2 is not None:
                        utc_micros1, tz_offset1 = result1
                        utc_micros2, tz_offset2 = result2
                        # Skip dates before 1970
                        if utc_micros1 < 0 or utc_micros2 < 0:
                            return None
                        setup = f"let dt1 = datetime_from_epoch_microseconds_with_tz({utc_micros1}, {tz_offset1});\n    let dt2 = datetime_from_epoch_microseconds_with_tz({utc_micros2}, {tz_offset2});"
                        return (setup, f"{noir_func}(dt1, dt2)", None)
            except Exception:
                pass
    
    # Handle fn:not
    if symbol == "not" and noir_func == "fn_not":
        args = _get_function_args(token)
        if len(args) >= 1:
            try:
                arg_val = args[0].evaluate()
                if isinstance(arg_val, bool):
                    return ("", f"fn_not({str(arg_val).lower()})", None)
            except Exception:
                pass
        return None
    
    # Handle numeric mod operator (integer only)
    if symbol == "mod" and noir_func == "numeric_mod_int":
        if len(token) >= 2:
            try:
                a = token[0].evaluate()
                b = token[1].evaluate()
                if isinstance(a, (int, float, Decimal)) and isinstance(b, (int, float, Decimal)):
                    a_int, b_int = int(a), int(b)
                    if not _fits_in_i64(a_int) or not _fits_in_i64(b_int):
                        return None
                    return ("", f"numeric_mod_int({a_int}, {b_int})", None)
            except Exception:
                pass
        return None
    
    # Handle float arithmetic operators
    float_ops = {
        "+": ("numeric_add_float", "numeric_add_double"),
        "-": ("numeric_subtract_float", "numeric_subtract_double"),
        "*": ("numeric_multiply_float", "numeric_multiply_double"),
        "div": ("numeric_divide_float", "numeric_divide_double"),
    }
    
    if symbol in float_ops and noir_func in float_ops[symbol]:
        if len(token) >= 2:
            try:
                a = token[0].evaluate()
                b = token[1].evaluate()
                if isinstance(a, (int, float, Decimal)) and isinstance(b, (int, float, Decimal)):
                    a_float, b_float = float(a), float(b)
                    
                    # Determine if we're generating float32 or float64 code
                    is_float32 = noir_func.endswith('_float')
                    
                    if is_float32:
                        a_bits = float_to_bits(a_float)
                        b_bits = float_to_bits(b_float)
                        setup = f"let a = XsdFloat::from_bits({a_bits});\n    let b = XsdFloat::from_bits({b_bits});"
                        return (setup, f"{noir_func}(a, b)", None)
                    else:
                        a_bits = double_to_bits(a_float)
                        b_bits = double_to_bits(b_float)
                        setup = f"let a = XsdDouble::from_bits({a_bits});\n    let b = XsdDouble::from_bits({b_bits});"
                        return (setup, f"{noir_func}(a, b)", None)
            except Exception:
                pass
        return None
    
    # Handle float comparison operators (eq, lt, gt)
    float_cmp_ops = {
        "eq": ("numeric_equal_float", "numeric_equal_double"),
        "lt": ("numeric_less_than_float", "numeric_less_than_double"),
        "gt": ("numeric_greater_than_float", "numeric_greater_than_double"),
        "=": ("numeric_equal_float", "numeric_equal_double"),
        "<": ("numeric_less_than_float", "numeric_less_than_double"),
        ">": ("numeric_greater_than_float", "numeric_greater_than_double"),
    }
    
    if symbol in float_cmp_ops and noir_func in float_cmp_ops[symbol]:
        if len(token) >= 2:
            try:
                a = token[0].evaluate()
                b = token[1].evaluate()
                if isinstance(a, (int, float, Decimal)) and isinstance(b, (int, float, Decimal)):
                    a_float, b_float = float(a), float(b)
                    
                    is_float32 = noir_func.endswith('_float')
                    
                    if is_float32:
                        a_bits = float_to_bits(a_float)
                        b_bits = float_to_bits(b_float)
                        setup = f"let a = XsdFloat::from_bits({a_bits});\n    let b = XsdFloat::from_bits({b_bits});"
                        return (setup, f"{noir_func}(a, b)", None)
                    else:
                        a_bits = double_to_bits(a_float)
                        b_bits = double_to_bits(b_float)
                        setup = f"let a = XsdDouble::from_bits({a_bits});\n    let b = XsdDouble::from_bits({b_bits});"
                        return (setup, f"{noir_func}(a, b)", None)
            except Exception:
                pass
        return None
    
    # Handle integer numeric operators
    numeric_ops = {
        "+": "numeric_add_int",
        "-": "numeric_subtract_int",
        "*": "numeric_multiply_int",
        "div": "numeric_divide_int",
        "idiv": "numeric_divide_int",
    }
    
    if symbol in numeric_ops and numeric_ops[symbol] == noir_func:
        if len(token) >= 2:
            try:
                a = token[0].evaluate()
                b = token[1].evaluate()
                if isinstance(a, (int, float, Decimal)) and isinstance(b, (int, float, Decimal)):
                    a_int, b_int = int(a), int(b)
                    # Skip values outside i64 range
                    if not _fits_in_i64(a_int) or not _fits_in_i64(b_int):
                        return None
                    return ("", f"{noir_func}({a_int}, {b_int})", None)
            except Exception:
                pass
        return None
    
    # Handle fn:abs
    if symbol == "abs" and noir_func == "abs_int":
        args = _get_function_args(token)
        if len(args) >= 1:
            try:
                arg_val = args[0].evaluate()
                if isinstance(arg_val, (int, float, Decimal)):
                    val_int = int(arg_val)
                    if not _fits_in_i64(val_int):
                        return None
                    return ("", f"abs_int({val_int})", None)
            except Exception:
                pass
        return None
    
    # Handle type casting expressions
    # xs:float(integer_expr), xs:double(integer_expr), xs:integer(float_expr), etc.
    cast_pattern = CAST_FUNCTION_PATTERNS.get(function_name)
    if cast_pattern is not None:
        source_type, target_type = cast_pattern
        
        # Check if the expression is a cast expression
        # The symbol should be 'float', 'double', or 'integer' (depending on target type)
        target_symbols = {
            'float': 'float',
            'double': 'double',
            'int': 'integer',
        }
        expected_symbol = target_symbols.get(target_type)
        
        if symbol == expected_symbol:
            args = _get_function_args(token)
            if len(args) >= 1:
                try:
                    # First check if the argument has the right source type
                    arg_token = args[0]
                    arg_symbol = _get_function_name(arg_token)
                    
                    # For xs:float-from-int: expect integer input (plain number or xs:integer())
                    if source_type == 'int':
                        # Try to evaluate as integer
                        arg_val = arg_token.evaluate()
                        if isinstance(arg_val, (int, Decimal)):
                            val_int = int(arg_val)
                            if not _fits_in_i64(val_int):
                                return None
                            return ("", f"{noir_func}({val_int})", None)
                        elif isinstance(arg_val, float):
                            # Float literal being cast - skip for int source
                            return None
                    
                    # For xs:integer-from-float: expect xs:float() input
                    elif source_type == 'float':
                        if arg_symbol == 'float':
                            # Get the inner value
                            inner_args = _get_function_args(arg_token)
                            if len(inner_args) >= 1:
                                inner_val = inner_args[0].evaluate()
                                if isinstance(inner_val, (int, float, Decimal)):
                                    float_val = float(inner_val)
                                    bits = float_to_bits(float_val)
                                    setup = f"let f = XsdFloat::from_bits({bits});"
                                    return (setup, f"{noir_func}(f)", None)
                        return None
                    
                    # For xs:integer-from-double or xs:float-from-double: expect xs:double() input
                    elif source_type == 'double':
                        if arg_symbol == 'double':
                            inner_args = _get_function_args(arg_token)
                            if len(inner_args) >= 1:
                                inner_val = inner_args[0].evaluate()
                                if isinstance(inner_val, (int, float, Decimal)):
                                    double_val = float(inner_val)
                                    bits = double_to_bits(double_val)
                                    setup = f"let d = XsdDouble::from_bits({bits});"
                                    return (setup, f"{noir_func}(d)", None)
                        return None
                    
                except Exception:
                    pass
        return None
    
    return None


def _datetime_to_epoch(dt: DateTime10) -> Optional[Tuple[int, int]]:
    """Convert elementpath DateTime10 to (UTC microseconds, tz_offset_minutes)."""
    try:
        # Get timezone offset in minutes
        tz_offset_minutes = 0
        if dt.tzinfo is not None:
            offset = dt.tzinfo.offset
            tz_offset_minutes = int(offset.total_seconds() / 60)
        
        # Build a Python datetime and convert to epoch
        py_tz = timezone(timedelta(minutes=tz_offset_minutes))
        py_dt = datetime(
            dt.year, dt.month, dt.day,
            dt.hour, dt.minute, int(dt.second),
            dt.microsecond,
            tzinfo=py_tz
        )
        
        epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
        utc_dt = py_dt.astimezone(timezone.utc)
        delta = utc_dt - epoch
        utc_micros = int(delta.total_seconds() * 1_000_000)
        
        return (utc_micros, tz_offset_minutes)
    except Exception:
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
    
    setup_code, test_expr, embedded_expected = conversion
    
    # Determine what functions return boolean values
    boolean_returning_functions = [
        "fn_not", "boolean_equal",
        "datetime_equal", "datetime_less_than", "datetime_greater_than",
        "numeric_equal_int", "numeric_less_than_int", "numeric_greater_than_int",
        "numeric_equal_float", "numeric_less_than_float", "numeric_greater_than_float",
        "numeric_equal_double", "numeric_less_than_double", "numeric_greater_than_double",
    ]
    
    # Functions that return float/double types
    float_returning_functions = [
        "numeric_add_float", "numeric_subtract_float", 
        "numeric_multiply_float", "numeric_divide_float",
        "cast_integer_to_float",  # xs:float(integer)
        "cast_double_to_float",   # xs:float(double)
    ]
    double_returning_functions = [
        "numeric_add_double", "numeric_subtract_double",
        "numeric_multiply_double", "numeric_divide_double",
        "cast_integer_to_double", # xs:double(integer)
    ]
    
    # Functions that return Option<i64>
    option_int_returning_functions = [
        "cast_float_to_integer",  # xs:integer(float)
        "cast_double_to_integer", # xs:integer(double)
    ]
    
    noir_func = FUNCTION_MAP.get(function_name)
    func_returns_bool = noir_func in boolean_returning_functions
    func_returns_float = noir_func in float_returning_functions
    func_returns_double = noir_func in double_returning_functions
    func_returns_option_int = noir_func in option_int_returning_functions
    
    # Generate assertion based on result type
    # If embedded_expected is set, it means the XPath expression contained a comparison
    # and we extracted the expected value from it
    if embedded_expected is not None:
        # The expression contains a comparison, use the embedded expected value
        int_val = parse_integer(embedded_expected)
        if int_val is not None:
            assertion = f"assert({test_expr} == {int_val});"
        else:
            # Try as float (for seconds)
            try:
                float_val = float(embedded_expected)
                int_part = int(float_val)
                assertion = f"assert({test_expr} == {int_part});"
            except ValueError:
                return f"""// SKIP: {test_name}
// Cannot parse embedded expected: {embedded_expected}
"""
    elif test.result_type in ("assert-true", "assert-false"):
        # Only allow assert-true/assert-false for functions that return boolean
        if not func_returns_bool:
            return f"""// SKIP: {test_name}
// Result type {test.result_type} incompatible with non-boolean function {noir_func}
// Expression: {test.test_expr}
"""
        bool_val = test.result_type == "assert-true"
        assertion = f"assert({test_expr} == {str(bool_val).lower()});"
    elif test.result_type == "assert-eq":
        # Parse expected value
        expected = test.expected_result
        int_val = parse_integer(expected)
        bool_val = parse_boolean(expected)
        float_val = parse_float(expected)
        
        # For Option<i64> returning functions (cast to integer)
        if func_returns_option_int:
            if int_val is not None:
                assertion = f"assert({test_expr}.is_some());\n    assert({test_expr}.unwrap() == {int_val});"
            elif float_val is not None:
                # Truncate float to integer
                val, _ = float_val
                int_part = int(val)
                assertion = f"assert({test_expr}.is_some());\n    assert({test_expr}.unwrap() == {int_part});"
            else:
                return f"""// SKIP: {test_name}
// Cannot parse expected for cast-to-integer function: {expected}
"""
        # For float/double returning functions, we need to convert the expected value to bits
        elif func_returns_float or func_returns_double:
            # Try to parse as float first
            if float_val is not None:
                val, ftype = float_val
                if func_returns_float:
                    # For zero comparisons, use equality (handles +0 vs -0)
                    if val == 0.0:
                        assertion = f"assert({test_expr} == XsdFloat::zero());"
                    else:
                        expected_bits = float_to_bits(val)
                        assertion = f"assert({test_expr}.to_bits() == {expected_bits});"
                else:
                    if val == 0.0:
                        assertion = f"assert({test_expr} == XsdDouble::zero());"
                    else:
                        expected_bits = double_to_bits(val)
                        assertion = f"assert({test_expr}.to_bits() == {expected_bits});"
            elif int_val is not None:
                # Integer value for float function - convert to float bits
                if func_returns_float:
                    if int_val == 0:
                        assertion = f"assert({test_expr} == XsdFloat::zero());"
                    else:
                        expected_bits = float_to_bits(float(int_val))
                        assertion = f"assert({test_expr}.to_bits() == {expected_bits});"
                else:
                    if int_val == 0:
                        assertion = f"assert({test_expr} == XsdDouble::zero());"
                    else:
                        expected_bits = double_to_bits(float(int_val))
                        assertion = f"assert({test_expr}.to_bits() == {expected_bits});"
            else:
                # Cannot parse expected value for float function
                return f"""// SKIP: {test_name}
// Cannot parse expected for float function: {expected}
"""
        elif int_val is not None:
            # Skip negative values for functions that return unsigned types
            unsigned_return_functions = [
                "month_from_datetime", "day_from_datetime",
                "hours_from_datetime", "minutes_from_datetime", "seconds_from_datetime",
            ]
            if int_val < 0 and noir_func in unsigned_return_functions:
                return f"""// SKIP: {test_name}
// Negative expected value {int_val} incompatible with unsigned return type
"""
            assertion = f"assert({test_expr} == {int_val});"
        elif bool_val is not None:
            assertion = f"assert({test_expr} == {str(bool_val).lower()});"
        elif float_val is not None:
            # Float value but function doesn't return float - type mismatch
            return f"""// SKIP: {test_name}
// Float expected value incompatible with function {noir_func}
"""
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
    pkg_name = f"xpath_test_{sanitize_test_name(function_name)}"
    
    # Convert tests first to see if we have any
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
        # Clean up any existing empty package directory
        pkg_dir = output_dir / pkg_name
        if pkg_dir.exists():
            shutil.rmtree(pkg_dir)
        return 0

    # Create package directory only if we have tests
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

    # Split tests into chunks
    chunks = [converted_tests[i:i + chunk_size] for i in range(0, len(converted_tests), chunk_size)]

    # Determine required imports
    imports = ["use dep::xpath::{"]
    noir_func = FUNCTION_MAP.get(function_name)
    if noir_func:
        imports.append(f"    {noir_func},")
    
    # Add datetime imports if needed
    if "datetime" in function_name.lower():
        imports.append("    datetime_from_epoch_microseconds_with_tz,")
    
    # Add float/double type imports if needed
    # Check both function_name and noir_func for float/double
    func_lower = function_name.lower()
    noir_func_lower = noir_func.lower() if noir_func else ""
    
    if "float" in func_lower or "float" in noir_func_lower:
        imports.append("    XsdFloat,")
    if "double" in func_lower or "double" in noir_func_lower:
        imports.append("    XsdDouble,")
    
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

    # Build the complete members list
    all_members = ["xpath", "xpath_unit_tests"] + packages
    
    # Generate new Nargo.toml content
    members_list = ",\n    ".join(f'"{m}"' for m in all_members)
    new_content = f"""[workspace]
members = [
    {members_list},
]
"""
    
    nargo_path.write_text(new_content)
    print(f"\nUpdated workspace Nargo.toml with {len(packages)} test packages")


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
    total_tests_identified = 0
    total_tests_generated = 0
    print("\nGenerating tests...")
    for func in functions:
        if func not in FUNCTION_TEST_FILES:
            print(f"  Warning: No test file mapping for {func}")
            continue

        test_file = args.qt3_dir / FUNCTION_TEST_FILES[func]
        tests = parse_test_file(test_file)
        total_tests_identified += len(tests)

        if tests:
            count = generate_test_package(func, tests, args.output_dir)
            total_tests_generated += count
        else:
            print(f"  No tests found for {func}")

    # Update workspace Nargo.toml
    update_workspace_toml(args.output_dir.parent)

    print(f"\nTest generation complete!")
    print(f"Total tests identified in qt3tests: {total_tests_identified}")
    print(f"Total tests generated: {total_tests_generated}")


if __name__ == "__main__":
    main()

//! Numeric type definitions and type promotion for XPath/SPARQL
//!
//! Implements the xs:numeric union type and type promotion rules as defined in
//! XPath 2.0 Functions and Operators Section 4.1.
//!
//! Type hierarchy:
//! - xs:integer (derived from xs:decimal)
//! - xs:decimal
//! - xs:float (IEEE 754 single precision)
//! - xs:double (IEEE 754 double precision)
//!
//! Type promotion rules:
//! - xs:integer can substitute for xs:decimal (subtype substitution)
//! - xs:decimal can be promoted to xs:float or xs:double
//! - xs:float can be promoted to xs:double
//!
//! For operations with mixed types, both operands are promoted to the same type.

use ieee754::float::{
    IEEE754Float32, IEEE754Float64,
    float32_from_bits, float32_to_bits,
    float64_from_bits, float64_to_bits,
    float32_eq, float32_lt, float32_gt, float32_le, float32_ge,
    float64_eq, float64_lt, float64_gt, float64_le, float64_ge,
    float32_is_nan, float64_is_nan,
    add_float32, sub_float32, mul_float32, div_float32,
    add_float64, sub_float64, mul_float64, div_float64,
    abs_float32, abs_float64,
};

// ============================================================================
// Numeric Type Enum
// ============================================================================

/// XPath numeric type discriminator
/// Used to track the original type of a numeric value
pub struct NumericType {
    /// 0 = integer, 1 = decimal, 2 = float, 3 = double
    pub type_id: u8,
}

impl NumericType {
    pub fn integer() -> Self {
        NumericType { type_id: 0 }
    }

    pub fn decimal() -> Self {
        NumericType { type_id: 1 }
    }

    pub fn float() -> Self {
        NumericType { type_id: 2 }
    }

    pub fn double() -> Self {
        NumericType { type_id: 3 }
    }

    pub fn is_integer(self) -> bool {
        self.type_id == 0
    }

    pub fn is_decimal(self) -> bool {
        self.type_id == 1
    }

    pub fn is_float(self) -> bool {
        self.type_id == 2
    }

    pub fn is_double(self) -> bool {
        self.type_id == 3
    }
}

impl Eq for NumericType {
    fn eq(self, other: Self) -> bool {
        self.type_id == other.type_id
    }
}

// ============================================================================
// Float32 Wrapper (xs:float)
// ============================================================================

/// IEEE 754 float32 wrapped as XPath xs:float
pub struct XsdFloat {
    /// The underlying IEEE 754 float32 value
    pub value: IEEE754Float32,
}

impl XsdFloat {
    /// Create from IEEE 754 bit representation
    pub fn from_bits(bits: u32) -> Self {
        XsdFloat { value: float32_from_bits(bits) }
    }

    /// Convert to IEEE 754 bit representation
    pub fn to_bits(self) -> u32 {
        float32_to_bits(self.value)
    }

    /// Check if this value is NaN
    pub fn is_nan(self) -> bool {
        float32_is_nan(self.value)
    }

    /// Create positive zero
    pub fn zero() -> Self {
        XsdFloat::from_bits(0x00000000)
    }

    /// Create negative zero
    pub fn neg_zero() -> Self {
        XsdFloat::from_bits(0x80000000)
    }

    /// Create positive infinity
    pub fn infinity() -> Self {
        XsdFloat::from_bits(0x7F800000)
    }

    /// Create negative infinity
    pub fn neg_infinity() -> Self {
        XsdFloat::from_bits(0xFF800000)
    }

    /// Create NaN
    pub fn nan() -> Self {
        XsdFloat::from_bits(0x7FC00000) // Quiet NaN
    }

    /// Create from a small integer (-127 to 127)
    /// For zero-knowledge compatible conversion
    pub fn from_small_int(n: i8) -> Self {
        // Handle zero case
        if n == 0 {
            XsdFloat::zero()
        } else {
            let is_negative = n < 0;
            let abs_n: u8 = if is_negative { ((-n) as i8) as u8 } else { n as u8 };
            
            // Find highest set bit position using bounded loop
            let mut msb_pos: u32 = 0;
            for i in 0..8 {
                if (abs_n >> i) != 0 {
                    msb_pos = i as u32;
                }
            }
            
            // Exponent is biased by 127
            let exponent: u32 = 127 + msb_pos;
            
            // Mantissa: shift value left to fill 23 bits, remove implicit leading 1
            let mantissa: u32 = if msb_pos == 0 {
                0
            } else {
                ((abs_n as u32) << (23 - msb_pos)) & 0x7FFFFF
            };
            
            let sign_bit: u32 = if is_negative { 1 << 31 } else { 0 };
            XsdFloat::from_bits(sign_bit | (exponent << 23) | mantissa)
        }
    }
}

impl Eq for XsdFloat {
    fn eq(self, other: Self) -> bool {
        float32_eq(self.value, other.value)
    }
}

// ============================================================================
// Float64 Wrapper (xs:double)
// ============================================================================

/// IEEE 754 float64 wrapped as XPath xs:double
pub struct XsdDouble {
    /// The underlying IEEE 754 float64 value
    pub value: IEEE754Float64,
}

impl XsdDouble {
    /// Create from IEEE 754 bit representation
    pub fn from_bits(bits: u64) -> Self {
        XsdDouble { value: float64_from_bits(bits) }
    }

    /// Convert to IEEE 754 bit representation
    pub fn to_bits(self) -> u64 {
        float64_to_bits(self.value)
    }

    /// Check if this value is NaN
    pub fn is_nan(self) -> bool {
        float64_is_nan(self.value)
    }

    /// Create positive zero
    pub fn zero() -> Self {
        XsdDouble::from_bits(0x0000000000000000)
    }

    /// Create negative zero
    pub fn neg_zero() -> Self {
        XsdDouble::from_bits(0x8000000000000000)
    }

    /// Create positive infinity
    pub fn infinity() -> Self {
        XsdDouble::from_bits(0x7FF0000000000000)
    }

    /// Create negative infinity
    pub fn neg_infinity() -> Self {
        XsdDouble::from_bits(0xFFF0000000000000)
    }

    /// Create NaN
    pub fn nan() -> Self {
        XsdDouble::from_bits(0x7FF8000000000000) // Quiet NaN
    }

    /// Create from a small integer (-127 to 127)
    /// For zero-knowledge compatible conversion
    pub fn from_small_int(n: i8) -> Self {
        if n == 0 {
            XsdDouble::zero()
        } else {
            let is_negative = n < 0;
            let abs_n: u8 = if is_negative { ((-n) as i8) as u8 } else { n as u8 };
            
            // Find highest set bit position using bounded loop
            let mut msb_pos: u32 = 0;
            for i in 0..8 {
                if (abs_n >> i) != 0 {
                    msb_pos = i as u32;
                }
            }
            
            // Exponent is biased by 1023 for float64
            let exponent: u64 = (1023 + msb_pos) as u64;
            
            // Mantissa: shift value left to fill 52 bits, remove implicit leading 1
            let shift_amount: u64 = (52 - msb_pos) as u64;
            let mantissa: u64 = if msb_pos == 0 {
                0
            } else {
                ((abs_n as u64) << shift_amount) & 0xFFFFFFFFFFFFF
            };
            
            let sign_bit: u64 = if is_negative { 1 << 63 } else { 0 };
            XsdDouble::from_bits(sign_bit | (exponent << 52) | mantissa)
        }
    }

    /// Promote from float32 to float64
    /// This is exact for all finite float32 values
    pub fn from_float(f: XsdFloat) -> Self {
        let bits32 = f.to_bits();
        let sign: u64 = ((bits32 >> 31) & 1) as u64;
        let exp32: u32 = (bits32 >> 23) & 0xFF;
        let mant32: u32 = bits32 & 0x7FFFFF;

        // Handle zero
        let is_zero = (exp32 == 0) & (mant32 == 0);
        // Handle infinity/NaN  
        let is_special = exp32 == 0xFF;
        // Handle denormalized
        let is_denorm = (exp32 == 0) & (mant32 != 0);

        // For each case, compute the bits (only one will be valid)
        // Zero case
        let zero_bits: u64 = sign << 63;
        
        // Special (infinity/NaN) case
        let special_exp: u64 = 0x7FF;
        let special_mant: u64 = (mant32 as u64) << 29;
        let special_bits: u64 = (sign << 63) | (special_exp << 52) | special_mant;
        
        // Normal case
        let normal_exp: u64 = ((exp32 as i64 - 127 + 1023) as u64) & 0x7FF;
        let normal_mant: u64 = (mant32 as u64) << 29;
        let normal_bits: u64 = (sign << 63) | (normal_exp << 52) | normal_mant;
        
        // Denormalized - simplified handling (treat as zero for now)
        // Full denorm handling requires unbounded loops
        let denorm_bits: u64 = sign << 63;
        
        // Select the appropriate result
        let result_bits = if is_zero {
            zero_bits
        } else if is_special {
            special_bits
        } else if is_denorm {
            denorm_bits
        } else {
            normal_bits
        };
        
        XsdDouble::from_bits(result_bits)
    }
}

impl Eq for XsdDouble {
    fn eq(self, other: Self) -> bool {
        float64_eq(self.value, other.value)
    }
}

// ============================================================================
// Type Promotion Functions
// ============================================================================

/// Get the common type for two numeric types according to XPath promotion rules
/// Returns the type that both operands should be promoted to
pub fn get_common_type(t1: NumericType, t2: NumericType) -> NumericType {
    // double has highest precedence, then float, then decimal, then integer
    // When mixing types, promote to the highest precedence type
    if t1.is_double() | t2.is_double() {
        NumericType::double()
    } else if t1.is_float() | t2.is_float() {
        // Per XPath spec: When mixing float with decimal, promote to double
        // to avoid precision loss
        NumericType::double()
    } else if t1.is_decimal() | t2.is_decimal() {
        NumericType::decimal()
    } else {
        NumericType::integer()
    }
}

// ============================================================================
// Float Comparison Functions
// ============================================================================

/// op:numeric-equal for xs:float
/// NaN does not equal itself per IEEE 754 / XPath spec
pub fn numeric_equal_float(a: XsdFloat, b: XsdFloat) -> bool {
    float32_eq(a.value, b.value)
}

/// op:numeric-less-than for xs:float
/// Returns false if either operand is NaN
pub fn numeric_less_than_float(a: XsdFloat, b: XsdFloat) -> bool {
    float32_lt(a.value, b.value)
}

/// op:numeric-greater-than for xs:float
/// Returns false if either operand is NaN
pub fn numeric_greater_than_float(a: XsdFloat, b: XsdFloat) -> bool {
    float32_gt(a.value, b.value)
}

/// op:numeric-less-than-or-equal for xs:float
pub fn numeric_le_float(a: XsdFloat, b: XsdFloat) -> bool {
    float32_le(a.value, b.value)
}

/// op:numeric-greater-than-or-equal for xs:float
pub fn numeric_ge_float(a: XsdFloat, b: XsdFloat) -> bool {
    float32_ge(a.value, b.value)
}

// ============================================================================
// Double Comparison Functions
// ============================================================================

/// op:numeric-equal for xs:double
/// NaN does not equal itself per IEEE 754 / XPath spec
pub fn numeric_equal_double(a: XsdDouble, b: XsdDouble) -> bool {
    float64_eq(a.value, b.value)
}

/// op:numeric-less-than for xs:double
/// Returns false if either operand is NaN
pub fn numeric_less_than_double(a: XsdDouble, b: XsdDouble) -> bool {
    float64_lt(a.value, b.value)
}

/// op:numeric-greater-than for xs:double
/// Returns false if either operand is NaN
pub fn numeric_greater_than_double(a: XsdDouble, b: XsdDouble) -> bool {
    float64_gt(a.value, b.value)
}

/// op:numeric-less-than-or-equal for xs:double
pub fn numeric_le_double(a: XsdDouble, b: XsdDouble) -> bool {
    float64_le(a.value, b.value)
}

/// op:numeric-greater-than-or-equal for xs:double
pub fn numeric_ge_double(a: XsdDouble, b: XsdDouble) -> bool {
    float64_ge(a.value, b.value)
}

// ============================================================================
// Float Arithmetic Functions
// ============================================================================

/// op:numeric-add for xs:float
pub fn numeric_add_float(a: XsdFloat, b: XsdFloat) -> XsdFloat {
    XsdFloat { value: add_float32(a.value, b.value) }
}

/// op:numeric-subtract for xs:float
pub fn numeric_subtract_float(a: XsdFloat, b: XsdFloat) -> XsdFloat {
    XsdFloat { value: sub_float32(a.value, b.value) }
}

/// op:numeric-multiply for xs:float
pub fn numeric_multiply_float(a: XsdFloat, b: XsdFloat) -> XsdFloat {
    XsdFloat { value: mul_float32(a.value, b.value) }
}

/// op:numeric-divide for xs:float
pub fn numeric_divide_float(a: XsdFloat, b: XsdFloat) -> XsdFloat {
    XsdFloat { value: div_float32(a.value, b.value) }
}

/// fn:abs for xs:float
pub fn abs_float(a: XsdFloat) -> XsdFloat {
    XsdFloat { value: abs_float32(a.value) }
}

// ============================================================================
// Double Arithmetic Functions
// ============================================================================

/// op:numeric-add for xs:double
pub fn numeric_add_double(a: XsdDouble, b: XsdDouble) -> XsdDouble {
    XsdDouble { value: add_float64(a.value, b.value) }
}

/// op:numeric-subtract for xs:double
pub fn numeric_subtract_double(a: XsdDouble, b: XsdDouble) -> XsdDouble {
    XsdDouble { value: sub_float64(a.value, b.value) }
}

/// op:numeric-multiply for xs:double
pub fn numeric_multiply_double(a: XsdDouble, b: XsdDouble) -> XsdDouble {
    XsdDouble { value: mul_float64(a.value, b.value) }
}

/// op:numeric-divide for xs:double
pub fn numeric_divide_double(a: XsdDouble, b: XsdDouble) -> XsdDouble {
    XsdDouble { value: div_float64(a.value, b.value) }
}

/// fn:abs for xs:double
pub fn abs_double(a: XsdDouble) -> XsdDouble {
    XsdDouble { value: abs_float64(a.value) }
}

// ============================================================================
// Mixed Type Comparison Functions
// ============================================================================

/// Compare integer to double for equality
/// Promotes integer to double first
pub fn compare_int_double_eq(a: i64, b: XsdDouble) -> bool {
    let a_double = XsdDouble::from_small_int(a as i8);
    numeric_equal_double(a_double, b)
}

/// Compare integer to double for less-than
pub fn compare_int_double_lt(a: i64, b: XsdDouble) -> bool {
    let a_double = XsdDouble::from_small_int(a as i8);
    numeric_less_than_double(a_double, b)
}

/// Compare integer to double for greater-than
pub fn compare_int_double_gt(a: i64, b: XsdDouble) -> bool {
    let a_double = XsdDouble::from_small_int(a as i8);
    numeric_greater_than_double(a_double, b)
}

/// Compare double to integer for equality
pub fn compare_double_int_eq(a: XsdDouble, b: i64) -> bool {
    let b_double = XsdDouble::from_small_int(b as i8);
    numeric_equal_double(a, b_double)
}

/// Compare double to integer for less-than
pub fn compare_double_int_lt(a: XsdDouble, b: i64) -> bool {
    let b_double = XsdDouble::from_small_int(b as i8);
    numeric_less_than_double(a, b_double)
}

/// Compare double to integer for greater-than
pub fn compare_double_int_gt(a: XsdDouble, b: i64) -> bool {
    let b_double = XsdDouble::from_small_int(b as i8);
    numeric_greater_than_double(a, b_double)
}

/// Compare float to double for equality (promotes float to double)
pub fn compare_float_double_eq(a: XsdFloat, b: XsdDouble) -> bool {
    let a_double = XsdDouble::from_float(a);
    numeric_equal_double(a_double, b)
}

/// Compare float to double for less-than
pub fn compare_float_double_lt(a: XsdFloat, b: XsdDouble) -> bool {
    let a_double = XsdDouble::from_float(a);
    numeric_less_than_double(a_double, b)
}

/// Compare float to double for greater-than
pub fn compare_float_double_gt(a: XsdFloat, b: XsdDouble) -> bool {
    let a_double = XsdDouble::from_float(a);
    numeric_greater_than_double(a_double, b)
}

// ============================================================================
// Tests
// ============================================================================

#[test]
fn test_numeric_type_constructors() {
    assert(NumericType::integer().is_integer());
    assert(NumericType::decimal().is_decimal());
    assert(NumericType::float().is_float());
    assert(NumericType::double().is_double());
}

#[test]
fn test_get_common_type() {
    // Integer + Integer = Integer
    assert(get_common_type(NumericType::integer(), NumericType::integer()).is_integer());
    
    // Integer + Decimal = Decimal
    assert(get_common_type(NumericType::integer(), NumericType::decimal()).is_decimal());
    
    // Float + Integer = Double (promoted)
    assert(get_common_type(NumericType::float(), NumericType::integer()).is_double());
    
    // Double + anything = Double
    assert(get_common_type(NumericType::double(), NumericType::integer()).is_double());
    assert(get_common_type(NumericType::double(), NumericType::float()).is_double());
}

#[test]
fn test_float_zero() {
    let zero = XsdFloat::zero();
    let neg_zero = XsdFloat::neg_zero();
    
    // +0 == -0 per IEEE 754
    assert(numeric_equal_float(zero, neg_zero));
}

#[test]
fn test_float_nan() {
    let nan = XsdFloat::nan();
    
    // NaN != NaN per IEEE 754
    assert(!numeric_equal_float(nan, nan));
    assert(!numeric_less_than_float(nan, nan));
    assert(!numeric_greater_than_float(nan, nan));
}

#[test]
fn test_float_infinity() {
    let inf = XsdFloat::infinity();
    let neg_inf = XsdFloat::neg_infinity();
    let one = XsdFloat::from_bits(0x3F800000); // 1.0f
    
    assert(numeric_less_than_float(neg_inf, one));
    assert(numeric_less_than_float(one, inf));
    assert(numeric_greater_than_float(inf, neg_inf));
}

#[test]
fn test_double_zero() {
    let zero = XsdDouble::zero();
    let neg_zero = XsdDouble::neg_zero();
    
    // +0 == -0 per IEEE 754
    assert(numeric_equal_double(zero, neg_zero));
}

#[test]
fn test_double_nan() {
    let nan = XsdDouble::nan();
    
    // NaN != NaN per IEEE 754
    assert(!numeric_equal_double(nan, nan));
    assert(!numeric_less_than_double(nan, nan));
    assert(!numeric_greater_than_double(nan, nan));
}

#[test]
fn test_float_arithmetic() {
    // Use known bit patterns for 2.0 and 3.0
    let two = XsdFloat::from_bits(0x40000000);   // 2.0f
    let three = XsdFloat::from_bits(0x40400000); // 3.0f
    let five = XsdFloat::from_bits(0x40A00000);  // 5.0f
    
    let sum = numeric_add_float(two, three);
    assert(numeric_equal_float(sum, five));
}

#[test]
fn test_double_arithmetic() {
    // Use known bit patterns for 2.0 and 3.0
    let two = XsdDouble::from_bits(0x4000000000000000);   // 2.0
    let three = XsdDouble::from_bits(0x4008000000000000); // 3.0
    let five = XsdDouble::from_bits(0x4014000000000000);  // 5.0
    
    let sum = numeric_add_double(two, three);
    assert(numeric_equal_double(sum, five));
}

#[test]
fn test_float_to_double_promotion() {
    // Promote 1.0f to double
    let one_float = XsdFloat::from_bits(0x3F800000); // 1.0f
    let one_double = XsdDouble::from_float(one_float);
    let expected = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    
    assert(numeric_equal_double(one_double, expected));
}

#[test]
fn test_small_int_to_float() {
    let one = XsdFloat::from_small_int(1);
    let expected = XsdFloat::from_bits(0x3F800000); // 1.0f
    assert(numeric_equal_float(one, expected));
}

#[test]
fn test_small_int_to_double() {
    let one = XsdDouble::from_small_int(1);
    let expected = XsdDouble::from_bits(0x3FF0000000000000); // 1.0
    assert(numeric_equal_double(one, expected));
}

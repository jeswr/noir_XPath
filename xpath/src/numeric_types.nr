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
    abs_float32, abs_float64, add_float32, add_float64, div_float32, div_float64, float32_eq,
    float32_from_bits, float32_ge, float32_gt, float32_is_nan, float32_le, float32_lt,
    float32_to_bits, float64_eq, float64_from_bits, float64_ge, float64_gt, float64_is_nan,
    float64_le, float64_lt, float64_to_bits, IEEE754Float32, IEEE754Float64, mul_float32,
    mul_float64, sub_float32, sub_float64,
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
            let abs_n: u8 = if is_negative {
                ((-n) as i8) as u8
            } else {
                n as u8
            };

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
            let abs_n: u8 = if is_negative {
                ((-n) as i8) as u8
            } else {
                n as u8
            };

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

/// fn:round for xs:float
/// Rounds to the nearest integer, ties to even (banker's rounding)
pub fn round_float(a: XsdFloat) -> XsdFloat {
    let bits = a.to_bits();
    let sign = bits >> 31;
    let exp_bits = (bits >> 23) & 0xFF;
    let mant = bits & 0x7FFFFF;
    
    // Handle special cases
    let is_zero = (exp_bits == 0) & (mant == 0);
    let is_nan = (exp_bits == 0xFF) & (mant != 0);
    let is_inf = (exp_bits == 0xFF) & (mant == 0);
    
    let mut result = a;
    
    if !(is_zero | is_nan | is_inf) {
        // Unbias exponent
        let exp: i32 = (exp_bits as i32) - 127;
        
        // If exponent >= 23, number is already an integer (no fractional bits)
        if exp >= 23 {
            result = a;
        } else if exp < 0 {
            // Absolute value < 1, round to 0 or +/-1
            // For 0.5 <= absolute value < 1, round to +/-1
            // For absolute value < 0.5, round to 0
            // exp = -1 means value is in range [0.5, 1) or (-1, -0.5]
            if exp == -1 {
                // Exactly 0.5 or in range [0.5, 1)
                // Check if exactly 0.5 (mantissa would be 0)
                if mant == 0 {
                    // Exactly +/-0.5, round to even (0)
                    result = XsdFloat::zero();
                } else {
                    // In range (0.5, 1) or (-1, -0.5), round to +/-1
                    result = if sign == 0 {
                        XsdFloat::from_bits(0x3F800000) // +1.0
                    } else {
                        XsdFloat::from_bits(0xBF800000) // -1.0
                    };
                }
            } else {
                // Absolute value < 0.5, round to 0
                result = if sign == 0 {
                    XsdFloat::zero()
                } else {
                    XsdFloat::neg_zero()
                };
            }
        } else {
            // 0 <= exp < 23: number has both integer and fractional parts
            let frac_bits = 23 - (exp as u32);
            let frac_mask = (1 << frac_bits) - 1;
            let int_mask = 0x7FFFFF - frac_mask;
            
            let frac_part = mant & frac_mask;
            let int_part = mant & int_mask;
            
            // Check if fractional part is exactly 0.5
            let half_bit = 1 << (frac_bits - 1);
            let is_exactly_half = frac_part == half_bit;
            let is_greater_than_half = frac_part > half_bit;
            
            // Determine if we should round up
            let lsb_of_int = (mant >> frac_bits) & 1;
            let round_up = is_greater_than_half | (is_exactly_half & (lsb_of_int == 1));
            
            // Build result
            let incremented = int_part + (1 << frac_bits);
            let mant_overflow = incremented >= 0x800000;
            let new_exp_bits = exp_bits + 1;
            let exp_overflow = new_exp_bits >= 0xFF;
            
            result = if round_up {
                if mant_overflow {
                    if exp_overflow {
                        if sign == 0 {
                            XsdFloat::infinity()
                        } else {
                            XsdFloat::neg_infinity()
                        }
                    } else {
                        XsdFloat::from_bits((sign << 31) | (new_exp_bits << 23) | 0)
                    }
                } else {
                    XsdFloat::from_bits((sign << 31) | (exp_bits << 23) | incremented)
                }
            } else {
                XsdFloat::from_bits((sign << 31) | (exp_bits << 23) | int_part)
            };
        }
    }
    
    result
}

/// fn:ceiling for xs:float
/// Rounds up to the nearest integer
pub fn ceil_float(a: XsdFloat) -> XsdFloat {
    let bits = a.to_bits();
    let sign = bits >> 31;
    let exp_bits = (bits >> 23) & 0xFF;
    let mant = bits & 0x7FFFFF;
    
    // Handle special cases
    let is_zero = (exp_bits == 0) & (mant == 0);
    let is_nan = (exp_bits == 0xFF) & (mant != 0);
    let is_inf = (exp_bits == 0xFF) & (mant == 0);
    
    let mut result = a;
    
    if !(is_zero | is_nan | is_inf) {
        let exp: i32 = (exp_bits as i32) - 127;
        
        if exp >= 23 {
            // Already an integer
            result = a;
        } else if exp < 0 {
            // Absolute value < 1
            result = if sign == 0 {
                // Positive: ceil of (0, 1) is 1
                XsdFloat::from_bits(0x3F800000) // +1.0
            } else {
                // Negative: ceil of (-1, 0) is -0
                XsdFloat::neg_zero()
            };
        } else {
            // Has fractional part
            let frac_bits = 23 - (exp as u32);
            let frac_mask = (1 << frac_bits) - 1;
            let int_mask = 0x7FFFFF - frac_mask;
            
            let frac_part = mant & frac_mask;
            let int_part = mant & int_mask;
            
            // If positive and has any fractional part, round up
            // If negative, truncate (round toward zero, which is up for negatives)
            let incremented = int_part + (1 << frac_bits);
            let mant_overflow = incremented >= 0x800000;
            let new_exp_bits = exp_bits + 1;
            let exp_overflow = new_exp_bits >= 0xFF;
            
            result = if (sign == 0) & (frac_part != 0) {
                // Positive with fraction: round up
                if mant_overflow {
                    if exp_overflow {
                        XsdFloat::infinity()
                    } else {
                        XsdFloat::from_bits((sign << 31) | (new_exp_bits << 23) | 0)
                    }
                } else {
                    XsdFloat::from_bits((sign << 31) | (exp_bits << 23) | incremented)
                }
            } else {
                // Negative or no fraction: truncate
                XsdFloat::from_bits((sign << 31) | (exp_bits << 23) | int_part)
            };
        }
    }
    
    result
}

/// fn:floor for xs:float
/// Rounds down to the nearest integer
pub fn floor_float(a: XsdFloat) -> XsdFloat {
    let bits = a.to_bits();
    let sign = bits >> 31;
    let exp_bits = (bits >> 23) & 0xFF;
    let mant = bits & 0x7FFFFF;
    
    // Handle special cases
    let is_zero = (exp_bits == 0) & (mant == 0);
    let is_nan = (exp_bits == 0xFF) & (mant != 0);
    let is_inf = (exp_bits == 0xFF) & (mant == 0);
    
    let mut result = a;
    
    if !(is_zero | is_nan | is_inf) {
        let exp: i32 = (exp_bits as i32) - 127;
        
        if exp >= 23 {
            // Already an integer
            result = a;
        } else if exp < 0 {
            // Absolute value < 1
            result = if sign == 0 {
                // Positive: floor of (0, 1) is 0
                XsdFloat::zero()
            } else {
                // Negative: floor of (-1, 0) is -1
                XsdFloat::from_bits(0xBF800000) // -1.0
            };
        } else {
            // Has fractional part
            let frac_bits = 23 - (exp as u32);
            let frac_mask = (1 << frac_bits) - 1;
            let int_mask = 0x7FFFFF - frac_mask;
            
            let frac_part = mant & frac_mask;
            let int_part = mant & int_mask;
            
            // If negative and has any fractional part, round down (increase magnitude)
            // If positive, truncate (round toward zero, which is down for positives)
            let incremented = int_part + (1 << frac_bits);
            let mant_overflow = incremented >= 0x800000;
            let new_exp_bits = exp_bits + 1;
            let exp_overflow = new_exp_bits >= 0xFF;
            
            result = if (sign == 1) & (frac_part != 0) {
                // Negative with fraction: round down (increase magnitude)
                if mant_overflow {
                    if exp_overflow {
                        XsdFloat::neg_infinity()
                    } else {
                        XsdFloat::from_bits((sign << 31) | (new_exp_bits << 23) | 0)
                    }
                } else {
                    XsdFloat::from_bits((sign << 31) | (exp_bits << 23) | incremented)
                }
            } else {
                // Positive or no fraction: truncate
                XsdFloat::from_bits((sign << 31) | (exp_bits << 23) | int_part)
            };
        }
    }
    
    result
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

/// fn:round for xs:double
/// Rounds to the nearest integer, ties to even (banker's rounding)
pub fn round_double(a: XsdDouble) -> XsdDouble {
    let bits = a.to_bits();
    let sign = bits >> 63;
    let exp_bits = (bits >> 52) & 0x7FF;
    let mant = bits & 0xFFFFFFFFFFFFF;
    
    // Handle special cases
    let is_zero = (exp_bits == 0) & (mant == 0);
    let is_nan = (exp_bits == 0x7FF) & (mant != 0);
    let is_inf = (exp_bits == 0x7FF) & (mant == 0);
    
    let mut result = a;
    
    if !(is_zero | is_nan | is_inf) {
        let exp: i64 = (exp_bits as i64) - 1023;
        
        if exp >= 52 {
            // Already an integer
            result = a;
        } else if exp < 0 {
            // Absolute value < 1
            if exp == -1 {
                // In range [0.5, 1) or (-1, -0.5]
                result = if mant == 0 {
                    // Exactly +/-0.5, round to even (0)
                    XsdDouble::zero()
                } else {
                    // Round to +/-1
                    if sign == 0 {
                        XsdDouble::from_bits(0x3FF0000000000000) // +1.0
                    } else {
                        XsdDouble::from_bits(0xBFF0000000000000) // -1.0
                    }
                };
            } else {
                // Absolute value < 0.5, round to 0
                result = if sign == 0 {
                    XsdDouble::zero()
                } else {
                    XsdDouble::neg_zero()
                };
            }
        } else {
            // Has fractional part
            let frac_bits = 52 - (exp as u64);
            let frac_mask = (1 << frac_bits) - 1;
            let int_mask = 0xFFFFFFFFFFFFF - frac_mask;
            
            let frac_part = mant & frac_mask;
            let int_part = mant & int_mask;
            
            let half_bit = 1 << (frac_bits - 1);
            let is_exactly_half = frac_part == half_bit;
            let is_greater_than_half = frac_part > half_bit;
            
            let lsb_of_int = (mant >> frac_bits) & 1;
            let round_up = is_greater_than_half | (is_exactly_half & (lsb_of_int == 1));
            
            let incremented = int_part + (1 << frac_bits);
            let mant_overflow = incremented >= 0x10000000000000;
            let new_exp_bits = exp_bits + 1;
            let exp_overflow = new_exp_bits >= 0x7FF;
            
            result = if round_up {
                if mant_overflow {
                    if exp_overflow {
                        if sign == 0 {
                            XsdDouble::infinity()
                        } else {
                            XsdDouble::neg_infinity()
                        }
                    } else {
                        XsdDouble::from_bits((sign << 63) | (new_exp_bits << 52) | 0)
                    }
                } else {
                    XsdDouble::from_bits((sign << 63) | (exp_bits << 52) | incremented)
                }
            } else {
                XsdDouble::from_bits((sign << 63) | (exp_bits << 52) | int_part)
            };
        }
    }
    
    result
}

/// fn:ceiling for xs:double
/// Rounds up to the nearest integer
pub fn ceil_double(a: XsdDouble) -> XsdDouble {
    let bits = a.to_bits();
    let sign = bits >> 63;
    let exp_bits = (bits >> 52) & 0x7FF;
    let mant = bits & 0xFFFFFFFFFFFFF;
    
    let is_zero = (exp_bits == 0) & (mant == 0);
    let is_nan = (exp_bits == 0x7FF) & (mant != 0);
    let is_inf = (exp_bits == 0x7FF) & (mant == 0);
    
    let mut result = a;
    
    if !(is_zero | is_nan | is_inf) {
        let exp: i64 = (exp_bits as i64) - 1023;
        
        if exp >= 52 {
            result = a;
        } else if exp < 0 {
            result = if sign == 0 {
                XsdDouble::from_bits(0x3FF0000000000000) // +1.0
            } else {
                XsdDouble::neg_zero()
            };
        } else {
            let frac_bits = 52 - (exp as u64);
            let frac_mask = (1 << frac_bits) - 1;
            let int_mask = 0xFFFFFFFFFFFFF - frac_mask;
            
            let frac_part = mant & frac_mask;
            let int_part = mant & int_mask;
            
            let incremented = int_part + (1 << frac_bits);
            let mant_overflow = incremented >= 0x10000000000000;
            let new_exp_bits = exp_bits + 1;
            let exp_overflow = new_exp_bits >= 0x7FF;
            
            result = if (sign == 0) & (frac_part != 0) {
                if mant_overflow {
                    if exp_overflow {
                        XsdDouble::infinity()
                    } else {
                        XsdDouble::from_bits((sign << 63) | (new_exp_bits << 52) | 0)
                    }
                } else {
                    XsdDouble::from_bits((sign << 63) | (exp_bits << 52) | incremented)
                }
            } else {
                XsdDouble::from_bits((sign << 63) | (exp_bits << 52) | int_part)
            };
        }
    }
    
    result
}

/// fn:floor for xs:double
/// Rounds down to the nearest integer
pub fn floor_double(a: XsdDouble) -> XsdDouble {
    let bits = a.to_bits();
    let sign = bits >> 63;
    let exp_bits = (bits >> 52) & 0x7FF;
    let mant = bits & 0xFFFFFFFFFFFFF;
    
    let is_zero = (exp_bits == 0) & (mant == 0);
    let is_nan = (exp_bits == 0x7FF) & (mant != 0);
    let is_inf = (exp_bits == 0x7FF) & (mant == 0);
    
    let mut result = a;
    
    if !(is_zero | is_nan | is_inf) {
        let exp: i64 = (exp_bits as i64) - 1023;
        
        if exp >= 52 {
            result = a;
        } else if exp < 0 {
            result = if sign == 0 {
                XsdDouble::zero()
            } else {
                XsdDouble::from_bits(0xBFF0000000000000) // -1.0
            };
        } else {
            let frac_bits = 52 - (exp as u64);
            let frac_mask = (1 << frac_bits) - 1;
            let int_mask = 0xFFFFFFFFFFFFF - frac_mask;
            
            let frac_part = mant & frac_mask;
            let int_part = mant & int_mask;
            
            let incremented = int_part + (1 << frac_bits);
            let mant_overflow = incremented >= 0x10000000000000;
            let new_exp_bits = exp_bits + 1;
            let exp_overflow = new_exp_bits >= 0x7FF;
            
            result = if (sign == 1) & (frac_part != 0) {
                if mant_overflow {
                    if exp_overflow {
                        XsdDouble::neg_infinity()
                    } else {
                        XsdDouble::from_bits((sign << 63) | (new_exp_bits << 52) | 0)
                    }
                } else {
                    XsdDouble::from_bits((sign << 63) | (exp_bits << 52) | incremented)
                }
            } else {
                XsdDouble::from_bits((sign << 63) | (exp_bits << 52) | int_part)
            };
        }
    }
    
    result
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
// Type Casting Functions (xs:float, xs:double, xs:integer constructors)
// ============================================================================

/// Cast a small integer (-127 to 127) to xs:float
/// xs:float($arg as xs:integer) -> xs:float
///
/// Note: For Noir compatibility, this only handles small integers.
/// Use XsdFloat::from_small_int for the implementation.
pub fn cast_integer_to_float(n: i8) -> XsdFloat {
    XsdFloat::from_small_int(n)
}

/// Cast a small integer (-127 to 127) to xs:double
/// xs:double($arg as xs:integer) -> xs:double
///
/// Note: For Noir compatibility, this only handles small integers.
/// Use XsdDouble::from_small_int for the implementation.
pub fn cast_integer_to_double(n: i8) -> XsdDouble {
    XsdDouble::from_small_int(n)
}

/// Cast xs:float to xs:integer (truncation toward zero)
/// xs:integer($arg as xs:float) -> xs:integer
///
/// Returns None if the value is NaN, Infinity, or out of range.
/// This simplified version handles common cases for small values.
pub fn cast_float_to_integer(f: XsdFloat) -> Option<i64> {
    let bits = f.to_bits();
    let sign = (bits >> 31) & 1;
    let exp = ((bits >> 23) & 0xFF) as u32;
    let mant = bits & 0x7FFFFF;

    // Check for NaN or infinity (exp == 255)
    let is_special = exp == 255;

    // Check for zero or denormal (exp == 0)
    let is_zero_or_denorm = exp == 0;

    // Unbias the exponent (bias is 127)
    // For valid floating point numbers, exp is 1-254, so unbiased is -126 to 127
    let unbiased_exp: i32 = (exp as i32) - 127;

    // If exponent is negative, value is < 1, truncates to 0
    let truncates_to_zero = unbiased_exp < 0;

    // If exponent is too large (> 62), value exceeds i64 range
    let out_of_range = unbiased_exp > 62;

    // Determine if we need to compute a shift at all
    let needs_computation = !is_special & !is_zero_or_denorm & !truncates_to_zero & !out_of_range;

    // Add implicit leading 1 to mantissa (24 bits total)
    let full_mantissa: u64 = (mant as u64) | 0x800000;

    // Calculate safe shift amounts - clamp to valid range
    let clamped_exp: i32 = if unbiased_exp < 0 {
        0
    } else if unbiased_exp > 62 {
        62
    } else {
        unbiased_exp
    };

    let shift_left_amount: u64 = if clamped_exp >= 23 {
        (clamped_exp - 23) as u64
    } else {
        0
    };
    let shift_right_amount: u64 = if clamped_exp < 23 {
        (23 - clamped_exp) as u64
    } else {
        0
    };

    // Only compute shifted value when needed (using clamped safe values)
    let shifted_value: u64 = if needs_computation {
        if clamped_exp >= 23 {
            full_mantissa << shift_left_amount
        } else {
            full_mantissa >> shift_right_amount
        }
    } else {
        0
    };

    // Apply sign
    let signed_result: i64 = if sign == 1 {
        -(shifted_value as i64)
    } else {
        shifted_value as i64
    };

    // Return based on conditions
    if is_special {
        Option::none()
    } else if is_zero_or_denorm {
        Option::some(0)
    } else if truncates_to_zero {
        Option::some(0)
    } else if out_of_range {
        Option::none()
    } else {
        Option::some(signed_result)
    }
}

/// Cast xs:double to xs:integer (truncation toward zero)
/// xs:integer($arg as xs:double) -> xs:integer
///
/// Returns None if the value is NaN, Infinity, or out of range.
pub fn cast_double_to_integer(d: XsdDouble) -> Option<i64> {
    let bits = d.to_bits();
    let sign = (bits >> 63) & 1;
    let exp = ((bits >> 52) & 0x7FF) as u32;
    let mant = bits & 0xFFFFFFFFFFFFF;

    // Check for NaN or infinity (exp == 2047)
    let is_special = exp == 2047;

    // Check for zero or denormal (exp == 0)
    let is_zero_or_denorm = exp == 0;

    // Unbias the exponent (bias is 1023), but clamp for safety
    // For exp=2047 (special), this gives 1024, but we won't use it
    let unbiased_exp: i32 = (exp as i32) - 1023;

    // If exponent is negative, value is < 1, truncates to 0
    let truncates_to_zero = unbiased_exp < 0;

    // If exponent is too large (> 62), value exceeds i64 range
    let out_of_range = unbiased_exp > 62;

    // Determine if we need to compute a shift at all
    // Only compute shift for normal values in range
    let needs_computation = !is_special & !is_zero_or_denorm & !truncates_to_zero & !out_of_range;

    // Add implicit leading 1 to mantissa (53 bits total)
    let full_mantissa: u64 = mant | 0x10000000000000;

    // Calculate safe shift amounts - clamp to valid range [0, 63]
    // When needs_computation is false, these values don't matter
    let clamped_exp: i32 = if unbiased_exp < 0 {
        0
    } else if unbiased_exp > 62 {
        62
    } else {
        unbiased_exp
    };

    let shift_left_amount: u64 = if clamped_exp >= 52 {
        (clamped_exp - 52) as u64
    } else {
        0
    };
    let shift_right_amount: u64 = if clamped_exp < 52 {
        (52 - clamped_exp) as u64
    } else {
        0
    };

    // Only compute shifted value when needed (using clamped safe values)
    let shifted_value: u64 = if needs_computation {
        if clamped_exp >= 52 {
            full_mantissa << shift_left_amount
        } else {
            full_mantissa >> shift_right_amount
        }
    } else {
        0
    };

    // Apply sign
    let signed_result: i64 = if sign == 1 {
        -(shifted_value as i64)
    } else {
        shifted_value as i64
    };

    // Return based on conditions
    if is_special {
        Option::none()
    } else if is_zero_or_denorm {
        Option::some(0)
    } else if truncates_to_zero {
        Option::some(0)
    } else if out_of_range {
        Option::none()
    } else {
        Option::some(signed_result)
    }
}

/// Cast xs:double to xs:float (narrowing conversion)
/// xs:float($arg as xs:double) -> xs:float
///
/// Converts double to float with potential precision loss and overflow/underflow.
/// Uses XsdDouble::from_float in reverse via bit manipulation.
pub fn cast_double_to_float(d: XsdDouble) -> XsdFloat {
    let bits64 = d.to_bits();
    let sign: u32 = ((bits64 >> 63) & 1) as u32;
    let exp64 = ((bits64 >> 52) & 0x7FF) as u32;
    let mant64: u64 = bits64 & 0xFFFFFFFFFFFFF;

    // Handle zero
    let is_zero = (exp64 == 0) & (mant64 == 0);

    // Handle infinity or NaN (exp == 2047)
    let is_infinity = (exp64 == 2047) & (mant64 == 0);
    let is_nan = (exp64 == 2047) & (mant64 != 0);

    // Handle denormal double (exp == 0, mant != 0)
    let is_denorm = (exp64 == 0) & (mant64 != 0);

    // Convert exponent: unbias from 1023, rebias to 127
    let unbiased_exp: i32 = (exp64 as i32) - 1023;
    let new_exp: i32 = unbiased_exp + 127;

    // Check for overflow (becomes infinity in float)
    let is_overflow = new_exp >= 255;

    // Check for underflow (becomes zero in float)
    let is_underflow = new_exp <= 0;

    // Truncate mantissa from 52 bits to 23 bits
    let mant32: u32 = ((mant64 >> 29) & 0x7FFFFF) as u32;

    // Build result bits
    let zero_bits: u32 = sign << 31;
    let inf_bits: u32 = (sign << 31) | 0x7F800000;
    let nan_bits: u32 = 0x7FC00000; // Quiet NaN
    let normal_bits: u32 = (sign << 31) | ((new_exp as u32) << 23) | mant32;

    let result_bits = if is_zero {
        zero_bits
    } else if is_nan {
        nan_bits
    } else if is_infinity {
        inf_bits
    } else if is_denorm {
        zero_bits // Denormal doubles become zero in float
    } else if is_overflow {
        inf_bits
    } else if is_underflow {
        zero_bits
    } else {
        normal_bits
    };

    XsdFloat::from_bits(result_bits)
}

"""
CORDIC Algorithm Model for Accuracy Analysis
Supports Circular (m=1) and Linear (m=0) modes in Rotation mode
"""

import numpy as np
import matplotlib.pyplot as plt

class CORDICModel:
    def __init__(self, n_iterations=16, word_length=32, frac_bits=28):
        """
        Initialize CORDIC model
        
        Parameters:
        - n_iterations: Number of CORDIC iterations
        - word_length: Total bit width (including sign bit)
        - frac_bits: Number of fractional bits
        """
        self.n_iterations = n_iterations
        self.word_length = word_length
        self.frac_bits = frac_bits
        self.int_bits = word_length - frac_bits
        
        # Compute scaling factors and arctangent tables
        self._compute_constants()
        
    def _compute_constants(self):
        """Precompute CORDIC constants"""
        # Circular mode (m=1): K_circular
        K_circular = 1.0
        for i in range(self.n_iterations):
            K_circular *= np.sqrt(1 + 2**(-2*i))
        self.K_circular = K_circular
        
        # Linear mode (m=0): K_linear = 1 (no scaling needed)
        self.K_linear = 1.0
        
        # Arctangent table for circular mode
        self.atan_table = [np.arctan(2**(-i)) for i in range(self.n_iterations)]
        
        # Shift values for linear mode (just 2^-i)
        self.linear_table = [2**(-i) for i in range(self.n_iterations)]
        
    def fixed_point_convert(self, value):
        """Convert floating point to fixed point representation"""
        # Scale by 2^frac_bits
        scaled = value * (2 ** self.frac_bits)
        # Round to nearest integer
        rounded = int(np.round(scaled))
        # Clip to prevent overflow
        max_val = 2**(self.word_length - 1) - 1
        min_val = -(2**(self.word_length - 1))
        clipped = np.clip(rounded, min_val, max_val)
        return clipped
    
    def fixed_point_to_float(self, fixed_val):
        """Convert fixed point back to floating point"""
        return fixed_val / (2 ** self.frac_bits)
    
    def circular_rotation(self, x0, y0, z0, use_fixed_point=False):
        """
        CORDIC Circular Rotation Mode (m=1)
        Computes: x_n = K(x0*cos(z0) - y0*sin(z0))
                  y_n = K(y0*cos(z0) + x0*sin(z0))
                  z_n = 0
        
        For sin/cos calculation: x0=1/K, y0=0, z0=angle
        Result: x_n = cos(angle), y_n = sin(angle)
        """
        if use_fixed_point:
            x = self.fixed_point_convert(x0)
            y = self.fixed_point_convert(y0)
            z = self.fixed_point_convert(z0)
        else:
            x, y, z = x0, y0, z0
        
        iterations_data = []
        
        for i in range(self.n_iterations):
            if use_fixed_point:
                # Fixed-point arithmetic
                d = -1 if z < 0 else 1
                
                x_new = x - d * (y >> i)
                y_new = y + d * (x >> i)
                z_new = z - d * self.fixed_point_convert(self.atan_table[i])
                
                x, y, z = x_new, y_new, z_new
            else:
                # Floating-point arithmetic
                d = -1 if z < 0 else 1
                
                x_new = x - d * y * (2**(-i))
                y_new = y + d * x * (2**(-i))
                z_new = z - d * self.atan_table[i]
                
                x, y, z = x_new, y_new, z_new
            
            if use_fixed_point:
                iterations_data.append({
                    'iter': i,
                    'x': self.fixed_point_to_float(x),
                    'y': self.fixed_point_to_float(y),
                    'z': self.fixed_point_to_float(z)
                })
            else:
                iterations_data.append({
                    'iter': i,
                    'x': x,
                    'y': y,
                    'z': z
                })
        
        if use_fixed_point:
            return (self.fixed_point_to_float(x), 
                    self.fixed_point_to_float(y), 
                    self.fixed_point_to_float(z),
                    iterations_data)
        else:
            return x, y, z, iterations_data
    
    def linear_rotation(self, x0, y0, z0, use_fixed_point=False):
        """
        CORDIC Linear Rotation Mode (m=0)
        Computes: x_n = x0
                  y_n = y0 + x0*z0
                  z_n = 0
        
        For multiplication: x0=multiplicand, y0=0, z0=multiplier
        Result: y_n = x0 * z0
        """
        if use_fixed_point:
            x = self.fixed_point_convert(x0)
            y = self.fixed_point_convert(y0)
            z = self.fixed_point_convert(z0)
        else:
            x, y, z = x0, y0, z0
        
        iterations_data = []
        
        for i in range(self.n_iterations):
            if use_fixed_point:
                # Fixed-point arithmetic
                d = -1 if z < 0 else 1
                
                x_new = x  # x remains constant in linear mode
                y_new = y + d * (x >> i)
                z_new = z - d * self.fixed_point_convert(self.linear_table[i])
                
                x, y, z = x_new, y_new, z_new
            else:
                # Floating-point arithmetic
                d = -1 if z < 0 else 1
                
                x_new = x
                y_new = y + d * x * (2**(-i))
                z_new = z - d * (2**(-i))
                
                x, y, z = x_new, y_new, z_new
            
            if use_fixed_point:
                iterations_data.append({
                    'iter': i,
                    'x': self.fixed_point_to_float(x),
                    'y': self.fixed_point_to_float(y),
                    'z': self.fixed_point_to_float(z)
                })
            else:
                iterations_data.append({
                    'iter': i,
                    'x': x,
                    'y': y,
                    'z': z
                })
        
        if use_fixed_point:
            return (self.fixed_point_to_float(x), 
                    self.fixed_point_to_float(y), 
                    self.fixed_point_to_float(z),
                    iterations_data)
        else:
            return x, y, z, iterations_data
    
    def compute_sin_cos(self, angle, use_fixed_point=False):
        """
        Compute sin and cos using CORDIC circular mode
        
        Parameters:
        - angle: Input angle in radians (should be in range [-π/2, π/2] for best accuracy)
        - use_fixed_point: Whether to use fixed-point arithmetic
        
        Returns:
        - (cos_result, sin_result, error_cos, error_sin)
        """
        # Normalize angle to [-π/2, π/2] range
        # CORDIC circular mode works best in this range
        angle_normalized = angle
        quadrant_adjust = False
        sign_adjust = 1
        
        # Reduce angle to [-π, π]
        while angle_normalized > np.pi:
            angle_normalized -= 2*np.pi
        while angle_normalized < -np.pi:
            angle_normalized += 2*np.pi
        
        # Map to [-π/2, π/2]
        if angle_normalized > np.pi/2:
            angle_normalized = np.pi - angle_normalized
            quadrant_adjust = True
        elif angle_normalized < -np.pi/2:
            angle_normalized = -np.pi - angle_normalized
            quadrant_adjust = True
            sign_adjust = -1
        
        # Initialize with x0 = 1/K, y0 = 0, z0 = angle
        x0 = 1.0 / self.K_circular
        y0 = 0.0
        z0 = angle_normalized
        
        x_n, y_n, z_n, iterations = self.circular_rotation(x0, y0, z0, use_fixed_point)
        
        # Apply quadrant corrections if needed
        if quadrant_adjust:
            x_n = -x_n
        
        # True values
        true_cos = np.cos(angle)
        true_sin = np.sin(angle)
        
        # Errors
        error_cos = abs(x_n - true_cos)
        error_sin = abs(y_n - true_sin)
        
        return x_n, y_n, error_cos, error_sin, iterations
    
    def compute_multiply(self, a, b, use_fixed_point=False):
        """
        Compute multiplication a * b using CORDIC linear mode
        
        Parameters:
        - a: First operand
        - b: Second operand
        - use_fixed_point: Whether to use fixed-point arithmetic
        
        Returns:
        - (result, error)
        """
        x0 = a
        y0 = 0.0
        z0 = b
        
        x_n, y_n, z_n, iterations = self.linear_rotation(x0, y0, z0, use_fixed_point)
        
        # True value
        true_result = a * b
        
        # Error
        error = abs(y_n - true_result)
        
        return y_n, error, iterations


def analyze_accuracy():
    """Analyze CORDIC accuracy for different iteration counts"""
    
    print("="*70)
    print("CORDIC ACCURACY ANALYSIS")
    print("="*70)
    
    # Test different iteration counts
    iteration_counts = [8, 12, 16, 20, 24]
    word_length = 32
    frac_bits = 28
    
    test_angles = [0, np.pi/6, np.pi/4, np.pi/3, np.pi/2, 3*np.pi/4]
    test_multiplications = [(0.5, 0.5), (0.7, 0.3), (0.9, 0.8), (1.5, 2.0)]
    
    print(f"\nConfiguration: Word Length = {word_length}, Fractional Bits = {frac_bits}\n")
    
    # Circular mode analysis
    print("-"*70)
    print("CIRCULAR MODE (Sin/Cos Calculation)")
    print("-"*70)
    
    for n_iter in iteration_counts:
        cordic = CORDICModel(n_iterations=n_iter, word_length=word_length, frac_bits=frac_bits)
        
        max_cos_error = 0
        max_sin_error = 0
        
        for angle in test_angles:
            cos_val, sin_val, err_cos, err_sin, _ = cordic.compute_sin_cos(angle, use_fixed_point=True)
            max_cos_error = max(max_cos_error, err_cos)
            max_sin_error = max(max_sin_error, err_sin)
        
        print(f"Iterations: {n_iter:2d} | Max Cos Error: {max_cos_error:.2e} | Max Sin Error: {max_sin_error:.2e}")
    
    # Linear mode analysis
    print("\n" + "-"*70)
    print("LINEAR MODE (Multiplication)")
    print("-"*70)
    
    for n_iter in iteration_counts:
        cordic = CORDICModel(n_iterations=n_iter, word_length=word_length, frac_bits=frac_bits)
        
        max_mult_error = 0
        
        for a, b in test_multiplications:
            result, error, _ = cordic.compute_multiply(a, b, use_fixed_point=True)
            max_mult_error = max(max_mult_error, error)
        
        print(f"Iterations: {n_iter:2d} | Max Multiplication Error: {max_mult_error:.2e}")
    
    # Recommended configuration
    print("\n" + "="*70)
    print("RECOMMENDATION")
    print("="*70)
    print(f"For acceptable accuracy (<1e-6 error):")
    print(f"  - Minimum iterations: 16")
    print(f"  - Word length: 32 bits")
    print(f"  - Fractional bits: 28 bits")
    print(f"  - Integer bits: 4 bits (including sign)")
    print("="*70)


def detailed_example():
    """Show detailed example of CORDIC execution"""
    
    print("\n" + "="*70)
    print("DETAILED EXECUTION EXAMPLE")
    print("="*70)
    
    cordic = CORDICModel(n_iterations=16, word_length=32, frac_bits=28)
    
    # Example 1: Sin/Cos calculation
    angle = np.pi / 4  # 45 degrees
    print(f"\nExample 1: Computing sin({angle:.4f}) and cos({angle:.4f})")
    print(f"Expected: cos = {np.cos(angle):.10f}, sin = {np.sin(angle):.10f}")
    
    cos_val, sin_val, err_cos, err_sin, iterations = cordic.compute_sin_cos(angle, use_fixed_point=True)
    
    print(f"CORDIC Result: cos = {cos_val:.10f}, sin = {sin_val:.10f}")
    print(f"Errors: cos_err = {err_cos:.2e}, sin_err = {err_sin:.2e}")
    
    # Example 2: Multiplication
    a, b = 1.5, 0.75
    print(f"\nExample 2: Computing {a} * {b}")
    print(f"Expected: {a * b:.10f}")
    
    result, error, iterations = cordic.compute_multiply(a, b, use_fixed_point=True)
    
    print(f"CORDIC Result: {result:.10f}")
    print(f"Error: {error:.2e}")
    
    # Print scaling factors
    print(f"\nScaling Factors:")
    print(f"  K_circular = {cordic.K_circular:.10f}")
    print(f"  1/K_circular = {1/cordic.K_circular:.10f}")
    print(f"  K_linear = {cordic.K_linear:.10f}")


if __name__ == "__main__":
    analyze_accuracy()
    detailed_example()

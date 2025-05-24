//
//  Array + Float.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-23.
//

import Accelerate


extension MultiArray<Float> {
    
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public prefix static func - (array: MultiArray<Float>) -> MultiArray<Float> {
        let result = MultiArray.allocate(array.shape)
        vDSP_vneg(array.baseAddress, 1, result.baseAddress, 1, vDSP_Length(array.count))
        
        return result
    }
    
    @inlinable
    public func negate() {
        vDSP_vneg(self.baseAddress, 1, self.baseAddress, 1, vDSP_Length(self.count))
    }
    
    
    
    /// Performs element-wise addition on two matrices.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func + (lhs: MultiArray<Float>, rhs: MultiArray<Float>) -> MultiArray<Float> {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        let result = MultiArray.allocate(lhs.shape)
        vDSP_vadd(lhs.baseAddress, 1, rhs.baseAddress, 1, result.baseAddress, 1, vDSP_Length(lhs.count))
        
        return result
    }
    
    /// Performs element-wise addition on two matrices.
    @inlinable
    public static func += (lhs: inout MultiArray<Float>, rhs: MultiArray<Float>) {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        vDSP_vadd(lhs.baseAddress, 1, rhs.baseAddress, 1, lhs.baseAddress, 1, vDSP_Length(lhs.count))
    }
    
    /// Performs element-wise subtraction on two matrices.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func - (lhs: MultiArray<Float>, rhs: MultiArray<Float>) -> MultiArray<Float> {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        let result = MultiArray.allocate(lhs.shape)
        vDSP_vsub(lhs.baseAddress, 1, rhs.baseAddress, 1, result.baseAddress, 1, vDSP_Length(lhs.count))
        
        return result
    }
    
    /// Performs element-wise subtraction on two matrices.
    @inlinable
    public static func -= (lhs: inout MultiArray<Float>, rhs: MultiArray<Float>) {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        vDSP_vsub(lhs.baseAddress, 1, rhs.baseAddress, 1, lhs.baseAddress, 1, vDSP_Length(lhs.count))
    }
    
    /// Performs element-wise multiplication.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func * (lhs: MultiArray<Float>, factor: Float) -> MultiArray<Float> {
        let result = MultiArray.allocate(lhs.shape)
        
        withUnsafePointer(to: factor) { factor in
            vDSP_vsmul(lhs.baseAddress, 1, factor, result.baseAddress, 1, vDSP_Length(lhs.count))
        }
        
        return result
    }
    
    /// Performs element-wise multiplication.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func * (factor: Float, lhs: MultiArray<Float>) -> MultiArray<Float> {
        lhs * factor
    }
    
    /// Performs element-wise multiplication.
    @inlinable
    public static func *= (lhs: inout MultiArray<Float>, factor: Float) {
        withUnsafePointer(to: factor) { factor in
            vDSP_vsmul(lhs.baseAddress, 1, factor, lhs.baseAddress, 1, vDSP_Length(lhs.count))
        }
    }
    
    
}

//
//  Array + Float + Multiplication.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Accelerate


extension MultiArray where Element == Float {
    
    /// Performs element-wise multiplication.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func * (lhs: MultiArray<Float>, factor: Float) -> MultiArray<Float> {
        let result = MultiArray.conditionalAllocate(referencing: lhs)
        
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
    
    
    /// Performs element-wise division.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func / (lhs: MultiArray<Float>, factor: Float) -> MultiArray<Float> {
        var result = MultiArray.conditionalAllocate(referencing: lhs)
        vDSP.divide(lhs, factor, result: &result)
        return result
    }
    
    /// Performs element-wise division.
    ///
    /// > Optimization Tip:
    /// > Use mutating alternative to prevent additional memory allocation.
    @inlinable
    public static func / (factor: Float, rhs: MultiArray<Float>) -> MultiArray<Float> {
        var result = MultiArray.conditionalAllocate(referencing: rhs)
        vDSP.divide(factor, rhs, result: &result)
        return result
    }
    
    /// Performs element-wise division.
    @inlinable
    public static func /= (lhs: inout MultiArray<Float>, factor: Float) {
        vDSP.divide(lhs, factor, result: &lhs)
    }
    
}

//
//  Array + Float.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-23.
//

import Accelerate


extension MultiArray<Float> {
    
    @inlinable
    public prefix static func - (array: MultiArray<Float>) -> MultiArray<Float> {
        let result = MultiArray.conditionalAllocate(referencing: array)
        vDSP_vneg(array.baseAddress, 1, result.baseAddress, 1, vDSP_Length(array.count))
        
        return result
    }
    
    @inlinable
    public func negate() {
        vDSP_vneg(self.baseAddress, 1, self.baseAddress, 1, vDSP_Length(self.count))
    }
    
    /// Performs element-wise addition on two matrices.
    @inlinable
    public static func + (lhs: MultiArray<Float>, rhs: MultiArray<Float>) -> MultiArray<Float> {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        let result = MultiArray.conditionalAllocate(referencing: lhs)
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
    @inlinable
    public static func - (lhs: MultiArray<Float>, rhs: MultiArray<Float>) -> MultiArray<Float> {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        let result = MultiArray.conditionalAllocate(referencing: lhs)
        vDSP_vsub(lhs.baseAddress, 1, rhs.baseAddress, 1, result.baseAddress, 1, vDSP_Length(lhs.count))
        
        return result
    }
    
    /// Performs element-wise subtraction on two matrices.
    @inlinable
    public static func -= (lhs: inout MultiArray<Float>, rhs: MultiArray<Float>) {
        assert(lhs.shape == rhs.shape, "Cannot add MultiArrays of shapes \(lhs.shape) and \(rhs.shape)")
        
        vDSP_vsub(lhs.baseAddress, 1, rhs.baseAddress, 1, lhs.baseAddress, 1, vDSP_Length(lhs.count))
    }
}


/// Returns the absolute value of each element in the supplied single-precision vector.
public func abs(_ input: MultiArray<Float>) -> MultiArray<Float> {
    var result = MultiArray.conditionalAllocate(referencing: input)
    vDSP.absolute(input, result: &result)
    return result
}

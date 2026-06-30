//
//  Float + Utils.swift
//  MultiArray
//
//  Created by Vaida on 2025-06-09.
//

import Accelerate


extension MultiArray<Float> {
    
    /// Returns the elements of a single-precision vector clipped to the specified range.
    @inlinable
    public func clip(to range: ClosedRange<Float>) {
        var result = self
        vDSP.clip(self, to: range, result: &result)
    }
    
    /// Populates a single-precision vector with a specified scalar value.
    @inlinable
    public func fill(with value: Float) {
        var result = self
        vDSP.fill(&result, with: value)
    }
    
    @inlinable
    public func min() -> Float {
        vDSP.minimum(self)
    }
    
    @inlinable
    public func max() -> Float {
        vDSP.maximum(self)
    }
    
    /// Applies the `sigmoid` function.
    ///
    /// - Complexity: O(*n*), in-place mutation.
    ///
    /// - Experiment: This may not be the optimal implementation, it seems that using `BNNS` could be faster.
    @inlinable
    public func sigmoid() {
        let count = vDSP_Length(self.count)
        var one: Float = 1.0
        vDSP_vneg(baseAddress, 1, baseAddress, 1, count) // Negate the values
        var _count = Int32(count)
        vvexpf(baseAddress, baseAddress, &_count)          // Apply exp to each value
        vDSP_vsadd(baseAddress, 1, &one, baseAddress, 1, count) // Add 1 to each value
        vvrecf(baseAddress, baseAddress, &_count) // Divide 1 by each value
    }
    
}

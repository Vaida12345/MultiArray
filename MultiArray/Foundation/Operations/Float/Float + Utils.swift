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
    
}

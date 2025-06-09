//
//  Float + Init.swift
//  MultiArray
//
//  Created by Vaida on 2025-06-09.
//

import Accelerate


extension MultiArray<Float> {
    
    @inlinable
    public static func stride(
        from start: Element,
        through end: Element,
        count: Int
    ) -> MultiArray {
        var result = MultiArray.allocate([count])
        vDSP.formRamp(in: start ... end, result: &result)
        return result
    }
    
    @inlinable
    public static func stride(
        from start: Element,
        by stride: Element,
        count: Int
    ) -> MultiArray {
        var result = MultiArray.allocate([count])
        vDSP.formRamp(withInitialValue: start, increment: stride, result: &result)
        return result
    }
    
}

//
//  Float + Special.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Accelerate


extension MultiArray where Element == Float {
    
    /// - precondition: self is Matrix (ie, 2D array)
    @inlinable
    public func multiplyColumn(_ column: MultiArray<Float>) {
        assert(self.shape.count == 2)
        assert(column.shape.count == 1)
        assert(self.shape[1] == column.shape[0])
        
        // for each column
        for i in 0..<self.shape[1] {
            var result = self.view(at: [i])
            vDSP.multiply(column.buffer[i], self.view(at: [i]), result: &result)
        }
    }
    
    /// - precondition: self is Matrix (ie, 2D array)
    @inlinable
    public func transposed() -> MultiArray<Float> {
        assert(self.shape.count == 2)
        
        let buffer = MultiArray.allocate(shape[1], shape[0])
        vDSP_mtrans(self.baseAddress, 1, buffer.baseAddress, 1, vDSP_Length(self.shape[1]), vDSP_Length(self.shape[0]))
        return buffer
    }
    
}

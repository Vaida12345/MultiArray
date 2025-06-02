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
    public func multiplyEachRow(byEachOf row: MultiArray<Float>) {
        assert(self.shape.count == 2)
        assert(row.shape.count == 1)
        assert(self.shape[0] == row.shape[0])
        
        // for each row
        for i in 0..<self.shape[0] {
            var result = self.view(at: [i])
            vDSP.multiply(row.buffer[i], self.view(at: [i]), result: &result)
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

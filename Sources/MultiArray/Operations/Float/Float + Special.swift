//
//  Float + Special.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Accelerate


extension MultiArray where Element == Float {
    
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
    
}

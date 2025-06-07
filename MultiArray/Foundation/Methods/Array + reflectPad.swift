//
//  Array + reflectPad.swift
//  MultiArray
//
//  Created by Vaida on 2025-06-07.
//

import Essentials


extension MultiArray {
    
    /// Pads the `MultiArray` using the reflection of `self` boundary.
    @inlinable
    public func reflectionPad(size pad: Int) -> MultiArray {
        assert(self.shape.count == 1)
        assert(pad <= self.count - 1, "Invalid pad size")
        
        let result = MultiArray.allocate([self.count + 2 * pad])
        
        // copy center
        (result.baseAddress + pad).copy(from: self.baseAddress, count: self.count)
        
        var i = 0
        while i < pad {
            // left pad
            result.buffer.initializeElement(at: i, to: self.buffer[pad &- i])
            
            // right pad
            result.buffer.initializeElement(at: i &+ pad &+ self.count, to: self.buffer[self.count &- 2 &- i])
            
            i &+= 1
        }
        
        return result
    }
    
}

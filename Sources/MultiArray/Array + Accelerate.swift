//
//  Array + Accelerate.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Accelerate


extension MultiArray: AccelerateMutableBuffer {
    
    public func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R {
        var buffer = self.buffer // it should never change the address.
        return try body(&buffer)
    }
    
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        try body(UnsafeBufferPointer(self.buffer))
    }
    
}

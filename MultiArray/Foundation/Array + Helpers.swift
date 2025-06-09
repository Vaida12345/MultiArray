//
//  Array + Helpers.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-22.
//

import Foundation


extension MultiArray {
    
    public static func contiguousStrides(shape: [Int]) -> UnsafeMutableBufferPointer<Int> {
        let buffer = UnsafeMutableBufferPointer<Int>.allocate(capacity: shape.count)
        buffer.initializeElement(at: shape.count - 1, to: 1)
        // [5, 4, 3, 2]
        for i in Swift.stride(from: shape.count - 1, to: 0, by: -1) {
            buffer.initializeElement(at: i - 1, to: shape[i] * (i == 0 ? 1 : buffer[i]))
        }
        return buffer
    }
    
}

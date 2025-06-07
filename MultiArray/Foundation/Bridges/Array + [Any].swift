//
//  Array + bridge.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Essentials
import Foundation


extension MultiArray {
    
    /// Initialize using the given array.
    @inlinable
    public convenience init(_ array: [Element]) {
        let buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: array.count)
        _ = array.withUnsafeBytes {
            buffer.copy(from: $0.baseAddress!, count: buffer.count)
        }
        self.init(bytesNoCopy: buffer, shape: [buffer.count], deallocator: .free)
    }
    
    /// Initialize using the given array.
    @inlinable
    public convenience init(_ array: [[Element]]) {
        let shape = [array.count, array.first?.count ?? 0]
        assert(array.allSatisfy({ $0.count == shape[1] }))
        
        let buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: shape.reduce(1, *))
        var offset = 0
        for array in array {
            _ = array.withUnsafeBytes {
                memcpy(buffer.baseAddress! + offset, $0.baseAddress!, array.count * MemoryLayout<Element>.stride)
            }
            offset &+= array.count
        }
        
        self.init(bytesNoCopy: buffer, shape: shape, deallocator: .free)
    }
    
    /// Initialize using the given array.
    @inlinable
    public convenience init(_ array: [[[Element]]]) {
        let shape = [array.count, array.first?.count ?? 0, array.first?.first?.count ?? 0]
        assert(array.allSatisfy({ $0.count == shape[1] && $0.allSatisfy({ $0.count == shape[2] }) }))
        
        let buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: shape.reduce(1, *))
        var offset = 0
        for array in array {
            for array in array {
                _ = array.withUnsafeBytes {
                    memcpy(buffer.baseAddress! + offset, $0.baseAddress!, array.count * MemoryLayout<Element>.stride)
                }
                offset &+= array.count
            }
        }
        
        self.init(bytesNoCopy: buffer, shape: shape, deallocator: .free)
    }
    
}


extension Array {
    
    /// Calls the given closure with a pointer to the array's mutable contiguous storage.
    @inlinable
    public mutating func withMultiArray<R>(_ body: (MultiArray<Element>) throws -> R) rethrows -> R {
        try self.withUnsafeMutableBufferPointer {
            let array = MultiArray(bytesNoCopy: $0, shape: [$0.count], deallocator: .none)
            return try body(array)
        }
    }
    
    /// Creates array using the given `MultiArray`.
    @inlinable
    public init(_ array: MultiArray<Element>) {
        self.init(array.buffer)
    }
    
}

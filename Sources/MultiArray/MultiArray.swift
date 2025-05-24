//
//  MultiArray.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import Foundation


/// A collection type that stores numeric values in an array with multiple dimensions.
public final class MultiArray<Element>: @unchecked Sendable {
    
    /// The underlying buffer.
    ///
    /// Unlike `torch.tenor`, this property is always in contiguous `row-major` form.
    public let buffer: UnsafeMutableBufferPointer<Element>
    
    @usableFromInline
    var deallocator: Data.Deallocator
    
    /// The array multidimensional shape as a number array in which each element’s value is the size of the corresponding dimension.
    public let shape: [Int]
    
    /// A number array in which each element is the number of memory locations that span the length of the corresponding dimension.
    public let strides: [Int]
    
    @inlinable
    public var baseAddress: UnsafeMutablePointer<Element> {
        self.buffer.baseAddress!
    }
    
    /// The number of elements in the `MultiArray`.
    @inlinable
    public var count: Int {
        self.buffer.count
    }
    
    
    @inlinable
    public init(
        bytesNoCopy buffer: UnsafeMutableBufferPointer<Element>,
        shape: [Int],
        deallocator: Data.Deallocator
    ) {
        assert(!shape.isEmpty && shape.allSatisfy({ $0 > 0 }), "Invalid shape")
        assert(buffer.count == shape.reduce(1, *), "Invalid shape \(shape) and buffer size \(buffer.count)")
        
        self.buffer = buffer
        self.deallocator = deallocator
        self.shape = shape
        self.strides = MultiArray.contiguousStrides(shape: shape)
    }
    
    @inlinable
    deinit {
        switch self.deallocator {
        case .free:
            buffer.deallocate()
        case .unmap:
            munmap(self.baseAddress, self.buffer.count * MemoryLayout<Element>.stride)
        case .none:
            break
        case .custom(let deallocator):
            deallocator(UnsafeMutableRawPointer(self.baseAddress), self.buffer.count * MemoryLayout<Element>.stride)
        case .virtualMemory:
            fatalError("Not Implemented")
        @unknown default:
            fatalError()
        }
    }
    
    
}

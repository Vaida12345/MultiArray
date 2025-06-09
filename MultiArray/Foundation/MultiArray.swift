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
    ///
    /// `self` owns this buffer.
    public let buffer: UnsafeMutableBufferPointer<Element>
    
    @usableFromInline
    var deallocator: Data.Deallocator
    
    /// See Array + Copy.swift
    @usableFromInline
    internal let operatorsShouldReturnCopiedSelf: OperatorsShouldReturnCopiedSelf
    
    /// The array multidimensional shape as a number array in which each element’s value is the size of the corresponding dimension.
    ///
    /// For a 2D array (matrix), the shapes are in height-width order.
    public let shape: [Int]
    
    /// A number array in which each element is the number of memory locations that span the length of the corresponding dimension.
    ///
    /// `self` owns this buffer.
    public let strides: UnsafeMutableBufferPointer<Int>
    
    /// The base address underlying buffer
    @inlinable
    public var baseAddress: UnsafeMutablePointer<Element> {
        self.buffer.baseAddress!
    }
    
    /// The number of elements in the `MultiArray`.
    @inlinable
    public var count: Int {
        self.buffer.count
    }
    
    /// Returns and gives up ownership towards the underlying buffer.
    ///
    /// `self` no longer owns the returned buffer, and you are responsible for its deallocation.
    ///
    /// - precondition: The underlying buffer must be allocated by itself (``allocate(_:)-(Int...)``) or by referencing explicit a buffer that you own (``init(bytesNoCopy:shape:deallocator:)-(UnsafeMutablePointer<Element>,_,_)``). This method does not work when the ownership is indirect (initialize from `MLMultiArray`).
    @inlinable
    public func moved() -> UnsafeMutableBufferPointer<Element> {
        switch self.deallocator {
        case .free, .none: break
        default: preconditionFailure("Cannot remove ownership when it is indirect.")
        }
        
        self.deallocator = .none
        return self.buffer
    }
    
    
    @inlinable
    internal init(
        bytesNoCopy buffer: UnsafeMutableBufferPointer<Element>,
        shape: [Int],
        deallocator: Data.Deallocator,
        operatorsShouldReturnCopiedSelf: OperatorsShouldReturnCopiedSelf
    ) {
        assert(shape.allSatisfy({ $0 >= 0 }), "Invalid shape")
        assert(buffer.count == shape.reduce(1, *), "Invalid shape \(shape) and buffer size \(buffer.count)")
        
        self.buffer = buffer
        self.deallocator = deallocator
        self.shape = shape
        self.strides = MultiArray.contiguousStrides(shape: shape)
        self.operatorsShouldReturnCopiedSelf = operatorsShouldReturnCopiedSelf
    }
    
    @inlinable
    deinit {
        self.strides.deallocate()
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

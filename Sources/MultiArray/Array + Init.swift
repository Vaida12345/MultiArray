//
//  MultiArray + Init.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import Essentials
import Foundation
import Accelerate


extension MultiArray {
    
    @inlinable
    public static func allocate(_ shape: [Int]) -> MultiArray {
        let count = shape.reduce(1, *)
        return MultiArray(
            bytesNoCopy: UnsafeMutableBufferPointer<Element>.allocate(capacity: count),
            shape: shape,
            deallocator: .free
        )
    }
    
    @inlinable
    public static func allocate(_ shape: Int...) -> MultiArray {
        MultiArray.allocate(shape)
    }
    
    /// Allocate, and fill with `random(0, 1)`
    @inlinable
    public static func random(_ shape: Int...) -> MultiArray where Element: BinaryFloatingPoint, Element.RawSignificand: FixedWidthInteger {
        let result = MultiArray.allocate(shape)
        var i = 0
        while i < result.count {
            result.buffer.initializeElement(at: i, to: Element.random(in: 0...1))
            i &+= 1
        }
        return result
    }
    
    @inlinable
    public static func zeros(_ shape: Int...) -> MultiArray where Element == Float {
        let result = MultiArray.allocate(shape)
        vDSP_vclr(result.baseAddress, 1, vDSP_Length(result.count))
        return result
    }
    
    @inlinable
    public convenience init(
        bytesNoCopy buffer: UnsafeMutableBufferPointer<Element>,
        shape: [Int],
        deallocator: Data.Deallocator
    ) {
        self.init(
            bytesNoCopy: buffer,
            shape: shape,
            deallocator: deallocator,
            operatorsShouldReturnCopiedSelf: OperatorsShouldReturnCopiedSelf()
        )
    }
    
    @inlinable
    public convenience init(
        copying source: UnsafeMutableBufferPointer<Element>,
        shape: [Int]
    ) {
        assert(shape.count >= 1, "Invalid shape")
        assert(source.count == shape.reduce(1, *), "Invalid shape \(shape) and buffer size \(source.count)")
        
        let buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: source.count)
        source.baseAddress!.copy(to: buffer.baseAddress!, count: buffer.count)
        
        self.init(bytesNoCopy: buffer, shape: shape, deallocator: .free)
    }
    
    @inlinable
    public convenience init(
        bytesNoCopy: UnsafeMutablePointer<Element>,
        shape: [Int],
        deallocator: Data.Deallocator
    ) {
        let count = shape.reduce(1, *)
        self.init(bytesNoCopy: UnsafeMutableBufferPointer(start: bytesNoCopy, count: count), shape: shape, deallocator: deallocator)
    }
    
}

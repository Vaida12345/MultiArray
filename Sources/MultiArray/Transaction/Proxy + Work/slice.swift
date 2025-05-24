//
//  slice.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Essentials


extension MultiArray.TransactionProxy {
    
    @usableFromInline
    struct Slice: WorkProtocol {
        
        @usableFromInline
        let slices: [Range<Int>?]
        
        @inlinable
        func transformIndex(
            indexes: UnsafeMutableBufferPointer<Int>,
            shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
            strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
        ) -> Bool {
            var i = 0
            while i < slices.count {
                defer { i &+= 1 }
                guard let slice = slices[i] else { continue }
                guard slice.contains(indexes[i]) else { return false }
                indexes[i] &-= slice.lowerBound
            }
            return true
        }
        
        @inlinable
        func transformShape(shape: [Int]) -> [Int] {
            assert(shape.count == slices.count, "Invalid slices shape")
            return [Int](unsafeUninitializedCapacity: slices.count) { buffer, initializedCount in
                initializedCount = slices.count
                
                var i = 0
                while i < slices.count {
                    buffer.initializeElement(at: i, to: slices[i]?.count ?? shape[i])
                    i &+= 1
                }
            }
        }
        
        @inlinable
        init(slices: [Range<Int>?]) {
            self.slices = slices
        }
        
    }
    
    /// - parameter slice: The indexes for slices.
    ///
    /// - term `slices.element`: `nil` for keeping the entire range
    @inlinable
    public func sliced(_ slices: Range<Int>?...) -> Self {
        Self(works: self.works + [Slice(slices: slices)])
    }
    
}

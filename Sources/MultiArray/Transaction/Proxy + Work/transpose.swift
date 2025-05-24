//
//  transpose.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


extension MultiArray.TransactionProxy {
    
    @usableFromInline
    struct Transpose: WorkProtocol {
        
        @usableFromInline
        let lhs: Int
        @usableFromInline
        let rhs: Int
        
        @inlinable
        func transformIndex(
            indexes: UnsafeMutableBufferPointer<Int>,
            shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
            strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
        ) {
            swap(&(indexes.baseAddress! + lhs).pointee, &(indexes.baseAddress! + rhs).pointee)
        }
        
        @inlinable
        func transformShape(shape: [Int]) -> [Int] {
            var shape = shape
            shape.swapAt(lhs, rhs)
            return shape
        }
        
        @inlinable
        init(lhs: Int, rhs: Int) {
            self.lhs = lhs
            self.rhs = rhs
        }
        
    }
    
    @inlinable
    public func transposed(_ lhs: Int, _ rhs: Int) -> Self {
        Self(works: self.works + [Transpose(lhs: lhs, rhs: rhs)])
    }
    
}

//
//  transpose.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


extension MultiArray.TransactionProxy {
    
    @usableFromInline
    struct Reshape: WorkProtocol {
        
        @usableFromInline
        let shape: [Int]
        
        @inlinable
        func transformIndex(
            indexes: UnsafeMutableBufferPointer<Int>,
            shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
            strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
        ) -> Bool {
            var index = 0
            MultiArray<Float>.convertIndex(from: indexes, to: &index, strides: strides.curr)
            MultiArray<Float>.convertIndex(from: index, to: indexes, strides: strides.next)
            return true
        }
        
        @inlinable
        func transformShape(shape: [Int]) -> [Int] {
            let originalCount = shape.reduce(1, *)
            var newShape = self.shape
            if let negativeIndex = newShape.firstIndex(of: -1) {
                newShape[negativeIndex] = originalCount / newShape.reduce(1) { $0 * ($1 == -1 ? 1 : $1) }
            }
            assert(newShape.reduce(1, *) == originalCount, "Invalid Shape")
            
            return newShape
        }
        
        @inlinable
        init(shape: [Int]) {
            self.shape = shape
        }
        
    }
    
    @inlinable
    public func reshape(_ shape: [Int]) -> Self {
        let work = Reshape(shape: shape)
        self.works.append(work)
        self.shape = work.transformShape(shape: self.shape)
        return self
    }
    
    @inlinable
    public func reshape(_ shape: Int...) -> Self {
        self.reshape(shape)
    }
    
}

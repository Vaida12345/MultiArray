//
//  offset.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-25.
//

extension MultiArray.TransactionProxy {
    
    @usableFromInline
    struct Offset: WorkProtocol {
        
        @usableFromInline
        let offsets: [Int]
        
        @inlinable
        func transformIndex(
            indexes: UnsafeMutableBufferPointer<Int>,
            shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
            strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
        ) -> Bool {
            var i = 0
            while i < offsets.count {
                indexes[i] &+= offsets[i]
                
                i &+= 1
            }
            return true
        }
        
        @inlinable
        func transformShape(shape: [Int]) -> [Int] {
            []
        }
        
        @inlinable
        init(offsets: [Int]) {
            self.offsets = offsets
        }
        
    }
    
    /// Apply an offset
    ///
    /// - Warning: This method can only be used in `withTransaction(into:_:)`.
    @inlinable
    public func offset(_ offsets: Int...) -> Self {
        let work = Offset(offsets: offsets)
        self.works.append(work)
        self.shape = work.transformShape(shape: self.shape)
        return self
    }
    
}

//
//  Array + forEach.swift
//  MultiArray
//
//  Created by Vaida on 2026-07-07.
//

extension MultiArray {
    
    /// For each of the element in the array.
    ///
    /// - Complexity: O(*n*)
    @inlinable
    public func forEach(_ block: (_ indexes: Indexes, _ value: Element) -> Void) {
        var i = 0
        let iteratorCount = self.strides.count
        let iterator = UnsafeMutableBufferPointer<Int>.allocate(capacity: iteratorCount)
        iterator.initialize(repeating: 0)
        defer { iterator.deallocate() }
        
        let upperBound = self.count
        
        while i < upperBound {
            let value = self.buffer[i]
            block(Indexes(buffer: iterator, offset: i), value)
            
            iterator[iteratorCount &- 1] &+= 1
            
            // carry
            var ishape = iteratorCount &- 1
            while ishape != 0 {
                if iterator[ishape] == self.shape[ishape] {
                    iterator[ishape] = 0
                    iterator[ishape &- 1] &+= 1
                } else {
                    break
                }
                ishape &-= 1
            }
            
            i &+= 1
        }
    }
    
    @inlinable
    public nonisolated func initializeElement(at indexes: Indexes, to value: consuming Element) {
        (self.baseAddress + indexes.offset).initialize(to: value)
    }
    
    /// Subscripts at the given `offset`
    @inlinable
    public nonisolated subscript(indexes: Indexes) -> Element {
        get { self.buffer[indexes.offset] }
        set { self.buffer[indexes.offset] = newValue }
    }
    
    /// Subscript indexes created by `forEach`.
    public struct Indexes: RandomAccessCollection {
        @usableFromInline
        let buffer: UnsafeMutableBufferPointer<Int>
        public let offset: Int
        
        @inlinable
        init(buffer: UnsafeMutableBufferPointer<Int>, offset: Int) {
            self.buffer = buffer
            self.offset = offset
        }
        
        @inlinable
        public subscript(index: Int) -> Int {
            buffer[index]
        }
        
        @inlinable
        public var startIndex: Int { 0 }
        @inlinable
        public var endIndex: Int { buffer.count }
    }
    
}

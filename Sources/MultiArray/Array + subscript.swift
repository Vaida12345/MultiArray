//
//  MultiArray + subscript.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import Foundation


extension MultiArray {
    
    /// Returns the plain sequence at the given index.
    ///
    /// The `index` must points to an array, for example,
    /// ```swift
    /// let multiArray = MultiArray<Float>.allocate(shape: 4, 3, 2)
    /// multiArray.sequence(at: 0, 0) // returns the first sequence with two elements
    /// ```
    ///
    /// The returned buffer is owned by this `MultiArray`. Do not deallocate the returned buffer, and ensure `self` outlives the returned buffer.
    public nonisolated func sequence(at index: [Int]) -> UnsafeMutableBufferPointer<Element> {
        assert(index.count == shape.count - 1, "Invalid indexes")
        let startIndex = zip(index, self.strides.dropLast()).reduce(0) { $0 + $1.0 * $1.1 }
        return UnsafeMutableBufferPointer(start: self.baseAddress + startIndex, count: self.strides[self.strides.count - 2])
    }
    
    /// Initializes the element at `indexes` to the given value.
    ///
    /// The memory underlying the destination element must be uninitialized,
    /// or `Element` must be a trivial type. After a call to `initialize(to:)`,
    /// the memory underlying this element of the buffer is initialized.
    ///
    /// - Parameters:
    ///   - value: The value used to initialize the buffer element's memory.
    @inlinable
    public nonisolated func initializeElement(at indexes: [Int], to value: consuming Element) {
        assert(indexes.count == shape.count, "Invalid indexes")
        assert(zip(indexes, self.shape).allSatisfy(<), "Index out of range")
        var index = 0
        self.convertIndex(from: indexes, to: &index)
        
        self.buffer.initializeElement(at: index, to: consume value)
    }
    
    /// Returns a view of the `MultiArray` at the given `indexes`.
    ///
    /// This method mimics the subscripts on nested arrays.
    /// ```swift
    /// let array = [...]
    /// let multiArray = MultiArray(array)
    /// // multiArray.view(i, j) == array[i][j]
    /// ```
    @inlinable
    public func view(at indexes: [Int]) -> MultiArray {
        assert(indexes.count < self.strides.count, "Invalid indexes")
        let offset = zip(indexes + [Int](repeating: 0, count: self.strides.count - indexes.count), self.strides).reduce(0) { $0 + $1.0 * $1.1 }
        let shape = Array(self.shape.dropFirst(indexes.count))
        return MultiArray(bytesNoCopy: UnsafeMutableBufferPointer<Element>(start: self.baseAddress + offset, count: shape.reduce(1, *)),
                          shape: shape,
                          deallocator: captureReference())
    }
    
    /// For each of the element in the array.
    ///
    /// - Complexity: O(*n*)
    @inlinable
    public func forEach(_ block: (_ indexes: [Int], _ value: Element) -> Void) {
        var i = 0
        var indexes = [Int](repeating: 0, count: self.strides.count)
        while i != self.count {
            block(indexes, self.buffer[i])
            
            indexes[indexes.count - 1] &+= 1
            
            // carry
            var ishape = shape.count - 1
            while ishape != 0 {
                if indexes[ishape] == self.shape[ishape] {
                    indexes[ishape] = 0
                    indexes[ishape - 1] &+= 1
                } else {
                    break
                }
                ishape &-= 1
            }
            
            i &+= 1
        }
    }
    
    /// Subscripts at the given `indexes`.
    ///
    /// - Warning: The pointer at the given `indexes` must be initialized, otherwise use ``initializeElement(at:to:)`` instead.
    @inlinable
    public nonisolated subscript(_ indexes: [Int]) -> Element {
        get {
            assert(indexes.count == shape.count, "Invalid indexes")
            assert(zip(indexes, self.shape).allSatisfy(<), "Index out of range")
            var index = 0
            self.convertIndex(from: indexes, to: &index)
            
            return self.buffer[index]
        }
        set {
            assert(indexes.count == shape.count, "Invalid indexes")
            assert(zip(indexes, self.shape).allSatisfy(<), "Index out of range")
            var index = 0
            self.convertIndex(from: indexes, to: &index)
            
            self.buffer[index] = newValue
        }
    }
    
    /// Subscripts at the given `indexes`.
    ///
    /// - Warning: The pointer at the given `indexes` must be initialized, otherwise use ``initializeElement(at:to:)`` instead.
    @inlinable
    public nonisolated subscript(_ indexes: Int...) -> Element {
        get { self[indexes] }
        set { self[indexes] = newValue }
    }
    
}

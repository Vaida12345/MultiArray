//
//  MultiArray + subscript.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import Foundation


extension MultiArray {
    
    /// Returns a view at the plain sequence at the given index.
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
        assert(isValid(indexes: indexes), "Index out of range")
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
        return MultiArray(
            bytesNoCopy: UnsafeMutableBufferPointer<Element>(start: self.baseAddress + offset, count: shape.reduce(1, *)),
            shape: shape,
            deallocator: captureReference(),
            operatorsShouldReturnCopiedSelf: self.operatorsShouldReturnCopiedSelf
        )
    }
    
    /// For each of the element in the array.
    ///
    /// - Complexity: O(*n*)
    @inlinable
    public func forEach(_ block: (_ indexes: UnsafeMutableBufferPointer<Int>, _ value: Element) -> Void) {
        var i = 0
        let iterator = UnsafeMutableBufferPointer<Int>.allocate(capacity: self.strides.count)
        iterator.initialize(repeating: 0)
        defer {
            iterator.deallocate()
        }
        
        while i != self.count {
            let value = self.buffer[i]
            block(iterator, value)
            
            iterator[iterator.count - 1] &+= 1
            
            // carry
            var ishape = self.shape.count - 1
            while ishape != 0 {
                if iterator[ishape] == self.shape[ishape] {
                    iterator[ishape] = 0
                    iterator[ishape - 1] &+= 1
                } else {
                    break
                }
                ishape &-= 1
            }
            
            i &+= 1
        }
    }
    
    @inlinable
    func isValid(indexes: [Int]) -> Bool {
        var i = 0
        while i < indexes.count {
            guard indexes[i] < self.shape[i] else { return false }
            i += 1
        }
        return true
    }
    
    @inlinable
    func isValid(indexes: UnsafeMutableBufferPointer<Int>) -> Bool {
        var i = 0
        while i < indexes.count {
            guard indexes[i] < self.shape[i] else { return false }
            i += 1
        }
        return true
    }
    
    /// Subscripts at the given `indexes`.
    ///
    /// - Warning: The pointer at the given `indexes` must be initialized, otherwise use ``initializeElement(at:to:)`` instead.
    ///
    /// > Performance Consideration:
    /// > This subscript is not O(*1*), as index conversion is required.
    @inlinable
    public nonisolated subscript(_ indexes: [Int]) -> Element {
        get {
            assert(indexes.count == shape.count, "Invalid indexes")
            assert(isValid(indexes: indexes), "Index out of range")
            var index = 0
            self.convertIndex(from: indexes, to: &index)
            
            return self.buffer[index]
        }
        set {
            assert(indexes.count == shape.count, "Invalid indexes")
            assert(isValid(indexes: indexes), "Index out of range")
            var index = 0
            self.convertIndex(from: indexes, to: &index)
            
            self.buffer[index] = newValue
        }
    }
    
    /// Subscripts at the given `indexes`.
    ///
    /// - Warning: The pointer at the given `indexes` must be initialized, otherwise use ``initializeElement(at:to:)`` instead.
    ///
    /// > Performance Consideration:
    /// > This subscript is not O(*1*), as index conversion is required. Nevertheless, this method is the most performant variant of `subscript`.
    @inlinable
    public nonisolated subscript(_ indexes: UnsafeMutableBufferPointer<Int>) -> Element {
        get {
            assert(indexes.count == shape.count, "Invalid indexes")
            assert(isValid(indexes: indexes), "Index out of range")
            var index = 0
            self.convertIndex(from: indexes, to: &index)
            
            return self.buffer[index]
        }
        set {
            assert(indexes.count == shape.count, "Invalid indexes")
            assert(isValid(indexes: indexes), "Index out of range")
            var index = 0
            self.convertIndex(from: indexes, to: &index)
            
            self.buffer[index] = newValue
        }
    }
    
    /// Subscripts at the given `indexes`.
    ///
    /// - Warning: The pointer at the given `indexes` must be initialized, otherwise use ``initializeElement(at:to:)`` instead.
    ///
    /// > Performance Consideration:
    /// > This subscript is not O(*1*), as index conversion is required.
    @inlinable
    public nonisolated subscript(_ indexes: Int...) -> Element {
        get { self[indexes] }
        set { self[indexes] = newValue }
    }
    
}

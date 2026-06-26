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
    /// multiArray.sequence(0, 0) // returns the first sequence with two elements
    /// ```
    ///
    /// The returned buffer is owned by this `MultiArray`. Do not deallocate the returned buffer, and ensure `self` outlives the returned buffer.
    @available(*, deprecated, message: "Use the variant that takes integers instead.")
    public nonisolated func sequence(at index: [Int]) -> UnsafeMutableBufferPointer<Element> {
        assert(index.count == shape.count - 1, "Invalid indexes")
        let startIndex = zip(index, self.strides.dropLast()).reduce(0) { $0 + $1.0 * $1.1 }
        return UnsafeMutableBufferPointer(start: self.baseAddress + startIndex, count: self.strides[self.strides.count - 2])
    }
    public nonisolated func sequence(_ dim0: Int) -> UnsafeMutableBufferPointer<Element> {
        return UnsafeMutableBufferPointer(start: self.pointer(dim0), count: self.strides[0])
    }
    public nonisolated func sequence(_ dim0: Int, _ dim1: Int) -> UnsafeMutableBufferPointer<Element> {
        return UnsafeMutableBufferPointer(start: self.pointer(dim0, dim1), count: self.strides[1])
    }
    public nonisolated func sequence(_ dim0: Int, _ dim1: Int, _ dim2: Int) -> UnsafeMutableBufferPointer<Element> {
        return UnsafeMutableBufferPointer(start: self.pointer(dim0, dim1, dim2), count: self.strides[2])
    }
    public nonisolated func sequence(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int) -> UnsafeMutableBufferPointer<Element> {
        return UnsafeMutableBufferPointer(start: self.pointer(dim0, dim1, dim2, dim3), count: self.strides[3])
    }
    public nonisolated func sequence(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int) -> UnsafeMutableBufferPointer<Element> {
        return UnsafeMutableBufferPointer(start: self.pointer(dim0, dim1, dim2, dim3, dim4), count: self.strides[4])
    }
    
    /// Initializes the element at `indexes` to the given value.
    ///
    /// The memory underlying the destination element must be uninitialized,
    /// or `Element` must be a trivial type. After a call to `initialize(to:)`,
    /// the memory underlying this element of the buffer is initialized.
    ///
    /// - Parameters:
    ///   - value: The value used to initialize the buffer element's memory.
    @available(*, deprecated, message: "Use the variant that takes integers instead.")
    @inlinable
    public nonisolated func initializeElement(at indexes: [Int], to value: consuming Element) {
        assert(indexes.count == shape.count, "Invalid indexes")
        assert(isValid(indexes: indexes), "Index out of range")
        var index = 0
        self.convertIndex(from: indexes, to: &index)
        
        self.buffer.initializeElement(at: index, to: consume value)
    }
    @inlinable
    public nonisolated func initializeElement(at dim0: Int, to value: consuming Element) {
        self.pointer(dim0).initialize(to: value)
    }
    @inlinable
    public nonisolated func initializeElement(at dim0: Int, _ dim1: Int, to value: consuming Element) {
        self.pointer(dim0, dim1).initialize(to: value)
    }
    @inlinable
    public nonisolated func initializeElement(at dim0: Int, _ dim1: Int, _ dim2: Int, to value: consuming Element) {
        self.pointer(dim0, dim1, dim2).initialize(to: value)
    }
    
    @inlinable
    public nonisolated func initializeElement(at dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, to value: consuming Element) {
        self.pointer(dim0, dim1, dim2, dim3).initialize(to: value)
    }
    
    @inlinable
    public nonisolated func initializeElement(at dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int, to value: consuming Element) {
        self.pointer(dim0, dim1, dim2, dim3, dim4).initialize(to: value)
    }
    
    /// Returns a view of the `MultiArray` at the given `indexes`.
    ///
    /// This method mimics the subscripts on nested arrays.
    /// ```swift
    /// let array = [...]
    /// let multiArray = MultiArray(array)
    /// // multiArray.view(i, j) == array[i][j]
    /// ```
    @available(*, deprecated, message: "Use the variant that takes integers, or `pointer(at:)` instead.")
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
    
    /// - SeeAlso: `pointer(at:)`
    @inlinable
    public func view(_ dim0: Int) -> MultiArray {
        MultiArray(
            bytesNoCopy: self.sequence(dim0),
            shape: Array(self.shape.dropFirst()),
            deallocator: captureReference(),
            operatorsShouldReturnCopiedSelf: self.operatorsShouldReturnCopiedSelf
        )
    }
    /// - SeeAlso: `pointer(at:)`
    @inlinable
    public func view(_ dim0: Int, _ dim1: Int) -> MultiArray {
        MultiArray(
            bytesNoCopy: self.sequence(dim0, dim1),
            shape: Array(self.shape.dropFirst(2)),
            deallocator: captureReference(),
            operatorsShouldReturnCopiedSelf: self.operatorsShouldReturnCopiedSelf
        )
    }
    /// - SeeAlso: `pointer(at:)`
    @inlinable
    public func view(_ dim0: Int, _ dim1: Int, _ dim2: Int) -> MultiArray {
        MultiArray(
            bytesNoCopy: self.sequence(dim0, dim1, dim2),
            shape: Array(self.shape.dropFirst(3)),
            deallocator: captureReference(),
            operatorsShouldReturnCopiedSelf: self.operatorsShouldReturnCopiedSelf
        )
    }
    
    /// - SeeAlso: `pointer(at:)`
    @inlinable
    public func view(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int) -> MultiArray {
        MultiArray(
            bytesNoCopy: self.sequence(dim0, dim1, dim2, dim3),
            shape: Array(self.shape.dropFirst(4)),
            deallocator: captureReference(),
            operatorsShouldReturnCopiedSelf: self.operatorsShouldReturnCopiedSelf
        )
    }
    
    /// - SeeAlso: `pointer(at:)`
    @inlinable
    public func view(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int) -> MultiArray {
        MultiArray(
            bytesNoCopy: self.sequence(dim0, dim1, dim2, dim3, dim4),
            shape: Array(self.shape.dropFirst(5)),
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
        let iteratorCount = self.strides.count
        let iterator = UnsafeMutableBufferPointer<Int>.allocate(capacity: iteratorCount)
        iterator.initialize(repeating: 0)
        defer { iterator.deallocate() }
        
        let upperBound = self.count
        
        while i < upperBound {
            let value = self.buffer[i]
            block(iterator, value)
            
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
    func isValid(indexes: [Int]) -> Bool {
        var i = 0
        while i < indexes.count {
            guard indexes[i] < self.shape[i] else { return false }
            i &+= 1
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
    @available(*, deprecated, message: "Use the variant that takes integers instead.")
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
    @inlinable
    public nonisolated subscript(_ dim0: Int) -> Element {
        get { self.pointer(dim0).pointee }
        set { self.pointer(dim0).pointee = newValue }
    }
    @inlinable
    public nonisolated subscript(_ dim0: Int, _ dim1: Int) -> Element {
        get { self.pointer(dim0, dim1).pointee }
        set { self.pointer(dim0, dim1).pointee = newValue }
    }
    @inlinable
    public nonisolated subscript(_ dim0: Int, _ dim1: Int, _ dim2: Int) -> Element {
        get { self.pointer(dim0, dim1, dim2).pointee }
        set { self.pointer(dim0, dim1, dim2).pointee = newValue }
    }
    @inlinable
    public nonisolated subscript(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int) -> Element {
        get { self.pointer(dim0, dim1, dim2, dim3).pointee }
        set { self.pointer(dim0, dim1, dim2, dim3).pointee = newValue }
    }
    @inlinable
    public nonisolated subscript(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int) -> Element {
        get { self.pointer(dim0, dim1, dim2, dim3, dim4).pointee }
        set { self.pointer(dim0, dim1, dim2, dim3, dim4).pointee = newValue }
    }
    @inlinable
    public nonisolated subscript(_ dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int, _ dim5: Int) -> Element {
        get { self.pointer(dim0, dim1, dim2, dim3, dim4, dim5).pointee }
        set { self.pointer(dim0, dim1, dim2, dim3, dim4, dim5).pointee = newValue }
    }
    
    /// Subscripts at the given `offset`
    @inlinable
    public nonisolated subscript(offset offset: Int) -> Element {
        get { self.buffer[offset] }
        set { self.buffer[offset] = newValue }
    }
    
}

//
//  Proxy + Work.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


extension MultiArrayTransactionProxy {
    
    @usableFromInline
    struct WorkItem {
        // use C-style enum so we don't need to use generics, improving efficiency.
        @usableFromInline
        enum WorkType {
            case offset
            case reshape
            case slice
            case transpose
        }
        
        @usableFromInline
        let type: WorkType
        @usableFromInline
        let offset: [Int]
        @usableFromInline
        let reshape: [Int]
        @usableFromInline
        let slice: [Range<Int>?]
        @usableFromInline
        let transpose: (lhs: Int, rhs: Int)
        
        
        /// - Returns: whether should continue
        @inlinable
        func transformIndex(
            indexes: UnsafeMutableBufferPointer<Int>,
            shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
            strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
        ) -> Bool {
            switch self.type {
            case .offset:
                var i = 0
                while i < offset.count {
                    indexes[i] &+= offset[i]
                    
                    i &+= 1
                }
                return true
                
            case .reshape:
                var index = 0
                MultiArrayConvertIndex(from: indexes, to: &index, strides: strides.curr)
                MultiArrayConvertIndex(from: index, to: indexes, strides: strides.next)
                return true
                
            case .slice:
                var i = 0
                while i < slice.count {
                    defer { i &+= 1 }
                    guard let slice = slice[i] else { continue }
                    guard slice.contains(indexes[i]) else { return false }
                    indexes[i] &-= slice.lowerBound
                }
                return true
                
            case .transpose:
                swap(&(indexes.baseAddress! + transpose.lhs).pointee, &(indexes.baseAddress! + transpose.rhs).pointee)
                return true
            }
        }
        
        @inlinable
        func transformShape(
            shape: [Int]
        ) -> [Int] {
            switch self.type {
            case .offset:
                return []
                
            case .reshape:
                let originalCount = shape.reduce(1, *)
                var newShape = self.reshape
                if let negativeIndex = newShape.firstIndex(of: -1) {
                    newShape[negativeIndex] = originalCount / newShape.reduce(1) { $0 * ($1 == -1 ? 1 : $1) }
                }
                assert(newShape.reduce(1, *) == originalCount, "Invalid Shape")
                
                return newShape
                
            case .slice:
                assert(shape.count == slice.count, "Invalid slices shape")
                return [Int](unsafeUninitializedCapacity: slice.count) { buffer, initializedCount in
                    initializedCount = slice.count
                    
                    var i = 0
                    while i < slice.count {
                        buffer.initializeElement(at: i, to: slice[i]?.count ?? shape[i])
                        i &+= 1
                    }
                }
                
            case .transpose:
                var shape = shape
                shape.swapAt(transpose.lhs, transpose.rhs)
                return shape
            }
        }
        
        
        @inlinable
        init(type: WorkType, offset: [Int] = [], reshape: [Int] = [], slice: [Range<Int>?] = [], transpose: (lhs: Int, rhs: Int) = (0, 0)) {
            self.type = type
            self.offset = offset
            self.reshape = reshape
            self.slice = slice
            self.transpose = transpose
        }
        
    }

    
    /// Apply an offset
    ///
    /// - Warning: This method can only be used as the last statement AND in `withTransaction(into:_:)`.
    ///
    /// - Warning: Offset calculation does not check for overflow due to performance considerations.
    @inlinable
    public func offset(_ offsets: Int...) -> MultiArrayTransactionProxy {
        let work = WorkItem(type: .offset, offset: offsets)
        let shape = work.transformShape(shape: self.shape)
        
        return MultiArrayTransactionProxy(works: self.works + [work], shape: shape)
    }
    
    @inlinable
    public func reshape(_ shape: [Int]) -> MultiArrayTransactionProxy {
        let work = WorkItem(type: .reshape, reshape: shape)
        let shape = work.transformShape(shape: self.shape)
        
        return MultiArrayTransactionProxy(works: self.works + [work], shape: shape)
    }
    
    @inlinable
    public mutating func reshape(_ shape: Int...) -> MultiArrayTransactionProxy {
        self.reshape(shape)
    }
    
    /// - parameter slice: The indexes for slices.
    ///
    /// - term `slices.element`: `nil` for keeping the entire range
    @inlinable
    public func sliced(_ slices: Range<Int>?...) -> MultiArrayTransactionProxy {
        let work = WorkItem(type: .slice, slice: slices)
        let shape = work.transformShape(shape: self.shape)
        
        return MultiArrayTransactionProxy(works: self.works + [work], shape: shape)
    }
    
    @inlinable
    public func transposed(_ lhs: Int, _ rhs: Int) -> MultiArrayTransactionProxy {
        let work = WorkItem(type: .transpose, transpose: (lhs, rhs))
        let shape = work.transformShape(shape: self.shape)
        
        return MultiArrayTransactionProxy(works: self.works + [work], shape: shape)
    }
    
    
}

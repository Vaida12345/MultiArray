//
//  Array + bridge.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Foundation


extension MultiArray {
    
    /// Convert this MultiArray into nested Swift arrays.
    /// - returns: A nested array of depth `shape.count`.
    ///   At the outermost level you always get an `Any` which you can downcast
    ///   to `[Any]`; at the innermost level you’ll get `[Element]`.
    public func nestedArray<T>(as type: T.Type = T.self) -> T {
        // recursive builder: level = current dimension, offset = linear offset into buffer
        func build(level: Int, offset: Int) -> Any {
            let dimSize = shape[level]
            // if we are at the last dimension, return a [Element]
            if level == shape.count - 1 {
                var slice = [Element]()
                slice.reserveCapacity(dimSize)
                for i in 0..<dimSize {
                    let idx = offset + i * strides[level]
                    slice.append(buffer[idx])
                }
                return slice
            }
            // otherwise return an [Any] of “one level deeper”
            var array = [Any]()
            array.reserveCapacity(dimSize)
            for i in 0..<dimSize {
                let idx = offset + i * strides[level]
                array.append(build(level: level + 1, offset: idx))
            }
            return array
        }
        
        return build(level: 0, offset: 0) as! T
    }
    
    /// Build a `MultiArray<Element>` from a nested Array structure.
    ///
    /// - nested: must be an `[Any]` of depth ≥ 1, whose innermost
    ///   leaves are all `Element`.  All sibling arrays at each level
    ///   must have the same count (i.e. a rectangular shape).
    /// - deallocator: how to free the backing buffer.
    ///
    /// - Returns: a row-major `MultiArray<Element>` with inferred shape/strides.
    public convenience init(_ nested: Any) {
        
        // 1) Infer the shape
        var shape: [Int] = []
        func inferShape(_ node: Any, level: Int) {
            if let arr = node as? [Any] {
                let c = arr.count
                if level >= shape.count {
                    shape.append(c)
                } else {
                    precondition(shape[level] == c,
                                 "Inconsistent sizes at level \(level): "
                                 + "\(shape[level]) vs \(c)")
                }
                // dive into the first child to pick up deeper dims
                if c > 0 {
                    inferShape(arr[0], level: level + 1)
                }
            }
            // else we hit a leaf, do nothing more here
        }
        
        precondition(nested is [Any], "Top‐level must be an [Any], you may accidentally used the wrong initializer.")
        inferShape(nested, level: 0)
        precondition(!shape.isEmpty, "Cannot build a zero‐dimensional array")
        
        // 2) Compute row‐major strides
        let rank = shape.count
        
        // 3) Flatten into a Swift array
        var flat = [Element]()
        flat.reserveCapacity(shape.reduce(1, *))
        
        func flatten(_ node: Any, level: Int) {
            if level == rank {
                // leaf; must be an Element
                guard let e = node as? Element else {
                    preconditionFailure("Expected leaf of type \(Element.self), got \(type(of: node))")
                }
                flat.append(e)
            } else {
                // must be an array
                guard let arr = node as? [Any], arr.count == shape[level] else {
                    preconditionFailure("Bad shape at level \(level)")
                }
                for child in arr {
                    flatten(child, level: level + 1)
                }
            }
        }
        flatten(nested, level: 0)
        precondition(flat.count == shape.reduce(1, *), "Flattened count mismatch")
        
        // 4) Allocate an UnsafeMutableBufferPointer and copy
        let count = flat.count
        let ptr = UnsafeMutablePointer<Element>.allocate(capacity: count)
        ptr.initialize(from: flat, count: count)
        let buffer = UnsafeMutableBufferPointer(start: ptr, count: count)
        
        // 5) Build the MultiArray
        self.init(
            bytesNoCopy: buffer,
            shape: shape,
            deallocator: .free
        )
    }
}


extension Array {
    
    /// Calls the given closure with a pointer to the array's mutable contiguous storage.
    @inlinable
    public mutating func withMultiArray<R>(_ body: (MultiArray<Element>) throws -> R) rethrows -> R {
        try self.withUnsafeMutableBufferPointer {
            let array = MultiArray(bytesNoCopy: $0, shape: [$0.count], deallocator: .none)
            return try body(array)
        }
    }
    
}

//
//  Array + Transaction.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Foundation
import Essentials
import Accelerate


extension MultiArray {
    
    /// Apply a transformation.
    ///
    /// - Note: This method is highly optimized, using pointers to optimize retain/release.
    @inlinable
    public func withTransaction(
        into multiArray: inout MultiArray<Element>,
        _ body: (_ proxy: inout TransactionProxy) -> TransactionProxy
    ) {
        var shape: [Int] = []
        _ = self._withTransaction(into: multiArray, resultingShape: &shape, body)
    }
    
    /// Apply a transformation.
    ///
    /// - Note: This method is highly optimized, using pointers to optimize retain/release.
    @inlinable
    public func withTransaction(_ body: (_ proxy: inout TransactionProxy) -> TransactionProxy) -> MultiArray<Element> {
        var shape: [Int] = []
        let buffer = self._withTransaction(into: nil, resultingShape: &shape, body)
        // the buffer is allocated
        return MultiArray(bytesNoCopy: buffer, shape: shape, deallocator: .free)
    }
    
    /// Apply a transformation.
    ///
    /// - Note: This method is highly optimized, using pointers to optimize retain/release.
    @inlinable
    func _withTransaction(
        into resultBuffer: MultiArray<Element>?,
        resultingShape: inout [Int],
        _ body: (_ proxy: inout TransactionProxy) -> TransactionProxy
    ) -> UnsafeMutablePointer<Element> {
        var proxy = TransactionProxy(works: [])
        proxy.shape = self.shape
        let works = body(&proxy).works
        
        var shape: [[Int]] = []
        var strides: [UnsafeMutableBufferPointer<Int>] = []
        defer {
            for stride in strides.dropFirst() {
                stride.deallocate()
            }
        }
        
        shape.append(self.shape)
        strides.append(self.strides)
        
        for (offset, work) in works.enumerated() {
            assert(!shape[offset].isEmpty, "Cannot use `offset` on a non-trailing position.")
            let _shape = work.transformShape(shape: shape[offset])
            shape.append(_shape)
            
            if _shape.isEmpty {
                // use result strides
                assert(!(shape.last!.isEmpty && resultBuffer == nil), "Cannot use `offset` to create a new MultiArray.")
                let _strides = MultiArray.contiguousStrides(shape: resultBuffer!.shape)
                strides.append(_strides)
            } else {
                let _strides = MultiArray.contiguousStrides(shape: _shape)
                strides.append(_strides)
            }
        }
        
        if !shape.last!.isEmpty {
            resultingShape = shape.last!
        }
        let resultBuffer = resultBuffer?.buffer.baseAddress ?? .allocate(capacity: resultingShape.reduce(1, *))
        let indexes = UnsafeMutableBufferPointer<Int>.allocate(capacity: self.shape.count)
        
        defer {
            indexes.deallocate()
        }
        
        // MARK: - shape & strides
        let _shape = UnsafeMutableBufferPointer<UnsafeMutableBufferPointer<Int>>.allocate(capacity: shape.count)
        for (offset, shape) in shape.enumerated() {
            let element = UnsafeMutableBufferPointer<Int>.allocate(capacity: shape.count)
            _ = element.initialize(from: shape)
            
            _shape.initializeElement(at: offset, to: element)
        }
        _ = consume shape
        defer {
            for shape in _shape {
                shape.deallocate()
            }
            _shape.deallocate()
        }
        
        let _strides = UnsafeMutableBufferPointer<UnsafeMutableBufferPointer<Int>>.allocate(capacity: strides.count)
        for (offset, strides) in strides.enumerated() {
            let element = UnsafeMutableBufferPointer<Int>.allocate(capacity: strides.count)
            _ = element.initialize(from: strides)
            
            _strides.initializeElement(at: offset, to: element)
        }
        
        defer {
            for strides in _strides {
                strides.deallocate()
            }
            _strides.deallocate()
        }
        let trailingStride = _strides.last!
        
        // MARK: - ForEach
        self.forEach { _indexes, value in
            _indexes.withUnsafeBufferPointer {
                indexes.copy(from: $0.baseAddress!, count: $0.count)
                
                var i = 0
                while i < works.count {
                    guard works[i].transformIndex(indexes: indexes, shape: (_shape[i], _shape[i + 1]), strides: (_strides[i], _strides[i + 1])) else { return }
                    i &+= 1
                }
                
                var index = 0
                MultiArray.convertIndex(from: indexes, to: &index, strides: trailingStride)
                (resultBuffer + index).initialize(to: value)
            }
        }
        
        return resultBuffer
    }
    
}

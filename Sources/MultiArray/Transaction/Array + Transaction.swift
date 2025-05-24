//
//  Array + Transaction.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Foundation
import Essentials


extension MultiArray {
    
    /// Apply a transformation.
    ///
    /// - Note: This method is highly optimized, using pointers to optimize retain/release.
    @inlinable
    public func withTransaction(_ body: (_ proxy: TransactionProxy) -> TransactionProxy) -> MultiArray {
        let proxy = TransactionProxy(works: [])
        let works = body(proxy).works
        
        var shape: [[Int]] = []
        var strides: [[Int]] = []
        
        shape.append(self.shape)
        strides.append(self.strides)
        
        for (offset, work) in works.enumerated() {
            let _shape = work.transformShape(shape: shape[offset])
            shape.append(_shape)
            
            let _strides = MultiArray.contiguousStrides(shape: _shape)
            strides.append(_strides)
        }
        
        let result = MultiArray.allocate(shape.last!)
        let resultBuffer = result.buffer
        let indexes = UnsafeMutableBufferPointer<Int>.allocate(capacity: self.shape.count)
        defer {
            indexes.deallocate()
        }
        
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
        _ = consume strides
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
                resultBuffer.initializeElement(at: index, to: value)
            }
        }
        
        return result
    }
    
}

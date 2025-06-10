//
//  Array + Proxy.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


public struct MultiArrayTransactionProxy {
    
    @usableFromInline
    var works: [WorkItem]
    
    /// The shape always reflects the current shape.
    public var shape: [Int] = []
    
    @inlinable
    init(works: [WorkItem], shape: [Int]) {
        self.works = works
        self.shape = shape
    }
    
}

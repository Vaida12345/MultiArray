//
//  Array + Proxy.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


extension MultiArray {
    
    public final class TransactionProxy {
        
        @usableFromInline
        var works: [any WorkProtocol]
        
        /// The shape always reflects the current shape.
        public var shape: [Int] = []
        
        @inlinable
        init(works: [any WorkProtocol]) {
            self.works = works
        }
        
    }
    
}

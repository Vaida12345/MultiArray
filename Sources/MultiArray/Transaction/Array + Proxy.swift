//
//  Array + Proxy.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


extension MultiArray {
    
    public struct TransactionProxy {
        
        @usableFromInline
        var works: [any WorkProtocol]
        
        @inlinable
        init(works: [any WorkProtocol]) {
            self.works = works
        }
        
    }
    
}

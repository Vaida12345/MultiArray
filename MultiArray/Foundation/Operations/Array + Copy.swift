//
//  Array + Copy.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Essentials


extension MultiArray {
    
    @usableFromInline
    internal final class OperatorsShouldReturnCopiedSelf {
        
        @usableFromInline
        var value = true
        
        @inlinable
        init() {
            
        }
        
    }
    
        
    /// Indicates that operators should not attempt to return a new copy.
    ///
    /// This method is used for low-level memory optimizations.
    ///
    /// This value is inherited for all views of `self`.
    ///
    /// In binary operators, the `lhs` will be checked, and stored in `lhs` when required.
    @inlinable
    public func withoutCopying<T, E: Error>(_ work: () throws(E) -> T) throws(E) -> T {
        self.operatorsShouldReturnCopiedSelf.value = false
        defer {
            self.operatorsShouldReturnCopiedSelf.value = true
        }
        
        return try work()
    }
    
    @inlinable
    internal static func conditionalAllocate(referencing reference: MultiArray) -> MultiArray {
        if reference.operatorsShouldReturnCopiedSelf.value {
            return MultiArray.allocate(reference.shape)
        } else {
            return reference
        }
    }
    
    /// Creates an explicit deep copy.
    ///
    /// The returned value and `self` does not share the underlying buffer.
    @inlinable
    func copy() -> MultiArray {
        let result = MultiArray.allocate(self.shape)
        self.buffer.copy(to: result.baseAddress, count: self.count)
        return result
    }

    
}

//
//  Array + ==.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//


extension MultiArray where Element: Equatable {
    
    public static func == (_ lhs: MultiArray, _ rhs: MultiArray) -> Bool {
        guard lhs.shape == rhs.shape else { return false }
        
        // value by value
        var i = 0
        while i < lhs.buffer.count {
            guard lhs.buffer[i] == rhs.buffer[i] else { return false }
            
            i &+= 1
        }
        return true
    }
    
}

extension MultiArray where Element: BinaryFloatingPoint {
    
    public func contentsEqual(_ other: MultiArray, tolerance: Element = 1e-6) -> Bool {
        guard self.shape == other.shape else { return false }
        
        // value by value
        var i = 0
        while i < self.buffer.count {
            guard abs(self.buffer[i] - other.buffer[i]) < tolerance else { return false }
            
            i &+= 1
        }
        return true
    }
    
}

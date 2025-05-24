//
//  Array + Index.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-23.
//

extension MultiArray {
    
    @inlinable
    public func convertIndex(from offset: Int, to indexes: inout [Int]) {
        MultiArray.convertIndex(from: offset, to: &indexes, strides: self.strides)
    }
    
    @inlinable
    public static func convertIndex(
        from offset: Int,
        to indexes: inout [Int],
        strides: [Int]
    ) {
        assert(strides.count == indexes.count, "Mismatch between strides and indexes count")
        var rem = offset
        var i = 0
        let endIndex = strides.count
        while i < endIndex {
            // computes both quotient & remainder in one machine‐instruction
            let qr = rem.quotientAndRemainder(dividingBy: strides[i])
            indexes[i] = qr.quotient
            rem = qr.remainder
            
            i &+= 1
        }
    }
    
    /// > Optimization Tip:
    /// > Store `strides` and use `convertIndex(from:to:strides:)`
    @inlinable
    public static func convertIndex(
        from offset: Int,
        to indexes: inout [Int],
        shape: [Int]
    ) {
        let strides = MultiArray.contiguousStrides(shape: shape)
        MultiArray.convertIndex(from: offset, to: &indexes, strides: strides)
    }
    
    
    @inlinable
    public func convertIndex(from indexes: [Int], to offset: inout Int) {
        MultiArray.convertIndex(from: indexes, to: &offset, strides: self.strides)
    }
    
    @inlinable
    public static func convertIndex(
        from indexes: [Int],
        to offset: inout Int,
        strides: [Int]
    ) {
        assert(strides.count == indexes.count, "Mismatch between strides and indexes count")
        var i = 0
        let endIndex = indexes.count
        while i < endIndex {
            offset &+= indexes[i] &* strides[i]
            i &+= 1
        }
    }
    
    /// > Optimization Tip:
    /// > Store `strides` and use `convertIndex(from:to:strides:)`
    @inlinable
    public static func convertIndex(
        from indexes: [Int],
        to offset: inout Int,
        shape: [Int]
    ) {
        let strides = MultiArray.contiguousStrides(shape: shape)
        MultiArray.convertIndex(from: indexes, to: &offset, strides: strides)
    }
    
}

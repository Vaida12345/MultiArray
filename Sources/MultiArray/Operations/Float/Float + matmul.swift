//
//  Float + matmul.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Accelerate


extension MultiArray where Element == Float {
    
    /// Performs out-of-place multiplication of two matrices, inline-mutation.
    ///
    /// - Experiment: This function is equally performant as `BNNSMatMul`.
    ///
    /// > Example:
    /// > ```swift
    /// > let instance: Matrix = [
    /// >     [1, 2],
    /// >     [3, 4]
    /// > ]
    /// >
    /// > instance * instance
    /// >  7 10
    /// > 15 22
    /// > ```
    ///
    /// - Complexity: in-place mutation.
    @inlinable
    static func matmul(_ lhs: MultiArray, _ rhs: MultiArray, into buffer: inout MultiArray) {
        assert(lhs.shape.count == 2 && rhs.shape.count == 2 && buffer.shape.count == 2)
        assert(lhs.shape[1] == rhs.shape[0])
        assert(lhs.shape[0] == buffer.shape[0] && rhs.shape[1] == buffer.shape[1])

        let m = lhs.shape[0]
        let n = lhs.shape[1] // which is also rhs.height
        let p = rhs.shape[1]
        let alpha: Float = 1
        let beta:  Float = 0
        
        cblas_sgemm(
            CblasRowMajor, CblasNoTrans, CblasNoTrans,
            Int32(m), Int32(p), Int32(n),
            alpha,
            lhs.baseAddress, Int32(n),
            rhs.baseAddress, Int32(p),
            beta,
            buffer.baseAddress, Int32(p)
        )
    }
    
    /// Performs out-of-place multiplication of two matrices, inline-mutation.
    ///
    /// - Experiment: This function is equally performant as `BNNSMatMul`.
    ///
    /// > Example:
    /// > ```swift
    /// > let instance: Matrix = [
    /// >     [1, 2],
    /// >     [3, 4]
    /// > ]
    /// >
    /// > instance * instance
    /// >  7 10
    /// > 15 22
    /// > ```
    ///
    /// - Complexity: in-place mutation.
    @inlinable
    static func matmul(_ lhs: MultiArray, _ rhs: MultiArray) -> MultiArray {
        var result = MultiArray.allocate(lhs.shape[0], rhs.shape[1])
        MultiArray.matmul(lhs, rhs, into: &result)
        return result
    }
    
}

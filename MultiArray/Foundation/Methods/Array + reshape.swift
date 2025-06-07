//
//  Array + reshape.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-22.
//


extension MultiArray {
    
    /// Reshape and returns the new array.
    ///
    /// Similar to `torch.reshape`, you can use `-1` to indicate the auto-inferring of a dimension.
    ///
    /// - Complexity: O(*1*), the underlying buffer is referenced when the new shape.
    public func reshape(_ shape: Int...) -> MultiArray {
        var shape = shape
        if let negativeIndex = shape.firstIndex(of: -1) {
            shape[negativeIndex] = self.count / shape.reduce(1) { $0 * ($1 == -1 ? 1 : $1) }
        }
        assert(shape.reduce(1, *) == self.count, "Invalid shape")
        
        return MultiArray(
            bytesNoCopy: self.buffer,
            shape: shape,
            deallocator: self.captureReference(),
            operatorsShouldReturnCopiedSelf: self.operatorsShouldReturnCopiedSelf
        )
    }
    
}

//
//  Array + ==.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Accelerate


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


extension MultiArray<Float> {
    
    /// Computes the Normalized Mean Squared Error (NMSE) between `self` (the prediction)
    /// and the `groundTruth`.
    ///
    /// The NMSE is defined as:
    /// ```
    /// NMSE = sum((groundTruth - prediction)²) / sum(groundTruth²)
    /// ```
    ///
    /// - An NMSE of `0` indicates a perfect match.
    /// - An NMSE of `1` means the error energy equals the signal energy
    ///   (equivalent to predicting all zeros).
    /// - Values greater than `1` indicate the prediction is worse than a zero prediction.
    ///
    /// - Warning: If `groundTruth` is all zeros, the result is `inf` (or `nan` if
    ///   `self` is also all zeros), as the relative error is undefined / infinite.
    ///
    /// - Precondition: `self.count == groundTruth.count`
    ///
    /// - Parameter groundTruth: The reference / target values.
    /// - Returns: The NMSE, a non-negative value measuring relative error energy.
    public func normalizedMSE(to groundTruth: MultiArray<Float>) -> Float {
        precondition(self.count == groundTruth.count)

        let diff = vDSP.sumOfSquares(groundTruth - self)
        let signalEnergy = vDSP.sumOfSquares(groundTruth)
        return diff / signalEnergy
    }
    
    public func maxAbsoluteError(to other: MultiArray<Float>) -> Float {
        precondition(self.count == other.count)
        
        let diff = self - other
        let abs = vDSP.absolute(diff)
        return vDSP.maximum(abs)
    }
}

//
//  Array + Playgrounds.swift
//  MultiArray
//
//  Created by Vaida on 2025-07-13.
//


extension MultiArray: CustomPlaygroundDisplayConvertible {
    
    private func reshape<T>(_ flat: [T], dims: [Int]) -> Any {
        guard !dims.isEmpty else { return flat[0] }
        assert(flat.count == dims.reduce(1, *), "Size mismatch")
        
        func helper(_ flat: [T], _ dims: [Int]) -> Any {
            if dims.count == 1 {
                return flat
            }
            let stride = dims.dropFirst().reduce(1, *)
            return Swift.stride(from: 0, to: flat.count, by: stride).map {
                Array(helper(Array(flat[$0..<$0+stride]), Array(dims.dropFirst())) as! [Any])
            }
        }
        
        return helper(flat, dims)
    }
    
    public var playgroundDescription: Any {
        self.reshape(Array(self), dims: self.shape)
    }
}



#if canImport(Playgrounds) && os(macOS)
import Playgrounds
import SwiftUI

#Playground {
    let array = MultiArray<Float>([[[1, 2, 3], [4, 5, 6]]])
    print(array)
}
#endif

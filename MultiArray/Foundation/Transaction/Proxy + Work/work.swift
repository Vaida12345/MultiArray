//
//  Proxy + Work.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


@usableFromInline
protocol WorkProtocol {
    
    /// - Returns: whether should continue
    func transformIndex(
        indexes: UnsafeMutableBufferPointer<Int>,
        shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
        strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
    ) -> Bool
    
    func transformShape(
        shape: [Int]
    ) -> [Int]
    
}

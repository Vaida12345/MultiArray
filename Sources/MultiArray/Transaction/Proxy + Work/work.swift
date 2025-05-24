//
//  Proxy + Work.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//


@usableFromInline
protocol WorkProtocol {
    
    func transformIndex(
        indexes: UnsafeMutableBufferPointer<Int>,
        shape: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>),
        strides: (curr: UnsafeMutableBufferPointer<Int>, next: UnsafeMutableBufferPointer<Int>)
    )
    
    func transformShape(
        shape: [Int]
    ) -> [Int]
    
}

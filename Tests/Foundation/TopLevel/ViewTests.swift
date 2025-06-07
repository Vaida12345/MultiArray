//
//  ViewTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-22.
//

import Testing
import MultiArray
import Foundation


@Suite
struct ViewTests {
    
    @Test
    func simpleTest() {
        let array = [
            [
                [1, 2],
                [3, 4],
            ]
        ]
        
        let multiArray = MultiArray<Int>(array)
        #expect(multiArray.view(at: [0]) == MultiArray<Int>(array[0]))
        #expect(multiArray.view(at: [0, 0]) == MultiArray<Int>(array[0][0]))
        #expect(multiArray.view(at: [0, 1]) == MultiArray<Int>(array[0][1]))
    }
    
    @Test
    func lifetimeAutoReleaseTest() {
        let array = [
            [
                [1, 2],
                [3, 4],
            ]
        ]
        
        let view = autoreleasepool {
            let multiArray = MultiArray<Int>(array)
            let view = multiArray.view(at: [0])
            _ = consume multiArray // end lifetime
            return view
        }
        #expect(view == MultiArray<Int>(array[0]))
    }
    
    @Test
    func lifetimeTest() {
        var valueIsDeallocated = false
        let view = autoreleasepool {
            let pointer = UnsafeMutableBufferPointer<Int>.allocate(capacity: 1)
            let multiArray = MultiArray<Int>(bytesNoCopy: pointer, shape: [1, 1], deallocator: .custom({ _, _ in valueIsDeallocated = true }))
            let view = multiArray.view(at: [0])
            _ = consume multiArray // end lifetime
            return view
        }
        #expect(!valueIsDeallocated)
        _ = consume view
        #expect(valueIsDeallocated)
    }
    
}

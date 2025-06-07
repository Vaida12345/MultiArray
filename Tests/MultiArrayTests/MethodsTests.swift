//
//  MethodsTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Testing
import MultiArray

@Suite
struct MethodsTests {
    
    @Test func testReshape() {
        let x = MultiArray<Float>.random(3, 4)
        let y = x.reshape(-1, 3)
        #expect(y.shape == [4, 3])
    }
    
    @Test func testReflectPad() {
        let x = MultiArray([1, 2, 3, 4, 5])
        let y = x.reflectionPad(size: 3)
        #expect(Array(y) == [4, 3, 2, 1, 2, 3, 4, 5, 4, 3, 2])
    }
    
    
}

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
    
    
}

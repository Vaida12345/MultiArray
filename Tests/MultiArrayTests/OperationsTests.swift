//
//  OperationsTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-23.
//

import Testing
@testable
import MultiArray

@Suite
struct OperationsTests {
    
    @Test func negate() {
        let x = MultiArray<Float>.random(3, 4)
        let y = -x
        
        #expect(x[0, 0] == -y[0, 0])
        #expect(x[0, 1] == -y[0, 1])
        #expect(x[0, 2] == -y[0, 2])
        #expect(x[0, 3] == -y[0, 3])
    }
    
    
}

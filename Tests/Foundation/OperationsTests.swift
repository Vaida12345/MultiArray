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
    
    @Test func copy() {
        let x = MultiArray<Float>.random(3, 4)
        let y = -x
        
        #expect(x[0, 0] == -y[0, 0])
        #expect(x[0, 1] == -y[0, 1])
        #expect(x[0, 2] == -y[0, 2])
        #expect(x[0, 3] == -y[0, 3])
    }
    
    @Test func noCopy() {
        let x = MultiArray<Float>.random(3, 4)
        let copy = x.copy()
        let y = x.withoutCopying {
            let y = -x
            return y
        }
        
        #expect(x[0, 0] == -copy[0, 0])
        #expect(x[0, 1] == -copy[0, 1])
        #expect(x[0, 2] == -copy[0, 2])
        #expect(x[0, 3] == -copy[0, 3])
        #expect(x.baseAddress == y.baseAddress)
    }
    
    @Test func noCopyView() {
        let x = MultiArray<Float>.random(3, 4)
        let copy = x.copy()
        
        let y = x.withoutCopying {
            let view = x.view(at: [0])
            let y = -view
            return y
        }
        
        #expect(y[0] == -copy[0, 0])
        #expect(y[1] == -copy[0, 1])
        #expect(y[2] == -copy[0, 2])
        #expect(y[3] == -copy[0, 3])
        #expect(x.baseAddress == y.baseAddress)
    }
    
    @Test func copyView() {
        let x = MultiArray<Float>.random(3, 4)
        
        let view = x.withoutCopying {
            x.view(at: [0])
        }
        let y = -view
        
        #expect(y[0] == -x[0, 0])
        #expect(y[1] == -x[0, 1])
        #expect(y[2] == -x[0, 2])
        #expect(y[3] == -x[0, 3])
    }
    
    @Test func matmul() {
        let a = MultiArray<Float>([[1, 2], [3, 4]] as [[Float]])
        #expect(MultiArray.matmul(a, a).contentsEqual(MultiArray<Float>([[7, 10], [15, 22]] as [[Float]])))
    }
    
    
}

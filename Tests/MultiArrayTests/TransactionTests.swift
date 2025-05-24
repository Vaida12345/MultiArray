//
//  TransactionTests.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Testing
import MultiArray


@Suite
struct TransactionTests {
    
    @Test func transpose() async throws {
        let multiArray = MultiArray<Float>.random(2, 4, 2)
        let new = multiArray.withTransaction { proxy in
            proxy.transposed(0, 1)
        }
        
        #expect(new.shape == [4, 2, 2])
        #expect(multiArray[0, 0, 0] == new[0, 0, 0])
        #expect(multiArray[0, 1, 0] == new[1, 0, 0])
        #expect(multiArray[0, 2, 0] == new[2, 0, 0])
        #expect(multiArray[0, 3, 0] == new[3, 0, 0])
        #expect(multiArray[1, 0, 0] == new[0, 1, 0])
        #expect(multiArray[1, 1, 0] == new[1, 1, 0])
        #expect(multiArray[1, 2, 0] == new[2, 1, 0])
        #expect(multiArray[1, 3, 0] == new[3, 1, 0])
    }
    
    @Test func reshape() async throws {
        let multiArray = MultiArray<Float>.random(2, 7, 3)
        let new = multiArray.withTransaction { proxy in
            proxy.reshape(-1, 7)
        }
        
        #expect(new == multiArray.reshape(-1, 7))
    }
}

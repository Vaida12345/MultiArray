//
//  BridgeTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Testing
import CoreML
import MultiArray


@Suite
struct BridgeTests {
    
    @Test
    func arrayBridgeTests() {
        let array = [
            [1, 2, 3],
            [4, 5, 6]
        ]
        
        let multiArray = MultiArray<Int>(array)
        #expect(multiArray.shape == [2, 3])
        #expect(multiArray[0, 0] == 1)
        #expect(multiArray[0, 1] == 2)
        #expect(multiArray[0, 2] == 3)
        #expect(multiArray[1, 0] == 4)
        #expect(multiArray[1, 1] == 5)
        #expect(multiArray[1, 2] == 6)
        #expect(multiArray.nestedArray() == array)
    }
    
    @Test
    func MLArrayBridgeTests() throws {
        let array = [
            [1, 2, 3],
            [4, 5, 6]
        ] as [[Int32]]
        
        let multiArray = MultiArray<Int32>(array)
        let mlMultiArray = try MLMultiArray(multiArray)
        for i in 0..<3 {
            for j in 0..<2 {
                #expect(mlMultiArray[[NSNumber(value: j), NSNumber(value: i)]].intValue == multiArray[j, i])
            }
        }
        #expect(MultiArray(mlMultiArray) == multiArray)
    }
    
}

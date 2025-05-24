//
//  MultiArrayTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import Testing
import MultiArray
import CoreML


@Suite
struct MultiArrayTests {
    
    @Test
    func stridesTest() async throws {
        let multiArray = MultiArray<Float>.allocate(5, 4, 3, 2)
        let mlMultiArray = try MLMultiArray(
            shape: [5, 4, 3, 2] as [NSNumber],
            dataType: .float32
        )
        
        #expect(multiArray.shape == mlMultiArray.shape.map(\.intValue))
        #expect(multiArray.strides == mlMultiArray.strides.map(\.intValue))
    }
    
    @Test
    func stridesOneDimensionTest() async throws {
        let multiArray = MultiArray<Float>.allocate(5)
        let mlMultiArray = try MLMultiArray(
            shape: [5] as [NSNumber],
            dataType: .float32
        )
        
        #expect(multiArray.shape == mlMultiArray.shape.map(\.intValue))
        #expect(multiArray.strides == mlMultiArray.strides.map(\.intValue))
    }
    
    @Test
    func extractSequenceTest() {
        let multiArray = MultiArray<Float>.allocate(4, 3, 2)
        multiArray.initializeElement(at: [0, 0, 0], to: 1)
        multiArray.initializeElement(at: [0, 0, 1], to: 2)
        #expect(Array(multiArray.sequence(at: [0, 0])) == [1, 2])
        
        multiArray.initializeElement(at: [0, 1, 0], to: 1)
        multiArray.initializeElement(at: [0, 1, 1], to: 2)
        #expect(Array(multiArray.sequence(at: [0, 1])) == [1, 2])
    }
    
    @Test
    func forEachTest() {
        let array = [
            [
                [1, 2],
                [3, 4],
            ]
        ]
        
        let multiArray = MultiArray<Int>(array)
        
        var index: [[Int]] = []
        let reference = [
            [0, 0, 0],
            [0, 0, 1],
            [0, 1, 0],
            [0, 1, 1],
        ]
        
        multiArray.forEach { indexes, value in
            index.append(indexes)
        }
        
        #expect(reference == index)
    }
    
    @Test
    func forEachLargeTest() {
        let array = [
            [
                [1, 2],
                [3, 4],
            ],
            [
                [1, 2],
                [3, 4],
            ]
        ]
        
        let multiArray = MultiArray<Int>(array)
        
        var index: [[Int]] = []
        let reference = [
            [0, 0, 0],
            [0, 0, 1],
            [0, 1, 0],
            [0, 1, 1],
            [1, 0, 0],
            [1, 0, 1],
            [1, 1, 0],
            [1, 1, 1],
        ]
        
        multiArray.forEach { indexes, value in
            index.append(indexes)
        }
        
        #expect(reference == index)
    }
}

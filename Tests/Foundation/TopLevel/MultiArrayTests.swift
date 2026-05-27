//
//  MultiArrayTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import Testing
@testable import MultiArray
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
        #expect(Array(multiArray.strides) == mlMultiArray.strides.map(\.intValue))
    }

    @Test
    func stridesOneDimensionTest() async throws {
        let multiArray = MultiArray<Float>.allocate(5)
        let mlMultiArray = try MLMultiArray(
            shape: [5] as [NSNumber],
            dataType: .float32
        )

        #expect(multiArray.shape == mlMultiArray.shape.map(\.intValue))
        #expect(Array(multiArray.strides) == mlMultiArray.strides.map(\.intValue))
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
            index.append(Array(indexes))
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
            index.append(Array(indexes))
        }

        #expect(reference == index)
    }

    @Test
    func subscriptOffset() {
        let x = MultiArray<Float>([10, 20, 30, 40])
        #expect(x[offset: 0] == 10)
        #expect(x[offset: 1] == 20)
        #expect(x[offset: 3] == 40)

        x[offset: 2] = 99
        #expect(x[offset: 2] == 99)
    }

    @Test
    func subscriptVariadic() {
        let x = MultiArray<Float>([[1, 2, 3], [4, 5, 6]] as [[Float]])
        #expect(x[0, 0] == 1)
        #expect(x[0, 2] == 3)
        #expect(x[1, 0] == 4)
        #expect(x[1, 2] == 6)

        x[0, 1] = 99
        #expect(x[0, 1] == 99)
    }

    @Test
    func subscriptUMBP() {
        let x = MultiArray<Float>([[1, 2], [3, 4]] as [[Float]])
        let indexes = UnsafeMutableBufferPointer<Int>.allocate(capacity: 2)
        indexes.initialize(repeating: 0)
        defer { indexes.deallocate() }

        indexes[0] = 0; indexes[1] = 0
        #expect(x[indexes] == 1)

        indexes[0] = 1; indexes[1] = 1
        #expect(x[indexes] == 4)

        indexes[0] = 0; indexes[1] = 1
        x[indexes] = 99
        #expect(x[0, 1] == 99)
    }

    @Test
    func initializeElement() {
        let x = MultiArray<Float>.allocate(3, 2)
        x.initializeElement(at: [0, 0], to: 1.0)
        x.initializeElement(at: [0, 1], to: 2.0)
        x.initializeElement(at: [2, 0], to: 5.0)
        x.initializeElement(at: [2, 1], to: 6.0)

        #expect(x[0, 0] == 1.0)
        #expect(x[0, 1] == 2.0)
        #expect(x[2, 0] == 5.0)
        #expect(x[2, 1] == 6.0)
    }

    @Test
    func isValid() {
        let x = MultiArray<Float>.allocate(3, 4)
        #expect(x.isValid(indexes: [0, 0]))
        #expect(x.isValid(indexes: [2, 3]))
        #expect(!x.isValid(indexes: [3, 0]))
        #expect(!x.isValid(indexes: [0, 4]))
    }

    @Test
    func contiguousStrides() {
        let strides = MultiArray<Int>.contiguousStrides(shape: [4, 3, 2])
        #expect(Array(strides) == [6, 2, 1])
        strides.deallocate()
    }

    @Test
    func contiguousStridesEmpty() {
        let strides = MultiArray<Int>.contiguousStrides(shape: [])
        #expect(strides.isEmpty)
        strides.deallocate()
    }

    @Test
    func moved() {
        let x = MultiArray<Float>([1, 2, 3, 4])
        let buffer = x.moved()
        #expect(Array(buffer) == [1, 2, 3, 4])
        buffer.deallocate()
    }

    @Test
    func copyingInit() {
        let source = UnsafeMutableBufferPointer<Float>.allocate(capacity: 4)
        source.initialize(repeating: 0)
        source[0] = 1; source[1] = 2; source[2] = 3; source[3] = 4
        defer { source.deallocate() }

        let x = MultiArray<Float>(copying: source, shape: [2, 2])
        #expect(x.shape == [2, 2])
        #expect(x[0, 0] == 1)
        #expect(x[0, 1] == 2)
        #expect(x[1, 0] == 3)
        #expect(x[1, 1] == 4)
    }

    @Test
    func descriptionDoesNotCrash() {
        let x = MultiArray<Float>.random(2, 3)
        let desc = x.description
        #expect(!desc.isEmpty)
    }

    @Test
    func zeros() {
        let x = MultiArray<Float>.zeros(3, 2)
        #expect(x.shape == [3, 2])
        for i in 0..<x.count {
            #expect(x[offset: i] == 0.0)
        }
    }

    @Test
    func randomRange() {
        let x = MultiArray<Float>.random(100)
        var allInRange = true
        for i in 0..<x.count {
            if x[offset: i] < 0 || x[offset: i] > 1 {
                allInRange = false
                break
            }
        }
        #expect(allInRange)
    }

}

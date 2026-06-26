//
//  MethodsTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Testing
import MultiArray
import os


@Suite
struct MethodsTests {

    @Test func testReshape() {
        let x = MultiArray<Float>.random(3, 4)
        let y = x.reshape(-1, 3)
        #expect(y.shape == [4, 3])
    }

    @Test func reshapeTo1D() {
        let x = MultiArray<Float>.random(2, 3)
        let y = x.reshape(6)
        #expect(y.shape == [6])
    }

    @Test func reshapeSameShape() {
        let x = MultiArray<Float>.random(3, 4)
        let y = x.reshape(3, 4)
        #expect(y.shape == [3, 4])
        #expect(y.baseAddress == x.baseAddress)
    }

    @Test func testReflectPad() {
        let x = MultiArray([1, 2, 3, 4, 5])
        let y = x.reflectionPad(size: 3)
        #expect(Array(y) == [4, 3, 2, 1, 2, 3, 4, 5, 4, 3, 2])
    }

    @Test func reflectPadSize1() {
        let x = MultiArray([1, 2, 3])
        let y = x.reflectionPad(size: 1)
        #expect(Array(y) == [2, 1, 2, 3, 2])
    }

    @Test func reflectPadSize0() {
        let x = MultiArray([1, 2, 3])
        let y = x.reflectionPad(size: 0)
        #expect(Array(y) == [1, 2, 3])
    }

    @Test func forEach() async throws {
        let array = MultiArray.zeros(200, 100, 300)
        let signpost = OSSignposter(subsystem: "Trace", category: .pointsOfInterest)
        signpost.withIntervalSignpost("ForEach") {
            array.forEach { indexes, value in

            }
        }
    }

    @Test func pointer() async throws {
        let x = MultiArray(
            [
                [1, 2, 3],
                [4, 5, 6]
            ]
        )
        #expect(x.pointer(at: 0).pointee == 1)
        #expect(x.pointer(at: 1).pointee == 4)
        #expect(x.pointer(at: 0, 0).pointee == 1)
        #expect(x.pointer(at: 1, 0).pointee == 4)
        #expect(Array(UnsafeMutableBufferPointer(start: x.pointer(at: 1, 0), count: 3)) == [4, 5, 6])
    }

}

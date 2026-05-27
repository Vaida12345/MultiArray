//
//  OperationsTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-23.
//

import Testing
@testable
import MultiArray
import Accelerate


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

    @Test func clip() async throws {
        var a = MultiArray<Float>([0, 0])
        vForce.log10(a, result: &a)
        a.clip(to: -1...1)
        #expect(Array(a) == [-1, -1])
    }

    @Test func negate() {
        let x = MultiArray<Float>([1, -2, 3, -4])
        x.negate()
        #expect(Array(x) == [-1, 2, -3, 4])
    }

    @Test func add() {
        let x = MultiArray<Float>([1, 2, 3, 4])
        let y = MultiArray<Float>([5, 6, 7, 8])
        let z = x + y
        #expect(Array(z) == [6, 8, 10, 12])
    }

    @Test func addInPlace() {
        var x = MultiArray<Float>([1, 2, 3, 4])
        let y = MultiArray<Float>([5, 6, 7, 8])
        x += y
        #expect(Array(x) == [6, 8, 10, 12])
    }

    @Test func subtract() {
        let x = MultiArray<Float>([5, 6, 7, 8])
        let y = MultiArray<Float>([1, 2, 3, 4])
        let z = x - y
        #expect(Array(z) == [4, 4, 4, 4])
    }

    @Test func subtractInPlace() {
        var x = MultiArray<Float>([5, 6, 7, 8])
        let y = MultiArray<Float>([1, 2, 3, 4])
        x -= y
        #expect(Array(x) == [4, 4, 4, 4])
    }

    @Test func multiplyByScalar() {
        let x = MultiArray<Float>([1, 2, 3, 4])
        let z = x * 2
        #expect(Array(z) == [2, 4, 6, 8])
    }

    @Test func multiplyByScalarInPlace() {
        var x = MultiArray<Float>([1, 2, 3, 4])
        x *= 3
        #expect(Array(x) == [3, 6, 9, 12])
    }

    @Test func divideByScalar() {
        let x = MultiArray<Float>([2, 4, 6, 8])
        let z = x / 2
        #expect(Array(z) == [1, 2, 3, 4])
    }

    @Test func divideByScalarInPlace() {
        var x = MultiArray<Float>([2, 4, 6, 8])
        x /= 2
        #expect(Array(x) == [1, 2, 3, 4])
    }

    @Test func scalarDivideArray() {
        let x = MultiArray<Float>([1, 2, 4, 8])
        let z = 8 / x
        #expect(Array(z) == [8, 4, 2, 1])
    }

    @Test func absValue() {
        let x = MultiArray<Float>([-1, 0, 2, -3])
        let z = abs(x)
        #expect(Array(z) == [1, 0, 2, 3])
    }

    @Test func transpose2D() {
        let x = MultiArray<Float>([[1, 2, 3], [4, 5, 6]] as [[Float]])
        let z = x.transposed()
        #expect(z.shape == [3, 2])
        #expect(z[0, 0] == 1)
        #expect(z[0, 1] == 4)
        #expect(z[1, 0] == 2)
        #expect(z[1, 1] == 5)
        #expect(z[2, 0] == 3)
        #expect(z[2, 1] == 6)
    }

    @Test func strideFromThrough() {
        let x = MultiArray<Float>.stride(from: 0, through: 1, count: 5)
        #expect(x.count == 5)
        #expect(abs(x[0] - 0.0) < 1e-4)
        #expect(abs(x[4] - 1.0) < 1e-4)
    }

    @Test func strideFromBy() {
        let x = MultiArray<Float>.stride(from: 0, by: 0.25, count: 5)
        #expect(x.count == 5)
        #expect(abs(x[0] - 0.00) < 1e-4)
        #expect(abs(x[1] - 0.25) < 1e-4)
        #expect(abs(x[4] - 1.00) < 1e-4)
    }

    @Test func fill() {
        let x = MultiArray<Float>.allocate(3)
        x.fill(with: 42)
        #expect(Array(x) == [42, 42, 42])
    }

    @Test func minMax() {
        let x = MultiArray<Float>([3, -1, 7, 2, 0])
        #expect(x.min() == -1)
        #expect(x.max() == 7)
    }

    @Test func multiplyEachRow() {
        let x = MultiArray<Float>([[1, 2], [3, 4], [5, 6]] as [[Float]])
        let row = MultiArray<Float>([2, 3, 4])
        x.multiplyEachRow(byEachOf: row)
        #expect(x[0, 0] == 2)
        #expect(x[0, 1] == 4)
        #expect(x[1, 0] == 9)
        #expect(x[1, 1] == 12)
        #expect(x[2, 0] == 20)
        #expect(x[2, 1] == 24)
    }


}

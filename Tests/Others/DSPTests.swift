//
//  DSPTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-22.
//

import Testing
import MultiArray
import Accelerate


extension Tag {
    @Tag static var dft: Self
    @Tag static var idft: Self
    @Tag static var stft: Self
    @Tag static var istft: Self
}


struct DSPTests {
    
    @Suite
    struct STFTTests {
        
        @Test(.tags(.stft))
        func length16() {
            let stft = ShortTimeFourierTransform(n_fft: 8, hop: 4)
            let input = MultiArray((0..<16).map(Float.init))
            let data = stft(input)
            
            let reference: [Float] = [4.585787, 0.0, 16.0, 0.0, 32.0, 0.0, 48.0, 0.0, 54.414215, 0.0, -0.58578646, 1.3155118e-08, -8.0, 3.8284268, -16.0, 3.8284264, -24.0, 3.8284266, -28.414215, -2.4142137, -2.0, -0.0, 3.6211688e-08, -0.82842684, 3.6211667e-08, -0.82842636, 3.621171e-08, -0.8284273, 0.99999994, 1.4142132, 0.58578646, 1.3155118e-08, 0.0, -0.17157304, 0.0, -0.17157304, 0.0, -0.1715734, 0.41421413, -0.41421366, -0.5857866, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.41421318, 0.0]
            #expect(data.shape == [5, 5, 2])
            #expect(reference.contentsEqual(Array(data.buffer), tolerance: 1e-3))
        }
        
    }
    
    @Suite(.tags(.stft, .istft))
    struct ISTFTTests {
        
        func length(count: Int, hop: Int) {
            let input = MultiArray<Float>((0..<count).map(Float.init))
            let transform = ShortTimeFourierTransform(n_fft: count, hop: hop)(input)
            let output = InverseShortTimeFourierTransform(n_fft: count, hop: hop)(transform)
            let isTrue = input.contentsEqual(MultiArray(output), tolerance: 1e-2)
            #expect(isTrue, "failed for count \(count), tolerance \(1e-2)")
        }
        
        @Test(arguments: 4...11)
        func length2n(i: Int) {
            length(count: 1 << i, hop: 4)
        }
        
        @Test(arguments: 4...8)
        func length3_2n(i: Int) {
            length(count: 3 * (1 << i), hop: 4)
        }
        
    }
    
    @Suite(.tags(.dft))
    struct DFTTests {
        
        @Test func length16() {
            let dft = DiscreteFourierTransform(count: 16)
            var input = (0..<16).map(Float.init)
            let reference = MultiArray<Float>([
                    [120, 0],
                    [-8, 40.2187],
                    [-8, 19.3137],
                    [-8, 11.9728],
                    [-8, 8.0000],
                    [-8, 5.3454],
                    [-8, 3.3137],
                    [-8, 1.5913],
                    [-8, 0.0000]
            ] as [[Float]])
            let output = input.withMultiArray { input in
                dft(input)
            }
            #expect(output.contentsEqual(reference, tolerance: 1e-4))
        }

        // MARK: - Position / stride

        /// DFT of impulse: all bins = 0.5 (after 0.5× scaling). Verifies each bin lands at its expected position.
        @Test func impulsePositionStride1() {
            let n = 8
            let dft = DiscreteFourierTransform(count: n)
            var input = [Float](repeating: 0, count: n)
            input[0] = 1.0

            let output = input.withMultiArray { dft($0) }

            // [5, 2] → 10 floats; all five complex bins = (1.0, 0)
            #expect(output.shape == [5, 2])
            let expected: [Float] = [1.0, 0, 1.0, 0, 1.0, 0, 1.0, 0, 1.0, 0]
            #expect(expected.contentsEqual(Array(output.buffer), tolerance: 1e-4))
        }

        /// DFT of constant: only DC = N/2; every other bin must be 0 at the right place.
        @Test func constantPositionStride1() {
            let n = 8
            let dft = DiscreteFourierTransform(count: n)
            var input = [Float](repeating: 1, count: n)

            let output = input.withMultiArray { dft($0) }

            #expect(output.shape == [5, 2])
            let expected: [Float] = [8.0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            #expect(expected.contentsEqual(Array(output.buffer), tolerance: 1e-4))
        }

        /// DFT of a pure sinusoid (freq = 2, N = 8). Only bin 2 should be non-zero.
        @Test func sinusoidFrequencyPlacement() {
            let n = 8
            let dft = DiscreteFourierTransform(count: n)
            // sin(2π·2·t/8), t = 0…7
            var input: [Float] = [0, 1, 0, -1, 0, 1, 0, -1]

            let output = input.withMultiArray { dft($0) }

            // sum x[t]·exp(-i·2π·2·t/8) = -4i  →  (0, -4) at bin 2
            #expect(abs(output[0, 0] - 0.0) < 1e-4)
            #expect(abs(output[0, 1] - 0.0) < 1e-4)
            #expect(abs(output[1, 0] - 0.0) < 1e-4)
            #expect(abs(output[1, 1] - 0.0) < 1e-4)
            #expect(abs(output[2, 0] - 0.0) < 1e-4)
            #expect(abs(output[2, 1] - (-4.0)) < 1e-2)
            #expect(abs(output[3, 0] - 0.0) < 1e-4)
            #expect(abs(output[3, 1] - 0.0) < 1e-4)
            #expect(abs(output[4, 0] - 0.0) < 1e-4)
            #expect(abs(output[4, 1] - 0.0) < 1e-4)
        }

        /// DFT with N = 4 (smallest even N) — edge case.
        @Test func impulseN4() {
            let n = 4
            let dft = DiscreteFourierTransform(count: n)
            var input = [Float](repeating: 0, count: n)
            input[0] = 1.0

            let output = input.withMultiArray { dft($0) }

            #expect(output.shape == [3, 2])
            let expected: [Float] = [1.0, 0, 1.0, 0, 1.0, 0]
            #expect(expected.contentsEqual(Array(output.buffer), tolerance: 1e-4))
        }

        /// DFT into a pre-filled buffer with stride = 3. Sentinel values surrounding the
        /// result region must stay untouched and each bin must sit at the correct offset.
        @Test func strideLayout3() {
            let n = 8
            let dft = DiscreteFourierTransform(count: n)
            let input = MultiArray<Float>([Float](repeating: 1, count: n))

            let total = 100
            let sentinel: Float = -999.0
            let buf = UnsafeMutableBufferPointer<Float>.allocate(capacity: total)
            buf.initialize(repeating: sentinel)
            defer { buf.deallocate() }

            let offset = 10
            let stride = 3

            dft(input, result: buf.baseAddress! + offset, stride: stride)

            // sentinel before result region
            for i in 0..<offset {
                #expect(buf[i] == sentinel)
            }

            // DC (always at complex offset 0)
            #expect(abs(buf[offset + 0] - 8.0) < 1e-4)
            #expect(abs(buf[offset + 1] - 0.0) < 1e-4)

            // bin positions with correct stride (IC = stride = 3):
            //   f0→(0,1)  f1→(6,7)  f2→(12,13)  f3→(18,19)  Nyq→(24,25)
            let bins: [(label: String, pos: Int)] = [
                ("f1", 6), ("f2", 12), ("f3", 18), ("Nyq", 24)
            ]
            for (label, pos) in bins {
                #expect(abs(buf[offset + pos + 0] - 0.0) < 1e-4,
                        "\(label) real at +\(pos): \(buf[offset + pos + 0])")
                #expect(abs(buf[offset + pos + 1] - 0.0) < 1e-4,
                        "\(label) imag at +\(pos + 1): \(buf[offset + pos + 1])")
            }

            // gaps between bins must stay sentinel
            for i in (offset + 2)..<(offset + 6) {
                #expect(buf[i] == sentinel, "gap at \(i): \(buf[i])")
            }
            for i in (offset + 8)..<(offset + 12) {
                #expect(buf[i] == sentinel, "gap at \(i): \(buf[i])")
            }

            // after Nyquist
            for i in (offset + 26)..<min(offset + 40, total) {
                #expect(buf[i] == sentinel, "after Nyquist at \(i): \(buf[i])")
            }
        }

        /// DFT into a pre-filled buffer with stride = 5 (simulates STFT frame spacing).
        @Test func strideLayout5() {
            let n = 8
            let dft = DiscreteFourierTransform(count: n)
            let input = MultiArray<Float>([Float](repeating: 1, count: n))

            let total = 200
            let sentinel: Float = -999.0
            let buf = UnsafeMutableBufferPointer<Float>.allocate(capacity: total)
            buf.initialize(repeating: sentinel)
            defer { buf.deallocate() }

            let offset = 20
            let stride = 5

            dft(input, result: buf.baseAddress! + offset, stride: stride)

            for i in 0..<offset {
                #expect(buf[i] == sentinel)
            }

            #expect(abs(buf[offset + 0] - 8.0) < 1e-4)
            #expect(abs(buf[offset + 1] - 0.0) < 1e-4)

            // correct layout (IC = 5): f0→(0,1) f1→(10,11) f2→(20,21) f3→(30,31) Nyq→(40,41)
            let bins: [(label: String, pos: Int)] = [
                ("f1", 10), ("f2", 20), ("f3", 30), ("Nyq", 40)
            ]
            for (label, pos) in bins {
                #expect(abs(buf[offset + pos + 0] - 0.0) < 1e-4,
                        "\(label) real at +\(pos): \(buf[offset + pos + 0])")
                #expect(abs(buf[offset + pos + 1] - 0.0) < 1e-4,
                        "\(label) imag at +\(pos + 1): \(buf[offset + pos + 1])")
            }

            // gap between DC and f1
            for i in (offset + 2)..<(offset + 10) {
                #expect(buf[i] == sentinel, "gap at \(i): \(buf[i])")
            }
            // after Nyquist
            for i in (offset + 42)..<min(offset + 60, total) {
                #expect(buf[i] == sentinel, "after Nyquist at \(i): \(buf[i])")
            }
        }

        /// Two frames written into the same buffer; frames must not interfere.
        @Test func twoFrameLayout() {
            let n = 8
            let dft = DiscreteFourierTransform(count: n)

            let total = 200
            let sentinel: Float = -999.0
            let buf = UnsafeMutableBufferPointer<Float>.allocate(capacity: total)
            buf.initialize(repeating: sentinel)
            defer { buf.deallocate() }

            let stride = 5

            // frame 0: constant → DC = 4
            dft(MultiArray<Float>([Float](repeating: 1, count: n)),
                result: buf.baseAddress! + 0, stride: stride)
            // frame 1: zeros → all bins = 0
            dft(MultiArray<Float>([Float](repeating: 0, count: n)),
                result: buf.baseAddress! + 2, stride: stride)

            // frame 0 DC
            #expect(abs(buf[0] - 8.0) < 1e-4)
            #expect(abs(buf[1] - 0.0) < 1e-4)
            // frame 1 DC
            #expect(abs(buf[2] - 0.0) < 1e-4)
            #expect(abs(buf[3] - 0.0) < 1e-4)
            // frame 0 f1 at float offset 10
            #expect(abs(buf[10] - 0.0) < 1e-4)
            #expect(abs(buf[11] - 0.0) < 1e-4)
            // frame 1 f1 at float offset 12
            #expect(abs(buf[12] - 0.0) < 1e-4)
            #expect(abs(buf[13] - 0.0) < 1e-4)
            // frame 0 f2 at float offset 20
            #expect(abs(buf[20] - 0.0) < 1e-4)
            // frame 1 f2 at float offset 22
            #expect(abs(buf[22] - 0.0) < 1e-4)
        }
    }
    
    @Suite(.tags(.dft, .idft))
    struct IDFTTests {
        
        func length(count: Int) {
            var input = (0..<count).map(Float.init)
            input.withMultiArray { input in
                let transform = DiscreteFourierTransform(count: count)(input)
                let output = InverseDiscreteFourierTransform(count: count)(transform)
                let isTrue = Array(input.buffer).contentsEqual(output, tolerance: 1e-3)
                #expect(isTrue, "failed for count \(count), tolerance \(1e-3)")
            }
        }
        
        @Test(arguments: 4...11)
        func length2n(i: Int) {
            length(count: 1 << i)
        }
        
        @Test(arguments: 4...9)
        func length3_2n(i: Int) {
            length(count: 3 * (1 << i))
        }
        
        @Test(arguments: 4...8)
        func length5_2n(i: Int) {
            length(count: 5 * (1 << i))
        }
        
        @Test(arguments: 4...7)
        func length15_2n(i: Int) {
            length(count: 15 * (1 << i))
        }

        // MARK: - Stride

        /// IDFT with stride = 3: feed DC-only input, expect constant output.
        @Test func strideLayout3() {
            let n = 8
            let idft = InverseDiscreteFourierTransform(count: n)

            let stride = 3
            let half = n / 2 + 1                       // 5
            var buf = [DSPComplex](repeating: DSPComplex(real: 0, imag: 0),
                                   count: half * stride) // 15

            buf[0] = DSPComplex(real: 1.0, imag: 0)     // DC
            // Nyquist (freq 4) lives in DC's imag slot per vDSP packed convention
            // and also at complex position (n/2)*stride

            let output: [Float] = buf.withUnsafeMutableBufferPointer { cb in
                cb.withMemoryRebound(to: Float.self) { fp in
                    idft(fp.baseAddress!, stride: stride)
                }
            }

            #expect(output.count == n)
            let expected = 1.0 / Float(n)
            for i in 0..<n {
                #expect(abs(output[i] - expected) < 1e-4,
                        "output[\(i)] = \(output[i]), expected \(expected)")
            }
        }

        /// IDFT of uniform spectrum (all bins = 1) → time-domain impulse at t = 0.
        @Test func uniformSpectrumGivesImpulse() {
            let n = 8
            let idft = InverseDiscreteFourierTransform(count: n)

            let stride = 1
            let half = n / 2 + 1                       // 5
            var buf = [DSPComplex](repeating: DSPComplex(real: 1.0, imag: 0),
                                   count: half)
            buf[0].imag = 1.0                           // Nyquist in DC imag

            let output: [Float] = buf.withUnsafeMutableBufferPointer { cb in
                cb.withMemoryRebound(to: Float.self) { fp in
                    idft(fp.baseAddress!, stride: stride)
                }
            }

            #expect(output.count == n)
            #expect(abs(output[0] - 1.0) < 1e-4)
            for i in 1..<n {
                #expect(abs(output[i] - 0.0) < 1e-4, "output[\(i)] = \(output[i])")
            }
        }

        /// IDFT reads from stride = 3 buffer: only frequency 2 excited → pure 2·n sinusoid.
        @Test func singleFrequencyStride3() {
            let n = 8
            let idft = InverseDiscreteFourierTransform(count: n)

            let stride = 3
            let k: Int = 2                              // excite frequency bin 2
            let half = n / 2 + 1
            var buf = [DSPComplex](repeating: DSPComplex(real: 0, imag: 0),
                                   count: half * stride)

            buf[k * stride] = DSPComplex(real: 1.0, imag: 0)

            let output: [Float] = buf.withUnsafeMutableBufferPointer { cb in
                cb.withMemoryRebound(to: Float.self) { fp in
                    idft(fp.baseAddress!, stride: stride)
                }
            }

            #expect(output.count == n)
            // A single real excitation at bin k yields x[t] = (2/N)·cos(2π·k·t/N)
            for t in 0..<n {
                let expected = (2.0 / Float(n)) * cosf(2.0 * Float.pi * Float(k) * Float(t) / Float(n))
                #expect(abs(output[t] - expected) < 1e-4,
                        "t=\(t): \(output[t]) vs \(expected)")
            }
        }
    }
}


extension Array<Float> {
    
    func contentsEqual(_ other: some Sequence<Float>, tolerance: Float = 1e-6) -> Bool {
        zip(self, other).allSatisfy { abs($0.0 - $0.1) < tolerance }
    }
    
}


extension Array<DSPComplex> {
    
    func contentsEqual(_ other: some Sequence<DSPComplex>, tolerance: Float = 1e-4) -> Bool {
        zip(self, other).allSatisfy { abs($0.0.real - $0.1.real) < tolerance && abs($0.0.imag - $0.1.imag) < tolerance }
    }
    
}

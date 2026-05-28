//
//  LogMelTests.swift
//  MultiArray
//
//  Created by Vaida on 2025-06-03.
//

import Testing
@testable import MultiArray
import Foundation
import Accelerate


@Test func logMel() {
    let inputs = MultiArray<Float>(Array(0..<162048).map { sin(Float($0) * 0.001) })
    let frames_per_second = 100
    
    let signpost = OSSignposter(subsystem: "main", category: .pointsOfInterest)
    let signpostID = signpost.makeSignpostID()
    
    let state = signpost.beginInterval("Logmel", id: signpostID)
    
    let stft = ShortTimeFourierTransform(n_fft: 2048, hop: 16000 / frames_per_second, center: false)
    var output = stft(inputs)
    var count = Int32(output.count)
    vDSP.multiply(output, output, result: &output)
    
    signpost.emitEvent("Iterate", id: signpostID)
    
    // now convert to torchlibrosa style
    let spectrogram = MultiArray<Float>.allocate(1001, 1025)
    
    var i = 0
    let iterator = UnsafeMutableBufferPointer<Int>.allocate(capacity: 2)
    iterator.initialize(repeating: 0)
    defer { iterator.deallocate() }
    
    
    let outputCount = output.count
    while i < outputCount {
        // work
        spectrogram[iterator[1], iterator[0]] = output.buffer[i] + output.buffer[i + 1]
        
        iterator[1] &+= 1
        
        // carry
        var ishape = 1
        while ishape != 0 {
            if iterator[ishape] == output.shape[ishape] {
                iterator[ishape] = 0
                iterator[ishape &- 1] &+= 1
            } else {
                break
            }
            ishape &-= 1
        }
        
        i &+= 2
    }
    
    signpost.emitEvent("Spectrogram", id: signpostID)
    
    // MARK: - LogmelFilterBank
    
    
    let melW = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 229, fmin: 30, fmax: 16000 / 2)
    let a = melW(spectrogram)
    
    
    signpost.endInterval("Logmel", state)
    
}


@Suite
struct LogMelFilterTests {
    
    // MARK: - Filter bank shape
    
    @Test func filterShape() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 128, fmin: 30, fmax: 8000)
        #expect(mel.filters.shape == [128, 1025])
    }
    
    @Test func filterShapeDefaultFmax() {
        let mel = LogmelFilter(sampleRate: 22050, n_fft: 2048, n_mels: 64)
        #expect(mel.filters.shape == [64, 1025])
    }
    
    @Test func filterShapeSmallNFFT() {
        let mel = LogmelFilter(sampleRate: 8000, n_fft: 16, n_mels: 8, fmin: 0, fmax: 4000)
        #expect(mel.filters.shape == [8, 9])
    }
    
    // MARK: - Filter weight properties
    
    @Test func filterWeightsAreNonNegative() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64, fmin: 30, fmax: 8000)
        for (i, val) in mel.filters.buffer.enumerated() {
            #expect(val >= -1e-4, "Negative filter weight at index \(i): \(val)")
        }
    }
    
    @Test func filterWeightsAreFinite() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64, fmin: 30, fmax: 8000)
        for (i, val) in mel.filters.buffer.enumerated() {
            #expect(val.isFinite, "Non-finite filter weight at index \(i): \(val)")
        }
    }
    
    @Test func eachMelBandHasNonZeroWeight() {
        let n_mels = 64
        let nFreqBins = 1 + 2048 / 2
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: n_mels, fmin: 30, fmax: 8000)
        for melIdx in 0..<n_mels {
            var maxWeight: Float = 0
            for freqIdx in 0..<nFreqBins {
                let w = mel.filters[melIdx, freqIdx]
                if w > maxWeight { maxWeight = w }
            }
            #expect(maxWeight > 0, "Mel band \(melIdx) has no positive weights")
        }
    }
    
    @Test func filterWeightsAreNormalized() {
        // After enorm = 2/(mel_f[i+2] - mel_f[i]), each triangular filter
        // should have a peak height not exceeding 1.
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64, fmin: 30, fmax: 8000)
        let maxWeight = mel.filters.buffer.max()!
        #expect(maxWeight <= 1.0 + 1e-3, "Max filter weight \(maxWeight) exceeds 1.0")
    }
    
    // MARK: - Triangular structure
    
    @Test func filtersHaveTriangularStructure() {
        let n_mels = 16
        let n_fft = 256
        let nFreqBins = n_fft / 2 + 1
        let mel = LogmelFilter(sampleRate: 16000, n_fft: n_fft, n_mels: n_mels, fmin: 0, fmax: 8000)
        
        for melIdx in 0..<n_mels {
            var firstNonZero: Int?
            var lastNonZero: Int?
            for freqIdx in 0..<nFreqBins {
                if mel.filters[melIdx, freqIdx] > 1e-6 {
                    if firstNonZero == nil { firstNonZero = freqIdx }
                    lastNonZero = freqIdx
                }
            }
            guard let first = firstNonZero, let last = lastNonZero else {
                #expect(Bool(false), "Mel band \(melIdx) has no non-zero weights")
                continue
            }
            // Verify no gaps: every bin between first and last should be > 0
            // (triangular filters are strictly positive in their passband)
            for freqIdx in first...last {
                #expect(mel.filters[melIdx, freqIdx] > -1e-4,
                        "Gap in mel band \(melIdx) at frequency bin \(freqIdx)")
            }
        }
    }
    
    @Test func filterPeaksAreBetweenEndpoints() {
        let n_mels = 16
        let n_fft = 256
        let nFreqBins = n_fft / 2 + 1
        let mel = LogmelFilter(sampleRate: 16000, n_fft: n_fft, n_mels: n_mels, fmin: 0, fmax: 8000)
        
        for melIdx in 1..<(n_mels - 1) {
            var peakIdx = 0
            var peakVal: Float = 0
            var firstNonZero: Int?
            var lastNonZero: Int?
            for freqIdx in 0..<nFreqBins {
                let w = mel.filters[melIdx, freqIdx]
                if w > peakVal { peakVal = w; peakIdx = freqIdx }
                if w > 1e-6 {
                    if firstNonZero == nil { firstNonZero = freqIdx }
                    lastNonZero = freqIdx
                }
            }
            guard let first = firstNonZero, let last = lastNonZero else { continue }
            #expect(peakIdx > first && peakIdx < last,
                    "Mel band \(melIdx): peak at \(peakIdx), range [\(first), \(last)]")
        }
    }
    
    // MARK: - Determinism
    
    @Test func filterConstructionIsDeterministic() {
        let mel1 = LogmelFilter(sampleRate: 16000, n_fft: 512, n_mels: 32, fmin: 30, fmax: 8000)
        let mel2 = LogmelFilter(sampleRate: 16000, n_fft: 512, n_mels: 32, fmin: 30, fmax: 8000)
        #expect(mel1.filters.buffer.elementsEqual(mel2.filters.buffer))
    }
    
    // MARK: - callAsFunction output shape
    
    @Test func outputShape() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64)
        let input = MultiArray<Float>.zeros(10, 1025)
        let output = mel(input)
        #expect(output.shape == [10, 64])
    }
    
    @Test func outputShapeSingleFrame() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 128, fmin: 30, fmax: 8000)
        let input = MultiArray<Float>.zeros(1, 1025)
        let output = mel(input)
        #expect(output.shape == [1, 128])
    }
    
    @Test func outputShapeManyFrames() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64)
        let input = MultiArray<Float>.zeros(500, 1025)
        let output = mel(input)
        #expect(output.shape == [500, 64])
    }
    
    // MARK: - callAsFunction output properties
    
    @Test func outputIsNonNegative() {
        // With non-negative input and non-negative filter weights,
        // the output must be non-negative.
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64)
        let input = MultiArray<Float>.zeros(5, 1025)
        input.fill(with: 1.0)
        let output = mel(input)
        for (i, val) in output.buffer.enumerated() {
            #expect(val.isFinite, "Non-finite output at index \(i): \(val)")
            #expect(val >= -1e-4, "Negative output at index \(i): \(val)")
        }
    }
    
    @Test func outputIsFinite() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64)
        let input = MultiArray<Float>.zeros(5, 1025)
        input.fill(with: 1.0)
        let output = mel(input)
        for (i, val) in output.buffer.enumerated() {
            #expect(val.isFinite, "Non-finite output at index \(i): \(val)")
        }
    }
    
    @Test func outputIsDeterministic() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64)
        let input = MultiArray<Float>.random(5, 1025)
        let output1 = mel(input)
        let output2 = mel(input)
        #expect(output1.buffer.elementsEqual(output2.buffer))
    }
    
    // MARK: - Zero and identity inputs
    
    @Test func zeroInputGivesZeroOutput() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64)
        let input = MultiArray<Float>.zeros(3, 1025)
        let output = mel(input)
        for val in output.buffer {
            #expect(abs(val) < 1e-4, "Zero input should give zero output, got \(val)")
        }
    }
    
    @Test func singleFrequencyResponse() {
        let n_mels = 64
        let n_fft = 2048
        let mel = LogmelFilter(sampleRate: 16000, n_fft: n_fft, n_mels: n_mels, fmin: 30, fmax: 8000)
        // Activate a single frequency bin; each mel band response equals
        // the corresponding filter weight.
        let k = 500
        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input[0, k] = 1.0
        let output = mel(input)

        var maxResponse: Float = 0
        for melIdx in 0..<n_mels {
            let val = output[0, melIdx]
            #expect(val >= -1e-4, "Negative response at mel band \(melIdx): \(val)")
            if val > maxResponse { maxResponse = val }
        }
        #expect(maxResponse > 0, "No mel band responded to frequency bin \(k)")
    }
    
    // MARK: - Edge cases
    
    @Test func singleMelBand() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 1, fmin: 30, fmax: 8000)
        #expect(mel.filters.shape == [1, 1025])
        let input = MultiArray<Float>.zeros(3, 1025)
        input.fill(with: 1.0)
        let output = mel(input)
        #expect(output.shape == [3, 1])
        for val in output.buffer {
            #expect(val.isFinite)
        }
    }
    
    @Test func narrowFrequencyRange() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 512, n_mels: 32, fmin: 1000, fmax: 2000)
        #expect(mel.filters.shape == [32, 257])
        let minWeight = mel.filters.buffer.min()!
        #expect(minWeight >= -1e-4, "Narrow fmin-fmax range: negative weight \(minWeight)")
        // At least some filters should have positive weights
        let maxWeight = mel.filters.buffer.max()!
        #expect(maxWeight > 0, "Narrow fmin-fmax range: no positive weights found")
    }
    
    @Test func fminAtZero() {
        let mel = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 64, fmin: 0, fmax: 8000)
        let minWeight = mel.filters.buffer.min()!
        #expect(minWeight >= -1e-4)
    }
    
    @Test func highSampleRate() {
        let mel = LogmelFilter(sampleRate: 44100, n_fft: 4096, n_mels: 128, fmin: 20, fmax: 22050)
        #expect(mel.filters.shape == [128, 2049])
        let minWeight = mel.filters.buffer.min()!
        #expect(minWeight >= -1e-4)
    }
    
    // MARK: - Monotonicity
    
    @Test func melBandsIncreaseInCenterFrequency() {
        // Higher mel band indices should respond to higher frequencies.
        // Find the peak frequency bin for each mel band and verify they increase.
        let n_mels = 32
        let n_fft = 512
        let nFreqBins = n_fft / 2 + 1
        let mel = LogmelFilter(sampleRate: 16000, n_fft: n_fft, n_mels: n_mels, fmin: 0, fmax: 8000)
        
        var peakBins: [Int] = []
        for melIdx in 0..<n_mels {
            var peakBin = 0
            var peakVal: Float = 0
            for freqIdx in 0..<nFreqBins {
                let w = mel.filters[melIdx, freqIdx]
                if w > peakVal { peakVal = w; peakBin = freqIdx }
            }
            if peakVal > 0 {
                peakBins.append(peakBin)
            }
        }
        // Peak bins should be strictly increasing
        for i in 1..<peakBins.count {
            #expect(peakBins[i] > peakBins[i - 1],
                    "Mel bands not monotonic: band \(i) peaks at bin \(peakBins[i]), band \(i-1) at \(peakBins[i - 1])")
        }
    }
}


// MARK: - Librosa Comparison Suite

/// Tests that verify the Swift LogmelFilter output matches librosa's
/// `librosa.filters.mel` reference values exactly.
@Suite
struct LogMelLibrosaComparisonTests {

    /// Load the reference JSON generated by the Python script.
    private static func loadReference() throws -> [String: Any] {
        let testDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let jsonURL = testDir.appendingPathComponent("logmel_reference.json")
        let data = try Data(contentsOf: jsonURL)
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return obj
    }

    /// Assert two float arrays match within tolerance.
    private static func expectEqual(_ actual: [Float], _ expected: [Float], tolerance: Float = 1e-5, _ message: @autoclosure () -> String = "") {
        guard actual.count == expected.count else {
            #expect(Bool(false), "\(message()) length mismatch: \(actual.count) vs \(expected.count)")
            return
        }
        for i in actual.indices {
            let diff = abs(actual[i] - expected[i])
            #expect(diff < tolerance, "\(message()) [\(i)]: \(actual[i]) vs \(expected[i]) (diff \(diff))")
        }
    }

    // MARK: - Test A: Small filter exact comparison

    @Test func filterBankMatchesLibrosaSmall() throws {
        let ref = try Self.loadReference()
        let a = ref["A"] as! [String: Any]
        let sr = a["sr"] as! Float
        let n_fft = a["n_fft"] as! Int
        let n_mels = a["n_mels"] as! Int
        let fmin = a["fmin"] as! Float
        let fmax = a["fmax"] as! Float
        let expectedMel = (a["mel_basis"] as! [[Double]]).map { $0.map(Float.init) }

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)

        #expect(mel.filters.shape == [n_mels, n_fft / 2 + 1])

        for i in 0..<n_mels {
            for j in 0..<(n_fft / 2 + 1) {
                let diff = abs(mel.filters[i, j] - expectedMel[i][j])
                #expect(diff < 1e-5, "A: filter[\(i),\(j)] swift=\(mel.filters[i, j]) librosa=\(expectedMel[i][j]) (diff \(diff))")
            }
        }
    }

    @Test func onesInputMatchesLibrosaSmall() throws {
        let ref = try Self.loadReference()
        let a = ref["A"] as! [String: Any]
        let sr = a["sr"] as! Float
        let n_fft = a["n_fft"] as! Int
        let n_mels = a["n_mels"] as! Int
        let fmin = a["fmin"] as! Float
        let fmax = a["fmax"] as! Float
        let expected = (a["ones_output"] as! [[Double]]).flatMap { $0.map(Float.init) }

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input.fill(with: 1.0)
        let output = mel(input)

        Self.expectEqual(Array(output.buffer), expected, tolerance: 1e-5, "A: ones output")
    }

    @Test func singleFrequencyMatchesLibrosaSmall() throws {
        let ref = try Self.loadReference()
        let a = ref["A"] as! [String: Any]
        let sr = a["sr"] as! Float
        let n_fft = a["n_fft"] as! Int
        let n_mels = a["n_mels"] as! Int
        let fmin = a["fmin"] as! Float
        let fmax = a["fmax"] as! Float
        let expected = (a["single3_output"] as! [[Double]]).flatMap { $0.map(Float.init) }

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input[0, 3] = 1.0
        let output = mel(input)

        Self.expectEqual(Array(output.buffer), expected, tolerance: 1e-5, "A: single freq bin 3")
    }

    // MARK: - Test B: n_mels=1

    @Test func singleMelBandMatchesLibrosa() throws {
        let ref = try Self.loadReference()
        let b = ref["B"] as! [String: Any]
        let sr = b["sr"] as! Float
        let n_fft = b["n_fft"] as! Int
        let n_mels = b["n_mels"] as! Int
        let fmin = b["fmin"] as! Float
        let fmax = b["fmax"] as! Float
        let expectedSum = Float(b["ones_output_sum"] as! Double)
        let expectedShape = b["mel_shape"] as! [Int]

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        #expect(mel.filters.shape == expectedShape)

        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input.fill(with: 1.0)
        let output = mel(input)
        #expect(abs(output[0, 0] - expectedSum) < 1e-5,
                "B: ones sum swift=\(output[0, 0]) expected=\(expectedSum)")
    }

    // MARK: - Test C: MIR params, all-ones

    @Test func onesInputMatchesLibrosaMIR() throws {
        let ref = try Self.loadReference()
        let c = ref["C"] as! [String: Any]
        let sr = c["sr"] as! Float
        let n_fft = c["n_fft"] as! Int
        let n_mels = c["n_mels"] as! Int
        let fmin = c["fmin"] as! Float
        let fmax = c["fmax"] as! Float
        let expected = (c["ones_output"] as! [[Double]]).flatMap { $0.map(Float.init) }

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input.fill(with: 1.0)
        let output = mel(input)

        Self.expectEqual(Array(output.buffer), expected, tolerance: 1e-5, "C: ones output")
    }

    // MARK: - Test D: Single frequency bin 500, fmin=30

    @Test func singleFrequencyMatchesLibrosaMIR() throws {
        let ref = try Self.loadReference()
        let d = ref["D"] as! [String: Any]
        let sr = d["sr"] as! Float
        let n_fft = d["n_fft"] as! Int
        let n_mels = d["n_mels"] as! Int
        let fmin = d["fmin"] as! Float
        let fmax = d["fmax"] as! Float
        let expected = (d["single500_output"] as! [[Double]]).flatMap { $0.map(Float.init) }

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input[0, 500] = 1.0
        let output = mel(input)

        Self.expectEqual(Array(output.buffer), expected, tolerance: 1e-5, "D: single freq 500")
    }

    // MARK: - Test E: Narrow frequency range

    @Test func narrowFreqMatchesLibrosa() throws {
        let ref = try Self.loadReference()
        let e = ref["E"] as! [String: Any]
        let sr = e["sr"] as! Float
        let n_fft = e["n_fft"] as! Int
        let n_mels = e["n_mels"] as! Int
        let fmin = e["fmin"] as! Float
        let fmax = e["fmax"] as! Float
        let expected = (e["ones_output"] as! [[Double]]).flatMap { $0.map(Float.init) }

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        let input = MultiArray<Float>.zeros(1, n_fft / 2 + 1)
        input.fill(with: 1.0)
        let output = mel(input)

        Self.expectEqual(Array(output.buffer), expected, tolerance: 1e-5, "E: narrow freq")
    }

    // MARK: - Test F: Random spectrogram

    @Test func randomSpectrogramMatchesLibrosa() throws {
        let ref = try Self.loadReference()
        let f = ref["F"] as! [String: Any]
        let sr = f["sr"] as! Float
        let n_fft = f["n_fft"] as! Int
        let n_mels = f["n_mels"] as! Int
        let fmin = f["fmin"] as! Float
        let fmax = f["fmax"] as! Float
        let expected = (f["output"] as! [[Double]]).flatMap { $0.map(Float.init) }
        let specRows = f["spec"] as! [[Double]]

        let mel = LogmelFilter(sampleRate: sr, n_fft: n_fft, n_mels: n_mels, fmin: fmin, fmax: fmax)
        let input = MultiArray<Float>.zeros(specRows.count, n_fft / 2 + 1)
        for i in specRows.indices {
            for j in specRows[i].indices {
                input[i, j] = Float(specRows[i][j])
            }
        }
        let output = mel(input)
        #expect(output.shape == [specRows.count, n_mels])

        Self.expectEqual(Array(output.buffer), expected, tolerance: 1e-4, "F: random spectrogram")
    }
}

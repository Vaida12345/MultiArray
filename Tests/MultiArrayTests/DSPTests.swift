//
//  DSPTests.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-22.
//

import Testing
import MultiArray
import Accelerate


struct DSPTests {
    
    @Suite
    struct STFTTests {
        
        @Test func length16() async throws {
            let stft = ShortTimeFourierTransform(n_fft: 8, hop: 4)
            let input = (0..<16).map(Float.init)
            let data = stft(input)
            
            let reference: [Float] = [4.585787, 0.0, 16.0, 0.0, 32.0, 0.0, 48.0, 0.0, 54.414215, 0.0, -0.58578646, 1.3155118e-08, -8.0, 3.8284268, -16.0, 3.8284264, -24.0, 3.8284266, -28.414215, -2.4142137, -2.0, -0.0, 3.6211688e-08, -0.82842684, 3.6211667e-08, -0.82842636, 3.621171e-08, -0.8284273, 0.99999994, 1.4142132, 0.58578646, 1.3155118e-08, 0.0, -0.17157304, 0.0, -0.17157304, 0.0, -0.1715734, 0.41421413, -0.41421366, -0.5857866, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.41421318, 0.0]
            #expect(data.shape == [5, 5, 2])
            #expect(reference.contentsEqual(Array(data.buffer), tolerance: 1e-3))
        }
        
    }
    
    @Suite
    struct ISTFTTests {
        
        @Test func length16() async throws {
            let istft = InverseShortTimeFourierTransform(n_fft: 8, hop: 4)
//            let input =
//            let data = try await stft(input)
            
            var _input: [Float] = [4.585787, 0.0, 16.0, 0.0, 32.0, 0.0, 48.0, 0.0, 54.414215, 0.0, -0.58578646, 1.3155118e-08, -8.0, 3.8284268, -16.0, 3.8284264, -24.0, 3.8284266, -28.414215, -2.4142137, -2.0, -0.0, 3.6211688e-08, -0.82842684, 3.6211667e-08, -0.82842636, 3.621171e-08, -0.8284273, 0.99999994, 1.4142132, 0.58578646, 1.3155118e-08, 0.0, -0.17157304, 0.0, -0.17157304, 0.0, -0.1715734, 0.41421413, -0.41421366, -0.5857866, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.41421318, 0.0]
            let input = MultiArray<Float>.allocate(5, 5, 2)
            memcpy(input.baseAddress, &_input, MemoryLayout<Float>.stride * _input.count)
            
            let data = istft(input)
            #expect(Array(data).contentsEqual((0..<16).map(Float.init), tolerance: 1e-3))
        }
        
    }
    
    @Suite
    struct DFTTests {
        
        @Test func length16() throws {
            let dft = DiscreteFourierTransform(count: 16)
            let input = (0..<16).map(Float.init)
            let reference = [
                DSPComplex(real: 120, imag: 0),
                DSPComplex(real: -8, imag: 40.2187),
                DSPComplex(real: -8, imag: 19.3137),
                DSPComplex(real: -8, imag: 11.9728),
                DSPComplex(real: -8, imag: 8.0000),
                DSPComplex(real: -8, imag: 5.3454),
                DSPComplex(real: -8, imag: 3.3137),
                DSPComplex(real: -8, imag: 1.5913),
                DSPComplex(real: -8, imag: 0.0000),
            ]
            #expect(dft(input).contentsEqual(reference))
        }
    }
    
    @Suite
    struct IDFTTests {
        
        @Test func length16() throws {
            let idft = InverseDiscreteFourierTransform(count: 16)
            let input = [
                DSPComplex(real: 120, imag: 0),
                DSPComplex(real: -8, imag: 40.2187),
                DSPComplex(real: -8, imag: 19.3137),
                DSPComplex(real: -8, imag: 11.9728),
                DSPComplex(real: -8, imag: 8.0000),
                DSPComplex(real: -8, imag: 5.3454),
                DSPComplex(real: -8, imag: 3.3137),
                DSPComplex(real: -8, imag: 1.5913),
                DSPComplex(real: -8, imag: 0.0000),
            ]
            let reference = (0..<16).map(Float.init)
            #expect(idft(input).contentsEqual(reference, tolerance: 1e-3))
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

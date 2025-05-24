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
        
        @Test func length16() {
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
        
        func length(count: Int, hop: Int) {
            let input = (0..<count).map(Float.init)
            let transform = ShortTimeFourierTransform(n_fft: count, hop: hop)(input)
            let output = InverseShortTimeFourierTransform(n_fft: count, hop: hop)(transform)
            let isTrue = input.contentsEqual(output, tolerance: 1e-2)
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
    
    @Suite
    struct DFTTests {
        
        @Test func length16() {
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
        
        func length(count: Int) {
            let input = (0..<count).map(Float.init)
            let transform = DiscreteFourierTransform(count: count)(input)
            let output = InverseDiscreteFourierTransform(count: count)(transform)
            let isTrue = input.contentsEqual(output, tolerance: 1e-3)
            #expect(isTrue, "failed for count \(count), tolerance \(1e-3)")
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

//
//  STFTModel.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Foundation
import Accelerate


public struct ShortTimeFourierTransform: Sendable {
    
    private let n_fft: Int
    
    private let hop: Int
    
    private let center: Bool
    
    
    public init(
        n_fft: Int,
        hop: Int,
        center: Bool = true
    ) {
        self.n_fft = n_fft
        self.hop = hop
        self.center = center
    }
    
    /// Replicates exactly `torch.fft.stft`.
    ///
    /// - Parameter input: 1D array, `L`
    ///
    /// - Returns: `frequencySamples × frames × complexComponents`, `n_fft/2+1 × (1+L)/hop × 2`
    public func callAsFunction(_ input: Array<Float>) -> MultiArray<Float> {
        // 1. Optional reflect-padding to “center” frames, as PyTorch does by default.
        var x = input
        let padAmount = n_fft / 2
        if center {
            x = reflectPad(x, pad: padAmount)
        }
        
        // 2. Prepare the Hann window.
        let window = hannWindow(count: n_fft)
        
        // 4. Figure out how many frames we can extract.
        let totalLength = x.count
        let nFrames = max(0, (totalLength - n_fft) / hop + 1) // yes, this should be different to doc return shape.
        let halfSize = n_fft / 2 + 1  // onesided
        
        // Allocate output: [frequencyBin][frameIndex][realOrImag]
        let result = MultiArray<Float>.allocate(halfSize, nFrames, 2)
        
        let dft = DiscreteFourierTransform(count: n_fft)
        let hop = self.hop
        let n_fft = self.n_fft
        let input = consume x
        
        // 5. Slice out each frame, window it, FFT, and store.
        var frameIndex = 0
        while frameIndex < nFrames {
            let start = frameIndex * hop
            let end   = start + n_fft
            
            // Extract the current frame and apply the Hann window.
            var frame = Array(input[start..<end])
            vDSP.multiply(frame, window, result: &frame)  // in-place multiply by Hann
            
            let data = dft(frame)
            
            var index = 0
            while index < data.count {
                let value = data[index]
                result.initializeElement(at: [index, frameIndex, 0], to: value.real)
                result.initializeElement(at: [index, frameIndex, 1], to: value.imag)
                
                index &+= 1
            }
            
            frameIndex += 1
        }
        
        return result
    }
    
    /// Create a normalized Hann window of size nFFT.
    ///
    /// Generate a Hann window matching PyTorch's `torch.hann_window(window_length=nFFT, periodic=True)`
    private func hannWindow(count: Int) -> [Float] {
        Array<Float>(unsafeUninitializedCapacity: count) { buffer, initializedCount in
            initializedCount = count
            vDSP_hann_window(buffer.baseAddress!, vDSP_Length(count), Int32(vDSP_HANN_DENORM))
        }
    }
    
    /// 1D “reflect” padding that matches PyTorch’s pad_mode='reflect'.
    /// For example, if x = [1,2,3,4,5] and pad=2, the result becomes [3,2, 1,2,3,4,5, 4,3].
    private func reflectPad(_ input: [Float], pad: Int) -> [Float] {
        precondition(pad <= input.count - 1,
                     "Reflect padding must be <= (input.count - 1).")
        // Left side is input[1..pad], reversed
        let leftSlice = input[1...pad].reversed()
        // Right side is input[(end - pad - 1)..(end - 1)], reversed
        let rightSlice = input[(input.count - pad - 1)..<(input.count - 1)].reversed()
        return Array(leftSlice) + input + Array(rightSlice)
    }
    
}

extension DSPComplex {
    
    static func +(a: DSPComplex, b: DSPComplex) -> DSPComplex {
        DSPComplex(real: a.real + b.real, imag: a.imag + b.imag)
    }
    static func -(a: DSPComplex, b: DSPComplex) -> DSPComplex {
        DSPComplex(real: a.real - b.real, imag: a.imag - b.imag)
    }
    static func *(a: DSPComplex, b: DSPComplex) -> DSPComplex {
        DSPComplex(
            real: a.real * b.real - a.imag * b.imag,
            imag: a.real * b.imag + a.imag * b.real
        )
    }
    
}

extension DSPComplex: @retroactive CustomStringConvertible {
    
    public var description: String {
        if imag.sign == .plus {
            "\(real)+\(imag)i"
        } else {
            "\(real)\(imag)i"
        }
    }
    
}


extension DSPComplex: @retroactive Equatable {
    
    public static func == (_ lhs: DSPComplex, _ rhs: DSPComplex) -> Bool {
        lhs.real == rhs.real && lhs.imag == rhs.imag
    }
    
}

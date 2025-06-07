//
//  STFTModel.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Foundation
import Accelerate


/// ShortTimeFourierTransform using Hann window
public struct ShortTimeFourierTransform: Sendable {
    
    private let n_fft: Int
    
    private let hop: Int
    
    private let center: Bool
    
    /// - Parameters:
    ///   - n_fft: The length of each segment, this is the value passed to ``DiscreteFourierTransform/init(count:)``
    ///   - hop: The stride of segments.
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
    public func callAsFunction(_ input: consuming MultiArray<Float>) -> MultiArray<Float> {
        assert(input.shape.count == 1 || input.shape.dropLast().allSatisfy({ $0 == 1 }), "Invalid input shape")
        
        // 1. Optional reflect-padding to “center” frames, as PyTorch does by default.
        var x = consume input
        if center {
            x = x.reflectionPad(size: n_fft / 2)
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
            
            // Extract the current frame and apply the Hann window.
            let buffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: n_fft)
            vDSP_vmul(input.baseAddress + start, 1, window.baseAddress, 1, buffer.baseAddress!, 1, vDSP_Length(n_fft))
            
            let frame = MultiArray<Float>(bytesNoCopy: buffer, shape: [buffer.count], deallocator: .free)
            dft(frame, result: result.baseAddress + frameIndex * 2, stride: result.strides[0] / 2)
            
            frameIndex &+= 1
        }
        
        return result
    }
    
    /// Create a normalized Hann window of size nFFT.
    ///
    /// Generate a Hann window matching PyTorch's `torch.hann_window(window_length=nFFT, periodic=True)`
    private func hannWindow(count: Int) -> MultiArray<Float> {
        let result = MultiArray<Float>.allocate([count])
        vDSP_hann_window(result.baseAddress, vDSP_Length(count), Int32(vDSP_HANN_DENORM))
        return result
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

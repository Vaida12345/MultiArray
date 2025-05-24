//
//  ISTFTModel.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Foundation
import Accelerate


/// Inverse of ``ShortTimeFourierTransform``.
public struct InverseShortTimeFourierTransform: Sendable {
    
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
    
    /// Replicates exactly `torch.fft.istft`.
    ///
    /// - Parameter input: `frequencySamples × frames × complexComponents`, `n_fft/2+1 × (1+L)/hop × 2`
    ///
    /// - Returns: 1D array, `L`
    public func callAsFunction(_ input: MultiArray<Float>) -> Array<Float> {
        // MARK: - Prepare
        let idft = InverseDiscreteFourierTransform(count: n_fft)
        let window = hannWindow(count: n_fft)
        
        // MARK: - execute
        let nFrames = input.shape[1]
        let L = (nFrames - 1) * hop + n_fft
        
        let bufferLength = center ? L - n_fft : L
        let padAmount = center ? n_fft / 2 : 0
        
        return Array<Float>(unsafeUninitializedCapacity: bufferLength) { buffer, initializedCount in
            initializedCount = bufferLength
            
            var frameIndex = nFrames - 1
            while frameIndex >= 0 {
                let data = Array<DSPComplex>(unsafeUninitializedCapacity: n_fft / 2 + 1) { buffer, initializedCount in
                    initializedCount = n_fft / 2 + 1
                    
                    for index in 0..<n_fft / 2 + 1 {
                        buffer[index] = DSPComplex(
                            real: input[index, frameIndex, 0],
                            imag: input[index, frameIndex, 1]
                        )
                    }
                }
                
                var frame = idft(data)
                vDSP.divide(frame, window, result: &frame)
                
                let start = frameIndex * hop
                let end   = start + n_fft
                
                let span = end - start
                var offset = 0
                while offset < span {
                    defer {
                        offset &+= 1
                    }
                    
                    let index = start + offset
                    guard index >= padAmount && index < bufferLength + padAmount else { continue }
                    buffer.initializeElement(at: index - padAmount, to: frame[offset]) // Float is trivia type
                }
                frameIndex -= 1
            }
        }
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
    
}

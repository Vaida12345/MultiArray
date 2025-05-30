//
//  FFTModel.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Accelerate


/// One dimensional real discrete Fourier transform.
///
/// The `callAsFunction` method replicates exactly `torch.fft.rfft`.
public final class DiscreteFourierTransform {
    
    private let n_fft: Int
    
    private let dftSetup: vDSP_DFT_Setup
    
    private let buffer: UnsafeMutableBufferPointer<Float>
    
    private var splitComplex: DSPSplitComplex
    
    
    public init(count: Int) {
        self.n_fft = count
        self.dftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(n_fft), .FORWARD)!
        
        self.buffer = .allocate(capacity: n_fft)
        let realp = UnsafeMutableBufferPointer(start: buffer.baseAddress!, count: n_fft / 2)
        let imagp = UnsafeMutableBufferPointer(start: buffer.baseAddress! + n_fft / 2, count: n_fft / 2)
        self.splitComplex = DSPSplitComplex(realp: realp.baseAddress!, imagp: imagp.baseAddress!)
    }
    
    deinit {
        vDSP_DFT_DestroySetup(dftSetup)
        buffer.deallocate()
    }
    
    /// Replicates exactly `torch.fft.rfft`.
    ///
    /// - Parameters:
    ///   - input: 1D array, `n_fft`, interleaved complex
    ///   - stride: The stride of resulting pointer in number of *complex* values.
    ///
    /// - Returns: `n_fft/2 × 2` `complexCount × (real, imag)`
    ///
    /// - Warning: This method is not thread-safe. Do NEVER call this method of the same instance in parallel.
    public func callAsFunction(_ input: MultiArray<Float>, result: UnsafeMutablePointer<Float>, stride: Int) {
        assert(input.count == n_fft, "n_fft mismatch")
        input.buffer.withMemoryRebound(to: DSPComplex.self) { buffer in
            vDSP_ctoz(buffer.baseAddress!, 2, &splitComplex, 1, vDSP_Length(n_fft / 2))
        }
        
        vDSP_DFT_Execute(self.dftSetup, splitComplex.realp, splitComplex.imagp, splitComplex.realp, splitComplex.imagp)
        
        var scale: Float = 0.5                // to undo the doubling
        vDSP_vsmul(buffer.baseAddress!, 1, &scale, buffer.baseAddress!, 1, vDSP_Length(buffer.count))
        
        result.withMemoryRebound(to: DSPComplex.self, capacity: (n_fft / 2 + 1) * stride) { complexBuffer in
            vDSP_ztoc(&splitComplex, 1, complexBuffer, 2 /*complex values*/ * stride, vDSP_Length(n_fft / 2))
            complexBuffer[n_fft / 2 * stride] = DSPComplex(real: splitComplex.imagp[0], imag: 0)
            complexBuffer[0].imag = 0
        }
    }
    
    /// Replicates exactly `torch.fft.rfft`.
    ///
    /// - Parameter input: 1D array, `n_fft`
    ///
    /// - Returns: `n_fft/2 × 2` `complexCount × (real, imag)`
    public func callAsFunction(_ input: MultiArray<Float>) -> MultiArray<Float> {
        let result = MultiArray<Float>.allocate(n_fft / 2 + 1, 2)
        self.callAsFunction(input, result: result.baseAddress, stride: 1)
        return result
    }
    
}

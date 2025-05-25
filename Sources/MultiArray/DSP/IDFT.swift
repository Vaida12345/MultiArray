//
//  IFFTModel.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import Accelerate


/// One dimensional real inverse discrete Fourier transform.
///
/// The `callAsFunction` method replicates exactly `torch.fft.irfft`.
public final class InverseDiscreteFourierTransform {
    
    private let n_fft: Int
    
    private let dftSetup: vDSP_DFT_Setup
    
    private let buffer: UnsafeMutableBufferPointer<Float>
    
    private var splitComplex: DSPSplitComplex
    
    
    public init(count: Int) {
        self.n_fft = count
        self.dftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(n_fft), .INVERSE)!
        
        self.buffer = .allocate(capacity: n_fft)
        let realp = UnsafeMutableBufferPointer(start: buffer.baseAddress!, count: n_fft / 2)
        let imagp = UnsafeMutableBufferPointer(start: buffer.baseAddress! + n_fft / 2, count: n_fft / 2)
        self.splitComplex = DSPSplitComplex(realp: realp.baseAddress!, imagp: imagp.baseAddress!)
    }
    
    deinit {
        vDSP_DFT_DestroySetup(dftSetup)
        buffer.deallocate()
    }
    
    /// Replicates exactly `torch.fft.irfft`.
    ///
    /// - Parameters:
    ///   - input: `n_fft/2 × 2`, `complexCount × (real, imag)`
    ///   - stride: The stride of input pointer in number of *complex* values.
    ///
    /// - Returns: 1D array, `n_fft`, interleaved complex
    ///
    /// - Warning: This method is not thread-safe. Do NEVER call this method of the same instance in parallel.
    public func callAsFunction(_ input: UnsafeMutablePointer<Float>, stride: Int) -> [Float] {
        Array(unsafeUninitializedCapacity: n_fft) { result, initializedCount in
            input.withMemoryRebound(to: DSPComplex.self, capacity: (n_fft / 2 + 1) * stride) { input in
                // pack
                input[0].imag = input[(n_fft / 2) * stride].real
                // no need to update (n_fft / 2, 0), vDSP never expects to look that far
                defer {
                    // undo pack
                    input[0].imag = 0
                }
                
                // bind to realp and imagp
                vDSP_ctoz(input, 2 * stride, &splitComplex, 1, vDSP_Length(n_fft / 2))
                
                vDSP_DFT_Execute(self.dftSetup, splitComplex.realp, splitComplex.imagp, splitComplex.realp, splitComplex.imagp)
                
                // normalize, this aligns with torch.fft.irfft with normalized=False (default)
                var scale = 1 / Float(n_fft)
                vDSP_vsmul(buffer.baseAddress!, 1, &scale, buffer.baseAddress!, 1, vDSP_Length(buffer.count))
                
                result.withMemoryRebound(to: DSPComplex.self) {
                    vDSP_ztoc(&splitComplex, 1, $0.baseAddress!, 2, vDSP_Length(n_fft / 2))
                }
            }
            
            initializedCount = n_fft
        }
    }
    
    /// Replicates exactly `torch.fft.irfft`.
    ///
    /// - Parameters:
    ///   - input: `n_fft/2 × 2`, `complexCount × (real, imag)`
    ///   - stride: The stride of input pointer in number of *complex* values.
    ///
    /// - Returns: 1D array, `n_fft`
    public func callAsFunction(_ input: MultiArray<Float>) -> [Float] {
        assert(input.shape[0] == n_fft / 2 + 1, "n_fft mismatch")
        
        return self(input.baseAddress, stride: 1)
    }
    
}

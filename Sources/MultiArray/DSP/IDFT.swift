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
public final class InverseDiscreteFourierTransform: @unchecked Sendable {
    
    private let n_fft: Int
    
    private let dftSetup: vDSP_DFT_Setup
    
    
    public init(count: Int) {
        self.n_fft = count
        self.dftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(n_fft), .INVERSE)!
    }
    
    deinit {
        vDSP_DFT_DestroySetup(dftSetup)
    }
    
    /// Replicates exactly `torch.fft.irfft`.
    ///
    /// - Parameter input: `n_fft/2 × 2`
    ///
    /// - Returns: 1D array, `n_fft`
    public func callAsFunction(_ input: [DSPComplex]) -> [Float] {
        assert(input.count == n_fft / 2 + 1, "n_fft mismatch")
        
        let buffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: n_fft)
        defer {
            buffer.deallocate()
        }
        
        let realp = UnsafeMutableBufferPointer(start: buffer.baseAddress!, count: n_fft / 2)
        let imagp = UnsafeMutableBufferPointer(start: buffer.baseAddress! + n_fft / 2, count: n_fft / 2)
        var splitComplex = DSPSplitComplex(realp: realp.baseAddress!, imagp: imagp.baseAddress!)
        
        // pack
        var input = input
        input[0].imag = input[n_fft / 2].real
        
        return Array(unsafeUninitializedCapacity: n_fft) { result, initializedCount in
            input.withUnsafeMutableBufferPointer { input in
                // bind to realp and imagp
                vDSP_ctoz(input.baseAddress!, 2, &splitComplex, 1, vDSP_Length(realp.count))
                
                vDSP_DFT_Execute(self.dftSetup, realp.baseAddress!, imagp.baseAddress!, realp.baseAddress!, imagp.baseAddress!)
                
                // normalize
                var scale = 1 / Float(n_fft)
                vDSP_vsmul(buffer.baseAddress!, 1, &scale, buffer.baseAddress!, 1, vDSP_Length(buffer.count))
                
                result.withMemoryRebound(to: DSPComplex.self) {
                    vDSP_ztoc(&splitComplex, 1, $0.baseAddress!, 2, vDSP_Length(n_fft / 2))
                }
            }
            
            initializedCount = n_fft
        }
    }
    
}

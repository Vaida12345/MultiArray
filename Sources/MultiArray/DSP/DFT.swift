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
public final class DiscreteFourierTransform: @unchecked Sendable {
    
    private let n_fft: Int
    
    private let dftSetup: vDSP_DFT_Setup
    
    
    public init(count: Int) {
        self.n_fft = count
        self.dftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(n_fft), .FORWARD)!
    }
    
    deinit {
        vDSP_DFT_DestroySetup(dftSetup)
    }
    
    /// Replicates exactly `torch.fft.rfft`.
    ///
    /// - Parameter input: 1D array, `n_fft`
    ///
    /// - Returns: `n_fft/2 × 2`
    public func callAsFunction(_ input: [Float]) -> [DSPComplex] {
        assert(input.count == n_fft, "n_fft mismatch")
        
        let buffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: n_fft)
        defer {
            buffer.deallocate()
        }
        
        let realp = UnsafeMutableBufferPointer(start: buffer.baseAddress!, count: n_fft / 2)
        let imagp = UnsafeMutableBufferPointer(start: buffer.baseAddress! + n_fft / 2, count: n_fft / 2)
        var splitComplex = DSPSplitComplex(realp: realp.baseAddress!, imagp: imagp.baseAddress!)
        
        input.withUnsafeBytes {
            vDSP_ctoz($0.bindMemory(to: DSPComplex.self).baseAddress!, 2, &splitComplex, 1, vDSP_Length(n_fft / 2))
        }

        vDSP_DFT_Execute(self.dftSetup, realp.baseAddress!, imagp.baseAddress!, realp.baseAddress!, imagp.baseAddress!)
        
        var scale: Float = 0.5                // to undo the doubling
        vDSP_vsmul(buffer.baseAddress!, 1, &scale, buffer.baseAddress!, 1, vDSP_Length(buffer.count))
        
        return [DSPComplex](unsafeUninitializedCapacity: realp.count + 1) { buffer, initializedCount in
            initializedCount = n_fft / 2 + 1
            
            buffer.withMemoryRebound(to: DSPComplex.self) { buffer in
                vDSP_ztoc(&splitComplex, 1, buffer.baseAddress!, 2, vDSP_Length(realp.count))
                buffer[realp.count] = DSPComplex(real: imagp[0], imag: 0)
                buffer[0].imag = 0
            }
        }
    }
    
}

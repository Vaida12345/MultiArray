//
//  Logmel Filter.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-30.
//

import Foundation
import Accelerate


/// Replicates exactly `librosa.LogmelFilterBank`.
public final class LogmelFilter {
    
    private let sampleRate: Float
    
    private let n_fft: Int
    
    private let n_mels: Int
    
    private let fmin: Float
    
    private let fmax: Float
    
    private var filters: MultiArray<Float>!
    
    
    public init(
        sampleRate: Float = 22050,
        n_fft: Int = 2048,
        n_mels: Int = 64,
        fmin: Float = 0.0,
        fmax: Float? = nil
    ) {
        self.sampleRate = sampleRate
        self.n_fft = n_fft
        self.n_mels = n_mels
        self.fmin = fmin
        self.fmax = fmax ?? Float(sampleRate / 2)
        
        self.filters = self.filter().withTransaction { proxy in
            proxy.transposed(0, 1)
        }
    }
    
    
    public func callAsFunction(_ input: MultiArray<Float>) -> MultiArray<Float> {
        MultiArray.matmul(input, self.filters)
    }
    
    
    // MARK: - Build Filters
    
    private func filter() -> MultiArray<Float> {
        let weights = MultiArray<Float>.zeros(n_mels, 1 + n_fft / 2)
        let fftfreqs = fft_frequencies(sr: sampleRate, n_fft: n_fft)
        let mel_f = mel_frequencies(n_mels: n_mels + 2, fmin: fmin, fmax: fmax)
        
        let fdiff = diff(mel_f)
        let ramps = subtractOuter(mel_f, fftfreqs)
        
        for i in 0..<n_mels {
            var lower = ramps.withoutCopying {
                -ramps.view(at: [i]) / fdiff[i]
            }
            let upper = ramps.view(at: [i + 2]) / fdiff[i + 1]
            
            vDSP.minimum(lower, upper, result: &lower)
            
            var weight = weights.view(at: [i]) // return by reference
            vDSP.threshold(lower, to: 0, with: .clampToThreshold, result: &weight)
        }
        
        let slice1 = mel_f[2 ..< n_mels + 2]
        let slice2 = mel_f[..<n_mels]
        slice1.withUnsafeBufferPointer { slice1 in
            slice2.withUnsafeBufferPointer { slice2 in
                let slice1 = MultiArray(copying: .init(mutating: slice1), shape: [slice1.count])
                let slice2 = MultiArray(bytesNoCopy: .init(mutating: slice2), shape: [slice2.count], deallocator: .none)
                
                slice1.withoutCopying {
                    let enorm = 2 / (slice1 - slice2)
                    weights.multiplyColumn(enorm)
                }
            }
        }
        
        return weights
    }
    
    private func subtractOuter(_ a: [Float], _ b: [Float]) -> MultiArray<Float> {
        let multiArray = MultiArray<Float>.allocate(a.count, b.count)
        var count = 0
        for ai in a {
            for bi in b {
                multiArray.buffer[count] = ai - bi
                count += 1
            }
        }
        return multiArray
    }
    
    private func diff(_ array: Array<Float>) -> Array<Float> {
        zip(array.dropFirst(), array).map { next, current in next - current }
    }
    
    private func mel_frequencies(n_mels: Int, fmin: Float, fmax: Float) -> Array<Float> {
        let min_mel = hz_to_mel(fmin)
        let max_mel = hz_to_mel(fmax)
        
        let mels = linspace(start: min_mel, stop: max_mel, num: n_mels)
        return mel_to_hz(mels)
    }
    
    private func linspace(start: Float, stop: Float, num: Int, endpoint: Bool = true) -> [Float] {
        guard num > 0 else { return [] }
        if num == 1 { return [start] }
        let divisor = Float(endpoint ? (num - 1) : num)
        let step = (stop - start) / divisor
        return (0..<num).map { i in
            if endpoint && i == num - 1 {
                return stop
            } else {
                return start + Float(i) * step
            }
        }
    }

    
    private func fft_frequencies(sr: Float, n_fft: Int) -> Array<Float> {
        rfftfreq(n: n_fft, d: 1 / sr)
    }
    
    private func rfftfreq(n: Int, d: Float) -> Array<Float> {
        let count = n / 2 + 1
        return (0..<count).map { Float($0) / (Float(n) * d) }
    }
    
    private func hz_to_mel(_ hz: Float) -> Float {
        let fmin: Float = 0.0
        let f_sp: Float = 200.0 / 3
        let mels = (hz - fmin) / f_sp
        
        let min_log_hz: Float = 1000
        let min_log_mel = (min_log_hz - fmin) / f_sp
        let logstep: Float = log(6.4) / 27
        
        if hz >= min_log_hz {
            return min_log_mel + log(hz / min_log_hz) / logstep
        } else {
            return mels
        }
    }
    
    private func mel_to_hz(_ mels: Array<Float>) -> Array<Float> {
        let fmin: Float = 0.0
        let f_sp: Float = 200.0 / 3
        
        var freqs = vDSP.multiply(f_sp, mels)
        vDSP.add(fmin, freqs, result: &freqs)
        
        let min_log_hz: Float = 1000
        let min_log_mel = (min_log_hz - fmin) / f_sp
        let logstep: Float = log(6.4) / 27
        
        var i = 0
        while i < mels.count {
            guard mels[i] >= min_log_mel else { i &+= 1; continue }
            freqs[i] = min_log_hz * exp(logstep * (mels[i] - min_log_mel))
            
            i &+= 1
        }
        
        return freqs
        
//        vDSP.add(-min_log_mel, mels, result: &mels)
//        vDSP.multiply(logstep, mels, result: &mels)
//        mels.withUnsafeMutableBufferPointer { buffer in
//            vvexpf(buffer.baseAddress!, buffer.baseAddress!, [Int32(buffer.count)])
//        }
//        vDSP.multiply(min_log_hz, mels, result: &mels)
    }
    
}

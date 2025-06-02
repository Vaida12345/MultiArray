//
//  LogMelTests.swift
//  MultiArray
//
//  Created by Vaida on 2025-06-03.
//

import Testing
import MultiArray
import Foundation
import Accelerate


@Test func logMel() {
    let inputs = Array(0..<162048).map { sin(Float($0) * 0.001) }
    let frames_per_second = 100
    
    let date = Date()
    
    let stft = ShortTimeFourierTransform(n_fft: 2048, hop: 16000 / frames_per_second, center: false)
    var output = stft(inputs)
    var power: Float = 2
    var count = Int32(output.count)
    vDSP.multiply(output, output, result: &output)
    
    // now convert to torchlibrosa style
    let spectrogram = MultiArray<Float>.allocate(1001, 1025)
    
    let iteratorDate = Date()
    var i = 0
    let iterator = UnsafeMutableBufferPointer<Int>.allocate(capacity: 2)
    iterator.initialize(repeating: 0)
    defer {
        iterator.deallocate()
    }
    
    while i < output.count {
        // work
        spectrogram[iterator[1], iterator[0]] = output.buffer[i] + output.buffer[i + 1]
        
        iterator[iterator.count - 1] &+= 1
        
        // carry
        var ishape = 1
        while ishape != 0 {
            if iterator[ishape] == output.shape[ishape] {
                iterator[ishape] = 0
                iterator[ishape - 1] &+= 1
            } else {
                break
            }
            ishape &-= 1
        }
        
        i &+= 2
    }
    print("iterate", iteratorDate.distanceToNow())
    
    // MARK: - LogmelFilterBank
    
    let date2 = Date()
    let melW = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 229, fmin: 30, fmax: 16000 / 2)
    let a = melW(spectrogram)

}

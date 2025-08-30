//
//  main.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Foundation
import MultiArray
import Essentials
import Accelerate
import os



// MARK: - spectrogram
let date = Date()
let inputs = MultiArray<Float>(Array(0..<162048).map { sin(Float($0) * 0.001) })
let frames_per_second = 100

let signpost = OSSignposter(subsystem: "main", category: .pointsOfInterest)
let signpostID = signpost.makeSignpostID()

let state = signpost.beginInterval("Logmel", id: signpostID)

let stft = ShortTimeFourierTransform(n_fft: 2048, hop: 16000 / frames_per_second, center: false)
var output = stft(inputs)
var count = Int32(output.count)
vDSP.multiply(output, output, result: &output)

signpost.emitEvent("Iterate", id: signpostID)

// now convert to torchlibrosa style
let spectrogram = MultiArray<Float>.allocate(1001, 1025)

var i = 0
var it0 = 0
var it1 = 0
let stride = spectrogram.strides[0]
let shape = output.shape[1]


let outputCount = output.count
while i < outputCount {
    // work, iterator[1], iterator[0]
    spectrogram[offset: it1 * stride &+ it0] = output.buffer[i] + output.buffer[i &+ 1]
    it1 &+= 1
    
    // carry
    if it1 == shape {
        it1 = 0
        it0 &+= 1
    }
    
    i &+= 2
}
print(spectrogram)

signpost.emitEvent("Spectrogram", id: signpostID)

// MARK: - LogmelFilterBank


let melW = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 229, fmin: 30, fmax: 16000 / 2)
let a = melW(spectrogram)


signpost.endInterval("Logmel", state)
print(date.distanceToNow())

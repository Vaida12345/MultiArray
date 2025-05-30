//
//  main.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Foundation
import MultiArray
import Accelerate

// MARK: - spectrogram
let inputs = Array(0..<162048).map { sin(Float($0) * 0.001) }

//
//print(spectrogram.shape)
//print(spectrogram)

// MARK: - LogmelFilterBank

let melW = LogmelFilter(sampleRate: 16000, n_fft: 2048, n_mels: 229, fmin: 30, fmax: 16000 / 2)

//
//  main.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Foundation
import MultiArray


let date = Date()
//let multiArray = MultiArray<Float>.allocate(200, 700, 300)
//let new = multiArray.withTransaction { proxy in
//    proxy.reshape(-1, 7)
//}
let count = 1 << 11
let hop = 4
let input = (0..<count).map(Float.init)
let transform = ShortTimeFourierTransform(n_fft: count, hop: hop)(input)
let output = InverseShortTimeFourierTransform(n_fft: count, hop: hop)(transform)

print(date.distanceToNow())

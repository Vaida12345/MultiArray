//
//  main.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Foundation
import MultiArray


let date = Date()
let multiArray = MultiArray<Float>.allocate(200, 700, 300)
let new = multiArray.withTransaction { proxy in
    proxy.reshape(-1, 7)
}
print(date.distanceToNow())

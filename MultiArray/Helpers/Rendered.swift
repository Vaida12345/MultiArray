//
//  Render.swift
//  MultiArray
//
//  Created by Vaida on 2026-04-01.
//

import CoreGraphics
import Foundation
import Accelerate


extension MultiArray where Element == Float {
    
    /// Render `self` as a CGImage if `self` is a 2D or 1D array.
    ///
    /// Returns an image with luma relative to local min and max. The higher the value is, the darker.
    public func rendered(options: RenderOptions = RenderOptions()) -> CGImage? {
        
        guard options.unitWidth > 0, options.unitHeight > 0 else { return nil }
        guard self.shape.count <= 2, self.shape.count > 0 else { return nil }
        
        let sourceWidth = self.shape.last!
        let sourceHeight = self.shape.count == 2 ? self.shape[0] : 1
        let unitWidth = options.unitWidth
        let unitHeight = options.unitHeight
        let height = sourceHeight * unitHeight
        let width = sourceWidth * unitWidth

        var minimum = self.min()
        let maximum = self.max()
        
        var sourceLuma: [UInt8] = [UInt8](repeating: UInt8.max, count: self.count)
        if minimum != maximum {
            var scale = 255 / (maximum - minimum)
            let copy = MultiArray.allocate(self.shape)
            vDSP_vsadd(self.baseAddress, 1, &minimum, copy.baseAddress, 1, vDSP_Length(self.count))
            vDSP_vsdiv(copy.baseAddress, 1, &scale,  copy.baseAddress, 1, vDSP_Length(self.count))
            vDSP.convertElements(of: copy, to: &sourceLuma, rounding: .towardNearestInteger)
        }

        var imageData = Data(repeating: 0, count: width * height)
        imageData.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
            let buffer = buffer.bindMemory(to: UInt8.self)
            var y = 0
            while y < sourceHeight {
                let sourceRowStart = y * sourceWidth
                var yp = 0
                while yp < unitHeight {
                    let destinationRowStart = (y * unitHeight + yp) * width
                    var x = 0
                    while x < sourceWidth {
                        let luma = sourceLuma[sourceRowStart + x]
                        let destinationStart = destinationRowStart + x * unitWidth
                        var xp = 0
                        while xp < unitWidth {
                            buffer[destinationStart + xp] = luma
                            xp &+= 1
                        }
                        x &+= 1
                    }
                    yp &+= 1
                }
                y &+= 1
            }
        }

        guard let provider = CGDataProvider(data: imageData as CFData) else { return nil }
        let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) ?? CGColorSpaceCreateDeviceGray()
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
    
    public struct RenderOptions {
        public var unitWidth: Int
        public var unitHeight: Int
        
        public init(unitWidth: Int = 1, unitHeight: Int = 1) {
            self.unitWidth = unitWidth
            self.unitHeight = unitHeight
        }
    }
    
}

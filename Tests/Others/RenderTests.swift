//
//  RenderTests.swift
//  MultiArray
//
//  Created by Vaida on 2026-04-01.
//

import Testing
import MultiArray
import AppKit


@Suite
struct RenderTests {
    @Test func `1d`() async throws {
        let multiArray = MultiArray((0..<16).map(Float.init))
        let image = multiArray.rendered()!
        Attachment.record(NSImage(cgImage: image, size: .zero))
    }
}

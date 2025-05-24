//
//  Array + load.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-20.
//

import FinderItem



extension MultiArray {
    
    public func load(from source: FinderItem) throws {
        let data = try source.load(.data)
        guard data.count == MemoryLayout<Element>.stride * self.count else {
            throw FinderItem.FileError(code: .cannotRead(reason: .corruptFile), source: source)
        }
        
        data.withUnsafeBytes {
            _ = $0.copyBytes(to: UnsafeMutableRawBufferPointer(self.buffer))
        }
    }
    
}

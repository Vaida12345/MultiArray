//
//  Array + MLArray.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

import CoreML


extension MLMultiArray {
    
    public convenience init<T>(_ array: MultiArray<T>) throws {
        let dataType: MLMultiArrayDataType
        switch T.self {
        case is Int32.Type: dataType = .int32
#if (!os(macOS) || arch(arm64))
        case is Float16.Type: dataType = .float16
#endif
        case is Float.Type: dataType = .float32
        case is Double.Type: dataType = .double
        default: fatalError("Unsupported type \(T.self)")
        }
        
        try self.init(
            dataPointer: array.baseAddress,
            shape: array.shape.map({ NSNumber(value: $0) }),
            dataType: dataType,
            strides: array.strides.map({ NSNumber(value: $0) })
        ) { [array] _ in
            _ = array // capture is enough, let Swift does the rest
        }
    }
    
}


extension MultiArray {
    
    @inlinable
    func captureReference() -> Data.Deallocator {
        let unmanaged = Unmanaged.passRetained(self)
        return .custom { _, _ in
            unmanaged.release()
        }
    }
    
    public convenience init(_ array: MLMultiArray) {
        let dataType: MLMultiArrayDataType
        switch Element.self {
        case is Int32.Type: dataType = .int32
#if (!os(macOS) || arch(arm64))
        case is Float16.Type: dataType = .float16
#endif
        case is Float.Type: dataType = .float32
        case is Double.Type: dataType = .double
        default: fatalError("Unsupported type \(Element.self)")
        }
        precondition(dataType == array.dataType, "Data type mismatch")
        
        let shape = array.shape.map(\.intValue)
        let count = shape.reduce(1, *)
        self.init(
            bytesNoCopy: .init(start: array.dataPointer.assumingMemoryBound(to: Element.self), count: count),
            shape: shape,
            deallocator: .custom({ [array] _,_ in
                _ = array // capture
            })
        )
    }
    
}

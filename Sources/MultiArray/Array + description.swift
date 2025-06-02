//
//  Array + description.swift
//  VocalRemover
//
//  Created by Vaida on 2025-05-21.
//

extension MultiArray: CustomStringConvertible where Element: BinaryFloatingPoint & CVarArg {
    
    /// How many items to show at each end of a truncated axis
    private var edgeItems: Int { 3 }
    /// How many spaces per nesting level
    private var indentWidth: Int { 2 }
    
    public var description: String {
        _buildDescription(level: 0, offset: 0, strides: self.strides)
    }
    
    /// Recursively build the string for a subtensor at `level` and linear `offset`.
    private func _buildDescription(level: Int, offset: Int, strides: UnsafeMutableBufferPointer<Int>) -> String {
        let pad = String(repeating: " ", count: level * indentWidth)
        let isLastDim = (level == shape.count - 1)
        let dim = shape[level]
        
        if isLastDim {
            func transform(i: Int) -> String {
                let v = buffer[offset + i * strides[level]]
                return String(format: "% .4e", v)
            }
            
            // 1D case: collect and maybe truncate
            let s: String
            if dim <= 2 * edgeItems {
                s = "[ " + (0..<dim)
                    .map(transform)
                    .joined(separator: ", ") + " ]"
            } else {
                let leading = (0..<3).map(transform)
                let trailing = (dim-3..<dim).map(transform)
                
                let first = leading.joined(separator: ", ")
                let last  = trailing.joined(separator: ", ")
                s = "[ " + first + ",  …,  " + last + " ]"
            }
            return pad + s
        }
        
        // ND case: build child blocks, maybe truncated
        func transform(i: Int) -> String {
            let childOffset = offset + i * strides[level]
            return _buildDescription(level: level+1, offset: childOffset, strides: strides)
        }
        
        var blocks: [String] = []
        if dim <= 2 * edgeItems {
            blocks.append(contentsOf: (0..<dim).map(transform))
        } else {
            let leading = (0..<3).map(transform)
            let trailing = (dim-3..<dim).map(transform)
            
            let ell = String(repeating: " ", count: (level+1)*indentWidth) + "…"
            blocks.append(contentsOf: leading)
            blocks.append(ell)
            blocks.append(contentsOf: trailing)
        }
        
        // choose separator: PyTorch inserts a blank line between top‐level blocks
        let sep = level == 0 ? ",\n\n" : ",\n"
        let inner = blocks.joined(separator: sep)
        return pad + "[\n" + inner + "\n" + pad + "]"
    }
}

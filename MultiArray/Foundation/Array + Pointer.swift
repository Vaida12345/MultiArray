//
//  Array + Pointer.swift
//  MultiArray
//
//  Created by Vaida on 2026-06-26.
//


extension MultiArray {
    
    /// Returns the pointer of the first element whose leading dimension is `dim0`.
    ///
    /// The `pointer(at:)` methods provides views to the underlying raw address at a given location.
    ///
    /// For example, for a 2D array, you can use `matrix.pointer(at: i).pointee` to get `matrix[i, 0]`, or `Buffer(baseAddress: matrix.pointer(at: i), count: width)` to get the `i`th row.
    ///
    /// Furthermore, because the underlying buffer is raw-major contiguous, you can use `Buffer(start: matrix.pointer(at: i), count: width * 2)` to get the `matrix[i:i+1, :]` slice.
    ///
    /// - Precondition: dimension count must be at least `1`.
    ///
    /// - Complexity: Integer arithmetic (multiplication).
    @inlinable
    public func pointer(at dim0: Int) -> UnsafeMutablePointer<Element> {
        let offset = dim0 &* self.strides[0]
        return self.baseAddress + offset
    }
    
    /// Returns the pointer of the first element whose leading dimension is `[dim0, dim1]`.
    ///
    /// The `pointer(at:)` methods provides views to the underlying raw address at a given location.
    ///
    /// For example, for a 2D array, you can use `matrix.pointer(at: i).pointee` to get `matrix[i, 0]`, or `Buffer(baseAddress: matrix.pointer(at: i), count: width)` to get the `i`th row.
    ///
    /// Furthermore, because the underlying buffer is raw-major contiguous, you can use `Buffer(start: matrix.pointer(at: i), count: width * 2)` to get the `matrix[i:i+1, :]` slice.
    ///
    /// - Precondition: dimension count must be at least `2`.
    ///
    /// - Complexity: Integer arithmetic (multiplication).
    @inlinable
    public func pointer(at dim0: Int, _ dim1: Int) -> UnsafeMutablePointer<Element> {
        let offset = dim0 &* self.strides[0] &+ dim1 &* self.strides[1]
        return self.baseAddress + offset
    }
    
    /// Returns the pointer of the first element whose leading dimension is `[dim0, dim1, dim2]`.
    ///
    /// The `pointer(at:)` methods provides views to the underlying raw address at a given location.
    ///
    /// For example, for a 2D array, you can use `matrix.pointer(at: i).pointee` to get `matrix[i, 0]`, or `Buffer(baseAddress: matrix.pointer(at: i), count: width)` to get the `i`th row.
    ///
    /// Furthermore, because the underlying buffer is raw-major contiguous, you can use `Buffer(start: matrix.pointer(at: i), count: width * 2)` to get the `matrix[i:i+1, :]` slice.
    ///
    /// - Precondition: dimension count must be at least `3`.
    ///
    /// - Complexity: Integer arithmetic (multiplication).
    @inlinable
    public func pointer(at dim0: Int, _ dim1: Int, _ dim2: Int) -> UnsafeMutablePointer<Element> {
        let offset = dim0 &* self.strides[0] &+ dim1 &* self.strides[1] &+ dim2 &* self.strides[2]
        return self.baseAddress + offset
    }
    
    /// Returns the pointer of the first element whose leading dimension is `[dim0, dim1, dim2, dim3]`.
    ///
    /// The `pointer(at:)` methods provides views to the underlying raw address at a given location.
    ///
    /// For example, for a 2D array, you can use `matrix.pointer(at: i).pointee` to get `matrix[i, 0]`, or `Buffer(baseAddress: matrix.pointer(at: i), count: width)` to get the `i`th row.
    ///
    /// Furthermore, because the underlying buffer is raw-major contiguous, you can use `Buffer(start: matrix.pointer(at: i), count: width * 2)` to get the `matrix[i:i+1, :]` slice.
    ///
    /// - Precondition: dimension count must be at least `4`.
    ///
    /// - Complexity: Integer arithmetic (multiplication).
    @inlinable
    public func pointer(at dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int) -> UnsafeMutablePointer<Element> {
        let offset = dim0 &* self.strides[0] &+ dim1 &* self.strides[1] &+ dim2 &* self.strides[2] &+ dim3 &* self.strides[3]
        return self.baseAddress + offset
    }
    
    /// Returns the pointer of the first element whose leading dimension is `[dim0, dim1, dim2, dim3, dim4]`.
    ///
    /// The `pointer(at:)` methods provides views to the underlying raw address at a given location.
    ///
    /// For example, for a 2D array, you can use `matrix.pointer(at: i).pointee` to get `matrix[i, 0]`, or `Buffer(baseAddress: matrix.pointer(at: i), count: width)` to get the `i`th row.
    ///
    /// Furthermore, because the underlying buffer is raw-major contiguous, you can use `Buffer(start: matrix.pointer(at: i), count: width * 2)` to get the `matrix[i:i+1, :]` slice.
    ///
    /// - Precondition: dimension count must be at least `5`.
    ///
    /// - Complexity: Integer arithmetic (multiplication).
    @inlinable
    public func pointer(at dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int) -> UnsafeMutablePointer<Element> {
        let offset = dim0 &* self.strides[0] &+ dim1 &* self.strides[1] &+ dim2 &* self.strides[2] &+ dim3 &* self.strides[3] &+ dim4 &* self.strides[4]
        return self.baseAddress + offset
    }
    
    /// Returns the pointer of the first element whose leading dimension is `[dim0, dim1, dim2, dim3, dim4, dim5]`.
    ///
    /// The `pointer(at:)` methods provides views to the underlying raw address at a given location.
    ///
    /// For example, for a 2D array, you can use `matrix.pointer(at: i).pointee` to get `matrix[i, 0]`, or `Buffer(baseAddress: matrix.pointer(at: i), count: width)` to get the `i`th row.
    ///
    /// Furthermore, because the underlying buffer is raw-major contiguous, you can use `Buffer(start: matrix.pointer(at: i), count: width * 2)` to get the `matrix[i:i+1, :]` slice.
    ///
    /// - Precondition: dimension count must be at least `6`.
    ///
    /// - Complexity: Integer arithmetic (multiplication).
    @inlinable
    public func pointer(at dim0: Int, _ dim1: Int, _ dim2: Int, _ dim3: Int, _ dim4: Int, _ dim5: Int) -> UnsafeMutablePointer<Element> {
        let offset = dim0 &* self.strides[0] &+ dim1 &* self.strides[1] &+ dim2 &* self.strides[2] &+ dim3 &* self.strides[3] &+ dim4 &* self.strides[4] &+ dim5 &* self.strides[5]
        return self.baseAddress + offset
    }
    
}

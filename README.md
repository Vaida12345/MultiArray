# Multi Array
Swift wrapper for row-major multiarray

## Link with `MLMultiArray`
This framework enables conversion between `MultiArray` and `MLMultiArray` in O(*1*) using `init(_:)`, the underlying buffer is referenced.

## Optimized 
Use `withTransaction(_:)` to batch operations. This method is optimzed, using using pointers to optimize retain/release.

Operators include:
- `sliced`
- `reshape`
- `transpose`

## DSP
This framework offers audio processing models similar to the ones in `PyTorch`

| MultiArray | PyTorch |
|------------|---------|
|`DiscreteFourierTransform`|`torch.fft.rfft`|
|`InverseDiscreteFourierTransform`|`torch.fft.irfft`|
|`ShortTimeFourierTransform`|`torch.fft.stft`|
|`InverseShortTimeFourierTransform`|`torch.fft.istft`|

## Element-wise Operators
Element-wise operators implemented using `vDSP`

- `+`, `+=`
- `-`, `-=`
- `*`, `*=`

## Other features
- Subscript using variadic input
- shape, stride, and subscript using native Swift values
- Autorelease
- `torch.tensor`-like description
- view into the multiarray using `view(at:)` and `sequence(at:)`

#if canImport(CoreVideo)
import CoreVideo

// CoreVideo pixel buffers are reference types but we only share read-only snapshots across actors.
extension CVPixelBuffer: @unchecked @retroactive Sendable {}
#endif

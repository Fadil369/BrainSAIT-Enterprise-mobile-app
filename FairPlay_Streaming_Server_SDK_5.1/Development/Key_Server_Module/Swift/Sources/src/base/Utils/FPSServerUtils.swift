//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//
import Foundation

/// Used for debug printing of array in hex format
extension Array where Element == UInt8 {
  var hexStringUpper: String {
    self.reduce(into: "") {
      result, byte in result += String(format: "%02X", byte)
    }
  }

  init?(fromHexString hexString: String) {
    var result: [UInt8] = []
    guard hexString.utf8.count % 2 == 0 else {
      return nil
    }
    result.reserveCapacity(hexString.utf8.count / 2)

    var iter = hexString.utf8.makeIterator()
    while let upperBits = iter.next() {
      let lowerBits = iter.next()!
      guard let upperBits = upperBits.hexNibble else { return nil }
      guard let lowerBits = lowerBits.hexNibble else { return nil }

      result.append(upperBits << 4 | lowerBits)
    }

    self = result
  }
}

extension UInt8 {
  var hexNibble: UInt8? {
    switch self {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      return self - UInt8(ascii: "0")
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      return self - UInt8(ascii: "A") + 10
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      return self - UInt8(ascii: "a") + 10
    default:
      return nil
    }
  }
}

/// Read bytess from input with given offset and length.
///
/// Throws error if offset + length overflows.
/// Throws error if input is not large enough.
public func readBytes(
  _ input: [UInt8],
  _ offset: Int,
  _ numberOfBytesToRead: Int
) throws -> [UInt8] {

  // Check for integer overflow
  try requireAction(offset <= (offset + numberOfBytesToRead), { throw FPSStatus.paramErr })

  // Check that input is large enough
  try requireAction((offset + numberOfBytesToRead) <= input.count, { throw FPSStatus.paramErr })

  return Array(input[offset...(offset + numberOfBytesToRead - 1)])
}

/// Reads 16-byte big-endian value from src.
private func GetBigEndian16(_ src: [UInt8]) -> UInt16 {
  return (UInt16(src[0]) << 8) | UInt16(src[1])
}

/// Reads 32-byte big-endian value from src.
private func GetBigEndian32(_ src: [UInt8]) -> UInt32 {
  return (UInt32(src[0]) << 24) | (UInt32(src[1]) << 16) | (UInt32(src[2]) << 8) | UInt32(src[3])
}

/// Reads 64-byte big-endian value from src.
private func GetBigEndian64(_ src: [UInt8]) -> UInt64 {
  var ret: UInt64 = 0
  var tmp: UInt64 = 0

  tmp = UInt64(src[0])
  ret = (tmp << 56)
  tmp = UInt64(src[1])
  ret = ret | (tmp << 48)
  tmp = UInt64(src[2])
  ret = ret | (tmp << 40)
  tmp = UInt64(src[3])
  ret = ret | (tmp << 32)
  tmp = UInt64(src[4])
  ret = ret | (tmp << 24)
  tmp = UInt64(src[5])
  ret = ret | (tmp << 16)
  tmp = UInt64(src[6])
  ret = ret | (tmp << 8)
  tmp = UInt64(src[7])
  ret = ret | tmp

  return ret
}

/// Reads 16-byte big-endian value from input. Returns error if input is not large enough.
public func readBigEndianU16(_ input: [UInt8], _ offset: Int) throws -> UInt16 {
  try requireAction(input.count >= offset + MemoryLayout<UInt16>.size, { throw FPSStatus.paramErr })
  return GetBigEndian16(Array(input[offset...(offset + MemoryLayout<UInt16>.size - 1)]))
}

/// Reads 32-byte big-endian value from input. Returns error if input is not large enough.
public func readBigEndianU32(_ input: [UInt8], _ offset: Int) throws -> UInt32 {
  try requireAction(input.count >= offset + MemoryLayout<UInt32>.size, { throw FPSStatus.paramErr })
  return GetBigEndian32(Array(input[offset...(offset + MemoryLayout<UInt32>.size - 1)]))
}

/// Reads 64-byte big-endian value from input. Returns error if input is not large enough.
public func readBigEndianU64(_ input: [UInt8], _ offset: Int) throws -> UInt64 {
  try requireAction(input.count >= offset + MemoryLayout<UInt64>.size, { throw FPSStatus.paramErr })
  return GetBigEndian64(Array(input[offset...(offset + MemoryLayout<UInt64>.size - 1)]))
}

/// Fills buffer with random numbers
public func genRandom(_ out: inout [UInt8], _ length: Int) {
  out = (0..<length).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
}

public protocol ArrayHelperUtils {
  /// Appends buffer with a u32 in big endian
  mutating func appendBigEndianU32(_ value: UInt32)

  /// Appends buffer with a u64 in big endian
  mutating func appendBigEndianU64(_ value: UInt64)

  /// Appends buffer with random bytes
  mutating func appendRandomBytes(_ length: Int)
}

extension [UInt8]: ArrayHelperUtils {

  /// Appends buffer with a u32 in big endian
  public mutating func appendBigEndianU32(_ value: UInt32) {
    var value_be = value.bigEndian
    self.append(contentsOf: Array(Data(bytes: &(value_be), count: 4)))
  }

  /// Appends buffer with a u64 in big endian
  public mutating func appendBigEndianU64(_ value: UInt64) {
    var value_be = value.bigEndian
    self.append(contentsOf: Array(Data(bytes: &(value_be), count: 8)))
  }

  /// Appends buffer with random bytes
  public mutating func appendRandomBytes(_ length: Int) {
    var tempVec: [UInt8] = [UInt8](repeating: 0, count: length)

    genRandom(&tempVec, length)

    self.append(contentsOf: tempVec)
  }
}

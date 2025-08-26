//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

struct extension_constants {

  // Strings for output JSON
  public enum CodingKeys: String, CodingKey {
    case contentType = "content-type"
  }

  public static let CONTENT_TYPE_UHD_STR = "uhd"
  public static let CONTENT_TYPE_HD_STR = "hd"
  public static let CONTENT_TYPE_SD_STR = "sd"
  public static let CONTENT_TYPE_AUDIO_STR = "audio"

  /// FairPlay Streaming Key Formats
  public enum FPSKeyFormatTag: UInt64 {
    case buf16Byte = 0x58b38165af0e3d5a
  }

  /// Content Types
  public enum ContentType {
    case unknown
    case audio
    case sd
    case hd
    case uhd
  }

  /// FairPlay Security Levels (sent in SPC and CKC)
  ///
  /// Values are ordered so comparisions are possible
  public enum FPSSecurityLevel: UInt64 {
    case audio = 0x17d99d574eed567d
    case baseline = 0x32f0004966a5c4f8
    case main = 0x4e7fd92421d588b4
  }
}

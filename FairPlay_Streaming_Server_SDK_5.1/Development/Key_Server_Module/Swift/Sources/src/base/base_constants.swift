//
// base_constants.swift: Contains the constants that need to be defined for the Base class.
//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

public struct base_constants {

  // Standard sizes
  public static let AES128_KEY_SZ = 16
  public static let AES128_IV_SZ = 16
  public static let AES128_BLOCK_SIZE = 16

  // SPC v1 and CKC v1 field sizes as per specification for parsing
  public static let FPS_V1_ASSET_ID_MIN_SZ = 2
  public static let FPS_V1_ASSET_ID_MAX_SZ = 200
  public static let FPS_V1_SKR1_INTEGRITY_SZ = 16
  public static let FPS_V1_HASH_SZ = 20
  public static let FPS_V1_R2_SZ = 21
  public static let FPS_V1_R1_SZ = 44
  public static let FPS_V1_HU_SZ = 20
  public static let FPS_V1_SKR1_SZ = 112
  public static let FPS_V1_WRAPPED_KEY_SZ = 128
  public static let FPS_V2_WRAPPED_KEY_SZ = 256

  public static let FPS_ENCRYPTED_SECURITY_LEVEL_REPORT_TLLV_SIZE = 32

  public static let NO_LEASE_DURATION: UInt32 = 0xFFFFFFFF

  public static let FPS_MAX_STREAM_ID_LENGTH = 16
  public static let FPS_MAX_TITLE_ID_LENGTH = 16
  public static let FPS_MAX_NUM_CRYPTO_VERSIONS = 100

  public static let FPS_VENDOR_HASH_SIZE = 8
  public static let FPS_PRODUCT_HASH_SIZE = 8

  public static let FPS_CAPABILITIES_FLAGS_LENGTH = 16

  public static let FPS_OFFLINE_CONTENTID_LENGTH = 16

  public static let FPS_TLLV_TAG_SZ = 8
  public static let FPS_TLLV_TOTAL_LENGTH_SZ = 4
  public static let FPS_TLLV_VALUE_LENGTH_SZ = 4

  public static let FPS_MAX_KEY_FORMATS = 64
  public static let FPS_KEY_PAYLOAD_STRUCT_VERSION: UInt64 = 1

  public static let FPS_TLLV_SECURITY_LEVEL_TLLV_VERSION = 1

  public static let KD_SYNC_SPC_FLAG_TITLEID_VALID: UInt64 = 1 << 3

  public static let FPS_TLLV_OFFLINEKEY_TLLV_VERSION = 1
  public static let FPS_TLLV_OFFLINEKEY_TLLV_VERSION_2 = 2

  // Capabilities TLLV flags (delivered in SPC)
  /// The client can enforce HDCP type1 (as well as type 0 or none values in HDCP TLLV when received in CKC)
  public static let FPS_CAPABILITY_HDCP_TYPE1_ENFORCEMENT_SUPPORTED =
    1
  /// The client can enforce dual expiry if sent by the server
  public static let FPS_CAPABILITY_OFFLINE_KEY_SUPPORTED =
    1 << 1
  /// The client can support check-in (secure delete) requests
  public static let FPS_CAPABILITY_CHECK_IN_SUPPORTED =
    1 << 2
  /// The client can support Offline Key TLLV V2
  public static let FPS_CAPABILITY_OFFLINE_KEY_V2_SUPPORTED =
    1 << 3
  /// The client can support enforcement of security level Baseline
  public static let FPS_CAPABILITY_SECURITY_LEVEL_BASELINE_SUPPORTED =
    1 << 4
  /// The client can support enforcement of security level Main
  public static let FPS_CAPABILITY_SECURITY_LEVEL_MAIN_SUPPORTED =
    1 << 5

  public static let FPS_KEY_DURATION_RESERVED_FIELD_VALUE: UInt32 = 0x86d34a3a

  /// Latest published macOS Kext Deny List version by Apple
  public static let MIN_KDL_VERSION: Int = 31

  public enum FairPlayStreamingVersion: UInt32 {
    case v1 = 1
  }

  /// Version number of the SPC
  ///
  /// v1 uses 1024-bit certificates
  /// v2 uses 2048-bit certificates
  public enum SPCVersion: UInt32 {
    case v1 = 1
    case v2 = 2
  }

  /// AES Encryption Mode
  public enum AESEncryptionMode: UInt32 {
    case aesEncrypt = 0
    case aesDecrypt = 1
  }

  /// AES Cipher Mode
  public enum AESEncryptionCipher: UInt32 {
    case aesCBC = 0
    case aesECB = 1
  }

  /// FairPlay Streaming Requested Key Type
  public enum FPSKeyType: UInt32 {
    case none = 0
  }

  /// FairPlay Streaming License Type
  public enum FPSLicenseType: UInt32 {
    case none = 0
    case offlineHLS = 1
  }

  /// TLLV tag values used in SPC and CKC
  public enum FPSTLLVTagValue: UInt64 {
    case r2tag = 0x71b5595ac1521133
    case antiReplayTag = 0x89c90f12204106b2
    case sessionKeyR1Tag = 0x3d1a10b8bffac2ec
    case sessionKeyR1IntegrityTag = 0xb349d4809e910687
    case assetIDTag = 0x1bf7f53f5d5d5a1f
    case transactionIDTag = 0x47aa7ad3440577de
    case protocolVersionUsedTag = 0x5d81bcbcc7f61703
    case protocolVersionsSupportedTag = 0x67b8fb79ecce1a13
    case returnRequestTag = 0x19f9d4e5ab7609cb
    case r1Tag = 0xea74c4645d5efee9
    case streamingIndicatorTag = 0xabb0256a31843974
    case mediaPlaybackStateTag = 0xeb8efdf2b25ab3a0
    case offlineSyncTag = 0x77966de1dc1083ad
    case capabilitiesTag = 0x9c02af3253c07fb2
    case keyDurationTag = 0x47acf6a418cd091a
    case offlineKeyTag = 0x6375d9727060218c
    case hdcpInformationTag = 0x2e52f1530d8ddb4a
    case securityLevelTag = 0x644cb1dac0313250
    case supportedKeyFormatTag = 0x8d8e84fa6cc35eb7
    case securityLevelReportTag = 0xb18ee16ea50f6c02
    case deviceInfoTag = 0xd43fc6abc596aae7
    case deviceIdentityTag = 0x94c17cd676c69b59
    case kdlVersionReportTag = 0x70eca6573388e329
    case vmDeviceInfoTag = 0x756440e240499f70
  }

  /// Content Type used for KSMKeyPayload structure
  public enum KSMKeyPayloadContentType: UInt64 {
    case unknown = 0
    case video = 1
    case audio = 3
  }

  /// FairPlay Streaming Key Duration Type
  public enum FPSKeyDurationType: UInt32 {
    case none = 0
    case lease = 0x1a4bde7e
    case rental = 0x3dfe45a0
    case leaseAndRental = 0x27b59bde
    case persistence = 0x3df2d9fb
    case persistenceAndDuration = 0x18f06048
  }

  /// FairPlay Streaming HDCP Requirement Type
  public enum FPSHDCPRequirement: UInt64 {
    case hdcpNotRequired = 0xef72894ca7895b78
    case hdcpType0 = 0x40791ac78bd5c571
    case hdcpType1 = 0x285a0863bba8e1d3
  }

  /// FairPlay Streaming Device Playback State
  public enum FPSDevicePlaybackState: UInt64 {
    case firstPlaybackCKRequired = 0xf4dee5a2
    case currentlyPlayingCKRequired = 0x4f834330
    case currentlyPlayingCKNotRequired = 0xa5d6739e
  }

  /// FairPlay Streaming Apple Device Type
  public enum FPSAppleDeviceType: UInt64 {
    case mac = 0x358c41b1ec78f599
    case tv = 0xc1500767c86c1fae
    case iOS = 0x8551fd5e31f479b3
    case watch = 0x5da86ac0c57155dc
  }

  /// FairPlay Streaming Device Class
  public enum FPSDeviceClass: UInt32 {
    case unknown = 0

    // Apple Devices
    case appleLivingRoom = 1
    case appleMobile = 2
    case appleDesktop = 3
    case appleSpacial = 4
    case appleWearable = 5
    case appleUnknown = 127

    // Partner Devices
    case partnerLivingRoom = 128
    case partnerUnknown = 255

    var description: String {
        switch self {
            case .appleLivingRoom: return "appleLivingRoom"
            case .appleMobile: return "appleMobile"
            case .appleDesktop: return "appleDesktop"
            case .appleSpacial: return "appleSpacial"
            case .appleWearable: return "appleWearable"
            case .appleUnknown: return "appleUnknown"
            case .partnerLivingRoom: return "partnerLivingRoom"
            case .partnerUnknown: return "partnerUnknown"
            default: return "Unknown"
        }
    }
  }
}

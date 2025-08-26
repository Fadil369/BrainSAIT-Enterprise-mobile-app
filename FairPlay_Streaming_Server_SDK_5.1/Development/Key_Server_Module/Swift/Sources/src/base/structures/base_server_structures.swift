//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//
/// Contains both the SPC and CKC containers along with stream and title IDs.
/// This is the base structure that is most commonly sent to functions.
public struct FPSServerCtx {
  public var spcContainer: FPSServerSPCContainer
  public var ckcContainer: FPSServerCKCContainer
  public var streamId: [UInt8]
  public var titleId: [UInt8]

  // Extension
  public var ext: ServerCtxExtension

  init() {
    spcContainer = FPSServerSPCContainer()
    ckcContainer = FPSServerCKCContainer()
    streamId = Array()
    titleId = Array()

    ext = ServerCtxExtension()
  }
}

/// Contains all the information parsed out of the SPC including version, SPC encryption AES key
/// and IV, and TLLV data.
public struct FPSServerSPCContainer {
  public var version: UInt32
  public var reservedValue: UInt32
  public var aesKeyIV: [UInt8]
  public var aesWrappedKey: [UInt8]
  public var aesWrappedKeySize: Int
  public var certificateHash: [UInt8]
  public var spcDecryptedData: [UInt8]
  public var spcDataSize: Int
  public var spcDataOffset: Int
  public var spcData: FPSServerSPCData

  // Extension
  public var ext: SPCContainerExtension

  init() {
    version = 0
    reservedValue = 0
    aesKeyIV = Array(repeating: 0, count: Int(base_constants.AES128_IV_SZ))
    aesWrappedKey = Array(repeating: 0, count: Int(base_constants.FPS_V2_WRAPPED_KEY_SZ))
    aesWrappedKeySize = 0
    certificateHash = Array(repeating: 0, count: Int(base_constants.FPS_V1_HASH_SZ))
    spcDecryptedData = [UInt8]()
    spcDataSize = 0
    spcDataOffset = 0
    spcData = FPSServerSPCData()

    ext = SPCContainerExtension()
  }
}

/// Contains information that will be added to the CKC including version, CKC encryption, AES key
/// and IV, and the CKC payload.
public struct FPSServerCKCContainer {
  /// If this is set to false, the CKC will not be returned as part of the output.
  public var returnCKC: Bool
  public var version: UInt32
  public var aesKeyIV: [UInt8]
  public var ckc: [UInt8]
  public var ckcDataPtr: [UInt8]
  public var ckcData: FPSServerCKCData

  init() {
    returnCKC = true
    version = 0
    aesKeyIV = Array(repeating: 0, count: Int(base_constants.AES128_IV_SZ))
    ckc = [UInt8]()
    ckcDataPtr = [UInt8]()
    ckcData = FPSServerCKCData()
  }
}

/// Contains information parsed out of the SPC TLLVs after decryption.
public struct FPSServerSPCData {
  public var antiReplay: [UInt8]
  public var sk: [UInt8]
  public var hu: [UInt8]
  public var r2: [UInt8]
  public var r1: [UInt8]
  public var skR1IntegrityTag: [UInt8]
  public var skR1Integrity: [UInt8]
  public var skR1: [UInt8]
  public var assetId: [UInt8]
  public var versionUsed: UInt32
  public var versionsSupported: [UInt32]
  public var returnTLLVs: [FPSServerTLLV]
  public var returnRequest: FPSServerTLLV
  public var clientFeatures: FPSServerClientFeatures
  public var spcDataParser: FPSServerSPCDataParser
  public var playInfo: FPSServerMediaPlaybackState
  public var streamingIndicator: UInt64
  public var transactionId: UInt64

  // Sync TLLV
  public var syncServerChallenge: UInt64
  public var syncFlags: UInt64
  public var syncTitleId: [UInt8]
  public var durationToRentalExpiry: UInt32
  public var recordsDeleted: Int
  public var deletedContentIDs: [UInt8]

  // Client capabilities flags TLLV
  public var clientCapabilities: [UInt8]

  // Security Level Report TLLV
  public var isSecurityLevelTLLVValid: Bool
  public var supportedSecurityLevel: UInt64
  public var clientKextDenyListVersion: UInt32

  public var deviceIdentity: FPSDeviceIdentity
  // Deprecated - newer devices send Device Identity instead
  public var deviceInfo: FPSDeviceInfo

  // Supported Key Formats
  public var numberOfSupportedKeyFormats: UInt32
  public var supportedKeyFormats: [UInt64]

  public var vmDeviceInfo: Optional<VMDeviceInfo>

  // Extension
  public var ext: SPCDataExtension

  init() {
    antiReplay = Array(repeating: 0, count: Int(base_constants.AES128_KEY_SZ))
    sk = Array(repeating: 0, count: Int(base_constants.AES128_KEY_SZ))
    hu = Array(repeating: 0, count: Int(base_constants.FPS_V1_HASH_SZ))
    r2 = Array(repeating: 0, count: Int(base_constants.FPS_V1_R2_SZ))
    r1 = Array(repeating: 0, count: Int(base_constants.FPS_V1_R1_SZ))
    skR1IntegrityTag = Array(repeating: 0, count: Int(base_constants.FPS_V1_SKR1_INTEGRITY_SZ))
    skR1Integrity = Array(repeating: 0, count: Int(base_constants.FPS_V1_SKR1_INTEGRITY_SZ))
    skR1 = Array(repeating: 0, count: Int(base_constants.FPS_V1_SKR1_SZ))

    assetId = Array(repeating: 0, count: Int(base_constants.FPS_V1_ASSET_ID_MAX_SZ))
    versionUsed = 0
    versionsSupported = []
    returnTLLVs = [FPSServerTLLV]()
    returnRequest = FPSServerTLLV()
    clientFeatures = FPSServerClientFeatures()
    spcDataParser = FPSServerSPCDataParser()
    playInfo = FPSServerMediaPlaybackState()
    streamingIndicator = 0
    transactionId = 0

    syncServerChallenge = 0
    syncFlags = 0
    syncTitleId = Array(repeating: 0, count: Int(base_constants.FPS_MAX_TITLE_ID_LENGTH))
    durationToRentalExpiry = 0
    recordsDeleted = 0
    deletedContentIDs = [UInt8]()

    clientCapabilities = Array(
      repeating: 0, count: Int(base_constants.FPS_CAPABILITIES_FLAGS_LENGTH))

    isSecurityLevelTLLVValid = false
    supportedSecurityLevel = 0
    clientKextDenyListVersion = 0

    deviceIdentity = FPSDeviceIdentity()
    deviceInfo = FPSDeviceInfo()

    numberOfSupportedKeyFormats = 0
    supportedKeyFormats = Array(repeating: 0, count: base_constants.FPS_MAX_KEY_FORMATS)

    vmDeviceInfo = Optional.none

    ext = SPCDataExtension()
  }
}

/// Information used to help identify the client device type.
///
/// Includes vendor and product hashes, REE and TEE versions (only for third party devices), and
/// OS version (only for Apple products).
///
/// Note: this TLLV is only sent by devices running FairPlay client software released in 2021 or
/// later and its use should be prioritized over FPSDeviceInfo for client device type information.
public struct FPSDeviceIdentity {
  public var isDeviceIdentitySet: Bool
  public var fpdiVersion: UInt32
  public var deviceClass: UInt32
  public var vendorHash: [UInt8]
  public var productHash: [UInt8]
  public var fpVersionREE: UInt32
  public var fpVersionTEE: UInt32
  public var osVersion: UInt32

  init() {
    isDeviceIdentitySet = false
    fpdiVersion = 0
    deviceClass = 0
    vendorHash = [UInt8]()
    productHash = [UInt8]()
    fpVersionREE = 0
    fpVersionTEE = 0
    osVersion = 0
  }
}

/// Basic information about the client device including device type and OS version.
///
/// Note: This is a TLLV that is kept for legacy purposes. FPSDeviceIdentity should be used instead
/// if available.
public struct FPSDeviceInfo {
  public var isDeviceInfoSet: Bool
  public var deviceType: UInt64
  public var osVersion: UInt32

  init() {
    isDeviceInfoSet = false
    deviceType = 0
    osVersion = 0
  }
}

/// Data that will be added to the CKC TLLVs.
public struct FPSServerCKCData {
  public var ck: [UInt8]
  public var iv: [UInt8]
  public var r1: [UInt8]
  public var keyDuration: FPSServerKeyDuration
  public var hdcpTypeTLLVValue: base_constants.FPSHDCPRequirement

  // For new FPS crypto lib this is content key tag and content key TLLV payload to use
  public var contentKeyTLLVTag: UInt64
  public var contentKeyTLLVPayload: [UInt8]

  // Extension
  public var ext: CKCDataExtension

  init() {
    ck = Array(repeating: 0, count: Int(base_constants.AES128_KEY_SZ))
    iv = Array(repeating: 0, count: Int(base_constants.AES128_KEY_SZ))
    r1 = Array(repeating: 0, count: Int(base_constants.FPS_V1_R1_SZ))
    keyDuration = FPSServerKeyDuration()
    hdcpTypeTLLVValue = base_constants.FPSHDCPRequirement.hdcpNotRequired

    contentKeyTLLVTag = 0
    contentKeyTLLVPayload = [UInt8]()

    ext = CKCDataExtension()
  }
}

/// Contains the tag and value fields for a TLLV.
public struct FPSServerTLLV {
  public var tag: UInt64
  public var value: [UInt8]  // Contains only the value data (no padding)

  init() {
    tag = 0
    value = [UInt8]()
  }
}

/// Contains fields that indicate whether or not certain features are supported by the client.
///
/// Includes offline key V1 vs V2, Baseline vs Main security levels, and HDCP Type 1.
public struct FPSServerClientFeatures {
  public var supportsOfflineKeyTLLV: Bool
  public var supportsOfflineKeyTLLVV2: Bool
  public var supportsSecurityLevelBaseline: Bool
  public var supportsSecurityLevelMain: Bool
  public var supportsHDCPTypeOne: Bool
  public var supportsDualExpiry: Bool
  public var supportsCheckIn: Bool

  // Extension
  public var ext: ClientFeaturesExtension

  init() {
    supportsOfflineKeyTLLV = false
    supportsOfflineKeyTLLVV2 = false
    supportsSecurityLevelBaseline = false
    supportsSecurityLevelMain = false
    supportsHDCPTypeOne = false
    supportsDualExpiry = false
    supportsCheckIn = false

    ext = ClientFeaturesExtension()
  }
}

/// Intermediary data structure used when parsing the SPC.
///
/// Holds the current offset within the SPC data and parsed tags along with the TLLVs that have
/// been parsed.
public struct FPSServerSPCDataParser {
  public var currentOffset: Int
  public var TLLVs: [FPSServerTLLV]
  public var parsedTagValues: [UInt64]

  init() {
    currentOffset = 0
    TLLVs = [FPSServerTLLV]()
    parsedTagValues = [UInt64]()
  }
}

/// Contains information such as the date, playback state, and playback ID.
public struct FPSServerMediaPlaybackState {
  public var date: UInt32
  public var playbackState: UInt32
  public var playbackId: UInt64

  init() {
    date = 0
    playbackState = 0
    playbackId = 0
  }
}

/// Contains information about different key durations including lease, rental, and playback
/// duration, along with which type the key is.
public struct FPSServerKeyDuration {
  public var leaseDuration: UInt32
  public var rentalDuration: UInt32
  public var playbackDuration: UInt32
  public var keyType: UInt32

  // Extension
  public var ext: KeyDurationExtension

  init() {
    leaseDuration = 0
    rentalDuration = 0
    playbackDuration = 0
    keyType = 0

    ext = KeyDurationExtension()
  }
}

public struct VMDeviceInfo {
    public var hostDeviceClass: base_constants.FPSDeviceClass
    public var hostOSVersion: UInt32
    public var hostVMProtocolVersion: UInt32
    public var guestDeviceClass: base_constants.FPSDeviceClass
    public var guestOSVersion: UInt32
    public var guestVMProtocolVersion: UInt32

    init() {
        hostDeviceClass = base_constants.FPSDeviceClass.unknown
        hostOSVersion = 0
        hostVMProtocolVersion = 0
        guestDeviceClass = base_constants.FPSDeviceClass.unknown
        guestOSVersion = 0
        guestVMProtocolVersion = 0
    }
}

//
// base_fps_structures.swift: Contains the structure definitions for the Base class.
//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import Foundation

/// Base container where common code is implemented.
public struct Base: Codable {
  public var fpsOperations: FPSOperations

  enum CodingKeys: String, CodingKey {
    case fpsOperations = "fairplay-streaming-request"
  }

  public init() {
    fpsOperations = FPSOperations.init()
  }
}

/// Information about all create-ckc operations in a request.
///
/// Contains a vector of FPSOperation. This is necessary if receiving multiple requests in the same JSON.
public struct FPSOperations: Codable {
  var version: UInt32
  var operationsPtr: [FPSOperation]

  enum CodingKeys: String, CodingKey {
    case version
    case operationsPtr = "create-ckc"
  }

  public init() {
    version = 0
    operationsPtr = []
  }
}

/// Information about a single create-ckc operation.
///
/// This is the basic structure of a FairPlay Streaming key request after the JSON has been parsed.
public struct FPSOperation: Codable {

  var id: UInt64
  var spc: [UInt8]
  /// True when input SPC is a SyncSPC with check-in
  var isCheckIn: Bool
  var assetInfo: AssetInfo

  // Extension
  public var ext: FPSOperationExtension  // room for extension values if not in use template to ()

  enum CodingKeys: String, CodingKey {
    case id
    case spc
    case isCheckIn = "check-in"
    case assetInfo = "asset-info"
  }

  public init(from decoder: Decoder) throws {
    // Save any parsing errors until the end instead of throwing them immediately.
    // This way we can print all errors if there are more than one.
    var status = FPSStatus.noErr

    let values = try decoder.container(keyedBy: CodingKeys.self)

    // ID - optional, defaults to 0
    do {
      id = try values.decodeIfPresent(UInt64.self, forKey: .id) ?? 0
    } catch _ as DecodingError {
      do {
        // Try again as a string instead
        id = UInt64(try values.decodeIfPresent(String.self, forKey: .id)!) ?? 0
      } catch _ as DecodingError {
        id = 0 // default value if not provided
      }
    }

    // SPC - required
    spc = [0]
    let base64Request = try values.decode(String.self, forKey: .spc)
    if let decodedStr = Data(base64Encoded: base64Request) {
      spc = [UInt8](decodedStr)
    } else {
      fpsLogError(FPSStatus.parserErr, "Error parsing HDCP type:err")
      status = FPSStatus.parserErr
    }

    isCheckIn = try values.decodeIfPresent(Bool.self, forKey: .isCheckIn) ?? false

    // Extension
    ext = FPSOperationExtension()

    // Parse asset-info
    let assetInfoArray: [AssetInfo] = try values.decodeIfPresent(Array.self, forKey: .assetInfo) ?? []

    if !assetInfoArray.isEmpty {
      // We only handle one asset per request. Use the first one in the json array.
      assetInfo = assetInfoArray[0]
    } else {
      // Asset info not provided in input. They should be provided later.
      assetInfo = AssetInfo()
    }

    // Custom operations
    do {
      try parseCreateCKCOperationCustom(&self, decoder)
    } catch let error as FPSStatus {
      fpsLogError(error, "parseCreateCKCOperationCustom failed")
      status = error
    }

    if status != FPSStatus.noErr {
      throw status
    }
  }

  public func encode(to encoder: Encoder) throws {
  }
}

/// Protection requirements related to a particular asset.
public struct AssetInfo: Codable {

  var key: [UInt8]
  var iv: [UInt8]
  var isCKProvided: Bool

  public var hdcpReq: base_constants.FPSHDCPRequirement  // one of the FPSHDCPRequirement enums

  // Expirations
  var leaseDuration: UInt32     // Lease duration (starts at SPC creation time)
  var rentalDuration: UInt32    // rental duration in seconds. Starts at asset download time
  var playbackDuration: UInt32  // playback duration in seconds. Starts at asset first playback time

  // Offline HLS parameters
  var licenseType: base_constants.FPSLicenseType
  var streamId: [UInt8]   // unique Id of each HLS sub-stream
  var titleId: [UInt8]    // Id of a title (program). Same for all HLS subs-tream of a give title.

  // Extension
  public var ext: AssetInfoExtension

  enum CodingKeys: String, CodingKey {
    case key = "content-key"
    case iv = "content-iv"
    case isCKProvided
    case leaseDuration = "lease-duration"
    case hdcpReq = "hdcp-type"
    case offlinehls = "offline-hls"
  }

  enum OfflineHLSKeys: String, CodingKey {
    case licenseType
    case rentalDuration = "rental-duration"
    case playbackDuration = "playback-duration"
    case streamId = "stream-id"
    case titleId = "title-id"
  }

  public init() {
    key = [UInt8](repeating: 0, count: base_constants.AES128_KEY_SZ)
    iv = [UInt8](repeating: 0, count: base_constants.AES128_IV_SZ)
    isCKProvided = false
    leaseDuration = 0
    rentalDuration = 0
    playbackDuration = 0

    hdcpReq = base_constants.FPSHDCPRequirement.hdcpType0

    licenseType = base_constants.FPSLicenseType.none
    streamId = []
    titleId = []

    ext = AssetInfoExtension()
  }

  public init(from decoder: Decoder) throws {
    // Save any parsing errors until the end instead of throwing them immediately.
    // This way we can print all errors if there are more than one.
    var status = FPSStatus.noErr

    let values = try decoder.container(keyedBy: CodingKeys.self)

    isCKProvided = true

    // content key - optional for lease renewals
    key = Array(repeating: 0, count: base_constants.AES128_KEY_SZ)
    if var contentKey = try values.decodeIfPresent(String.self, forKey: .key) {
      if !contentKey.isEmpty {
        // Remove any initial 0x at the front
        if contentKey.hasPrefix("0x") {
          contentKey.removeFirst(2)
        }

        // Array fromHexString requires an even number of characters, so insert a 0 at the front if odd.
        if contentKey.count % 2 == 1 {
          contentKey.insert("0", at: contentKey.startIndex)
        }

        key = [UInt8](fromHexString: contentKey)!
      }
      key += [UInt8](repeating: 0, count: (base_constants.AES128_KEY_SZ - key.count))
    } else {
      isCKProvided = false
    }

    // content iv - optional for lease renewals
    iv = Array(repeating: 0, count: base_constants.AES128_IV_SZ)
    if var contentIV = try values.decodeIfPresent(String.self, forKey: .iv) {
      if !contentIV.isEmpty {
        // Remove any initial 0x at the front
        if contentIV.hasPrefix("0x") {
          contentIV.removeFirst(2)
        }

        // Array fromHexString requires an even number of characters, so insert a 0 at the front if odd.
        if contentIV.count % 2 == 1 {
          contentIV.insert("0", at: contentIV.startIndex)
        }

        iv = [UInt8](fromHexString: contentIV)!
      }
      iv += [UInt8](repeating: 0, count: (base_constants.AES128_IV_SZ - iv.count))
    } else {
      isCKProvided = false
    }

    leaseDuration =
      try values.decodeIfPresent(UInt32.self, forKey: .leaseDuration)
      ?? base_constants.NO_LEASE_DURATION

    // Offline HLS parameters
    licenseType = base_constants.FPSLicenseType.none
    streamId = Array()
    titleId = Array()
    rentalDuration = 0
    playbackDuration = 0

    // Extension
    ext = AssetInfoExtension()

    // HDCP requirement (-1: not required, 0: type 0, 1: type 1)
    hdcpReq = base_constants.FPSHDCPRequirement.hdcpNotRequired
    if values.contains(.hdcpReq) {
      let hdcpType = try values.decode(Int32.self, forKey: .hdcpReq)

      do {
        hdcpReq = try AssetInfo.parseHDCPType(hdcpType)
      } catch let error as FPSStatus {
        fpsLogError(error, "Error parsing HDCP type: \(hdcpType)")
        status = error
      }
    } else {
      Log.debug("Warning! HDCP Type not provided, defaulting to Type 0")
      hdcpReq = base_constants.FPSHDCPRequirement.hdcpType0
    }

    // Offline HLS parameters
    if values.contains(.offlinehls) {
      licenseType = base_constants.FPSLicenseType.offlineHLS
      do {
        try parseOfflineHLS(decoder)
      } catch let error as FPSStatus {
        fpsLogError(error, "parseOfflineHLS failed")
        status = error
      }
    }

    // Custom operations
    do {
      try parseAssetInfoCustom(&self, decoder)
    } catch let error as FPSStatus {
      fpsLogError(error, "parseAssetInfoCustom failed")
      status = error
    }

    if status != FPSStatus.noErr {
      throw status
    }
  }

  public func encode(to encoder: Encoder) throws {
  }
}

/// Return data for a single create-ckc operation (expected to be returned in the output JSON).
public struct FPSResult: Codable {
  public var id: UInt64
  public var status: FPSStatus
  public var hu: [UInt8]
  public var ckc: [UInt8]

  public var sessionId: UInt64  // Parsed from Reference Time Tag TLLV

  // Sync TLLV
  public var isCheckIn: Bool
  public var syncServerChallenge: UInt64
  public var syncFlags: UInt64
  public var syncTitleId: [UInt8]
  public var durationToRentalExpiry: UInt32
  public var recordsDeleted: Int  // number of keys deleted as reported by check-in variant of SyncTLLV
  public var deletedContentIDs: [UInt8]

  // Device Identity Data
  public var deviceIdentitySet: Bool
  public var fpdiVersion: UInt32
  public var deviceClass: UInt32
  public var vendorHash: [UInt8]
  public var productHash: [UInt8]
  public var fpVersionREE: UInt32
  public var fpVersionTEE: UInt32
  public var osVersion: UInt32

  public var vmDeviceInfo: Optional<VMDeviceInfo>

  // Extension
  public var ext: FPSResultExtension  // room for extension values, if not in use template to ()

  // Coding keys, raw values for enum cases must be literals
  enum CodingKeys: String, CodingKey {
    case id
    case status
    case hu
    case ckc
    case icCheckIn = "check-in-server-challenge"
    case syncServerChallenge
    case syncFlags = "check-in-flags"
    case syncTitleId = "check-in-title-id"
    case durationToRentalExpiry = "duration-left"
    case recordsDeleted
    case deletedContentIDs = "check-in-stream-id"
    case deviceIdentitySet
    case fpdiVersion = "fpdi-version"
    case deviceClass = "device-class"
    case vendorHash = "vendor-hash"
    case productHash = "product-hash"
    case fpVersionREE = "fps-ree-version"
    case fpVersionTEE = "fps-tee-version"
    case osVersion = "os-version"
    case hostDeviceClass = "host-device-class"
    case hostOSVersion = "host-os-version"
    case hostVMProtocolVersion = "host-vm-protocol-version"
    case guestDeviceClass = "guest-device-class"
    case guestOSVersion = "guest-os-version"
    case guestVMProtocolVersion = "guest-vm-protocol-version"
  }

  public init() {
    id = 0
    status = FPSStatus.noErr
    hu = Array(repeating: 0, count: base_constants.FPS_V1_HU_SZ)
    ckc = [UInt8]()

    sessionId = 0

    isCheckIn = false
    syncServerChallenge = 0
    syncFlags = 0
    syncTitleId = Array(repeating: 0, count: base_constants.FPS_MAX_TITLE_ID_LENGTH)
    durationToRentalExpiry = 0
    recordsDeleted = 0  // number of keys deleted as reported by check-in variant of SyncTLLV
    deletedContentIDs = [UInt8]()

    deviceIdentitySet = false
    fpdiVersion = 0
    deviceClass = 0
    vendorHash = Array(repeating: 0, count: base_constants.FPS_VENDOR_HASH_SIZE)
    productHash = Array(repeating: 0, count: base_constants.FPS_PRODUCT_HASH_SIZE)
    fpVersionREE = 0
    fpVersionTEE = 0
    osVersion = 0
    vmDeviceInfo = Optional.none


    ext = FPSResultExtension()
  }

  public init(from decoder: any Decoder) throws {
    self.init()
  }

  public func encode(to encoder: Encoder) throws {
    var json = encoder.container(keyedBy: CodingKeys.self)

    var huHex: String = ""
    for byte in hu {
      huHex += String(format: "%02X", byte)
    }
    try json.encode(id, forKey: .id)
    try json.encode(status.rawValue, forKey: .status)

    if status == FPSStatus.noErr {
      try json.encode(huHex, forKey: .hu)

      if isCheckIn {
        let sync_str = String(syncServerChallenge)
        try json.encode(sync_str, forKey: .syncServerChallenge)
      }

      if syncFlags != 0 {
        try json.encode(String(format: "%X", syncFlags), forKey: .syncFlags)
        try json.encode(String(durationToRentalExpiry), forKey: .durationToRentalExpiry)

        var syncTitleIdHex = ""
        for byte in syncTitleId {
          syncTitleIdHex += String(format: "%02X", byte)
        }
        try json.encode(syncTitleIdHex, forKey: .syncTitleId)

        if recordsDeleted > 0 && deletedContentIDs.count != 0 {
          var checkInContentIds: [String] = []
          for i in 0...recordsDeleted {
            let index = i * base_constants.FPS_OFFLINE_CONTENTID_LENGTH
            var hexContentId = ""
            for byte in deletedContentIDs[
              index...(index + base_constants.FPS_OFFLINE_CONTENTID_LENGTH)]
            {
              hexContentId += String(format: "%02X", byte)
            }
            checkInContentIds.append(hexContentId)
          }
          try json.encode(checkInContentIds, forKey: .deletedContentIDs)
        }
      }

      if deviceIdentitySet {
        try json.encode(fpdiVersion, forKey: .fpdiVersion)
        try json.encode(deviceClass, forKey: .deviceClass)
        try json.encode(vendorHash.map { String(format: "%02X", $0) }.joined(), forKey: .vendorHash)
        try json.encode(productHash.map { String(format: "%02X", $0) }.joined(), forKey: .productHash)
        try json.encode(String(format: "%08X", fpVersionREE), forKey: .fpVersionREE)
        try json.encode(String(format: "%08X", fpVersionTEE), forKey: .fpVersionTEE)
        try json.encode(String(format: "%08X", osVersion), forKey: .osVersion)
      }

      if let vmDeviceInfo {
          // Print Host VM Information
          try json.encode(vmDeviceInfo.hostDeviceClass.description, forKey: .hostDeviceClass)
          try json.encode(String(format: "%08X", vmDeviceInfo.hostOSVersion), forKey: .hostOSVersion)
          try json.encode(vmDeviceInfo.hostDeviceClass.description, forKey: .hostDeviceClass)
          try json.encode(vmDeviceInfo.hostVMProtocolVersion, forKey: .hostVMProtocolVersion)

          // Print Guest VM Information
          try json.encode(vmDeviceInfo.guestDeviceClass.description, forKey: .guestDeviceClass)
          try json.encode(String(format: "%08X", vmDeviceInfo.guestOSVersion), forKey: .guestOSVersion)
          try json.encode(vmDeviceInfo.guestDeviceClass.description, forKey: .guestDeviceClass)
          try json.encode(vmDeviceInfo.guestVMProtocolVersion, forKey: .guestVMProtocolVersion)
      }

      try serializeCKCNodeCustom(encoder: encoder)

      if !isCheckIn && ckc.count > 0 {
        let ckcData = Data(bytes: ckc, count: ckc.count)
        let base64Ckc = ckcData.base64EncodedString()
        try json.encode(base64Ckc, forKey: .ckc)
      }
    }
  }
}

/// Return data for all create-ckc operations in a request.
///
/// Contains a vector of FPSResult. This is necessary if multiple requests are sent at once (much like FPSOperations).
public struct FPSResults: Codable {
  public var resultPtr: [FPSResult]

  // Extension
  public var ext: FPSResultsExtension

  enum CodingKeys: String, CodingKey {
    case fpsResults = "fairplay-streaming-response"
    case resultPtr = "create-ckc"
  }

  public init() {
    resultPtr = [FPSResult]()
    ext = FPSResultsExtension()
  }

  public init(from decoder: any Decoder) throws {
    self.init()
  }

  public func encode(to encoder: any Encoder) throws {
    var json = encoder.container(keyedBy: CodingKeys.self)
    var response_container = json.nestedContainer(keyedBy: CodingKeys.self, forKey: .fpsResults)

    try response_container.encode(resultPtr, forKey: .resultPtr)

    try serializeResultsCustom(encoder: encoder)
  }
}

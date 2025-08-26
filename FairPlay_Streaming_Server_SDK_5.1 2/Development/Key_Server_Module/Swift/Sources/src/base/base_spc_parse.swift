//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import Foundation

extension Base {
  /// Parses, decrypts, and validates received SPC.
  public static func parseSPC(_ fpsOperation: FPSOperation, _ serverCtx: inout FPSServerCtx) throws {

    // Parse SPC container
    try parseSPCContainer(fpsOperation.spc, &serverCtx.spcContainer)

    // Open SPC Data
    try decryptSPCData(fpsOperation.spc, &serverCtx.spcContainer)

    // Parse SPC data
    try parseSPCData(&serverCtx.spcContainer)

    // Create set of flags of client supported features (lease, rental, persistence, etc)
    try checkSupportedFeatures(&serverCtx)
  }

  /// Parses fields in SPC other than the encrypted payload
  public static func parseSPCContainer(_ spc: [UInt8], _ spcContainer: inout FPSServerSPCContainer)
    throws
  {

    var offset = 0

    // 4B Version
    spcContainer.version = try readBigEndianU32(spc, offset)
    offset += MemoryLayout<UInt32>.size

    try requireAction(
      (spcContainer.version == base_constants.SPCVersion.v1.rawValue)
        || (spcContainer.version == base_constants.SPCVersion.v2.rawValue),
      { throw FPSStatus.spcVersionErr }
    )

    // 4B Reserved
    spcContainer.reservedValue = try readBigEndianU32(spc, offset)
    offset += MemoryLayout<UInt32>.size

    // 16B SPC Data IV
    spcContainer.aesKeyIV = try readBytes(spc, offset, base_constants.AES128_IV_SZ)
    offset += base_constants.AES128_IV_SZ

    // AES Wrapped Key (size depends on version)
    if spcContainer.version == base_constants.SPCVersion.v2.rawValue {
      spcContainer.aesWrappedKeySize = base_constants.FPS_V2_WRAPPED_KEY_SZ
    } else {
      spcContainer.aesWrappedKeySize = base_constants.FPS_V1_WRAPPED_KEY_SZ
    }

    spcContainer.aesWrappedKey = try readBytes(spc, offset, spcContainer.aesWrappedKeySize)
    offset += spcContainer.aesWrappedKeySize

    // 20B Certificate Hash
    // This is where we should check the certificateHash and fail if it is not what is expected.
    // Also, this is where the private RSA key would be selected if more than one was provisioned.
    spcContainer.certificateHash = try readBytes(spc, offset, base_constants.FPS_V1_HASH_SZ)
    offset += base_constants.FPS_V1_HASH_SZ

    // 4B SPC Size
    spcContainer.spcDataSize = Int(try readBigEndianU32(spc, offset))
    offset += MemoryLayout<UInt32>.size

    spcContainer.spcDataOffset = offset

    try requireAction(
      (spcContainer.spcDataSize + spcContainer.spcDataOffset) >= spcContainer.spcDataOffset,
      { throw FPSStatus.paramErr }
    )
    try requireAction(
      ((spcContainer.spcDataSize + spcContainer.spcDataOffset) <= spc.count),
      { throw FPSStatus.paramErr }
    )
  }

  /// Decrypts the encrypted SPC payload
  ///
  /// Using the provisioned RSA private key, decrypt the RSA public encrypted AES key.
  /// This AES key is the one used to encrypt the SPC data (aka SPCK, Fig 2-2 of specification).
  public static func decryptSPCData(_ spc: [UInt8], _ spcContainer: inout FPSServerSPCContainer) throws {

    try requireAction(!spc.isEmpty, { throw FPSStatus.paramErr })

    // Decrypt the encrypted AES key using the RSA private key
    var localKey: [UInt8] = [UInt8]()
    try decryptKeyRSACustom(
      &spcContainer,
      &localKey
    )
    localKey = Array(localKey.prefix(base_constants.AES128_KEY_SZ))

    // Decrypt the encrypted SPC payload using the decrypted AES key
    try encryptDecryptWithAES(
      Array(spc[spcContainer.spcDataOffset...]),
      localKey,
      spcContainer.aesKeyIV,
      base_constants.AESEncryptionMode.aesDecrypt,
      base_constants.AESEncryptionCipher.aesCBC,
      &spcContainer.spcDecryptedData
    )

    // Custom handling (if needed)
    try decryptSPCDataCustom(spc, &spcContainer)
  }

  /// Parses all TLLVs inside the SPC data.
  public static func parseSPCData(_ spcContainer: inout FPSServerSPCContainer) throws {

    // Initialization of playInfo
    spcContainer.spcData.playInfo.date = 0
    spcContainer.spcData.playInfo.playbackState = 0
    spcContainer.spcData.playInfo.playbackId = 0

    // Parse each TLLV
    while spcContainer.spcData.spcDataParser.currentOffset < spcContainer.spcDataSize {
      var tllv: FPSServerTLLV = FPSServerTLLV()

      // Read in the next TLLV (this moves the parser to the next TLLV on success)
      try readNextTLLV(
        spcContainer.spcDecryptedData,
        spcContainer.spcDataSize,
        &spcContainer.spcData.spcDataParser.currentOffset,
        &tllv
      )

      do {
        try parseTLLV(tllv, &spcContainer)
      } catch {
        Log.debug("Error \(error) while parsing TLLV tag 0x\(String(format:"%x", tllv.tag))")
        throw returnErrorStatus(error as! FPSStatus)
      }

      // Save the TLLV for later because we may need to return it.
      spcContainer.spcData.spcDataParser.TLLVs.append(tllv)
    }

    // Now that we have all the TLLVs, extract the ones specified by the return request tag
    try extractReturnTags(&spcContainer.spcData)

    // Make sure we received all required TLLVs
    try validateTLLVs(&spcContainer)
  }

  /// Reads the next TLLV from the SPC into `tllv`.
  public static func readNextTLLV(
    _ dataToParse: [UInt8],
    _ dataToParseSize: Int,
    _ currentOffset: inout Int,
    _ tllv: inout FPSServerTLLV
  ) throws {
    try requireAction(!dataToParse.isEmpty, { throw FPSStatus.paramErr })
    try requireAction(
      dataToParseSize
        >= (base_constants.FPS_TLLV_TAG_SZ + base_constants.FPS_TLLV_TOTAL_LENGTH_SZ
          + base_constants.FPS_TLLV_VALUE_LENGTH_SZ),
      { throw FPSStatus.paramErr }
    )

    // 8B Tag value
    let tag = try readBigEndianU64(dataToParse, currentOffset)
    currentOffset += MemoryLayout<UInt64>.size

    // 4B Total Size (value length + padding length)
    let totalSize = try readBigEndianU32(dataToParse, currentOffset)
    currentOffset += MemoryLayout<UInt32>.size

    // Verify total size
    try requireAction(
      (currentOffset + Int(totalSize) + base_constants.FPS_TLLV_VALUE_LENGTH_SZ)
        >= currentOffset,
      { throw FPSStatus.paramErr }
    )
    try requireAction(
      (currentOffset + Int(totalSize) + base_constants.FPS_TLLV_VALUE_LENGTH_SZ)
        <= dataToParseSize,
      { throw FPSStatus.paramErr }
    )

    // Read the size of the value (L2)
    let valueSize = try readBigEndianU32(dataToParse, currentOffset)
    currentOffset += MemoryLayout<UInt32>.size

    // Verify value size
    try requireAction(valueSize <= totalSize, { throw FPSStatus.paramErr })
    try requireAction(
      (currentOffset + Int(valueSize)) >= currentOffset,
      { throw FPSStatus.paramErr }
    )
    try requireAction(
      (currentOffset + Int(valueSize)) <= dataToParseSize,
      { throw FPSStatus.paramErr }
    )

    tllv.tag = tag

    // Copy the value into the returned tllv
    if valueSize > 0 {
      tllv.value =
        Array(
          dataToParse[currentOffset...currentOffset + Int(valueSize) - 1])
    }

    // Set the offset to the next TLLV
    currentOffset += Int(totalSize)
  }

  /// Sets `serverCtx.spcContainer.spcData.clientFeatures` flags based on SPC data
  ///
  /// This is done after parsing of the Capabilities TLLV so that any custom
  /// handling knows what the client capabilities are.
  public static func checkSupportedFeatures(_ serverCtx: inout FPSServerCtx) throws {
    // Defaults
    serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLV = false
    serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLVV2 = false
    serverCtx.spcContainer.spcData.clientFeatures.supportsSecurityLevelBaseline = false
    serverCtx.spcContainer.spcData.clientFeatures.supportsSecurityLevelMain = false
    serverCtx.spcContainer.spcData.clientFeatures.supportsHDCPTypeOne = false
    serverCtx.spcContainer.spcData.clientFeatures.supportsDualExpiry = false
    serverCtx.spcContainer.spcData.clientFeatures.supportsCheckIn = false

    let capabilitiesLVbits = try readBigEndianU64(
      serverCtx.spcContainer.spcData.clientCapabilities, 8)

    if (capabilitiesLVbits & UInt64(base_constants.FPS_CAPABILITY_OFFLINE_KEY_V2_SUPPORTED)) != 0 {
      serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLVV2 = true
      serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLV = true
    }
    if (capabilitiesLVbits & UInt64(base_constants.FPS_CAPABILITY_SECURITY_LEVEL_BASELINE_SUPPORTED)) != 0 {
      serverCtx.spcContainer.spcData.clientFeatures.supportsSecurityLevelBaseline = true
    }
    if (capabilitiesLVbits & UInt64(base_constants.FPS_CAPABILITY_SECURITY_LEVEL_MAIN_SUPPORTED)) != 0 {
      serverCtx.spcContainer.spcData.clientFeatures.supportsSecurityLevelMain = true
    }
    if (capabilitiesLVbits & UInt64(base_constants.FPS_CAPABILITY_HDCP_TYPE1_ENFORCEMENT_SUPPORTED))
      != 0
    {
      serverCtx.spcContainer.spcData.clientFeatures.supportsHDCPTypeOne = true
    }
    if (capabilitiesLVbits & UInt64(base_constants.FPS_CAPABILITY_OFFLINE_KEY_SUPPORTED)) != 0 {
      serverCtx.spcContainer.spcData.clientFeatures.supportsDualExpiry = true
    }
    if (capabilitiesLVbits & UInt64(base_constants.FPS_CAPABILITY_CHECK_IN_SUPPORTED)) != 0 {
      serverCtx.spcContainer.spcData.clientFeatures.supportsCheckIn = true
    }

    // Custom handling (if needed)
    try checkSupportedFeaturesCustom(&serverCtx)

  }

}

//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

extension Base {
  /// Parses a single TLLV received in the SPC from client.
  public static func parseTLLV(_ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer) throws {
    // Check for duplicate tag value
    if spcContainer
      .spcData
      .spcDataParser
      .parsedTagValues
      .contains(tllv.tag)
    {
      throw returnErrorStatus(FPSStatus.dupTagErr)
    }
    spcContainer.spcData.spcDataParser.parsedTagValues.append(tllv.tag)

    switch tllv.tag {
    case base_constants.FPSTLLVTagValue.sessionKeyR1Tag.rawValue:
      try parseTagSessionKeyR1(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.sessionKeyR1IntegrityTag.rawValue:
      try parseTagSessionKeyR1Integrity(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.antiReplayTag.rawValue:
      try parseTagAntiReplay(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.r2tag.rawValue:
      try parseTagR2(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.returnRequestTag.rawValue:
      try parseTagReturnRequest(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.assetIDTag.rawValue:
      try parseTagAssetID(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.transactionIDTag.rawValue:
      try parseTagTransactionID(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.protocolVersionsSupportedTag.rawValue:
      try parseTagProtocolVersionsSupported(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.protocolVersionUsedTag.rawValue:
      try parseTagProtocolVersionUsed(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.streamingIndicatorTag.rawValue:
      try parseTagServerStreamingIndicator(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.mediaPlaybackStateTag.rawValue:
      try parseTagMediaPlaybackState(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.capabilitiesTag.rawValue:
      try parseTagClientCapabilities(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.deviceInfoTag.rawValue:
      try parseTagDeviceInfo(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.deviceIdentityTag.rawValue:
      try parseTagDeviceIdentity(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.offlineSyncTag.rawValue:
      try parseTagOfflineSync(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.supportedKeyFormatTag.rawValue:
      try parseTagSupportedKeyFormat(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.securityLevelReportTag.rawValue:
      try parseTagSecurityLevelReport(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.kdlVersionReportTag.rawValue:
      try parseTagKDLVersionReport(tllv, &spcContainer)

    case base_constants.FPSTLLVTagValue.vmDeviceInfoTag.rawValue:
      try parseTagVMDeviceInformation(tllv, &spcContainer)

    default:
      try parseTLLVCustom(tllv, &spcContainer)
    }
  }
}

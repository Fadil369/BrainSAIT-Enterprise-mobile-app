//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension SDKExtension {
  public static func populateTagSecurityLevel(_ serverCtx: inout FPSServerCtx) throws {
    var securityLevel: [UInt8] = []

    // 4B Version
    securityLevel.appendBigEndianU32(
      UInt32(base_constants.FPS_TLLV_SECURITY_LEVEL_TLLV_VERSION))

    // 4B Reserved
    securityLevel.appendBigEndianU32(0)

    // 8B Required Security Level
    securityLevel.appendBigEndianU64(serverCtx.ckcContainer.ckcData.ext.requiredSecurityLevel.rawValue)

    try Base.serializeTLLV(
      base_constants.FPSTLLVTagValue.securityLevelTag.rawValue,
      securityLevel,
      &serverCtx.ckcContainer
    )
  }
}

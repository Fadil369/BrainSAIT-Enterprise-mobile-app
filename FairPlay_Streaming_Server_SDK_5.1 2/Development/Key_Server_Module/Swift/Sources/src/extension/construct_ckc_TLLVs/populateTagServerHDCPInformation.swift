//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension SDKExtension {
  public static func populateTagServerHDCPInformation(_ serverCtx: inout FPSServerCtx) throws {
    var hdcpReq: [UInt8] = []

    // 8B HDCP Requirement
    hdcpReq.appendBigEndianU64(serverCtx.ckcContainer.ckcData.hdcpTypeTLLVValue.rawValue)

    // 8B Random Values
    hdcpReq.appendRandomBytes(8)

    try Base.serializeTLLV(
      base_constants.FPSTLLVTagValue.hdcpInformationTag.rawValue,
      hdcpReq,
      &serverCtx.ckcContainer
    )
  }
}
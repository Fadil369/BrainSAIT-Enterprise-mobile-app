//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagProtocolVersionUsed(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(tllv.value.count == MemoryLayout<UInt32>.size, { throw FPSStatus.parserErr })

    // 4B Version Used
    spcContainer.spcData.versionUsed = try readBigEndianU32(tllv.value, 0)

  }
}

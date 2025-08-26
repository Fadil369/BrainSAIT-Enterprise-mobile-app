//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagAntiReplay(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(
      tllv.value.count == base_constants.AES128_KEY_SZ, { throw FPSStatus.parserErr })

    spcContainer.spcData.antiReplay = try readBytes(tllv.value, 0, base_constants.AES128_KEY_SZ)
  }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagSessionKeyR1(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {
    // Check that size matches expected size exactly
    try requireAction(
      tllv.value.count == base_constants.FPS_V1_SKR1_SZ, { throw FPSStatus.parserErr })

    // Entire TLLV value is the SK R1 value
    spcContainer.spcData.skR1 = try readBytes(tllv.value, 0, base_constants.FPS_V1_SKR1_SZ)

  }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagR2(_ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer)
    throws
  {

    // Check that size matches expected size exactly
    try requireAction(
      tllv.value.count == base_constants.FPS_V1_R2_SZ, { throw FPSStatus.parserErr })

    // Entire TLLV value is the R2 value
    spcContainer.spcData.r2 = try readBytes(tllv.value, 0, base_constants.FPS_V1_R2_SZ)

  }
}

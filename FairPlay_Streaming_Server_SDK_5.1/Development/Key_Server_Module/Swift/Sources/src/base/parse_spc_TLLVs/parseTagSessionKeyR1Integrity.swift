//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagSessionKeyR1Integrity(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(
      tllv.value.count == base_constants.FPS_V1_SKR1_INTEGRITY_SZ, { throw FPSStatus.parserErr })

    // Entire TLLV value is the SK R1 Integrity value
    spcContainer.spcData.skR1IntegrityTag = try readBytes(
      tllv.value, 0, base_constants.FPS_V1_SKR1_INTEGRITY_SZ)

  }
}

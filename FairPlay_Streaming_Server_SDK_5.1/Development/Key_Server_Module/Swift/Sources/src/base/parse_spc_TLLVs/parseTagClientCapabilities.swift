//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagClientCapabilities(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(
      tllv.value.count == base_constants.FPS_CAPABILITIES_FLAGS_LENGTH, { throw FPSStatus.paramErr }
    )

    // Entire TLLV value is the client capabilities flags
    spcContainer.spcData.clientCapabilities = tllv.value

    Log.debug(
      "Client Capabilities: 0x\(spcContainer.spcData.clientCapabilities.map { String(format: "%02x", $0) }.joined())")
  }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagProtocolVersionsSupported(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Size must be a multiple of the version information
    try requireAction(
      tllv.value.count % MemoryLayout<UInt32>.size == 0, { throw FPSStatus.parserErr })

    var offset = 0

    // Loop through the supported version tag and store them
    while offset < tllv.value.count {
      // 4B Supported Version
      let version = try readBigEndianU32(tllv.value, offset)
      offset += MemoryLayout<UInt32>.size

      // Save into versionsSupported list
      spcContainer.spcData.versionsSupported.append(version)

      try requireAction(
        spcContainer.spcData.versionsSupported.count < base_constants.FPS_MAX_NUM_CRYPTO_VERSIONS,
        { throw FPSStatus.paramErr }
      )
    }

  }
}

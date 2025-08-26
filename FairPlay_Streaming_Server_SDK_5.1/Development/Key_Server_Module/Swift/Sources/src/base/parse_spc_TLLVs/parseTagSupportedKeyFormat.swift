//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagSupportedKeyFormat(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // 4B Version
    let tllvVersion = try readBigEndianU32(tllv.value, 0)

    // Ignore the TLLV when version is not set to 1
    if tllvVersion == 1 {

      // 4B Reserved
      let _ = try readBigEndianU32(tllv.value, 4)

      // 4B Number of Keys
      let numberOfKeys = try readBigEndianU32(tllv.value, 8)

      if numberOfKeys > base_constants.FPS_MAX_KEY_FORMATS {
        fpsLogError(
          FPSStatus.paramErr,
          "\(numberOfKeys) exceeds maximum number of supported key formats \(base_constants.FPS_MAX_KEY_FORMATS)"
        )
        throw returnErrorStatus(FPSStatus.paramErr)
      }

      var offset = 12

      spcContainer.spcData.numberOfSupportedKeyFormats = numberOfKeys

      for i in 0...numberOfKeys - 1 {
        spcContainer.spcData.supportedKeyFormats[Int(i)] = try readBigEndianU64(tllv.value, offset)
        offset += MemoryLayout<UInt64>.size

        // Log.debug("Client Supported Key Format \(i): 0x\(String(format:"%llx", spcContainer.spcData.supportedKeyFormats[Int(i)]))")
      }
    }
  }
}

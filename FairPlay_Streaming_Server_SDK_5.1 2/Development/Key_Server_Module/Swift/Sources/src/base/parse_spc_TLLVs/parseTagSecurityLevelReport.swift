//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagSecurityLevelReport(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    spcContainer.spcData.isSecurityLevelTLLVValid = false  // default

    if tllv.value.count == base_constants.FPS_ENCRYPTED_SECURITY_LEVEL_REPORT_TLLV_SIZE {
      return  // This is encrypted security level TLLV. Just ignore it for now
    }

    // 4B Version
    let tllvVersion = try readBigEndianU32(tllv.value, 0)

    // Ignore the TLLV when version is not set to 1
    if tllvVersion == 1 {

      // 4B Reserved
      let reserved = try readBigEndianU32(tllv.value, 4)

      if reserved != 0 {
        fpsLogError(
          FPSStatus.paramErr,
          "Invalid reserved field in Security Level Report TLLV"
        )
        throw returnErrorStatus(FPSStatus.paramErr)
      }

      // 8B Security Level
      spcContainer.spcData.supportedSecurityLevel = try readBigEndianU64(tllv.value, 8)

      // 4B Kext Deny List Version
      // Do not overwrite if KDL verison was delivered in it's own TLLV
      if spcContainer.spcData.clientKextDenyListVersion == 0 {
        spcContainer.spcData.clientKextDenyListVersion = try readBigEndianU32(tllv.value, 16)
      }

      spcContainer.spcData.isSecurityLevelTLLVValid = true

      Log.debug("Client Security Level: 0x\(String(format:"%llx", spcContainer.spcData.supportedSecurityLevel))")
    }
  }
}

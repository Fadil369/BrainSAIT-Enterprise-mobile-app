//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

extension SDKExtension {
  /// Verifies that license is allowed to be created based on business rules
  public static func checkBusinessRules(
    _ operation: FPSOperation,
    _ serverCtx: inout FPSServerCtx
  ) throws {

    //
    // NOTE: These are just suggested default rules. Please feel free to edit as desired.
    //

    // Verify Kext Deny List version if client reported one
    if serverCtx.spcContainer.spcData.clientKextDenyListVersion > 0
      && serverCtx.spcContainer.spcData.clientKextDenyListVersion < base_constants.MIN_KDL_VERSION
    {
      fpsLogError(
        FPSStatus.clientSecurityLevelErr,
        "KDL version supported by the client (\(serverCtx.spcContainer.spcData.clientKextDenyListVersion)) does not meet minimum required (\(base_constants.MIN_KDL_VERSION))"
      )
      throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
    }

    // Lease cannot be used together with Offline HLS
    if (operation.assetInfo.leaseDuration != base_constants.NO_LEASE_DURATION)
      && (operation.assetInfo.leaseDuration != 0)
      && (operation.assetInfo.licenseType == base_constants.FPSLicenseType.offlineHLS)
    {
      fpsLogError(FPSStatus.paramErr, "lease is not supported for offline HLS")
      throw returnErrorStatus(FPSStatus.paramErr)
    }

    // Verify that if check-in is requested then SPC has syncFlags
    if operation.isCheckIn && (serverCtx.spcContainer.spcData.syncFlags == 0) {
      fpsLogError(FPSStatus.paramErr, "check-in requested but SPC is missing SyncTLLV")
      throw returnErrorStatus(FPSStatus.paramErr)
    }

    // Device security level checks based on content type
    switch operation.assetInfo.ext.contentType {
    case extension_constants.ContentType.uhd:
      // UHD content requires security level Main
      serverCtx.ckcContainer.ckcData.ext.requiredSecurityLevel = extension_constants.FPSSecurityLevel.main

      if serverCtx.spcContainer.spcData.isSecurityLevelTLLVValid {
        if serverCtx.spcContainer.spcData.supportedSecurityLevel < extension_constants.FPSSecurityLevel.main.rawValue {
          fpsLogError(
            FPSStatus.clientSecurityLevelErr,
            String(
              format: "UHD content requires security level Main. Client supports 0x%016llx",
              serverCtx.spcContainer.spcData.supportedSecurityLevel)
          )
          throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
        }
      } else if serverCtx.spcContainer.spcData.clientFeatures.supportsSecurityLevelBaseline
        && !serverCtx.spcContainer.spcData.clientFeatures.supportsSecurityLevelMain
      {
        // Note: older devices do not send any supported security fields, so only fail here if
        // supportsSecurityLevelBaseline is set but supportsSecurityLevelMain is not
        fpsLogError(
          FPSStatus.clientSecurityLevelErr,
          "UHD content requires security level Main. Client supports Baseline"
        )
        throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
      }

      // UHD content requires HDCP type 1
      if operation.assetInfo.hdcpReq != base_constants.FPSHDCPRequirement.hdcpType1 {
        fpsLogError(FPSStatus.paramErr, "UHD content requires HDCP type 1")
        throw returnErrorStatus(FPSStatus.paramErr)
      }

    case extension_constants.ContentType.hd:
      // HD content requires security level Baseline or higher
      serverCtx.ckcContainer.ckcData.ext.requiredSecurityLevel = extension_constants.FPSSecurityLevel.baseline

      if serverCtx.spcContainer.spcData.isSecurityLevelTLLVValid {
        if serverCtx.spcContainer.spcData.supportedSecurityLevel
          < extension_constants.FPSSecurityLevel.baseline.rawValue
        {
          fpsLogError(
            FPSStatus.clientSecurityLevelErr,
            String(
              format: "HD content requires security level Baseline. Client supports 0x%016llx",
              serverCtx.spcContainer.spcData.supportedSecurityLevel)
          )
          throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
        }
      }

      // HD content requires HDCP
      if operation.assetInfo.hdcpReq == base_constants.FPSHDCPRequirement.hdcpNotRequired {
        fpsLogError(FPSStatus.paramErr, "HD content requires HDCP")
        throw returnErrorStatus(FPSStatus.paramErr)
      }

    case extension_constants.ContentType.sd:
      // SD content requires security level Baseline or higher
      serverCtx.ckcContainer.ckcData.ext.requiredSecurityLevel = extension_constants.FPSSecurityLevel.baseline

      if serverCtx.spcContainer.spcData.isSecurityLevelTLLVValid {
        if serverCtx.spcContainer.spcData.supportedSecurityLevel
          < extension_constants.FPSSecurityLevel.baseline.rawValue
        {
          fpsLogError(
            FPSStatus.clientSecurityLevelErr,
            String(
              format: "SD content requires security level Baseline. Client supports 0x%016llx",
              serverCtx.spcContainer.spcData.supportedSecurityLevel)
          )
          throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
        }
      }

    case extension_constants.ContentType.audio:
      // No special requirements for audio content type
      serverCtx.ckcContainer.ckcData.ext.requiredSecurityLevel = extension_constants.FPSSecurityLevel.audio

    case extension_constants.ContentType.unknown:
      fpsLogError(FPSStatus.noErr, "Warning! unknown content type, using security level main")
      serverCtx.ckcContainer.ckcData.ext.requiredSecurityLevel = extension_constants.FPSSecurityLevel.main
    }

    // Verify that if HDCP Type 1 is required then client supports it
    if operation.assetInfo.hdcpReq == base_constants.FPSHDCPRequirement.hdcpType1
      && !serverCtx.spcContainer.spcData.clientFeatures.supportsHDCPTypeOne
    {
      fpsLogError(FPSStatus.clientSecurityLevelErr, "HDCP type 1 enforcement requested but not supported by client")
      throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
    }

    //To stop a license from being created for a virtual machine, uncomment this if statement
    /*if let _ = serverCtx.spcContainer.spcData.vmDeviceInfo {
        fpsLogError(FPSStatus.clientSecurityLevelErr, "Content cannot be played on a virtual machine")
        throw returnErrorStatus(FPSStatus.clientSecurityLevelErr)
    }*/

  }
}

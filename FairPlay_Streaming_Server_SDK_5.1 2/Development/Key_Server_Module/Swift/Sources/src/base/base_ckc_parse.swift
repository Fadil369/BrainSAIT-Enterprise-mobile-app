//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import Foundation

extension Base {
  /// Fills in `fpsResult` with values that will be returned in the license response
  public static func createResults(_ fpsOperation: FPSOperation, _ fpsResult: inout FPSResult) throws {
    var keyTypeRequested = base_constants.FPSKeyType.none.rawValue

    // Set the result id
    fpsResult.id = fpsOperation.id

    // Custom handling (if needed)
    try createResultsCustom(fpsOperation, &keyTypeRequested)

    // Generate CKC and other result fields
    try genCKCWithCKAndIV(fpsOperation, keyTypeRequested, &fpsResult)
  }

  /// Generates CKC and other result fields
  public static func genCKCWithCKAndIV(
    _ fpsOperation: FPSOperation, _ keyTypeRequested: UInt32, _ fpsResult: inout FPSResult
  ) throws {

    let localVersion = try readBigEndianU32(fpsOperation.spc, 0)

    switch localVersion {
    case base_constants.SPCVersion.v1.rawValue, base_constants.SPCVersion.v2.rawValue:
      var serverCtx: FPSServerCtx = FPSServerCtx()

      // Parse SPC
      try parseSPC(fpsOperation, &serverCtx)

      //Optional: if querying a database for more information outside of JSON, that is
      //done here
      try queryDatabaseCustom(fpsOperation, &serverCtx)

      // Extension specific SPC implementation/checks (if required)
      try validateSPCCustom(fpsOperation, &serverCtx)

      // Fill fpsResult structure
      try populateServerCtxResult(&serverCtx, fpsOperation, &fpsResult)

      // Create the encrypted content key payload
      // This also gets the client HU from the request
      try createContentKeyPayloadCustom(&serverCtx, keyTypeRequested, &fpsResult)

      if serverCtx.ckcContainer.returnCKC {
        // Generate the CKC
        try generateCKC(&serverCtx)

        fpsResult.ckc = serverCtx.ckcContainer.ckc
      }

      try finalizeResultsCustom(serverCtx, &fpsResult)

    default:
      throw returnErrorStatus(FPSStatus.spcVersionErr)
    }
  }

  /// Populates `serverCtx.ckcContainer` and `fpsResult` structure with fields that will be returned to the caller
  public static func populateServerCtxResult(
    _ serverCtx: inout FPSServerCtx,
    _ operation: FPSOperation,
    _ result: inout FPSResult
  ) throws {
    // Copy some SPC information to the results structure

    // Report movie ID (session ID)
    result.sessionId = serverCtx.spcContainer.spcData.playInfo.playbackId

    // Set the key and IV from the input json
    serverCtx.ckcContainer.ckcData.ck = Array(operation.assetInfo.key[0..<base_constants.AES128_KEY_SZ])
    serverCtx.ckcContainer.ckcData.iv = Array(operation.assetInfo.iv[0..<base_constants.AES128_IV_SZ])

    // Offline HLS or Online HLS rental
    if operation.assetInfo.licenseType == base_constants.FPSLicenseType.offlineHLS {
      if !operation.assetInfo.streamId.isEmpty {
        serverCtx.streamId = operation.assetInfo.streamId
      }

      if !operation.assetInfo.titleId.isEmpty {
        serverCtx.titleId = operation.assetInfo.titleId
        serverCtx.titleId += [UInt8](
          repeating: 0, count: (base_constants.FPS_MAX_TITLE_ID_LENGTH - serverCtx.titleId.count))
      }

      serverCtx.ckcContainer.ckcData.keyDuration.rentalDuration = operation.assetInfo.rentalDuration
      serverCtx.ckcContainer.ckcData.keyDuration.playbackDuration = operation.assetInfo.playbackDuration
      if (operation.assetInfo.rentalDuration != 0) || (operation.assetInfo.playbackDuration != 0) {
        serverCtx.ckcContainer.ckcData.keyDuration.keyType =
          base_constants.FPSKeyDurationType.persistenceAndDuration.rawValue
      } else {
        serverCtx.ckcContainer.ckcData.keyDuration.keyType =
          base_constants.FPSKeyDurationType.persistence.rawValue
      }
    }

    // Is lease requested?
    if operation.assetInfo.leaseDuration != base_constants.NO_LEASE_DURATION {
      serverCtx.ckcContainer.ckcData.keyDuration.leaseDuration = operation.assetInfo.leaseDuration
      serverCtx.ckcContainer.ckcData.keyDuration.rentalDuration = operation.assetInfo.rentalDuration
      serverCtx.ckcContainer.ckcData.keyDuration.playbackDuration = operation.assetInfo.playbackDuration
      serverCtx.ckcContainer.ckcData.keyDuration.keyType =
        base_constants.FPSKeyDurationType.lease.rawValue
    }

    // Required HDCP type for the content
    serverCtx.ckcContainer.ckcData.hdcpTypeTLLVValue = operation.assetInfo.hdcpReq

    // Check if device identity is set and copy information to result
    result.deviceIdentitySet = serverCtx.spcContainer.spcData.deviceIdentity.isDeviceIdentitySet
    if serverCtx.spcContainer.spcData.deviceIdentity.isDeviceIdentitySet {
      result.fpdiVersion = serverCtx.spcContainer.spcData.deviceIdentity.fpdiVersion
      result.deviceClass = serverCtx.spcContainer.spcData.deviceIdentity.deviceClass
      result.vendorHash = serverCtx.spcContainer.spcData.deviceIdentity.vendorHash
      result.productHash = serverCtx.spcContainer.spcData.deviceIdentity.productHash
      result.fpVersionREE = serverCtx.spcContainer.spcData.deviceIdentity.fpVersionREE
      result.fpVersionTEE = serverCtx.spcContainer.spcData.deviceIdentity.fpVersionTEE
      result.osVersion = serverCtx.spcContainer.spcData.deviceIdentity.osVersion
    }

    // Report if the request came from a virtual machine
    if let vmDeviceInfo = serverCtx.spcContainer.spcData.vmDeviceInfo {
        result.vmDeviceInfo = Optional.some(vmDeviceInfo)
    }
    else {
        result.vmDeviceInfo = Optional.none
    }

    try populateResultsCustom(&serverCtx, operation, &result)

    if operation.isCheckIn {
      result.isCheckIn = true
      result.syncServerChallenge = serverCtx.spcContainer.spcData.syncServerChallenge
      result.syncFlags = serverCtx.spcContainer.spcData.syncFlags
      // Make sure to send back the title ID if present
      if (serverCtx.spcContainer.spcData.syncFlags
        & base_constants.KD_SYNC_SPC_FLAG_TITLEID_VALID) != 0
      {
        result.syncTitleId = Array(
          serverCtx.spcContainer.spcData.syncTitleId[0..<base_constants.FPS_MAX_TITLE_ID_LENGTH])
        serverCtx.titleId = Array(
          serverCtx.spcContainer.spcData.syncTitleId[0..<serverCtx.titleId.count])
      }
      result.durationToRentalExpiry = serverCtx.spcContainer.spcData.durationToRentalExpiry
      result.recordsDeleted = serverCtx.spcContainer.spcData.recordsDeleted
      if result.recordsDeleted > 0 {
        result.deletedContentIDs = Array(
          serverCtx.spcContainer.spcData.deletedContentIDs[
            0..<(result.recordsDeleted * base_constants.FPS_OFFLINE_CONTENTID_LENGTH)])
      }
    } else {
      result.isCheckIn = false
    }

  }
}

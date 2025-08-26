//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

extension Base {
  public static func populateTagServerOfflineKey(_ serverCtx: inout FPSServerCtx) throws {
    var offlineKeyTLLVVersion = base_constants.FPS_TLLV_OFFLINEKEY_TLLV_VERSION
    var offlineKeyTLLV: [UInt8] = []

    // Check if we need to send down Stream ID (aka Content ID) and Title ID
    if (!serverCtx.streamId.isEmpty) || (!serverCtx.titleId.isEmpty) {
      // Verify that the client device actually supports Offline TLLV V2
      if !serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLVV2 {
        fpsLogError(
          FPSStatus.paramErr,
          "stream ID and title ID provided on the input but client doesn't support OfflineTLLV V2"
        )
        throw returnErrorStatus(FPSStatus.paramErr)
      }

      // If the client supports, then change TLLV version to V2
      offlineKeyTLLVVersion = base_constants.FPS_TLLV_OFFLINEKEY_TLLV_VERSION_2
    }

    // 4B Version
    offlineKeyTLLV.appendBigEndianU32(UInt32(offlineKeyTLLVVersion))

    // 4B Reserved
    offlineKeyTLLV.appendBigEndianU32(0)

    // 16B Content ID (Stream ID in V2)
    if !serverCtx.streamId.isEmpty {
      serverCtx.streamId += [UInt8](
        repeating: 0, count: (base_constants.FPS_MAX_STREAM_ID_LENGTH - serverCtx.streamId.count))
      offlineKeyTLLV.append(contentsOf: serverCtx.streamId)
    } else {
      // Content ID is a custom field
      try offlineKeyTagPopulateContentIDCustom(&serverCtx, &offlineKeyTLLV)
    }

    // 4B Storage Duration
    offlineKeyTLLV.appendBigEndianU32(serverCtx.ckcContainer.ckcData.keyDuration.rentalDuration)

    // 4B Playback Duration
    offlineKeyTLLV.appendBigEndianU32(serverCtx.ckcContainer.ckcData.keyDuration.playbackDuration)

    // Additional fields for Version 2
    if offlineKeyTLLVVersion == base_constants.FPS_TLLV_OFFLINEKEY_TLLV_VERSION_2 {
      // 16B Title ID
      serverCtx.titleId += [UInt8](
        repeating: 0, count: (base_constants.FPS_MAX_TITLE_ID_LENGTH - serverCtx.titleId.count))
      offlineKeyTLLV.append(contentsOf: serverCtx.titleId)
    }

    try serializeTLLV(
      base_constants.FPSTLLVTagValue.offlineKeyTag.rawValue,
      offlineKeyTLLV,
      &serverCtx.ckcContainer
    )
  }
}

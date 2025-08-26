//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func populateTagServerKeyDuration(_ serverCtx: inout FPSServerCtx) throws {
    var keyDuration: [UInt8] = []

    // 4B Lease Duration
    keyDuration.appendBigEndianU32(serverCtx.ckcContainer.ckcData.keyDuration.leaseDuration)

    // 4B Rental Duration
    keyDuration.appendBigEndianU32(serverCtx.ckcContainer.ckcData.keyDuration.rentalDuration)

    // 4B Key Type
    keyDuration.appendBigEndianU32(serverCtx.ckcContainer.ckcData.keyDuration.keyType)

    // 4B Reserved
    keyDuration.appendBigEndianU32(base_constants.FPS_KEY_DURATION_RESERVED_FIELD_VALUE)

    try serializeTLLV(
      base_constants.FPSTLLVTagValue.keyDurationTag.rawValue,
      keyDuration,
      &serverCtx.ckcContainer
    )
  }
}

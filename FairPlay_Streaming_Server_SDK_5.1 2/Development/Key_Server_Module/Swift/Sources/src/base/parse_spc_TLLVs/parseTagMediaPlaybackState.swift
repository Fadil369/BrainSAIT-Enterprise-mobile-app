//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagMediaPlaybackState(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(
      tllv.value.count == MemoryLayout<UInt32>.size * 2 + MemoryLayout<UInt64>.size,
      { throw FPSStatus.paramErr })

    // 4B Date
    spcContainer.spcData.playInfo.date = try readBigEndianU32(tllv.value, 0)

    // 4B Playback State
    spcContainer.spcData.playInfo.playbackState = try readBigEndianU32(tllv.value, 4)

    // 8B Playback ID
    spcContainer.spcData.playInfo.playbackId = try readBigEndianU64(tllv.value, 8)

  }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagServerStreamingIndicator(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(tllv.value.count == MemoryLayout<UInt64>.size, { throw FPSStatus.parserErr })

    // 8B Streaming Indicator
    spcContainer.spcData.streamingIndicator = try readBigEndianU64(tllv.value, 0)

  }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagTransactionID(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size matches expected size exactly
    try requireAction(tllv.value.count == MemoryLayout<UInt64>.size, { throw FPSStatus.parserErr })

    // 8B Transaction ID
    spcContainer.spcData.transactionId = try readBigEndianU64(tllv.value, 0)

    Log.debug("Transaction ID: 0x\(String(format:"%llx", spcContainer.spcData.transactionId))")
  }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  /// Populates TLLVs in the CKC.
  public static func serializeCKCData(_ serverCtx: inout FPSServerCtx) throws {
    // Populate common TLLVs
    try populateTagCK(serverCtx.ckcContainer.ckcData.contentKeyTLLVTag, &serverCtx)

    // Construct and serialize R1
    try populateTagR1(&serverCtx)

    try populateTagServerReturnTags(&serverCtx)

    // Populate TLLVs that have custom implementation
    try HDCPInformationTagPopulateCustom(&serverCtx)
    try securityLevelTagPopulateCustom(&serverCtx)
    try serializeCKCDataCustom(&serverCtx)

  }

  /// Serializes a single TLLV (tag, total length, value length, and value)
  /// onto `ckcContainer.ckcDataPtr`.
  ///
  /// Adds random bytes of padding to the end, so that total length is a
  /// multiple of `AES128_BLOCK_SIZE`.
  public static func serializeTLLV(
    _ tag: UInt64,
    _ value: [UInt8],
    _ ckcContainer: inout FPSServerCKCContainer
  ) throws {
    let valueSize = value.count

    // Determine minimum padding size to complete a block
    var paddingSize = 0

    if valueSize % base_constants.AES128_BLOCK_SIZE != 0 {
      paddingSize +=
        base_constants.AES128_BLOCK_SIZE - (valueSize % base_constants.AES128_BLOCK_SIZE)
    }

    // Add 0 to 3 random extra blocks of padding
    var extraPaddingBlocks: [UInt8] = [0]
    genRandom(&extraPaddingBlocks, 1)

    paddingSize += base_constants.AES128_BLOCK_SIZE * (Int(extraPaddingBlocks[0]) % 4)

    // Create random padding array
    var padding: [UInt8] = [UInt8](repeating: 0, count: paddingSize)
    genRandom(&padding, paddingSize)

    // Debug prints
    Log.debug(String(format: "Adding TLLV Tag -- 0x%016llx", tag))
    Log.debug(String(format: "    Block Length: 0x%x", valueSize + paddingSize))
    Log.debug(String(format: "    Value Length: 0x%x", valueSize))
    Log.debug("    Value: 0x\(value.map { String(format: "%02x", $0) }.joined())")

    // Write TLLV Tag
    ckcContainer.ckcDataPtr.appendBigEndianU64(tag)

    // Write Total Length and Value Length
    ckcContainer.ckcDataPtr.appendBigEndianU32(UInt32(valueSize + paddingSize))
    ckcContainer.ckcDataPtr.appendBigEndianU32(UInt32(valueSize))

    // Write Value
    if valueSize > 0 {
      ckcContainer.ckcDataPtr.append(contentsOf: value)
    }

    // Write Padding
    if paddingSize > 0 {
      ckcContainer.ckcDataPtr.append(contentsOf: padding)
    }
  }
}

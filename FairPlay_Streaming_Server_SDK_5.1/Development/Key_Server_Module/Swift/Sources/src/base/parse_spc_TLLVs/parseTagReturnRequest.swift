//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagReturnRequest(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // Check that size is a multiple of the tag field size
    try requireAction(
      (tllv.value.count % base_constants.FPS_TLLV_TAG_SZ == 0), { throw FPSStatus.parserErr })

    spcContainer.spcData.returnRequest.value = tllv.value

  }

  public static func extractReturnTags(_ spcData: inout FPSServerSPCData) throws {
    var offset = 0
    let returnRequest = spcData.returnRequest

    try requireAction(!spcData.spcDataParser.TLLVs.isEmpty, { throw FPSStatus.parserErr })

    // Iterate on list of TLLVs and extract the tags to be returned based on the returnRequest TLLV
    while offset < returnRequest.value.count {
      var tagAdded: Bool = false

      // Read the requested tag value
      let tag = try readBigEndianU64(returnRequest.value, offset)
      offset += MemoryLayout<UInt64>.size

      // Check if tag was already added
      for tllv in spcData.returnTLLVs {
        if tag == tllv.tag {
          tagAdded = true
          break
        }
      }

      if tagAdded {
        // Don't add tag twice
        continue
      }

      // Find tag in the list of incoming TLLVs from the SPC
      for tllv in spcData.spcDataParser.TLLVs {
        if tag == tllv.tag {
          spcData.returnTLLVs.append(tllv)
          tagAdded = true
          break
        }
      }

      // A tag from the SPC data that is to be returned in the CKC was not found in the SPC!
      if !tagAdded {
        fpsLogError(
          FPSStatus.missingRequiredTagErr,
          "Return tag missing from SPC 0x\(String(format:"%x", tag))")
        throw returnErrorStatus(FPSStatus.missingRequiredTagErr)
      }
    }
  }
}

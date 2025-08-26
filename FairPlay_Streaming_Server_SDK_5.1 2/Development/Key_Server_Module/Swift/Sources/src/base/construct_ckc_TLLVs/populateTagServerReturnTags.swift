//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func populateTagServerReturnTags(_ serverCtx: inout FPSServerCtx) throws {
    let spcData: FPSServerSPCData = serverCtx.spcContainer.spcData

    // Loop through the return tags and serialize them
    for tllv in spcData.returnTLLVs {
      // Return the TLLV data as sent by the client
      try serializeTLLV(
        tllv.tag,
        tllv.value,
        &serverCtx.ckcContainer
      )
    }
  }
}

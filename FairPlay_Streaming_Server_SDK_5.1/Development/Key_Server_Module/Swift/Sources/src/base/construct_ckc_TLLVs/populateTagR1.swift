//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func populateTagR1(_ serverCtx: inout FPSServerCtx) throws {
    try serializeTLLV(
      base_constants.FPSTLLVTagValue.r1Tag.rawValue,
      serverCtx.ckcContainer.ckcData.r1,
      &serverCtx.ckcContainer
    )
  }
}

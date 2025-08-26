//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func populateTagCK(_ tag: UInt64, _ serverCtx: inout FPSServerCtx) throws {
    try serializeTLLV(
      tag,
      serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload,
      &serverCtx.ckcContainer
    )
  }
}

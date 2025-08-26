//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  /// Makes sure all required TLLVs have been parsed from the SPC.
  public static func validateTLLVs(_ spcContainer: inout FPSServerSPCContainer) throws {
    // Enforce the minimum set of required TLLVs in V1
    let requiredTags: [UInt64] = [
      base_constants.FPSTLLVTagValue.sessionKeyR1Tag.rawValue,
      base_constants.FPSTLLVTagValue.antiReplayTag.rawValue,
      base_constants.FPSTLLVTagValue.r2tag.rawValue,
      base_constants.FPSTLLVTagValue.assetIDTag.rawValue,
      base_constants.FPSTLLVTagValue.transactionIDTag.rawValue,
      base_constants.FPSTLLVTagValue.protocolVersionUsedTag.rawValue,
      base_constants.FPSTLLVTagValue.protocolVersionsSupportedTag.rawValue,
      base_constants.FPSTLLVTagValue.returnRequestTag.rawValue,
      base_constants.FPSTLLVTagValue.sessionKeyR1IntegrityTag.rawValue,
    ]
    for tag in requiredTags {
      if !spcContainer.spcData.spcDataParser.parsedTagValues.contains(tag) {
        throw returnErrorStatus(FPSStatus.missingRequiredTagErr)
      }
    }

    // Custom handling (if needed)
    try validateTLLVsCustom(&spcContainer)
  }
}

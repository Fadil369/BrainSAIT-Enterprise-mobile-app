//
// base_parse_verification.swift : Defines verification functions required by the Base class.
//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import Foundation

extension AssetInfo {
  /// Verify validity of the Offline HLS input
  public func verifyOfflineHLS() throws {

    // contentID and titleID should be set (or not set) at the same time
    if streamId.isEmpty != titleId.isEmpty {
      Log.debug(
        "both stream-id and title-id should be set (or both not set) in offline HLS object"
      )
      throw returnErrorStatus(FPSStatus.paramErr)
    }

    try verifyOfflineHLSCustom(self)
  }
}

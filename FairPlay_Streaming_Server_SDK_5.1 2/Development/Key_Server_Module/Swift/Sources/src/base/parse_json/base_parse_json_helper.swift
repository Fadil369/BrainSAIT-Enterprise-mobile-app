//
// base_parse_json_helper.swift : Defines additional functions required by the Base class.
//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import Foundation

extension AssetInfo {
  /**

    parseHDCPType : Assigns correct value from HDCP based on input.

    Input:      JSON Object with HDCP information, AssetInfo struct variable
    Output:     updated AssetInfo struct variable

     **/
  /// Assigns HDCP requirement based on input integer.
  /// -1 = HDCP not required
  ///  0 = HDCP Type 0
  ///  1 = HDCP Type 1
  public static func parseHDCPType(_ hdcpType: Int32) throws -> base_constants.FPSHDCPRequirement {
    if hdcpType == -1 {
      return base_constants.FPSHDCPRequirement.hdcpNotRequired
    } else if hdcpType == 0 {
      return base_constants.FPSHDCPRequirement.hdcpType0
    } else if hdcpType == 1 {
      return base_constants.FPSHDCPRequirement.hdcpType1
    } else {
      // Unknown value. Check if extension wants to handle it.
      return try parseHDCPTypeCustom(hdcpType)
    }
  }

  /// Parses values from `offline-hls` JSON object.
  mutating func parseOfflineHLS(
    _ decoder: Decoder
  ) throws {

    let values = try decoder.container(keyedBy: CodingKeys.self)
    let offlinehlsInfo = try values.nestedContainer(
      keyedBy: OfflineHLSKeys.self, forKey: .offlinehls)
    licenseType = base_constants.FPSLicenseType.offlineHLS

    // content-id aka stream-id - optional
    if let stream = try offlinehlsInfo.decodeIfPresent(String.self, forKey: .streamId) {
      if !stream.isEmpty {
        streamId = [UInt8](fromHexString: stream)!
      }
    }

    // title-id - optional
    if let title = try offlinehlsInfo.decodeIfPresent(String.self, forKey: .titleId) {
      if !title.isEmpty {
        titleId = [UInt8](fromHexString: title)!
      }
    }

    // rental-duration - optional
    rentalDuration = try offlinehlsInfo.decodeIfPresent(UInt32.self, forKey: .rentalDuration) ?? 0

    // playback-duration - optional
    playbackDuration = try offlinehlsInfo.decodeIfPresent(UInt32.self, forKey: .playbackDuration) ?? 0

    try parseOfflineHLSCustom(decoder)

    try verifyOfflineHLS()
  }
}

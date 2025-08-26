//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

import Foundation

extension Base {
  public static func parseTagDeviceInfo(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // 8B Device Type (value is one of FPSAppleDeviceType)
    spcContainer.spcData.deviceInfo.deviceType = try readBigEndianU64(tllv.value, 0)

    // 4B OS Version (concatenation of 00 || major || minor || extra)
    spcContainer.spcData.deviceInfo.osVersion = try readBigEndianU32(tllv.value, 8)

    // 4B TLLV Version
    let _ = try readBigEndianU32(tllv.value, 12)

    spcContainer.spcData.deviceInfo.isDeviceInfoSet = true
  }
}

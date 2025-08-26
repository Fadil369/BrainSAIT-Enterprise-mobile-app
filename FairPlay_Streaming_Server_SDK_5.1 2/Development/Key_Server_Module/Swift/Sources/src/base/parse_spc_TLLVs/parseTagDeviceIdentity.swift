//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

import Foundation

extension Base {
  public static func parseTagDeviceIdentity(
    _ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer
  ) throws {

    // 4B FPDI Version
    spcContainer.spcData.deviceIdentity.fpdiVersion = try readBigEndianU32(tllv.value, 0)

    // 4B Device Class (value is one of FPSDeviceClass)
    spcContainer.spcData.deviceIdentity.deviceClass = try readBigEndianU32(tllv.value, 4)

    // 8B Vendor Hash
    spcContainer.spcData.deviceIdentity.vendorHash = try readBytes(
      tllv.value, 8, base_constants.FPS_VENDOR_HASH_SIZE)

    // 8B Product Hash
    spcContainer.spcData.deviceIdentity.productHash = try readBytes(
      tllv.value, 16, base_constants.FPS_PRODUCT_HASH_SIZE)

    // 4B FPS REE/userland Version
    spcContainer.spcData.deviceIdentity.fpVersionREE = try readBigEndianU32(tllv.value, 24)

    // 4B FPS TEE/kernel Version
    spcContainer.spcData.deviceIdentity.fpVersionTEE = try readBigEndianU32(tllv.value, 28)

    // 4B OS Version (Apple devices only)
    spcContainer.spcData.deviceIdentity.osVersion = try readBigEndianU32(tllv.value, 32)

    spcContainer.spcData.deviceIdentity.isDeviceIdentitySet = true
  }
}

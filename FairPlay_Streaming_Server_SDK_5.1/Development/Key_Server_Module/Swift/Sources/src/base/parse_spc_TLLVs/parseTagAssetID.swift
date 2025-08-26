//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

extension Base {
  public static func parseTagAssetID(_ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer)
    throws
  {

    // Check that Asset ID size is within bounds
    try requireAction(
      (tllv.value.count >= base_constants.FPS_V1_ASSET_ID_MIN_SZ), { throw FPSStatus.parserErr })
    try requireAction(
      (tllv.value.count <= base_constants.FPS_V1_ASSET_ID_MAX_SZ), { throw FPSStatus.parserErr })

    // Entire TLLV value is the Asset ID
    spcContainer.spcData.assetId = tllv.value

    if let assetId = String(bytes: spcContainer.spcData.assetId, encoding: .ascii) {
      Log.debug("Asset ID: \(assetId)")
    }
  }
}

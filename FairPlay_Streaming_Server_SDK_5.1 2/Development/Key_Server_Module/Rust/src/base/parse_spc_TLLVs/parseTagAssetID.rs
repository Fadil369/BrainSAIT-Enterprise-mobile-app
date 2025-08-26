//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

use crate::base::base_constants::{FPS_V1_ASSET_ID_MAX_SZ, FPS_V1_ASSET_ID_MIN_SZ};
use crate::base::structures::base_fps_structures::Base;
use crate::base::structures::base_server_structures::{FPSServerSPCContainer, FPSServerTLLV};
use crate::requireAction;
use crate::validate::{FPSStatus, Result};

impl Base {
    pub fn parseTagAssetID(tllv: &FPSServerTLLV, spcContainer: &mut FPSServerSPCContainer) -> Result<()> {
        // Check that Asset ID size is within bounds
        requireAction!(
            (tllv.value.len() >= FPS_V1_ASSET_ID_MIN_SZ),
            return Err(FPSStatus::parserErr)
        );
        requireAction!(
            (tllv.value.len() <= FPS_V1_ASSET_ID_MAX_SZ),
            return Err(FPSStatus::parserErr)
        );

        // Entire TLLV value is the Asset ID
        spcContainer.spcData.assetId = tllv.value.clone();

        if let Ok(assetId) = String::from_utf8(spcContainer.spcData.assetId.clone()) {
            log::debug!("Asset ID: {}", assetId);
        }

        Ok(())
    }
}

//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

use crate::base::base_constants::FPS_CAPABILITIES_FLAGS_LENGTH;
use crate::base::structures::base_fps_structures::Base;
use crate::base::structures::base_server_structures::{FPSServerSPCContainer, FPSServerTLLV};
use crate::requireAction;
use crate::validate::{FPSStatus, Result};

impl Base {
    pub fn parseTagClientCapabilities(tllv: &FPSServerTLLV, spcContainer: &mut FPSServerSPCContainer) -> Result<()> {
        // Check that size matches expected size exactly
        requireAction!(
            tllv.value.len() == FPS_CAPABILITIES_FLAGS_LENGTH,
            return Err(FPSStatus::paramErr)
        );

        // Entire TLLV value is the client capabilities flags
        spcContainer.spcData.clientCapabilities = tllv.value.clone();

        log::debug!(
            "Client Capabilities: 0x{}",
            hex::encode(spcContainer.spcData.clientCapabilities.as_slice())
        );

        Ok(())
    }
}

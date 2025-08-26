//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

use crate::base::base_constants::FPSTLLVTagValue;
use crate::base::structures::base_fps_structures::Base;
use crate::base::structures::base_server_structures::{FPSServerSPCContainer, FPSServerTLLV};
use crate::returnErrorStatus;
use crate::validate::{FPSStatus, Result};
use crate::Extension;

impl Base {
    /// Parses a single TLLV received in the SPC from client.
    pub fn parseTLLV(tllv: &FPSServerTLLV, spcContainer: &mut FPSServerSPCContainer) -> Result<()> {
        // Check for duplicate tag value
        if spcContainer.spcData.spcDataParser.parsedTagValues.contains(&tllv.tag) {
            returnErrorStatus!(FPSStatus::dupTagErr);
        }
        spcContainer.spcData.spcDataParser.parsedTagValues.push(tllv.tag);

        match tllv.tag {
            x if x == FPSTLLVTagValue::sessionKeyR1Tag as u64 => {
                Base::parseTagSessionKeyR1(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::sessionKeyR1IntegrityTag as u64 => {
                Base::parseTagSessionKeyR1Integrity(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::antiReplayTag as u64 => {
                Base::parseTagAntiReplay(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::r2tag as u64 => {
                Base::parseTagR2(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::returnRequestTag as u64 => {
                Base::parseTagReturnRequest(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::assetIDTag as u64 => {
                Base::parseTagAssetID(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::transactionIDTag as u64 => {
                Base::parseTagTransactionID(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::protocolVersionsSupportedTag as u64 => {
                Base::parseTagProtocolVersionsSupported(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::protocolVersionUsedTag as u64 => {
                Base::parseTagProtocolVersionUsed(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::streamingIndicatorTag as u64 => {
                Base::parseTagServerStreamingIndicator(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::mediaPlaybackStateTag as u64 => {
                Base::parseTagMediaPlaybackState(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::capabilitiesTag as u64 => {
                Base::parseTagClientCapabilities(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::deviceInfoTag as u64 => {
                Base::parseTagDeviceInfo(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::deviceIdentityTag as u64 => {
                Base::parseTagDeviceIdentity(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::offlineSyncTag as u64 => {
                Base::parseTagOfflineSync(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::supportedKeyFormatTag as u64 => {
                Base::parseTagSupportedKeyFormat(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::securityLevelReportTag as u64 => {
                Base::parseTagSecurityLevelReport(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::kdlVersionReportTag as u64 => {
                Base::parseTagKDLVersionReport(tllv, spcContainer)?;
            },
            x if x == FPSTLLVTagValue::vmDeviceInfoTag as u64 => {
                Base::parseTagVMDeviceInformation(tllv, spcContainer)?;
            },
            _ => {
                Extension::parseTLLVCustom(tllv, spcContainer)?;
            }
        }

        Ok(())
    }
}

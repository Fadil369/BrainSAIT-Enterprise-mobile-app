//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

#![allow(unused_assignments)]
use crate::base::base_constants;
use crate::base::base_constants::FPSDeviceClass;
use crate::base::base_constants::FPSKeyDurationType;
use crate::base::base_constants::FPSKeyTypeRequested;
use crate::base::base_constants::FPSLicenseType;
use crate::base::base_constants::SPCVersion;
use crate::base::base_constants::FPS_OFFLINE_CONTENTID_LENGTH;
use crate::base::base_constants::KD_SYNC_SPC_FLAG_TITLEID_VALID;
use crate::base::base_constants::{AES128_IV_SZ, AES128_KEY_SZ, FPS_MAX_TITLE_ID_LENGTH, NO_LEASE_DURATION};
use crate::base::structures::base_fps_structures::Base;
use crate::base::structures::base_fps_structures::{FPSOperation, FPSResult, FPSResults};
use crate::base::structures::base_server_structures::FPSServerCtx;
use crate::base::Utils::FPSServerUtils::readBigEndianU32;
use crate::validate::{FPSStatus, Result};
use crate::Extension;
use crate::{requireAction, returnErrorStatus};
use base64::engine::general_purpose;
use base64::Engine;
use hex::ToHex;
use serde_jsonrc::{Map, Number, Value};


impl Base {
    /// Fills in `fpsResult` with values that will be returned in the license response
    pub fn createResults(fpsOperation: &mut FPSOperation, fpsResult: &mut FPSResult) -> Result<()> {
        let mut keyTypeRequested = FPSKeyTypeRequested::none as u32;

        // Set the result id
        fpsResult.id = fpsOperation.id;

        // Custom handling (if needed)
        Extension::createResultsCustom(fpsOperation, &mut keyTypeRequested)?;

        // Generate CKC and other result fields
        Base::genCKCWithCKAndIV(fpsOperation, keyTypeRequested, fpsResult)?;

        Ok(())
    }

    /// Generates CKC and other result fields
    pub fn genCKCWithCKAndIV(
        fpsOperation: &mut FPSOperation,
        keyTypeRequested: u32,
        fpsResult: &mut FPSResult,
    ) -> Result<()> {
        let localVersion = readBigEndianU32(&fpsOperation.spc, 0)?;

        match localVersion {
            x if (x == (SPCVersion::v1 as u32) || x == (SPCVersion::v2 as u32)) => {
                let mut serverCtx: FPSServerCtx = Default::default();

                // Parse SPC
                Base::parseSPC(fpsOperation, &mut serverCtx)?;

                // Optional: if querying a database for more information outside of JSON, that is
                // done here
                Extension::queryDatabaseCustom(fpsOperation, &mut serverCtx)?;

                // Extension specific SPC implementation/checks (if required)
                Extension::validateSPCCustom(fpsOperation, &mut serverCtx)?;

                // Fill fpsResult structure
                Base::populateServerCtxResult(&mut serverCtx, fpsOperation, fpsResult)?;

                // Create the encrypted content key payload
                // This also gets the client HU from the request
                Extension::createContentKeyPayloadCustom(&mut serverCtx, keyTypeRequested, fpsResult)?;

                // Generate the CKC
                Base::generateCKC(&mut serverCtx)?;

                fpsResult.ckc = serverCtx.ckcContainer.ckc.to_owned();

                Extension::finalizeResultsCustom(&serverCtx, fpsResult)?;
            }

            _ => {
                returnErrorStatus!(FPSStatus::spcVersionErr);
            }
        }

        Ok(())
    }

    /// Populates `serverCtx.ckcContainer` and `fpsResult` structure with fields that will be returned to the caller
    pub fn populateServerCtxResult(
        serverCtx: &mut FPSServerCtx,
        operation: &FPSOperation,
        result: &mut FPSResult,
    ) -> Result<()> {
        // Copy some SPC information to the results structure

        // Report movie ID (session ID)
        result.sessionId = serverCtx.spcContainer.spcData.playInfo.playbackId;

        // Set the key and IV from the input json
        serverCtx.ckcContainer.ckcData.ck = operation.assetInfo.key[0..AES128_KEY_SZ].to_owned();
        serverCtx.ckcContainer.ckcData.iv = operation.assetInfo.iv[0..AES128_IV_SZ].to_owned();

        // Offline HLS or Online HLS rental
        if operation.assetInfo.licenseType == FPSLicenseType::offlineHLS as u32 {
            if operation.assetInfo.streamId.is_some(){
                serverCtx.streamId = operation.assetInfo.streamId.to_owned();
            }

            if operation.assetInfo.titleId.is_some() {
                serverCtx.titleId = operation.assetInfo.titleId.to_owned();
                serverCtx.titleId.as_mut().unwrap().resize(FPS_MAX_TITLE_ID_LENGTH, 0);
            }

            serverCtx.ckcContainer.ckcData.keyDuration.rentalDuration = operation.assetInfo.rentalDuration;
            serverCtx.ckcContainer.ckcData.keyDuration.playbackDuration = operation.assetInfo.playbackDuration;
            if (operation.assetInfo.rentalDuration != 0) || (operation.assetInfo.playbackDuration != 0) {
                serverCtx.ckcContainer.ckcData.keyDuration.keyType = FPSKeyDurationType::persistenceAndDuration as u32;
            } else {
                serverCtx.ckcContainer.ckcData.keyDuration.keyType = FPSKeyDurationType::persistence as u32;
            }
        }

        // Is lease requested?
        if operation.assetInfo.leaseDuration != NO_LEASE_DURATION {
            serverCtx.ckcContainer.ckcData.keyDuration.leaseDuration = operation.assetInfo.leaseDuration;
            serverCtx.ckcContainer.ckcData.keyDuration.rentalDuration = operation.assetInfo.rentalDuration;
            serverCtx.ckcContainer.ckcData.keyDuration.playbackDuration = operation.assetInfo.playbackDuration;
            serverCtx.ckcContainer.ckcData.keyDuration.keyType = FPSKeyDurationType::lease as u32;
        }

        // Required HDCP type for the content
        serverCtx.ckcContainer.ckcData.hdcpTypeTLLVValue = operation.assetInfo.hdcpReq;

        // Check if device identity is set and copy information to result
        result.deviceIdentitySet = serverCtx.spcContainer.spcData.deviceIdentity.isDeviceIdentitySet;
        if serverCtx.spcContainer.spcData.deviceIdentity.isDeviceIdentitySet {
            result.fpdiVersion = serverCtx.spcContainer.spcData.deviceIdentity.fpdiVersion;
            result.deviceClass = serverCtx.spcContainer.spcData.deviceIdentity.deviceClass;
            result.vendorHash = serverCtx.spcContainer.spcData.deviceIdentity.vendorHash.to_owned();
            result.productHash = serverCtx.spcContainer.spcData.deviceIdentity.productHash.to_owned();
            result.fpVersionREE = serverCtx.spcContainer.spcData.deviceIdentity.fpVersionREE;
            result.fpVersionTEE = serverCtx.spcContainer.spcData.deviceIdentity.fpVersionTEE;
            result.osVersion = serverCtx.spcContainer.spcData.deviceIdentity.osVersion;
        }

        // Report if the request came from a virtual machine
        if serverCtx.spcContainer.spcData.vmDeviceInfo.is_some() {
            result.vmDeviceInfo = serverCtx.spcContainer.spcData.vmDeviceInfo.clone();
        }
        else {
            result.vmDeviceInfo = None;
        }

        Extension::populateResultsCustom(serverCtx, operation, result)?;

        if operation.isCheckIn {
            result.isCheckIn = true;
            result.syncServerChallenge = serverCtx.spcContainer.spcData.syncServerChallenge;
            result.syncFlags = serverCtx.spcContainer.spcData.syncFlags;
            // Make sure to send back the title ID if present
            if (serverCtx.spcContainer.spcData.syncFlags & KD_SYNC_SPC_FLAG_TITLEID_VALID) != 0 {
                result.syncTitleId = serverCtx.spcContainer.spcData.syncTitleId[..FPS_MAX_TITLE_ID_LENGTH].to_vec();
                serverCtx.titleId = Some(serverCtx.spcContainer.spcData.syncTitleId.clone());
            }
            result.durationToRentalExpiry = serverCtx.spcContainer.spcData.durationToRentalExpiry;
            result.recordsDeleted = serverCtx.spcContainer.spcData.recordsDeleted;
            if result.recordsDeleted > 0 {
                result.deletedContentIDs = serverCtx.spcContainer.spcData.deletedContentIDs
                    [..result.recordsDeleted * FPS_OFFLINE_CONTENTID_LENGTH]
                    .to_vec();
            }
        } else {
            result.isCheckIn = false;
        }

        Ok(())
    }

    /// Serializes `fpsResults` into JSON string
    pub fn serializeResults(fpsResults: FPSResults, jsonOutput: &mut String) -> Result<()> {
        let mut jsonResults = Map::new();
        let mut ckcNode: Vec<Value> = Vec::new();
        let mut status: Result<()> = Ok(());

        // Serialize each create-ckc object
        for fpsResult in &fpsResults.resultPtr {
            status = Base::serializeCreateCKCNode(fpsResult, &mut ckcNode);

            if status.is_err() {
                log::debug!("failed to output result data for result {}", fpsResult.id);
            }
        }

        // Custom handling
        Extension::serializeResultsCustom(&fpsResults, ckcNode, &mut jsonResults)?;

        // Convert to JSON string
        let jsonStr = serde_jsonrc::to_string(&Value::Object(jsonResults)).unwrap();

        requireAction!(!jsonStr.is_empty(), return Err(FPSStatus::paramErr));

        *jsonOutput = jsonStr;

        status
    }

    /// Serializes a single create-ckc object into JSON
    pub fn serializeCreateCKCNode(result: &FPSResult, parentNode: &mut Vec<Value>) -> Result<()> {
        let mut ckcArrayNode = Map::new();

        // ID
        let idObj = Value::Number(Number::from(result.id));
        ckcArrayNode.insert(base_constants::ID_STR.to_string(), idObj);

        // Status
        let statusObj = Value::Number(Number::from(result.status as i32));
        ckcArrayNode.insert(base_constants::STATUS_STR.to_string(), statusObj);

        // Rest of the fields are printed only if status is no error
        if result.status == FPSStatus::noErr {
            // Player HU
            let hexHU: String = result.hu.encode_hex_upper();
            let huObj = Value::String(hexHU);
            ckcArrayNode.insert(base_constants::HU_STR.to_string(), huObj);

            if result.isCheckIn {
                // Server challenge
                let temp = format!("{}", result.syncServerChallenge);
                let checkInServerChallengeObj = Value::String(temp);
                ckcArrayNode.insert(
                    base_constants::CHECK_IN_SERVER_CHALLENGE_STR.to_string(),
                    checkInServerChallengeObj,
                );
            }
            if result.syncFlags != 0 {
                // Check-in / Sync flags
                let temp = format!("{:X?}", result.syncFlags);
                let checkInFlagsObj = Value::String(temp);
                ckcArrayNode.insert(base_constants::CHECK_IN_FLAGS_STR.to_string(), checkInFlagsObj);

                // Duration to expiry (rentals)
                let temp = format!("{}", result.durationToRentalExpiry);
                let syncDurationToExpiryObj = Value::String(temp);
                ckcArrayNode.insert(base_constants::DURATION_LEFT_STR.to_string(), syncDurationToExpiryObj);

                // Check-in Title ID
                if (result.syncFlags & KD_SYNC_SPC_FLAG_TITLEID_VALID) != 0 {
                    let hexTitleID = result.syncTitleId.encode_hex_upper();
                    let checkInTitleIdObj = Value::String(hexTitleID);
                    ckcArrayNode.insert(base_constants::CHECK_IN_TITLE_ID_STR.to_string(), checkInTitleIdObj);
                }

                // Array of content ID being checked in
                if (result.recordsDeleted > 0) && (!result.deletedContentIDs.is_empty()) {
                    let mut checkInContentIDNodeObj: Vec<Value> = Vec::new();

                    for i in 0..result.recordsDeleted {
                        // Player HU
                        let index = (i as usize) * FPS_OFFLINE_CONTENTID_LENGTH;
                        let hexContentId = result.deletedContentIDs[index..(index + FPS_OFFLINE_CONTENTID_LENGTH)]
                            .to_vec()
                            .encode_hex_upper();

                        let contentIdObj = Value::String(hexContentId);
                        checkInContentIDNodeObj.push(contentIdObj);
                    }

                    ckcArrayNode.insert(
                        base_constants::CHECK_IN_STREAM_ID_STR.to_string(),
                        Value::Array(checkInContentIDNodeObj),
                    );
                }
            }

            if result.deviceIdentitySet {
                // FPDI version
                let fpdiVersionObj = Value::Number(Number::from(result.fpdiVersion));
                ckcArrayNode.insert(base_constants::FPDI_VERSION_STR.to_string(), fpdiVersionObj);

                // Device class
                let fpdiDeviceClassObj = Value::Number(Number::from(result.deviceClass));
                ckcArrayNode.insert(base_constants::DEVICE_CLASS_STR.to_string(), fpdiDeviceClassObj);

                // Vendor hash
                let vendorHash = result.vendorHash.encode_hex_upper();
                let fpdiVendorHashObj = Value::String(vendorHash);
                ckcArrayNode.insert(base_constants::VENDOR_HASH_STR.to_string(), fpdiVendorHashObj);

                // Product hash
                let productHash = result.productHash.encode_hex_upper();
                let fpdiProductHashObj = Value::String(productHash);
                ckcArrayNode.insert(base_constants::PRODUCT_HASH_STR.to_string(), fpdiProductHashObj);

                // FPS version in REE
                let fpsReeVersion = format!("{:08X}", result.fpVersionREE);
                let fpdiFpsReeVersionObj = Value::String(fpsReeVersion);
                ckcArrayNode.insert(base_constants::FPS_REE_VERSION_STR.to_string(), fpdiFpsReeVersionObj);

                // FPS version in TEE
                let fpsTeeVersion = format!("{:08X}", result.fpVersionTEE);
                let fpdiFpsTeeVersionObj = Value::String(fpsTeeVersion);
                ckcArrayNode.insert(base_constants::FPS_TEE_VERSION_STR.to_string(), fpdiFpsTeeVersionObj);

                // OS version
                let osVersion = format!("{:08X}", result.osVersion);
                let fpdiOSVersionObj = Value::String(osVersion);
                ckcArrayNode.insert(base_constants::OS_VERSION_STR.to_string(), fpdiOSVersionObj);
            }

            if let Some(vmDeviceInfo) = &result.vmDeviceInfo {
                // Print Host VM Information
                let hostDeviceClass = match vmDeviceInfo.hostDeviceClass {
                    FPSDeviceClass::appleDesktop => "appleDesktop",
                    FPSDeviceClass::appleMobile => "appleMobile",
                    FPSDeviceClass::appleWearable => "appleWearable",
                    FPSDeviceClass::appleLivingRoom => "appleLivingRoom",
                    FPSDeviceClass::appleSpacial => "appleSpacial",
                    // Note: printing partner devices as unknown as this value should not occur for
                    // virtual machines
                    _ => "Unknown"
                };
                let hostDeviceClassObj = Value::String(hostDeviceClass.to_string());
                ckcArrayNode.insert(base_constants::HOST_DEVICE_CLASS_STR.to_string(), hostDeviceClassObj);

                let hostOSVersion = format!("{:08X}", vmDeviceInfo.hostOSVersion);
                let hostOSVersionObj = Value::String(hostOSVersion);
                ckcArrayNode.insert(base_constants::HOST_OS_VERSION_STR.to_string(), hostOSVersionObj);

                let hostVMProtocolVersionObj = Value::Number(Number::from(vmDeviceInfo.hostVMProtocolVersion));
                ckcArrayNode.insert(base_constants::HOST_VM_PROTOCOL_VERSION.to_string(), hostVMProtocolVersionObj);

                // Print Guest VM Information
                let guestDeviceClass = match vmDeviceInfo.guestDeviceClass {
                    FPSDeviceClass::appleDesktop => "appleDesktop",
                    FPSDeviceClass::appleMobile => "appleMobile",
                    FPSDeviceClass::appleWearable => "appleWearable",
                    FPSDeviceClass::appleLivingRoom => "appleLivingRoom",
                    FPSDeviceClass::appleSpacial => "appleSpacial",
                    // Note: printing partner devices as unknown as this value should not occur for
                    // virtual machines
                    _ => "Unknown"
                };
                let guestDeviceClassObj = Value::String(guestDeviceClass.to_string());
                ckcArrayNode.insert(base_constants::GUEST_DEVICE_CLASS_STR.to_string(), guestDeviceClassObj);

                let guestOSVersion = format!("{:08X}", vmDeviceInfo.guestOSVersion);
                let guestOSVersionObj = Value::String(guestOSVersion);
                ckcArrayNode.insert(base_constants::GUEST_OS_VERSION_STR.to_string(), guestOSVersionObj);

                let guestVMProtocolVersionObj = Value::Number(Number::from(vmDeviceInfo.guestVMProtocolVersion));
                ckcArrayNode.insert(base_constants::GUEST_VM_PROTOCOL_VERSION.to_string(), guestVMProtocolVersionObj);
            }

            Extension::serializeCreateCKCNodeCustom(result, &mut ckcArrayNode)?;

            if !result.isCheckIn && !result.ckc.is_empty() {
                // CKC
                let base64CKC = general_purpose::STANDARD.encode(&result.ckc);
                let ckcObj = Value::String(base64CKC);
                ckcArrayNode.insert(base_constants::CKC_STR.to_string(), ckcObj);
            }
        }

        parentNode.push(Value::Object(ckcArrayNode));

        Ok(())
    }
}

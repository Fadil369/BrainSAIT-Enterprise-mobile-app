//
// base_fps_structures.rs: Contains the structure definitions for the Base class.
//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

use crate::base::base_constants;
use crate::base::base_constants::FPSHDCPRequirement;
use crate::base::base_constants::FPS_V1_HU_SZ;
use super::base_server_structures::VMDeviceInfo;
use crate::extension_structures;
use crate::validate::FPSStatus;
use std::fmt::Debug;

/// Base container where common code is implemented.
pub struct Base {}

/// Information about all create-ckc operations in a request.
///
/// Contains a vector of FPSOperation. This is necessary if receiving multiple requests in the same JSON.
#[derive(Debug, Default)]
pub struct FPSOperations {
    pub operationsPtr: Vec<FPSOperation>,
}

/// Information about a single create-ckc operation.
///
/// This is the basic structure of a FairPlay Streaming key request after the JSON has been parsed.
#[derive(Debug, Default, Clone)]
pub struct FPSOperation {
    pub id: u64,
    pub spc: Vec<u8>,
    /// True when input SPC is a SyncSPC with check-in
    pub isCheckIn: bool,
    pub assetInfo: AssetInfo,

    // Extension
    pub extension: extension_structures::FPSOperationExtension,
}

/// Protection requirements related to a particular asset.
#[derive(Debug, Clone)]
pub struct AssetInfo {
    pub key: Vec<u8>,
    pub iv: Vec<u8>,
    pub isCKProvided: bool,     // true if key and iv are valid

    pub hdcpReq: u64,           // one of the FPSHDCPRequirement enums. Using type u64 so we can test with invalid values.

    // Expirations
    pub leaseDuration: u32,     // Lease duration (starts at SPC creation time)
    pub rentalDuration: u32,    // rental duration in seconds. Starts at asset download time
    pub playbackDuration: u32,  // playback duration in seconds. Starts at asset first playback time

    // Offline HLS parameters
    pub licenseType: u32,
    pub streamId: Option<Vec<u8>>,      // unique Id of each HLS sub-stream
    pub titleId: Option<Vec<u8>>,       // Id of a title (program). Same for all HLS substreams of a give title.

    // Extension
    pub extension: extension_structures::AssetInfoExtension,
}

impl Default for AssetInfo {
    fn default() -> AssetInfo {
        AssetInfo {
            isCKProvided: false,
            key: vec![0; base_constants::AES128_KEY_SZ],
            iv: vec![0; base_constants::AES128_IV_SZ],
            leaseDuration: 0,
            rentalDuration: 0,
            playbackDuration: 0,
            hdcpReq: FPSHDCPRequirement::hdcpNotRequired as u64,

            licenseType: 0,
            streamId: None,
            titleId: None,

            extension: Default::default(),
        }
    }
}

/// Return data for a single create-ckc operation (expected to be returned in the output JSON).
#[derive(Debug)]
pub struct FPSResult {
    pub id: u64,
    pub status: FPSStatus,
    pub hu: Vec<u8>,
    pub ckc: Vec<u8>,

    pub sessionId: u64, // Parsed from Reference Time Tag TLLV

    // Sync TLLV
    pub isCheckIn: bool,
    pub syncServerChallenge: u64,
    pub syncFlags: u64,
    pub syncTitleId: Vec<u8>,
    pub durationToRentalExpiry: u32,
    pub recordsDeleted: usize, // number of keys deleted as reported by check-in variant of SyncTLLV
    pub deletedContentIDs: Vec<u8>,

    // Device Identity Data
    pub deviceIdentitySet: bool,
    pub fpdiVersion: u32,
    pub deviceClass: u32,
    pub vendorHash: Vec<u8>,
    pub productHash: Vec<u8>,
    pub fpVersionREE: u32,
    pub fpVersionTEE: u32,
    pub osVersion: u32,
    pub vmDeviceInfo: Option<VMDeviceInfo>,

    // Extension
    pub extension: extension_structures::FPSResultExtension, // room for extension values, if not in use template to ()
}

impl Default for FPSResult {
    fn default() -> FPSResult {
        FPSResult {
            id: 0,
            status: FPSStatus::noErr,
            hu: vec![0; FPS_V1_HU_SZ],
            ckc: Vec::new(),

            sessionId: 0,

            isCheckIn: false,
            syncServerChallenge: 0,
            syncFlags: 0,
            syncTitleId: vec![0; base_constants::FPS_MAX_TITLE_ID_LENGTH],
            durationToRentalExpiry: 0,
            recordsDeleted: 0, // number of keys deleted as reported by check-in variant of SyncTLLV
            deletedContentIDs: Vec::new(),

            deviceIdentitySet: false,
            fpdiVersion: 0,
            deviceClass: 0,
            vendorHash: vec![0; base_constants::FPS_VENDOR_HASH_SIZE],
            productHash: vec![0; base_constants::FPS_PRODUCT_HASH_SIZE],
            fpVersionREE: 0,
            fpVersionTEE: 0,
            osVersion: 0,
            vmDeviceInfo: None,

            extension: Default::default(),
        }
    }
}

/// Return data for all create-ckc operations in a request.
///
/// Contains a vector of FPSResult. This is necessary if multiple requests are sent at once (much like FPSOperations).
#[derive(Debug, Default)]
pub struct FPSResults {
    pub resultPtr: Vec<FPSResult>,

    // Extension
    pub extension: extension_structures::FPSResultsExtension, // room for extension values, if not in use template to ()
}

/// Structure used to call C library function `PartnerKSMCreateKeyPayload`.
///
/// All members are 64B size (u64 or pointer) for easier compatibility.
#[derive(Debug)]
#[repr(C)]
pub struct KSMKeyPayload {
    pub version: u64,                       // in: version of the structure. Currently supported version is 1
    pub contentKey: *const u8,              // in: content key
    pub contentKeyLength: u64,              // in: only 16 byte long keys accepted at the moment
    pub contentIV: *const u8,               // in: content IV
    pub contentIVLength: u64,               // in: must be 16 bytes
    pub contentType: u64,                   // in: one of KSMKeyPayloadContentType enums
    pub SK_R1: *const u8,                   // in: content of FPSTLLVTagValue::sessionKeyR1Tag (0x3d1a10b8bffac2ec) TLLV
    pub SK_R1Length: u64,                   // in: size of SK_R1 data
    pub R2: *const u8,                      // in: content of FPSTLLVTagValue::r2tag (0x71b5595ac1521133) TLLV
    pub R2Length: u64,                      // in: size of R2 data
    pub R1Integrity: *const u8,             // in: content of FPSTLLVTagValue::sessionKeyR1IntegrityTag (0xb349d4809e910687) TLLV
    pub R1IntegrityLength: u64,             // in: size of R1 integrity data
    pub supportedKeyFormats: *const u64,    // in: either delivered in FPSTLLVTagValue::supportedKeyFormatTag (0x8d8e84fa6cc35eb7) or set to 16 byte key (FPSKeyFormatTag::buf16Byte) for older devices
    pub numberOfSupportedKeyFormats: u64,   // in: number of key formats in supportedKeyFormats array
    pub cryptoVersionUsed: u64,             // in: delivered in FPSTLLVTagValue::protocolVersionUsedTag (0x5d81bcbcc7f61703) TLLV
    pub provisioningData: *const u8,        // in: server Provisioning Data generated by WWDR
    pub provisioningDataLength: u64,        // in: size of the Provisioning Data
    pub certHash: *const u8,                // in: server certificate hash delivered in SPC header
    pub certHashLength: u64,                // in: size of the certificate hash
    pub clientHU: *const u8,                // out: client HU. Memory allocated by caller. Allocated buffer size should be passed in clientHULength
    pub clientHULength: u64,                // in/out: in: buffer size allocated for clientHU. out: actual HU size returned
    pub contentKeyTLLVTag: u64,             // out: Content Key TLLV tag to send to the client device
    pub contentKeyTLLVPayload: *mut u8,     // out: payload of Content Key TLLV. Memory allocated by caller. Allocated buffer size should be passed in contentKeyTLLVPayloadLength
    pub contentKeyTLLVPayloadLength: u64,   // in/out: in: buffer size allocated for contentKeyTLLVPayload. out: actual content key TLLV payload size returned
    pub R1: *mut u8,                        // out: R1 data. Memory allocated by caller. Allocated buffer size should be passed in R1Length
    pub R1Length: u64,                      // in/out: in: buffer size allocated for R1. out: actual R1 size returned
}

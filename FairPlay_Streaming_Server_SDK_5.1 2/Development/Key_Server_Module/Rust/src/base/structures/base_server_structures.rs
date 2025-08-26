//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

use crate::base::base_constants::FPS_MAX_KEY_FORMATS;
use crate::base::base_constants::{self, FPSDeviceClass};
use crate::extension_structures;
use derivative::Derivative;
use std::fmt::Debug;

/// Contains both the SPC and CKC containers along with stream and title IDs.
/// This is the base structure that is most commonly sent to functions.
#[derive(Debug, Default, Clone)]
pub struct FPSServerCtx {
    pub spcContainer: FPSServerSPCContainer,
    pub ckcContainer: FPSServerCKCContainer,
    pub streamId: Option<Vec<u8>>,
    pub titleId: Option<Vec<u8>>,

    // Extension
    pub extension: extension_structures::ServerCtxExtension,
}

/// Contains all the information parsed out of the SPC including version, SPC encryption AES key
/// and IV, and TLLV data.
#[derive(Debug, Default, Clone)]
pub struct FPSServerSPCContainer {
    pub version: u32,
    pub reservedValue: u32,
    pub aesKeyIV: Vec<u8>,
    pub aesWrappedKey: Vec<u8>,
    pub aesWrappedKeySize: usize,
    pub certificateHash: Vec<u8>,
    pub spcDecryptedData: Vec<u8>,
    pub spcDataSize: usize,
    pub spcDataOffset: usize,
    pub spcData: FPSServerSPCData,

    // Extension
    pub extension: extension_structures::SPCContainerExtension,
}

/// Contains information that will be added to the CKC including version, CKC encryption, AES key
/// and IV, and the CKC payload.
#[derive(Debug, Clone)]
pub struct FPSServerCKCContainer {
    /// If this is set to false, the CKC will not be returned as part of the output.
    pub returnCKC: bool,
    pub version: u32,
    pub aesKeyIV: Vec<u8>,
    pub ckc: Vec<u8>,
    pub ckcDataPtr: Vec<u8>,
    pub ckcData: FPSServerCKCData,
}

impl Default for FPSServerCKCContainer {
    fn default() -> FPSServerCKCContainer {
        FPSServerCKCContainer {
            returnCKC: true,
            version: 0,
            aesKeyIV: vec![0; 16],
            ckc: Vec::new(),
            ckcDataPtr: Vec::new(),
            ckcData: Default::default(),
        }
    }
}

/// Contains information parsed out of the SPC TLLVs after decryption.
#[derive(Debug, Clone)]
pub struct FPSServerSPCData {
    pub antiReplay: Vec<u8>,
    pub sk: Vec<u8>,
    pub hu: Vec<u8>,
    pub r2: Vec<u8>,
    pub r1: Vec<u8>,
    pub skR1IntegrityTag: Vec<u8>,
    pub skR1Integrity: Vec<u8>,
    pub skR1: Vec<u8>,
    pub assetId: Vec<u8>,
    pub versionUsed: u32,
    pub versionsSupported: Vec<u32>,
    pub returnTLLVs: Vec<FPSServerTLLV>,
    pub returnRequest: FPSServerTLLV,
    pub clientFeatures: FPSServerClientFeatures,
    pub spcDataParser: FPSServerSPCDataParser,
    pub playInfo: FPSServerMediaPlaybackState,
    pub streamingIndicator: u64,
    pub transactionId: u64,

    // Sync TLLV
    pub syncServerChallenge: u64,
    pub syncFlags: u64,
    pub syncTitleId: Vec<u8>,
    pub durationToRentalExpiry: u32,
    pub recordsDeleted: usize,
    pub deletedContentIDs: Vec<u8>,

    // Client capabilities flags TLLV
    pub clientCapabilities: Vec<u8>,

    // Security Level Report TLLV
    pub isSecurityLevelTLLVValid: bool,
    pub supportedSecurityLevel: u64,
    pub clientKextDenyListVersion: u32,

    pub deviceIdentity: FPSDeviceIdentity,
    // Deprecated - newer devices send Device Identity instead
    pub deviceInfo: FPSDeviceInfo,

    // Supported Key Formats
    pub numberOfSupportedKeyFormats: u32,
    pub supportedKeyFormats: [u64; FPS_MAX_KEY_FORMATS],

    pub vmDeviceInfo:  Option<VMDeviceInfo>,

    // Extension
    pub extension: extension_structures::SPCDataExtension,
}

impl Default for FPSServerSPCData {
    fn default() -> FPSServerSPCData {
        FPSServerSPCData {
            antiReplay: vec![0; base_constants::AES128_KEY_SZ],
            sk: vec![0; base_constants::AES128_KEY_SZ],
            hu: vec![0; base_constants::FPS_V1_HU_SZ],
            r2: vec![0; base_constants::FPS_V1_R2_SZ],
            r1: vec![0; base_constants::FPS_V1_R1_SZ],
            skR1IntegrityTag: vec![0; base_constants::FPS_V1_SKR1_INTEGRITY_SZ],
            skR1Integrity: vec![0; base_constants::FPS_V1_SKR1_INTEGRITY_SZ],
            skR1: vec![0; base_constants::FPS_V1_SKR1_SZ],

            assetId: Default::default(),
            versionUsed: 0,
            versionsSupported: Default::default(),
            returnTLLVs: Default::default(),
            returnRequest: FPSServerTLLV::default(),
            clientFeatures: Default::default(),
            spcDataParser: Default::default(),
            playInfo: Default::default(),
            streamingIndicator: 0,
            transactionId: 0,

            syncServerChallenge: 0,
            syncFlags: 0,
            syncTitleId: vec![0; base_constants::FPS_MAX_TITLE_ID_LENGTH],
            durationToRentalExpiry: 0,
            recordsDeleted: 0,
            deletedContentIDs: vec![],

            clientCapabilities: vec![],

            isSecurityLevelTLLVValid: false,
            supportedSecurityLevel: 0,
            clientKextDenyListVersion: 0,

            deviceIdentity: Default::default(),
            deviceInfo: Default::default(),

            numberOfSupportedKeyFormats: 0,
            supportedKeyFormats: [0; FPS_MAX_KEY_FORMATS],
            vmDeviceInfo: None,

            extension: Default::default(),
        }
    }
}

/// Information used to help identify the client device type.
///
/// Includes vendor and product hashes, REE and TEE versions (only for third party devices), and
/// OS version (only for Apple products).
///
/// Note: this TLLV is only sent by devices running FairPlay client software released in 2021 or
/// later and its use should be prioritized over FPSDeviceInfo for client device type information.
#[derive(Debug, Clone, Default)]
pub struct FPSDeviceIdentity {
    pub isDeviceIdentitySet: bool,
    pub fpdiVersion: u32,
    pub deviceClass: u32,
    pub vendorHash: Vec<u8>,
    pub productHash: Vec<u8>,
    pub fpVersionREE: u32,
    pub fpVersionTEE: u32,
    pub osVersion: u32,
}

/// Basic information about the client device including device type and OS version.
///
/// Note: This is a TLLV that is kept for legacy purposes. FPSDeviceIdentity should be used instead
/// if available.
#[derive(Debug, Clone, Default)]
pub struct FPSDeviceInfo {
    pub isDeviceInfoSet: bool,
    pub deviceType: u64,
    pub osVersion: u32,
}

/// Data that will be added to the CKC TLLVs.
#[derive(Derivative, Debug, Clone, Default)]
pub struct FPSServerCKCData {
    pub ck: Vec<u8>,
    pub iv: Vec<u8>,
    pub r1: Vec<u8>,
    pub keyDuration: FPSServerKeyDuration,
    pub hdcpTypeTLLVValue: u64,

    // For new FPS crypto lib this is content key tag and content key TLLV payload to use
    pub contentKeyTLLVTag: u64,
    pub contentKeyTLLVPayload: Vec<u8>,

    // Extension
    pub extension: extension_structures::CKCDataExtension,
}

/// Contains the tag and value fields for a TLLV.
#[derive(Debug, Clone, Default)]
pub struct FPSServerTLLV {
    pub tag: u64,
    pub value: Vec<u8>, // Contains only the value data (no padding)
}

/// Contains fields that indicate whether or not certain features are supported by the client.
///
/// Includes offline key V1 vs V2, Baseline vs Main security levels, and HDCP Type 1.
#[derive(Debug, Clone, Default)]
pub struct FPSServerClientFeatures {
    pub supportsOfflineKeyTLLV: bool,
    pub supportsOfflineKeyTLLVV2: bool,
    pub supportsSecurityLevelBaseline: bool,
    pub supportsSecurityLevelMain: bool,
    pub supportsHDCPTypeOne: bool,
    pub supportsDualExpiry: bool,
    pub supportsCheckIn: bool,

    // Extension
    pub extension: extension_structures::ClientFeaturesExtension,
}

/// Intermediary data structure used when parsing the SPC.
///
/// Holds the current offset within the SPC data and parsed tags along with the TLLVs that have
/// been parsed.
#[derive(Debug, Clone, Default)]
pub struct FPSServerSPCDataParser {
    pub currentOffset: usize,
    pub TLLVs: Vec<FPSServerTLLV>,
    pub parsedTagValues: Vec<u64>,
}

/// Contains information such as the date, playback state, and playback ID.
#[derive(Debug, Clone, Copy, Default)]
pub struct FPSServerMediaPlaybackState {
    pub date: u32,
    pub playbackState: u32,
    pub playbackId: u64,
}

/// Contains information about different key durations including lease, rental, and playback
/// duration, along with which type the key is.
#[derive(Debug, Clone, Default)]
pub struct FPSServerKeyDuration {
    pub leaseDuration: u32,
    pub rentalDuration: u32,
    pub playbackDuration: u32,
    pub keyType: u32,

    // Extension
    pub extension: extension_structures::KeyDurationExtension,
}

#[derive(Debug, Clone, Default)]
pub struct VMDeviceInfo {
    pub hostDeviceClass: FPSDeviceClass,
    pub hostOSVersion: u32,
    pub hostVMProtocolVersion: u32,
    pub guestDeviceClass: FPSDeviceClass,
    pub guestOSVersion: u32,
    pub guestVMProtocolVersion: u32,
}

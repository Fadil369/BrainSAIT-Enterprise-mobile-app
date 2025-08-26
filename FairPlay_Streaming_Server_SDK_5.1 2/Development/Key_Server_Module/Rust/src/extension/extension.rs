//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

use crate::base::base_constants;
use crate::base::base_constants::{FPSKeyDurationType, FPSTLLVTagValue};
use crate::base::structures::base_fps_structures::{AssetInfo, FPSOperation, FPSOperations, FPSResult, FPSResults};
use crate::base::structures::base_server_structures::{FPSServerCtx, FPSServerSPCContainer, FPSServerTLLV};
use crate::extension::credentials::credentials::{
    CREDENTIALS_PATH, PROVISIONING_DATA, RSA_1024_PRIVATE_KEY_PEM, RSA_2048_PRIVATE_KEY_PEM,
};
use crate::extension::extension_constants::{self, ContentType, FairPlayStreamingVersion};
use crate::extension::structures::extension_structures::SDKExtension;
use crate::extension_structures::FPSOperationExtension;
use crate::validate::{FPSStatus, Result};
use crate::Base;
use crate::{fpsLogError, requireAction, returnErrorStatus};
use rand::Rng;
use std::path::Path;
use serde_jsonrc::{Map, Value};
use std::io::Write;

////////////////////////////////////////////////////////////////////////////////
// Utility Functions
////////////////////////////////////////////////////////////////////////////////

/// Initializes custom log output formatting. Change the format here to match
/// whatever log formatting works best for your tools.
pub fn logInitCustom(_extension: Option<&FPSOperationExtension>) {
    let env = env_logger::Env::new()
        .filter_or("RUST_LOG", "trace")
        .write_style("RUST_LOG_STYLE");

    // Example configuration of log::Debug!() style prints:
    env_logger::Builder::from_env(env)
        .format(move |buf, record| writeln!(buf, "[DEBUG] {}", record.args()))
        .try_init()
        .unwrap_or(());
    // or match the fpsLogError!() style prints:
    // env_logger::Builder::from_env(env)
    //     .format(move |buf, record| {
    //         writeln!(
    //             buf,
    //             "timestamp=\"{}\",FP_TOOLN=\"{}\",FP_TOOLV=\"{}\",FP_PID=\"{}\",FP_FL=\"{}\",FP_LN=\"{}\",{}",
    //             chrono::Utc::now().format("%Y-%m-%d %T,%3f"),
    //             env!("CARGO_PKG_NAME"),
    //             env!("CARGO_PKG_VERSION"),
    //             std::process::id(),
    //             record.file().unwrap_or("unknown file"),
    //             record.line().unwrap_or(0),
    //             record.args()
    //             )
    //     })
    // .init();
    // or use default format:
    // env_logger::Builder::from_env(env).try_init().unwrap_or(());

    // Example configuration of fpsLogError!() style prints:
    crate::logging::LOG_FORMAT.with(|a| {
        let _ = a.replace(Box::new(|line, file| {
            format!(
                "timestamp=\"{}\",FP_TOOLN=\"{}\",FP_TOOLV=\"{}\",FP_PID=\"{}\",FP_FL=\"{}\",FP_LN=\"{}\"",
                chrono::Local::now().format("%Y-%m-%d %T,%3f"),
                env!("CARGO_PKG_NAME"),
                env!("CARGO_PKG_VERSION"),
                std::process::id(),
                file,
                line,
            )
        }));
    });
}

/// Fills buffer with random numbers
pub fn genRandom(out: &mut [u8], length: usize) {
    let mut rng = rand::thread_rng();
    rng.fill(&mut out[0..length]);
}

////////////////////////////////////////////////////////////////////////////////
// Input Parsing and Verification Functions
////////////////////////////////////////////////////////////////////////////////

/// Performs any custom input json top-level parsing operations
pub fn parseOperationsCustom(json: &Value, root: &mut Map<String, Value>) -> Result<()> {
    if let Some(rootObj) = json[extension_constants::FAIRPLAY_STREAMING_REQUEST_STR].as_object() {
        *root = rootObj.clone();
    } else {
        returnErrorStatus!(FPSStatus::paramErr);
    }
    Ok(())
}

/// Performs custom parsing of account info JSON input.
///
/// Use this function to handle any values outside of what the Base code parses
/// for json input `offline-hls`.
pub fn parseOfflineHLSCustom(_ckcObj: &serde_jsonrc::Map<String, Value>, _assetInfo: &mut AssetInfo) -> Result<()> {
    Ok(())
}

/// Performs custom verification of account info JSON input.
pub fn verifyOfflineHLSCustom(_assetInfo: &mut AssetInfo) -> Result<()> {
    Ok(())
}

/// Performs custom parsing of `hdcp-type` JSON input.
///
/// Use this function to handle any values outside of what the Base code parses.
pub fn parseHDCPTypeCustom(_hdcpType: i32) -> Result<u64> {
    // Base code already handled all known values. Treat unknown values as an error.
    Err(FPSStatus::paramErr)
}

/// Performs parsing of any custom fields within the `asset-info` object of the input JSON
pub fn parseAssetInfoCustom(assetInfoObj: &Value, assetInfo: &mut AssetInfo) -> Result<()> {
    // Parse "content-type" from input json
    if let Some(contentType) = assetInfoObj[extension_constants::CONTENT_TYPE_STR].as_str() {
        match contentType {
            extension_constants::CONTENT_TYPE_UHD_STR => {
                assetInfo.extension.contentType = ContentType::uhd;
            }
            extension_constants::CONTENT_TYPE_HD_STR => {
                assetInfo.extension.contentType = ContentType::hd;
            }
            extension_constants::CONTENT_TYPE_SD_STR => {
                assetInfo.extension.contentType = ContentType::sd;
            }
            extension_constants::CONTENT_TYPE_AUDIO_STR => {
                assetInfo.extension.contentType = ContentType::audio;
            }
            _ => {
                assetInfo.extension.contentType = ContentType::unknown;
            }
        }
    } else {
        assetInfo.extension.contentType = ContentType::unknown;
    }

    Ok(())
}

/// Performs parsing of any custom fields within the `create-ckc` object of the input JSON
pub fn parseCreateCKCOperationCustom(
    _fpsOperation: &mut FPSOperation,
    _ckcObj: &Value,
    _root: &mut &Map<String, Value>,
) -> Result<()> {
    Ok(())
}

/// Performs any remaining parsing of the top level input JSON after FPSOperation structure has been filled
pub fn processOperationsCustom(
    _json: &Value,
    _output: &mut Value,
    _fpsOperations: &FPSOperations,
    _fpsResults: &mut FPSResults,
) -> Result<()> {
    Ok(())
}

// Custom handling inside createResults() if needed
pub fn createResultsCustom(_fpsOperation: &mut FPSOperation, _keyTypeRequested: &mut u32) -> Result<()> {
    Ok(())
}

/// Decrypts `spcContainer.aesWrappedKey` into `aesKey`.
///
/// Uses partner-specific private key for the RSA decyrption.
pub fn decryptKeyRSACustom(spcContainer: &mut FPSServerSPCContainer, aesKey: &mut Vec<u8>) -> Result<()> {
    let mut keyPem: Vec<u8> = Default::default();
    let aesWrappedKeySize = spcContainer.aesWrappedKeySize;
    let aesWrappedKey: &Vec<u8> = &spcContainer.aesWrappedKey;

    // Sanity check inputs
    requireAction!(!aesWrappedKey.is_empty(), return Err(FPSStatus::paramErr));

    SDKExtension::getPrivateKey(spcContainer, &mut keyPem)?;

    let result = openssl::rsa::Rsa::private_key_from_pem(keyPem.as_slice());
    if result.is_err() {
        fpsLogError!(
            FPSStatus::internalErr,
            "Unable to load private key: {}",
            result.unwrap_err()
        );
        returnErrorStatus!(FPSStatus::internalErr);
    }
    let rsa = result.unwrap();

    *aesKey = vec![0_u8; rsa.size() as usize];

    if aesWrappedKeySize == base_constants::FPS_V1_WRAPPED_KEY_SZ {
        if rsa.private_decrypt(aesWrappedKey, aesKey, openssl::rsa::Padding::PKCS1_OAEP).is_err() {
            // If decryption failed, it is likely the data was encrypted for another key.
            fpsLogError!(FPSStatus::invalidCertificateErr, "RSA Decryption Failed");
            returnErrorStatus!(FPSStatus::invalidCertificateErr);
        }
    } else if aesWrappedKeySize == base_constants::FPS_V2_WRAPPED_KEY_SZ {
        let pkey = openssl::pkey::PKey::from_rsa(rsa).unwrap();

        let mut decrypter = openssl::encrypt::Decrypter::new(&pkey).unwrap();

        decrypter.set_rsa_padding(openssl::rsa::Padding::PKCS1_OAEP).unwrap();
        decrypter
            .set_rsa_mgf1_md(openssl::hash::MessageDigest::sha256())
            .unwrap();
        decrypter
            .set_rsa_oaep_md(openssl::hash::MessageDigest::sha256())
            .unwrap();

        // Get the length of the output buffer
        let bufferLen = decrypter.decrypt_len(aesWrappedKey).unwrap();
        let mut decoded = vec![0u8; bufferLen];

        // Decrypt the data
        if decrypter.decrypt(aesWrappedKey, &mut decoded).is_err() {
            // If decryption failed, it is likely the data was encrypted for another key.
            fpsLogError!(FPSStatus::invalidCertificateErr, "RSA Decryption Failed");
            returnErrorStatus!(FPSStatus::invalidCertificateErr);
        }

        *aesKey = decoded.to_vec();
    }

    Ok(())
}

/// Perform any custom steps needed directly after SPC decryption
pub fn decryptSPCDataCustom(_spc: &[u8], _spcContainer: &mut FPSServerSPCContainer) -> Result<()> {
    Ok(())
}

/// Performs parsing of any TLLVs not handled in Base
pub fn parseTLLVCustom(_tllv: &FPSServerTLLV, _value: &mut FPSServerSPCContainer) -> Result<()> {
    Ok(())
}

/// Performs any custom validation after all TLLVs have been parsed.
pub fn validateTLLVsCustom(_spcContainer: &mut FPSServerSPCContainer) -> Result<()> {
    Ok(())
}

/// Performs parsing of any capabilities flags not handled in Base
pub fn checkSupportedFeaturesCustom(_serverCtx: &mut FPSServerCtx) -> Result<()> {
    Ok(())
}

/// Performs validation of SPC after SPC data is parsed.
pub fn validateSPCCustom(fpsOperation: &mut FPSOperation, serverCtx: &mut FPSServerCtx) -> Result<()> {
    // Check that business rules are satisfied
    SDKExtension::checkBusinessRules(fpsOperation, serverCtx)
}

/// Optional query of database to get asset information.
///
/// If asset information is not passed in the JSON input, now is the time to use
/// the asset id found inside the request (`serverCtx.spcContainer.spcData.assetId`)
/// to query your database and fill in `fpsOperation.assetInfo`.
pub fn queryDatabaseCustom(_fpsOperation: &mut FPSOperation, _serverCtx: &mut FPSServerCtx) -> Result<()> {
    Ok(())
}

////////////////////////////////////////////////////////////////////////////////
// Output Creation Functions
////////////////////////////////////////////////////////////////////////////////

/// Populates `serverCtx.ckcContainer` and `fpsResult` structure with any custom fields that will be returned to the caller
pub fn populateResultsCustom(
    serverCtx: &mut FPSServerCtx,
    operation: &FPSOperation,
    _result: &mut FPSResult,
) -> Result<()> {
    // Copy content type to the server context
    serverCtx.extension.contentType = operation.assetInfo.extension.contentType;

    Ok(())
}

/// Adds Content Key payload TLLV and related data to the CKC container
pub fn createContentKeyPayloadCustom(
    serverCtx: &mut FPSServerCtx,
    keyTypeRequested: u32,
    fpsResult: &mut FPSResult,
) -> Result<()> {
    SDKExtension::createContentKeyPayloadCustomImpl(serverCtx, keyTypeRequested)?;

    // player HU
    fpsResult.hu = serverCtx.spcContainer.spcData.hu.to_owned();

    Ok(())
}

/// Fills version and IV of the CKC container
pub fn fillCKCContainerCustom(serverCtx: &mut FPSServerCtx) -> Result<()> {
    // Set the version
    serverCtx.ckcContainer.version = FairPlayStreamingVersion::v1 as u32; // currently, only V1 is supported

    // Generate the CKC container (AR) IV
    genRandom(&mut serverCtx.ckcContainer.aesKeyIV, 16);

    Ok(())
}

/// Populates hdcpInformationTag Tag
///
/// The base code does not add this tag to the CKC by default. It is up to the extension to add it here.
pub fn HDCPInformationTagPopulateCustom(serverCtx: &mut FPSServerCtx) -> Result<()> {
    SDKExtension::populateTagServerHDCPInformation(serverCtx)
}

/// Populates securityLevelTag Tag
///
/// The base code does not add this tag to the CKC by default. It is up to the extension to add it here.
pub fn securityLevelTagPopulateCustom(serverCtx: &mut FPSServerCtx) -> Result<()> {
    SDKExtension::populateTagSecurityLevel(serverCtx)
}

/// Populates any custom TLLVs
///
/// One of the TLLVs indicating license expiration should be populated here (if required),
/// because it is not done in Base.
pub fn serializeCKCDataCustom(serverCtx: &mut FPSServerCtx) -> Result<()> {
    // Construct and serialize either offline key tag or key duration tag
    let keyType: u32 = serverCtx.ckcContainer.ckcData.keyDuration.keyType;

    if serverCtx
        .spcContainer
        .spcData
        .spcDataParser
        .parsedTagValues
        .contains(&(FPSTLLVTagValue::mediaPlaybackStateTag as u64))
        && (keyType != FPSKeyDurationType::none as u32)
    {
        if ((keyType == FPSKeyDurationType::persistenceAndDuration as u32)
            || (keyType == FPSKeyDurationType::persistence as u32))
            && serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLV
        {
            Base::populateTagServerOfflineKey(serverCtx)?;
        } else {
            Base::populateTagServerKeyDuration(serverCtx)?;
        }
    }

    Ok(())
}

/// Populates Content ID for Offline Key TLLV V1
pub fn offlineKeyTagPopulateContentIDCustom(_serverCtx: &mut FPSServerCtx, offlineKeyTLLV: &mut Vec<u8>) -> Result<()> {
    // Just add 16B of zeros
    offlineKeyTLLV.append(&mut vec![0; 16]);

    Ok(())
}

/// Adds any custom items to `FPSResult` after CKC has been generated
pub fn finalizeResultsCustom(_serverCtx: &FPSServerCtx, _fpsResult: &mut FPSResult) -> Result<()> {
    Ok(())
}

/// Adds any custom fields to the 'create-ckc' object of the output JSON
pub fn serializeCreateCKCNodeCustom(_result: &FPSResult, _ckcNode: &mut Map<String, Value>) -> Result<()> {
    Ok(())
}

/// Packages `ckcNode` into final JSON output (required).
pub fn serializeResultsCustom(
    fpsResults: &FPSResults,
    ckcNode: Vec<Value>,
    jsonResults: &mut Map<String, Value>,
) -> Result<()> {
    let mut root = Map::new();

    root.insert(base_constants::CREATE_CKC_STR.to_string(), Value::Array(ckcNode));

    // Add into top level response object
    jsonResults.insert(
        extension_constants::FAIRPLAY_STREAMING_RESPONSE_STR.to_string(),
        Value::Object(root),
    );

    Ok(())
}

////////////////////////////////////////////////////////////////////////////////
// Creentials Functions
////////////////////////////////////////////////////////////////////////////////

impl SDKExtension {

    fn getCredentials(fileName : &str) -> Vec<u8> {
        // Open the file
        let filePath = CREDENTIALS_PATH.to_owned() + fileName;
        let path = Path::new(&filePath);
        std::fs::read(path).expect("Error while reading credentials")
    }

    /// Returns private key associated with either 1024 or 2048-bit certificate
    fn getPrivateKey(spcContainer: &FPSServerSPCContainer, keyPem: &mut Vec<u8>) -> Result<()> {
        match spcContainer.version {
            1 => {
                log::debug!("Dealing with RSA 1024-bit Certificate");
                *keyPem = Self::getCredentials(RSA_1024_PRIVATE_KEY_PEM);
            }
            2 => {
                log::debug!("Dealing with RSA 2048-bit Certificate");
                *keyPem = Self::getCredentials(RSA_2048_PRIVATE_KEY_PEM);
            }
            _ => {
                fpsLogError!(
                    FPSStatus::invalidCertificateErr,
                    "Unexpected SPC version: {}",
                    spcContainer.version
                );
                returnErrorStatus!(FPSStatus::invalidCertificateErr);
            }
        }

        Ok(())
    }

    /// Returns provisioning data
    pub fn getProvisioningData(provData: &mut Vec<u8>, provDataLength: &mut usize) -> Result<()> {
        *provData = Self::getCredentials(PROVISIONING_DATA);
        *provDataLength = provData.len();

        Ok(())
    }
}

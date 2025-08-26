//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//
import Foundation
import Crypto
import _CryptoExtras

////////////////////////////////////////////////////////////////////////////////
// Input Parsing and Verification Functions
////////////////////////////////////////////////////////////////////////////////

/// Performs custom parsing of account info JSON input.
///
/// Use this function to handle any values outside of what the Base code parses
/// for json input `offline-hls`.
public func parseOfflineHLSCustom(_ decoder: Decoder) throws {}

/// Performs custom verification of account info JSON input.
public func verifyOfflineHLSCustom(_ assetInfo: AssetInfo) throws {}

/// Performs custom parsing of `hdcp-type` JSON input.
///
/// Use this function to handle any values outside of what the Base code parses.
public func parseHDCPTypeCustom(_ hdcpType: Int32) throws -> base_constants.FPSHDCPRequirement {
  // Base code already handled all known values. Treat unknown values as an error.
  throw FPSStatus.paramErr
}

/// Performs parsing of any custom fields within the `asset-info` object of the input JSON
public func parseAssetInfoCustom(
  _ assetInfo: inout AssetInfo,
  _ decoder: Decoder
) throws {

  let values = try decoder.container(keyedBy: extension_constants.CodingKeys.self)

  // Parse "content-type" from input json
  let contentTypeInput = try values.decodeIfPresent(String.self, forKey: .contentType) ?? ""

  switch contentTypeInput {
  case extension_constants.CONTENT_TYPE_UHD_STR:
    assetInfo.ext.contentType = extension_constants.ContentType.uhd
  case extension_constants.CONTENT_TYPE_HD_STR:
    assetInfo.ext.contentType = extension_constants.ContentType.hd
  case extension_constants.CONTENT_TYPE_SD_STR:
    assetInfo.ext.contentType = extension_constants.ContentType.sd
  case extension_constants.CONTENT_TYPE_AUDIO_STR:
    assetInfo.ext.contentType = extension_constants.ContentType.audio
  default:
    assetInfo.ext.contentType = extension_constants.ContentType.unknown
  }
}

/// Performs parsing of any custom fields within the `create-ckc` object of the input JSON
public func parseCreateCKCOperationCustom(
  _ fpsOperation: inout FPSOperation,
  _ decoder: Decoder
) throws {}

/// Performs any remaining parsing of the top level input JSON after FPSOperation structure has been filled
public func processOperationsCustom(
  _ decoder: Decoder,
  _ output: inout String,
  _ fpsOperations: inout FPSOperations,
  _ fpsResults: inout FPSResults
) throws {}

// Custom handling inside createResults() if needed
public func createResultsCustom(
  _ fpsOperation: FPSOperation,
  _ keyTypeRequested: inout UInt32
) throws {}

/// Decrypts `spcContainer.aesWrappedKey` into `aesKey`.
///
/// Uses partner-specific private key for the RSA decyrption.
public func decryptKeyRSACustom(
  _ spcContainer: inout FPSServerSPCContainer, _ aesKey: inout [UInt8]
) throws {
  var keyPem: [UInt8] = [UInt8]()

  try getPrivateKeyCustom(spcContainer, &keyPem)

  let contents = String(bytes: keyPem, encoding: .utf8)!
  var key: Data = Data.init()
  let aesWrappedKey = spcContainer.aesWrappedKey

  do {
    if spcContainer.aesWrappedKeySize == base_constants.FPS_V1_WRAPPED_KEY_SZ {
      let pkey = try _RSA.Encryption.PrivateKey.init(unsafePEMRepresentation: contents)
      key = try pkey.decrypt(Data(aesWrappedKey), padding: _RSA.Encryption.Padding.PKCS1_OAEP)
    } else if spcContainer.aesWrappedKeySize == base_constants.FPS_V2_WRAPPED_KEY_SZ {
      let pkey = try _RSA.Encryption.PrivateKey.init(pemRepresentation: contents)
      key = try pkey.decrypt(Data(aesWrappedKey), padding: _RSA.Encryption.Padding.PKCS1_OAEP_SHA256)
    }
  } catch {
    // If decryption failed, it is likely the data was encrypted for another key.
    fpsLogError(
      FPSStatus.invalidCertificateErr,
      "RSA Decryption Failed: ",
      error.localizedDescription)

    throw returnErrorStatus(FPSStatus.invalidCertificateErr)
  }

  aesKey = [UInt8](key)
}

/// Perform any custom steps needed directly after SPC decryption
public func decryptSPCDataCustom(_ spc: [UInt8], _ spcContainer: inout FPSServerSPCContainer)
  throws
{}

/// Performs parsing of any TLLVs not handled in Base
public func parseTLLVCustom(_ tllv: FPSServerTLLV, _ value: inout FPSServerSPCContainer) throws {}

/// Performs any custom validation after all TLLVs have been parsed.
public func validateTLLVsCustom(_ spcContainer: inout FPSServerSPCContainer) throws {}

/// Performs parsing of any capabilities flags not handled in Base
public func checkSupportedFeaturesCustom(_ serverCtx: inout FPSServerCtx) throws {}

/// Performs validation of SPC after SPC data is parsed.
public func validateSPCCustom(
  _ fpsOperation: FPSOperation,
  _ serverCtx: inout FPSServerCtx
) throws {
  // Check that business rules are satisfied
  try SDKExtension.checkBusinessRules(fpsOperation, &serverCtx)
}

/// Optional query of database to get asset information.
///
/// If asset information is not passed in the JSON input, now is the time to use
/// the asset id found inside the request (`serverCtx.spcContainer.spcData.assetId`)
/// to query your database and fill in `fpsOperation.assetInfo`.
public func queryDatabaseCustom(_ fpsOperation: FPSOperation, _ serverCtx: inout FPSServerCtx) throws {}

////////////////////////////////////////////////////////////////////////////////
// Output Creation Functions
////////////////////////////////////////////////////////////////////////////////

/// Populates `serverCtx.ckcContainer` and `fpsResult` structure with any custom fields that will be returned to the caller
public func populateResultsCustom(
  _ serverCtx: inout FPSServerCtx,
  _ operation: FPSOperation,
  _ result: inout FPSResult
) throws {
  // Copy content type to the server context
  serverCtx.ext.contentType = operation.assetInfo.ext.contentType
}

/// Adds Content Key payload TLLV and related data to the CKC container
public func createContentKeyPayloadCustom(
  _ serverCtx: inout FPSServerCtx,
  _ keyTypeRequested: UInt32,
  _ fpsResult: inout FPSResult
) throws {
  try SDKExtension.createContentKeyPayloadCustomImpl(&serverCtx, keyTypeRequested)

  // player HU
  fpsResult.hu = serverCtx.spcContainer.spcData.hu
}

/// Fills version and IV of the CKC container
public func fillCKCContainerCustom(_ serverCtx: inout FPSServerCtx) throws {
  // Set the version
  serverCtx.ckcContainer.version = base_constants.FairPlayStreamingVersion.v1.rawValue  // currently, only V1 is supported

  // Generate the CKC container (AR) IV
  genRandom(&serverCtx.ckcContainer.aesKeyIV, 16)
}

/// Populates hdcpInformationTag Tag
///
/// The base code does not add this tag to the CKC by default. It is up to the extension to add it here.
public func HDCPInformationTagPopulateCustom(_ serverCtx: inout FPSServerCtx) throws {
  try SDKExtension.populateTagServerHDCPInformation(&serverCtx)
}

/// Populates securityLevelTag Tag
///
/// The base code does not add this tag to the CKC by default. It is up to the extension to add it here.
public func securityLevelTagPopulateCustom(_ serverCtx: inout FPSServerCtx) throws {
  try SDKExtension.populateTagSecurityLevel(&serverCtx)
}

/// Populates any custom TLLVs
///
/// One of the TLLVs indicating license expiration should be populated here (if required),
/// because it is not done in Base.
public func serializeCKCDataCustom(_ serverCtx: inout FPSServerCtx) throws {
  // Construct and serialize either offline key tag or key duration tag
  let keyType: UInt32 = serverCtx.ckcContainer.ckcData.keyDuration.keyType

  if serverCtx
    .spcContainer
    .spcData
    .spcDataParser
    .parsedTagValues
    .contains(base_constants.FPSTLLVTagValue.mediaPlaybackStateTag.rawValue)
    && (keyType != base_constants.FPSKeyDurationType.none.rawValue)
  {
    if ((keyType == base_constants.FPSKeyDurationType.persistenceAndDuration.rawValue)
      || (keyType == base_constants.FPSKeyDurationType.persistence.rawValue))
      && serverCtx.spcContainer.spcData.clientFeatures.supportsOfflineKeyTLLV
    {
      try Base.populateTagServerOfflineKey(&serverCtx)
    } else {
      try Base.populateTagServerKeyDuration(&serverCtx)
    }
  }
}

/// Populates Content ID for Offline Key TLLV V1
public func offlineKeyTagPopulateContentIDCustom(
  _ serverCtx: inout FPSServerCtx,
  _ offlineKeyTLLV: inout [UInt8]
) throws {
  // Just add 16B of zeros
  offlineKeyTLLV.append(contentsOf: [UInt8](repeating: 0, count: 16))
}

/// Adds any custom items to `FPSResult` after CKC has been generated
public func finalizeResultsCustom(
  _ serverCtx: FPSServerCtx,
  _ fpsResult: inout FPSResult
) throws {}

/// Adds any custom fields to the 'create-ckc' object of the output JSON
public func serializeCKCNodeCustom(encoder: Encoder) throws {}

/// Packages `ckcNode` into final JSON output (required).
public func serializeResultsCustom(encoder: Encoder) throws {}

////////////////////////////////////////////////////////////////////////////////
// Creentials Functions
////////////////////////////////////////////////////////////////////////////////

/// Returns private key associated with either 1024 or 2048-bit certificate
public func getPrivateKeyCustom(_ spcContainer: FPSServerSPCContainer, _ keyPem: inout [UInt8])
  throws
{
  switch spcContainer.version {
  case 1:
    Log.debug("Dealing with RSA 1024-bit Certificate")
    keyPem = try getCredentialFileContents(fileName:credentials.RSA_1024_PRIVATE_KEY_PEM)
  case 2:
    Log.debug("Dealing with RSA 2048-bit Certificate")
    keyPem = try getCredentialFileContents(fileName:credentials.RSA_2048_PRIVATE_KEY_PEM)
  default:
    fpsLogError(FPSStatus.invalidCertificateErr, "Unexpected SPC version: \(spcContainer.version)")
    throw returnErrorStatus(FPSStatus.invalidCertificateErr)
  }
}

/// Returns provisioning data
public func getProvisioningData(_ provData: inout [UInt8], _ provDataLength: inout Int) throws {
  provData = try getCredentialFileContents(fileName:credentials.PROVISIONING_DATA)
  provDataLength = provData.count
}

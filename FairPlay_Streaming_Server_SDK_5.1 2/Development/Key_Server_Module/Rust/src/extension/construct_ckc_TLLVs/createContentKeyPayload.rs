//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

use crate::base::base_constants::{
    KSMKeyPayloadContentType, AES128_IV_SZ, AES128_KEY_SZ, FPS_KEY_PAYLOAD_STRUCT_VERSION, FPS_V1_HASH_SZ, FPS_V1_R1_SZ,
};
use crate::base::structures::base_fps_structures::KSMKeyPayload;
use crate::base::structures::base_server_structures::FPSServerCtx;
use crate::extension::extension_constants::{ContentType, FPSKeyFormatTag};
use crate::validate::Result;
use crate::{fpsLogError, returnErrorStatus, FPSStatus, SDKExtension};

pub const FPS_CONTENT_KEY_TLLV_MAX_PAYLOAD: u32 = 1024;

extern "C" {
    pub fn KSMCreateKeyPayload(keyPayload: &mut KSMKeyPayload) -> FPSStatus;
}

impl SDKExtension {
    /// Calls cryptographic library to generate content key payload
    pub fn createContentKeyPayloadCustomImpl(serverCtx: &mut FPSServerCtx, _keyTypeRequested: u32) -> Result<()> {
        let mut provData: Vec<u8> = Default::default();
        let mut provDataLength: usize = 0;

        // Get provisioning data
        SDKExtension::getProvisioningData(&mut provData, &mut provDataLength)?;

        // Older devices may not send this information so default to 16 byte key
        if serverCtx.spcContainer.spcData.numberOfSupportedKeyFormats == 0 {
            serverCtx.spcContainer.spcData.numberOfSupportedKeyFormats = 1;
            serverCtx.spcContainer.spcData.supportedKeyFormats[0] = FPSKeyFormatTag::buf16Byte as u64;
        }

        // Convert from our custom ContentType to KSMKeyPayloadContentType
        let ksmKeyPayloadContentType: KSMKeyPayloadContentType = match serverCtx.extension.contentType {
            ContentType::uhd | ContentType::hd | ContentType::sd => KSMKeyPayloadContentType::video,
            ContentType::audio => KSMKeyPayloadContentType::audio,
            _ => KSMKeyPayloadContentType::unknown
        };

        let mut r1 = vec![0_u8; FPS_V1_R1_SZ];

        serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload = vec![0_u8; FPS_CONTENT_KEY_TLLV_MAX_PAYLOAD as usize];

        unsafe {
            let mut keyPayload = KSMKeyPayload {
                version: FPS_KEY_PAYLOAD_STRUCT_VERSION,
                contentKey: serverCtx.ckcContainer.ckcData.ck.as_ptr(),
                contentKeyLength: AES128_KEY_SZ as u64,
                contentIV: serverCtx.ckcContainer.ckcData.iv.as_ptr(),
                contentIVLength: AES128_IV_SZ as u64,
                contentType: ksmKeyPayloadContentType as u64,
                SK_R1: serverCtx.spcContainer.spcData.skR1.as_ptr(),
                SK_R1Length: serverCtx.spcContainer.spcData.skR1.len() as u64,
                R2: serverCtx.spcContainer.spcData.r2.as_ptr(),
                R2Length: serverCtx.spcContainer.spcData.r2.len() as u64,
                R1Integrity: serverCtx.spcContainer.spcData.skR1IntegrityTag.as_ptr(),
                R1IntegrityLength: serverCtx.spcContainer.spcData.skR1IntegrityTag.len() as u64,
                supportedKeyFormats: serverCtx.spcContainer.spcData.supportedKeyFormats.as_ptr(),
                numberOfSupportedKeyFormats: serverCtx.spcContainer.spcData.numberOfSupportedKeyFormats as u64,
                cryptoVersionUsed: serverCtx.spcContainer.spcData.versionUsed as u64,
                provisioningData: provData.as_ptr(),
                provisioningDataLength: provDataLength as u64,
                certHash: serverCtx.spcContainer.certificateHash.as_ptr(),
                certHashLength: FPS_V1_HASH_SZ as u64,
                clientHU: serverCtx.spcContainer.spcData.hu.as_mut_ptr(),
                clientHULength: serverCtx.spcContainer.spcData.hu.len() as u64,
                contentKeyTLLVTag: serverCtx.ckcContainer.ckcData.contentKeyTLLVTag,
                contentKeyTLLVPayload: serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload.as_mut_ptr(),
                contentKeyTLLVPayloadLength: serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload.len() as u64,
                R1: r1.as_mut_ptr(),
                R1Length: r1.len() as u64,
            };
            // Call to precompiled cryptographic library
            let status = KSMCreateKeyPayload(&mut keyPayload);

            // These returned values have type UInt64 instead of pointer, so copy out of the structure
            serverCtx.ckcContainer.ckcData.contentKeyTLLVTag = keyPayload.contentKeyTLLVTag;
            serverCtx
                .ckcContainer
                .ckcData
                .contentKeyTLLVPayload
                .resize(keyPayload.contentKeyTLLVPayloadLength as usize, 0);

            if status != FPSStatus::noErr {
                fpsLogError!(status, "KSMCreateKeyPayload failed");
                returnErrorStatus!(status);
            }
        }

        if serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload.len() <= AES128_KEY_SZ {
            returnErrorStatus!(FPSStatus::internalErr);
        }

        // Store R1 returned from the crypto lib
        serverCtx.ckcContainer.ckcData.r1 = r1.to_vec();

        Ok(())
    }
}

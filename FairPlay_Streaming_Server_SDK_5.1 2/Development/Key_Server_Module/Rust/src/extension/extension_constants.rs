//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

// Strings for output JSON
pub const FAIRPLAY_STREAMING_REQUEST_STR: &str = "fairplay-streaming-request";
pub const FAIRPLAY_STREAMING_RESPONSE_STR: &str = "fairplay-streaming-response";

pub const CONTENT_TYPE_STR: &str = "content-type";
pub const CONTENT_TYPE_UHD_STR: &str = "uhd";
pub const CONTENT_TYPE_HD_STR: &str = "hd";
pub const CONTENT_TYPE_SD_STR: &str = "sd";
pub const CONTENT_TYPE_AUDIO_STR: &str = "audio";

/// FairPlay Streaming Version
pub enum FairPlayStreamingVersion {
    v1 = 1,
}

/// FairPlay Streaming Key Formats
#[repr(u64)]
pub enum FPSKeyFormatTag {
    buf16Byte = 0x58b38165af0e3d5a,
}

/// Content Types
#[derive(Debug, Default, Clone, Copy)]
#[allow(dead_code)]
pub enum ContentType {
    #[default]
    unknown,
    audio,
    sd,
    hd,
    uhd,
}

/// FairPlay Security Levels (sent in SPC and CKC)
///
/// Values are ordered so comparisions are possible
#[derive(Debug, Default, Clone, Copy)]
#[repr(u64)]
pub enum FPSSecurityLevel {
    audio = 0x17d99d574eed567d,
    baseline = 0x32f0004966a5c4f8,
    #[default]
    main = 0x4e7fd92421d588b4,
}

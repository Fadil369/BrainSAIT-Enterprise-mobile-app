//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

use crate::extension::extension_constants::ContentType;
use crate::extension::extension_constants::FPSSecurityLevel;
use std::fmt::Debug;

#[derive(Debug, Default, Clone)]
pub struct SDKExtension {}

#[derive(Debug, Default, Clone)]
pub struct FPSOperationExtension {}

#[derive(Debug, Default, Clone)]
pub struct AssetInfoExtension {
    pub contentType: ContentType,
}

#[derive(Debug, Default, Clone)]
pub struct ServerCtxExtension {
    pub contentType: ContentType,
}

#[derive(Debug, Default, Clone)]
pub struct FPSResultsExtension {}

#[derive(Debug, Default, Clone)]
pub struct FPSResultExtension {}

#[derive(Debug, Default, Clone)]
pub struct SPCDataExtension {}

#[derive(Debug, Default, Clone)]
pub struct CKCDataExtension {
    pub requiredSecurityLevel: FPSSecurityLevel,
}

#[derive(Debug, Default, Clone)]
pub struct SPCContainerExtension {}

#[derive(Debug, Default, Clone)]
pub struct ClientFeaturesExtension {}

#[derive(Debug, Default, Clone)]
pub struct KeyDurationExtension {}

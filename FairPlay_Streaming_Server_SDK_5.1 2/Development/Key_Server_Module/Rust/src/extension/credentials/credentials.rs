//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

pub const CREDENTIALS_PATH: &str = "src/extension/credentials/";

// **********************************************************************************************
// RSA 1024-bit Private Key (PEM format)
// **********************************************************************************************

#[cfg(feature = "test_credentials")]
pub const RSA_1024_PRIVATE_KEY_PEM: &str = "test_priv_key_1024.pem";

#[cfg(not(feature = "test_credentials"))]
pub const RSA_1024_PRIVATE_KEY_PEM: &str = "priv_key_1024.pem";

// **********************************************************************************************
// RSA 2048-bit Private Key (PEM format)
// **********************************************************************************************

#[cfg(feature = "test_credentials")]
pub const RSA_2048_PRIVATE_KEY_PEM: &str = "test_priv_key_2048.pem";

#[cfg(not(feature = "test_credentials"))]
pub const RSA_2048_PRIVATE_KEY_PEM: &str = "priv_key_2048.pem";

// **********************************************************************************************
// Provisioning Data (binary format)
// **********************************************************************************************

#[cfg(feature = "test_credentials")]
pub const PROVISIONING_DATA: &str = "test_provisioning_data.bin";

#[cfg(not(feature = "test_credentials"))]
pub const PROVISIONING_DATA: &str = "provisioning_data.bin";
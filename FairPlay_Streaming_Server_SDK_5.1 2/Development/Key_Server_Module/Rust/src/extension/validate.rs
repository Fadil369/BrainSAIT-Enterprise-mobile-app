//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

/// Checks the `condition`. If false, logs failure and performs `action`.
#[macro_export]
macro_rules! requireAction {
    ($condition: expr, $action: expr) => {
        if !$condition {
            log::debug!(
                "❌ Assertion failure: {} [{}:{}]",
                stringify!($condition),
                file!(),
                line!()
            );
            // We don't have an error code. Use -1 so that it shows up if we filter out 0.
            $crate::fpsLogError!(-1, "Assertion failure: {}", stringify!($condition));
            $action;
        }
    };
}

/// Logs and returns error status.
#[macro_export]
macro_rules! returnErrorStatus {
    ($err: expr) => {
        log::debug!("❌ Returning error: {:?} ({}) [{}:{}]", $err, $err, file!(), line!());
        return Err($err);
    };
}

pub type Result<T> = std::result::Result<T, FPSStatus>;

/// Error codes used by FairPlay Streaming.
#[repr(C)] // This type is used as a return from unsafe functions
#[derive(Debug, PartialEq, Clone, Copy)]
pub enum FPSStatus {
    noErr = 0,
    spcVersionErr = -42580,
    parserErr = -42581,
    missingRequiredTagErr = -42583,
    paramErr = -42585,
    memoryErr = -42586,
    versionErr = -42590,
    dupTagErr = -42591,
    internalErr = -42601,
    clientSecurityLevelErr = -42604,
    invalidCertificateErr = -42605,
    notImplementedErr = -42612,
}

impl std::fmt::Display for FPSStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", *self as i32)
    }
}

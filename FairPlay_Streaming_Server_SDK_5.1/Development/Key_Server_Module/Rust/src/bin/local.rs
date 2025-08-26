//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

#![allow(nonstandard_style)] // Prevents renaming many variables

use fpssdk::base::base_constants;
use fpssdk::base::structures::base_fps_structures::Base;
use fpssdk::extension::extension_constants;
use fpssdk::extension::validate::{FPSStatus, Result};
use fpssdk::fpsLogError;
use serde_jsonrc::Value;
use std::env;
use std::fs::File;
use std::panic;
use std::path::Path;

fn main() -> Result<()> {
    launch_process()?;

    Ok(())
}

fn launch_process() -> Result<Value> {
    let result = panic::catch_unwind(|| -> Result<Value> {
        let mut _status: FPSStatus = FPSStatus::noErr;
        let args: Vec<String> = env::args().collect();

        let jsonFilePath: &Path;

        if args.len() > 1 {
            jsonFilePath = Path::new(&args[1]);
        } else {
            println!("Error: Input json file not provided");
            return Err(FPSStatus::paramErr);
        }

        let file = File::open(jsonFilePath).expect("file not found");

        let mut output: Value = Default::default();

        let root = Base::parseRootFromJson(file);
        Base::processOperations(root, &mut output)?;

        println!("{}", output);
        Ok(output)
    });

    if result.is_err() {
        // Manually create and return a fixed json indicating failure.
        let json_fail = serde_jsonrc::json!({ extension_constants::FAIRPLAY_STREAMING_RESPONSE_STR: { base_constants::CREATE_CKC_STR :[{base_constants::ID_STR :1,base_constants::STATUS_STR:FPSStatus::internalErr as i32}]}});
        println!("Rust panic!!");
        println!("{}", json_fail);
        fpsLogError!(FPSStatus::internalErr, "fpssdk panic: {:?}", result.unwrap_err());
        Ok(json_fail)
    } else {
        result.unwrap()
    }
}

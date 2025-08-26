//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//
import Foundation

public func getCredentialFileContents(fileName : String) throws -> [UInt8] {
  var data: Data = Data()

  let credentialsPath: String

  // If environment variable `FPS_CREDENTIALS_PATH` is set, use that as the path
  if let envVariable = ProcessInfo.processInfo.environment["FPS_CREDENTIALS_PATH"] {
    credentialsPath = envVariable
  } else {
    // Otherwise, assume we are running from the project root
    credentialsPath = (ProcessInfo.processInfo.environment["PWD"] ?? ".") + "/Sources/src/extension/credentials"
  }

  let fileURLWithPath = credentialsPath + "/" + fileName

  do {
    data = try Data(contentsOf: URL(fileURLWithPath: fileURLWithPath), options: .mappedIfSafe)
  } catch {
    fpsLogError(FPSStatus.invalidCertificateErr, "Error while reading credentials file: \(fileURLWithPath): \(error)")
    throw FPSStatus.invalidCertificateErr
  }

  Log.debug("Loaded file: \(fileURLWithPath)")
  return [UInt8](data)
}

struct credentials {

  // **********************************************************************************************
  // RSA 1024-bit Private Key (PEM format)
  // **********************************************************************************************

  #if test_credentials
  static let RSA_1024_PRIVATE_KEY_PEM: String = "test_priv_key_1024.pem"
  #else
  static let RSA_1024_PRIVATE_KEY_PEM: String = "priv_key_1024.pem"
  #endif

  // **********************************************************************************************
  // RSA 2048-bit Private Key (PEM format)
  // **********************************************************************************************

  #if test_credentials
  static let RSA_2048_PRIVATE_KEY_PEM: String = "test_priv_key_2048.pem"
  #else
  static let RSA_2048_PRIVATE_KEY_PEM: String = "priv_key_2048.pem"
  #endif

  // **********************************************************************************************
  // Provisioning Data (binary format)
  // **********************************************************************************************

  #if test_credentials
  static let PROVISIONING_DATA: String = "test_provisioning_data.bin"
  #else
  static let PROVISIONING_DATA: String = "provisioning_data.bin"
  #endif

}
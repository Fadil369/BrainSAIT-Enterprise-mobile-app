//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//
import Foundation
import Crypto
import _CryptoExtras

extension Base {
  /// Encrypt or decrypt input using AES
  ///
  /// Supports both ECB and CBC modes.
  public static func encryptDecryptWithAES(
    _ input: [UInt8],
    _ key: [UInt8],
    _ iv: [UInt8],
    _ opMode: base_constants.AESEncryptionMode,
    _ opCipher: base_constants.AESEncryptionCipher,
    _ output: inout [UInt8]
  ) throws {
    var aes_iv = try AES._CBC.IV.init(ivBytes: Array(repeating: 0, count: base_constants.AES128_IV_SZ))
    var data = Data.init()

    switch opCipher {
    case base_constants.AESEncryptionCipher.aesCBC:
      try requireAction(!input.isEmpty, { throw FPSStatus.paramErr })
      try requireAction(
        input.count % base_constants.AES128_BLOCK_SIZE == 0, { throw FPSStatus.paramErr })
      try requireAction(key.count == base_constants.AES128_KEY_SZ, { throw FPSStatus.paramErr })
      try requireAction(iv.count == base_constants.AES128_IV_SZ, { throw FPSStatus.paramErr })

      aes_iv = try AES._CBC.IV.init(ivBytes: iv)

    case base_constants.AESEncryptionCipher.aesECB:
      try requireAction(
        input.count == base_constants.AES128_BLOCK_SIZE, { throw FPSStatus.paramErr })
      try requireAction(key.count == base_constants.AES128_KEY_SZ, { throw FPSStatus.paramErr })
    // IV can be empty
    }

    switch opMode {
    case base_constants.AESEncryptionMode.aesEncrypt:
      data = try AES._CBC.encrypt(input, using: SymmetricKey(data: key), iv: aes_iv, noPadding: true)

    case base_constants.AESEncryptionMode.aesDecrypt:
      data = try AES._CBC.decrypt(input, using: SymmetricKey(data: key), iv: aes_iv, noPadding: true)
    }

    output = []
    data.withUnsafeBytes {
      output.append(contentsOf: $0)
    }

  }
}

//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//
import Foundation

import Crypto

extension Base {
  /// Serializes and encrypts the TLLVs into a CKC container
  public static func generateCKC(_ serverCtx: inout FPSServerCtx) throws {
    // Prepare the CKC container
    try fillCKCContainerCustom(&serverCtx)

    // Serialize CKC data
    try serializeCKCData(&serverCtx)

    var key: [UInt8] = [UInt8]()
    // Derive encryption key from anti replay seed and R1
    try deriveAntiReplayKey(
      arSeed: serverCtx.spcContainer.spcData.antiReplay,
      R1: serverCtx.ckcContainer.ckcData.r1,
      ek: &key
    )

    // Encrypt the CKC using the anti replay key
    try encryptCKCData(ckcContainer: &serverCtx.ckcContainer, key: key)

    // Serialize the CKC container
    try serializeCKCContainer(ckcContainer: &serverCtx.ckcContainer)
  }

  /// Derives anti-replay key used to encrypt the CKC
  public static func deriveAntiReplayKey(arSeed: [UInt8], R1: [UInt8], ek: inout [UInt8]) throws {

    try requireAction(!arSeed.isEmpty, { throw FPSStatus.paramErr })
    try requireAction(!R1.isEmpty, { throw FPSStatus.paramErr })

    // Log.debug("R1: 0x\(R1.map { String(format: "%02x", $0) }.joined())")

    var sha1 = Insecure.SHA1.init()
    sha1.update(data: R1)
    let hashOfR1 = sha1.finalize()

    // Log.debug("hashOfR1: 0x\(hashOfR1.map { String(format: "%02x", $0) }.joined())")
    // Log.debug("arSeed: 0x\(arSeed.map { String(format: "%02x", $0) }.joined())")

    let tmp: [UInt8] = hashOfR1.map { $0 }
    var ciphertext: [UInt8] = []
    try encryptDecryptWithAES(
      arSeed, Array(tmp[...15]), [],
      base_constants.AESEncryptionMode.aesEncrypt,
      base_constants.AESEncryptionCipher.aesECB, &ciphertext)

    ek = ciphertext

    // Log.debug("AntiReplay Key: 0x\(ek.map { String(format: "%02x", $0) }.joined())")
  }

  /// Encrypts CKC data
  public static func encryptCKCData(ckcContainer: inout FPSServerCKCContainer, key: [UInt8]) throws {

    var tempCKC: [UInt8] = []

    try encryptDecryptWithAES(
      ckcContainer.ckcDataPtr, key, ckcContainer.aesKeyIV,
      base_constants.AESEncryptionMode.aesEncrypt, base_constants.AESEncryptionCipher.aesCBC,
      &tempCKC)

    // Replace original data with the encrypted version
    ckcContainer.ckcDataPtr = tempCKC

  }

  /// Serialize CKC container with version, IV, data size, and payload
  public static func serializeCKCContainer(ckcContainer: inout FPSServerCKCContainer) throws {
    var localCKC: [UInt8] = []

    // 4B Version
    localCKC.appendBigEndianU32(ckcContainer.version)

    // 4B Reserved
    var reserved : UInt32 = 0
    try reportServerInformation(reserved: &reserved)
    localCKC.appendBigEndianU32(reserved)

    // 16B IV
    try requireAction(
      ckcContainer.aesKeyIV.count == base_constants.AES128_IV_SZ, { throw FPSStatus.paramErr })
    localCKC += ckcContainer.aesKeyIV

    // CKC Data size
    localCKC.appendBigEndianU32(UInt32(ckcContainer.ckcDataPtr.count))

    // CKC Data
    localCKC += ckcContainer.ckcDataPtr

    ckcContainer.ckc = localCKC
  }

  public static func reportServerInformation(reserved: inout UInt32) throws {
    var reserved_bits: UInt32 = 0

    // Platform information
    var platform : UInt32 = 0
    #if arch(x86_64)
      platform = 1
    #elseif arch(arm64)
      platform = 2
    #endif

    // Language (Swift = 1, Rust = 2)
    let language : UInt32 = 1;

    // Project version
    var major : UInt32 = 0;
    var minor : UInt32 = 0;

    let versionComponents = Version.number.split(separator: ".")
    if versionComponents.count >= 2 {
        major = UInt32(versionComponents[0]) ?? 0
        minor = UInt32(versionComponents[1]) ?? 0
    }

     reserved_bits |= major; // 7 bits

     reserved_bits <<= 4;
     reserved_bits |= minor; // 4 bits

     reserved_bits <<= 2;
     reserved_bits |= language; // 2 bits

     reserved_bits <<= 3;
     reserved_bits |= platform; // 3 bits

    reserved = reserved_bits
  }
}

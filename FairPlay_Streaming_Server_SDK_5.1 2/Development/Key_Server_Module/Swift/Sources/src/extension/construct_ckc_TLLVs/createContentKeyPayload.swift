//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

import prebuilt

public let FPS_CONTENT_KEY_TLLV_MAX_PAYLOAD: Int = 1024

extension SDKExtension {
  /// Calls cryptographic library to generate content key payload
  public static func createContentKeyPayloadCustomImpl(
    _ serverCtx: inout FPSServerCtx,
    _ keyTypeRequested: UInt32
  ) throws {
    var provData: [UInt8] = [UInt8]()
    var provDataLength: Int = 0

    // Get provisioning data
    try getProvisioningData(&provData, &provDataLength)

    // Older devices may not send this information so default to 16 byte key
    if serverCtx.spcContainer.spcData.numberOfSupportedKeyFormats == 0 {
      serverCtx.spcContainer.spcData.numberOfSupportedKeyFormats = 1
      serverCtx.spcContainer.spcData.supportedKeyFormats[0] =
        extension_constants.FPSKeyFormatTag.buf16Byte.rawValue
    }

    serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload = [UInt8](
      repeating: 0, count: FPS_CONTENT_KEY_TLLV_MAX_PAYLOAD)

    // Convert from our custom ContentType to KSMKeyPayloadContentType
    let ksmKeyPayloadContentType: base_constants.KSMKeyPayloadContentType
    switch serverCtx.ext.contentType {
    case extension_constants.ContentType.uhd, extension_constants.ContentType.hd, extension_constants.ContentType.sd:
      ksmKeyPayloadContentType = .video
    case extension_constants.ContentType.audio:
      ksmKeyPayloadContentType = .audio
    default:
      ksmKeyPayloadContentType = .unknown
    }

    var r1: [UInt8] = [UInt8](repeating: 0, count: base_constants.FPS_V1_R1_SZ)
    var contentKeyTLLVPayloadLength: Int = serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload
      .count
    var status: Int32 = 0

    serverCtx.ckcContainer.ckcData.ck.withUnsafeBufferPointer { ckPointer in
      serverCtx.ckcContainer.ckcData.iv.withUnsafeBufferPointer { ivPointer in
        serverCtx.spcContainer.spcData.skR1.withUnsafeBufferPointer { skR1Pointer in
          serverCtx.spcContainer.spcData.r2.withUnsafeBufferPointer { r2Pointer in
            serverCtx.spcContainer.spcData.skR1IntegrityTag.withUnsafeBufferPointer {
              skR1IntegrityTagPointer in
              serverCtx.spcContainer.spcData.supportedKeyFormats.withUnsafeBufferPointer {
                supportedKeyFormatsPointer in
                provData.withUnsafeBufferPointer { provDataPointer in
                  serverCtx.spcContainer.certificateHash.withUnsafeBufferPointer {
                    certificateHashPointer in
                    serverCtx.spcContainer.spcData.hu.withUnsafeMutableBufferPointer { huPointer in
                      serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload
                        .withUnsafeMutableBufferPointer { contentKeyTLLVPayloadPointer in
                          r1.withUnsafeMutableBufferPointer { r1Pointer in

                            var keyPayload = KSMKeyPayload(
                              version: base_constants.FPS_KEY_PAYLOAD_STRUCT_VERSION,
                              contentKey: ckPointer.baseAddress,
                              contentKeyLength: UInt64(base_constants.AES128_KEY_SZ),
                              contentIV: ivPointer.baseAddress,
                              contentIVLength: UInt64(base_constants.AES128_IV_SZ),
                              contentType: UInt64(ksmKeyPayloadContentType.rawValue),
                              SK_R1: skR1Pointer.baseAddress,
                              SK_R1Length: UInt64(serverCtx.spcContainer.spcData.skR1.count),
                              R2: r2Pointer.baseAddress,
                              R2Length: UInt64(serverCtx.spcContainer.spcData.r2.count),
                              R1Integrity: skR1IntegrityTagPointer.baseAddress,
                              R1IntegrityLength: UInt64(
                                serverCtx.spcContainer.spcData.skR1IntegrityTag.count),
                              supportedKeyFormats: supportedKeyFormatsPointer.baseAddress,
                              numberOfSupportedKeyFormats: UInt64(
                                serverCtx.spcContainer.spcData.numberOfSupportedKeyFormats),
                              cryptoVersionUsed: UInt64(serverCtx.spcContainer.spcData.versionUsed),
                              provisioningData: provDataPointer.baseAddress,
                              provisioningDataLength: UInt64(provDataLength),
                              certHash: certificateHashPointer.baseAddress,
                              certHashLength: UInt64(base_constants.FPS_V1_HASH_SZ),
                              clientHU: huPointer.baseAddress,
                              clientHULength: UInt64(huPointer.endIndex),
                              contentKeyTLLVTag: 0,
                              contentKeyTLLVPayload: contentKeyTLLVPayloadPointer.baseAddress,
                              contentKeyTLLVPayloadLength: UInt64(contentKeyTLLVPayloadLength),
                              R1: r1Pointer.baseAddress,
                              R1Length: UInt64(r1Pointer.endIndex)
                            )

                            // Call to precompiled cryptographic library
                            status = KSMCreateKeyPayload(&keyPayload)

                            // These returned values have type UInt64 instead of pointer, so copy out of the structure
                            serverCtx.ckcContainer.ckcData.contentKeyTLLVTag =
                              keyPayload.contentKeyTLLVTag
                            contentKeyTLLVPayloadLength = Int(
                              keyPayload.contentKeyTLLVPayloadLength)

                          }
                        }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    let error_status = FPSStatus(rawValue: Int(status))!
    if error_status != FPSStatus.noErr {
      fpsLogError(error_status, "KSMCreateKeyPayload failed")
      throw returnErrorStatus(error_status)
    }

    // Shorten size of contentKeyTLLVPayload to actual size returned
    serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload.removeLast(
      serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload.count - Int(contentKeyTLLVPayloadLength))

    if serverCtx.ckcContainer.ckcData.contentKeyTLLVPayload.count <= base_constants.AES128_KEY_SZ {
      throw returnErrorStatus(FPSStatus.internalErr)
    }

    // Store R1 returned from the crypto lib
    serverCtx.ckcContainer.ckcData.r1 = r1
  }
}

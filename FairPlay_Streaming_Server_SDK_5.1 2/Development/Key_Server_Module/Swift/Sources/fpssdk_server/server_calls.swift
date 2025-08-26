//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import Foundation
import src

/// Processes the operations specified in the input json.
///
/// The returned json must be disposed of with `fpsDisposeResponse`.
///
/// int fpsProcessOperations(const char *in_json, int in_json_size, char **out_json, int *out_json_size)
@_cdecl("fpsProcessOperations")
public func fpsProcessOperations(
  _ in_json: UnsafePointer<CChar>?,
  _ in_json_size: CInt,
  _ out_json: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
  _ out_json_size: UnsafeMutablePointer<CInt>?
) -> CInt {

  guard let inJsonPtr = in_json else {
    return CInt(FPSStatus.paramErr.rawValue)
  }
  guard let outJsonPtr = out_json else {
    return CInt(FPSStatus.paramErr.rawValue)
  }
  guard let outJsonSizePtr = out_json_size else {
    return CInt(FPSStatus.paramErr.rawValue)
  }

  // Initialize output
  outJsonPtr.pointee = nil
  outJsonSizePtr.pointee = 0

  // Read the input Json into a Data array
  let inJson = Data(bytes: inJsonPtr, count: Int(in_json_size))

  var outJson: String = ""

  do {
    do {
      let decoder = JSONDecoder()
      var base: Base = try decoder.decode(Base.self, from: inJson)
      try Base.processOperations(&base.fpsOperations, &outJson)
    } catch {
      // Something went wrong. Return an error result.
      var fpsError = FPSStatus.internalErr

      if let thrownFPSError = error as? FPSStatus {
        fpsError = thrownFPSError
        fpsLogError(fpsError, "fpssdk panic: \(fpsError.rawValue)")
      } else {
        fpsLogError(fpsError, "fpssdk panic: \(error)")
      }

      // Create FPSResults structure with one entry for the error code
      var fpsResults = FPSResults()
      var fpsResult = FPSResult()
      fpsResult.status = fpsError
      fpsResult.id = 1
      fpsResults.resultPtr.append(fpsResult)

      // Print encoded result as JSON
      let encoder = JSONEncoder()
      encoder.outputFormatting = encoder.outputFormatting.union(.sortedKeys)
      let data = try encoder.encode(fpsResults)
      outJson = String(data: data, encoding: .utf8)!
    }
  } catch {
    var status = FPSStatus.internalErr
    if let e = error as? FPSStatus {
      status = e
    }
    return CInt(status.rawValue)
  }

  // Convert to null-terminated C String
  outJson.withCString { outJsonCStr in
    let outBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: outJson.count+1)
    outBuffer.initialize(from: outJsonCStr, count: outJson.count+1)
    outJsonPtr.pointee = outBuffer
    outJsonSizePtr.pointee = CInt(outJson.count+1)
  }

  return CInt(FPSStatus.noErr.rawValue)
}

/// Disposes of the output json created by a call to `fpsProcessOperations`.
///
/// int fpsDisposeResponse(char *out_pay_load, int out_pay_load_sz)
@_cdecl("fpsDisposeResponse")
public func fpsDisposeResponse(
  _ outPayload: UnsafeMutablePointer<CChar>?,
  _ outPayloadSize: CInt
) -> CInt {
  guard let ptr = outPayload else {
    return CInt(FPSStatus.paramErr.rawValue)
  }

  ptr.deallocate()
  return CInt(FPSStatus.noErr.rawValue)
}

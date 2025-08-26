//
// base_parse_json_core.swift : Defines the mandatory functions inherited from the Core trait for the Base class.
//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

import Foundation

public func parseRootFromJson(_ file: String) -> Data {

  var data: Data = Data()
  do {
    data = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
  } catch {
    Log.debug("error while reading")
  }

  return data
}

extension Base {
  /// Main function that parses input JSON and generates output JSON
  public static func processOperations(_ fpsOperations: inout FPSOperations, _ output: inout String) throws {
    let status: FPSStatus = FPSStatus.noErr
    var fpsResults: FPSResults = FPSResults()

    for fpsOperation in fpsOperations.operationsPtr {
      var fpsResult: FPSResult = FPSResult()
      if status == FPSStatus.noErr {
        // Process operations only if fpsParseOperations() call succeeded (as indicated by status)
        do {
          try createResults(fpsOperation, &fpsResult)
          fpsResult.status = FPSStatus.noErr
        } catch {
          fpsResult.status = (error as! FPSStatus)
        }
      } else {
        // Set error code to all operation before serializing
        fpsResult.status = status
      }
      fpsResults.resultPtr.append(fpsResult)
    }

    let encoder = JSONEncoder()
    // Useful for debugging purposes, should be kept commented out for production
    // encoder.outputFormatting = encoder.outputFormatting.union(.prettyPrinted)
    encoder.outputFormatting = encoder.outputFormatting.union(.sortedKeys)
    let data = try encoder.encode(fpsResults)
    output = String(data: data, encoding: .utf8)!
  }
}

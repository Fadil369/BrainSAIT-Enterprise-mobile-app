//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//
import ArgumentParser
import Crypto
import Foundation
import prebuilt
import src

@main
struct FPSSDK: ParsableCommand {
  @Argument(help: "Filepath to test")
  var filepath: String

  mutating func run() throws {
    do {
      let root = parseRootFromJson(filepath)
      let decoder = JSONDecoder()
      var base: Base
      do {
        base = try decoder.decode(Base.self, from: root)
      } catch {
        fpsLogError(FPSStatus.paramErr, "input parsing error: \(error)")
        throw FPSStatus.paramErr
      }
      var output = ""
      try Base.processOperations(&base.fpsOperations, &output)
      print(output)
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
      fpsResult.id = (fpsError == FPSStatus.paramErr) ? 0 : 1
      fpsResults.resultPtr.append(fpsResult)

      // Print encoded result as JSON
      let encoder = JSONEncoder()
      encoder.outputFormatting = encoder.outputFormatting.union(.sortedKeys)
      let data = try encoder.encode(fpsResults)
      print(String(data: data, encoding: .utf8)!)
    }
  }
}

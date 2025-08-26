//
// Copyright © 2024-2025 Apple Inc. All rights reserved.
//

import Crypto
import XCTest
import src

@testable import src

final class fpssdk_test: XCTestCase {
  // XCTest Documentation
  // https://developer.apple.com/documentation/xctest

  // Defining Test Cases and Test Methods
  // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods

  func testAllSampleInputs() {
    let testInputsPath = "../Test_Inputs"
    let files = FileManager.default.enumerator(atPath: testInputsPath)
    var count = 0

    // Loop through all .json files in the Test_Inputs folder
    while let file = files?.nextObject() as? String {
      if file.hasSuffix(".json") {

        Log.debug("[testAllSampleInputs] testing input file: \(file)")
        count += 1

        // Parse the json file
        let root = parseRootFromJson(testInputsPath + "/" + file)
        let decoder = JSONDecoder()
        var base: Base
        do {
          base = try decoder.decode(Base.self, from: root)
        } catch {
          XCTFail("decoder.decode threw unexpected error: \(error)")
          return
        }

        // Generate CKC
        var output = ""
        do {
          try Base.processOperations(&base.fpsOperations, &output)
        } catch {
          XCTFail("Base.processOperations threw unexpected error: \(error)")
        }

        // Verify CKC returned successful status
        do {
          let outputData: Data = output.data(using: .ascii) ?? Data()
          let parsedOutput: ExpectedOutputJSON = try JSONDecoder().decode(ExpectedOutputJSON.self, from: outputData)

          // Make sure status is 0
          if let status = parsedOutput.fpsResponse.createCKC?.first?.status {
            XCTAssert(status == 0, "status != 0")
          } else {
            XCTFail("Unable to find create-ckc field in output JSON")
          }
        } catch {
          XCTFail("Unable to parse status from output JSON: \(error)")
        }
      }
    }

    Log.debug("[testAllSampleInputs] Finished testing \(count) files")
    XCTAssert(count > 0, "Didn't find any input files to test")
  }
}

/// This structure represents the basic form of expected output
private struct ExpectedOutputJSON: Codable {
  let fpsResponse: FPSResponseObject

  enum CodingKeys: String, CodingKey {
    case fpsResponse = "fairplay-streaming-response"
  }

  struct FPSResponseObject: Codable {
    let createCKC: [CreateCKCObject]?

    enum CodingKeys: String, CodingKey {
      case createCKC = "create-ckc"
    }

    struct CreateCKCObject: Codable {
      // NOTE: there are more fields which may exist in the JSON, but we are just verifying status
      let status: Int

      enum CodingKeys: String, CodingKey {
        case status = "status"
      }
    }
  }
}

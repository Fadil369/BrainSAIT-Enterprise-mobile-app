//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

import Foundation

/// Checks the `condition`. If false, logs failure and performs `action`.
public func requireAction(
  _ condition: Bool,
  _ action: @escaping () throws -> Void,
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) throws {
  if !condition {
    Log.debug(
      "❌ Assertion failure: \(condition) [\(file):\(line)]", file: file, function: function,
      line: line)
    fpsLogError(
      FPSStatus.noErr, "Assertion failure: \(condition)", file: file, function: function, line: line
    )
    try action()
  }
}

/// Logs and returns error status.
public func returnErrorStatus(
  _ err: FPSStatus,
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) -> FPSStatus {
  Log.debug(
    "❌ Assertion failure: \(err) (\(err.rawValue)) [\(file):\(line)]", file: file,
    function: function, line: line)
  return err
}

public enum Result<T> {
  case success(T)
  case failure(FPSStatus)
}

/// Error codes used by FairPlay Streaming.
public enum FPSStatus: Int, Error {
  case noErr = 0
  case spcVersionErr = -42580
  case parserErr = -42581
  case missingRequiredTagErr = -42583
  case paramErr = -42585
  case memoryErr = -42586
  case versionErr = -42590
  case dupTagErr = -42591
  case internalErr = -42601
  case clientSecurityLevelErr = -42604
  case invalidCertificateErr = -42605
  case notImplementedErr = -42612
}

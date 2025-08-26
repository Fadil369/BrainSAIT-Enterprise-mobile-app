//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

// Import the libc
#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  @preconcurrency import Glibc
#elseif canImport(Musl)
  import Musl
#endif

import Foundation

struct StdErr: TextOutputStream {
  func write(_ string: String) {
    #if canImport(Darwin)
      let stderrHandle = Darwin.stderr
    #elseif canImport(Glibc)
      let stderrHandle = Glibc.stderr!
    #elseif canImport(Musl)
      let stderrHandle = Musl.stderr!
    #endif

    fputs(string, stderrHandle)
  }
}

public enum Log {

  /// Get string containing log prefix
  static func getPrefix(
    error: FPSStatus, file: String = #fileID, function: String = #function, line: Int = #line
  ) -> String {
    var timestamp: String
    if #available(macOS 12, *) {
      // Format: "yyyy-MM-dd HH:mm:ss,SSS"
      timestamp = Date().formatted(
        .iso8601
          .year()
          .month()
          .day()
          .dateSeparator(.dash)
          .dateTimeSeparator(.space)
          .timeSeparator(.colon)
          .timeZoneSeparator(.omitted)
          .time(includingFractionalSeconds: true)
      ).replacingOccurrences(of: ".", with: ",")
    } else {
      timestamp = Date().description
    }

    let process = ProcessInfo.processInfo.processIdentifier

    // Remove any paths from filename
    let filename = URL(fileURLWithPath: file).lastPathComponent

    // Remove any argument names from function
    // var functionNoArgs = function
    // if let args = functionNoArgs.firstIndex(of: "(") {
    //   functionNoArgs.removeSubrange(args..<functionNoArgs.endIndex)
    //   functionNoArgs += "()"
    // }

    let result =
      "timestamp=\"\(timestamp)\","
      + "FP_TOOLN=\"fpssdk\","
      + "FP_TOOLV=\"\(Version.number)\","
      + "FP_PID=\"\(process)\","
      + "FP_FL=\"\(filename)\","
      //+ "FP_FN=\"\(functionNoArgs)\","
      + "FP_LN=\"\(line)\","
      + "FP_ERRCODE=\"\(error.rawValue)\","

    return result
  }

  /// Prints only in Debug builds
  public static func debug(
    _ str: String, file: String = #fileID, function: String = #function, line: Int = #line
  ) {
    #if DEBUG
      // Print to stderr
      var stderr = StdErr()
      print("[DEBUG] \(str)", to: &stderr)

      // Print to stdout
      //print("[DEBUG] \(str)")
    #endif
  }
}

/// Prints error with formatting to stderr in both debug and release builds
public func fpsLogError(
  _ error: FPSStatus, _ args: Any..., file: String = #fileID, function: String = #function,
  line: Int = #line
) {

  var string = ""

  for arg: Any in args {
    string += "\(arg)"
  }

  let prefix = Log.getPrefix(error: error, file: file, function: function, line: line)

  // Print to stderr
  var stderr = StdErr()
  print(prefix + string, to: &stderr)

  // Print to stdout
  //print(prefix + string)
}

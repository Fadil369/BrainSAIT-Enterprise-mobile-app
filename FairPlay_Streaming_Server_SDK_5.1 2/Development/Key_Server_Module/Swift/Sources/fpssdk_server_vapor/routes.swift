//
// Copyright © 2025 Apple Inc. All rights reserved.
//
import Vapor
import src

func routes(_ app: Application) throws {
    app.post("fps") { req async -> String in
        var outJson: String = ""
        do {
            do {
                var base: Base = try req.content.decode(Base.self, using: JSONDecoder())
                try Base.processOperations(&base.fpsOperations, &outJson)
                return "Result" + outJson
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
            return "Internal Error"
        }

        return outJson
    }
}

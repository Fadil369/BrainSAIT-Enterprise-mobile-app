// swift-tools-version:6.0

//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

import PackageDescription

#if os(macOS)
  let linkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../../../Sources/prebuilt/macos"]),
    .unsafeFlags(["-L./Sources/prebuilt/macos"]),
    .linkedLibrary("fpscrypto"),
  ]
  let linkerSettingsForTest: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "./Sources/prebuilt/macos"])
  ]
#elseif arch(x86_64)
  let linkerSettings: [LinkerSetting] = [
    .unsafeFlags([
      "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../../../Sources/prebuilt/x86_64-unknown-linux-gnu",
    ]),
    .unsafeFlags(["-L./Sources/prebuilt/x86_64-unknown-linux-gnu"]),
    .linkedLibrary("fpscrypto"),
  ]
  let linkerSettingsForTest: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "./Sources/prebuilt/x86_64-unknown-linux-gnu"])
  ]
#elseif arch(arm64)
  let linkerSettings: [LinkerSetting] = [
    .unsafeFlags([
      "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../../../Sources/prebuilt/aarch64-unknown-linux-gnu",
    ]),
    .unsafeFlags(["-L./Sources/prebuilt/aarch64-unknown-linux-gnu"]),
    .linkedLibrary("fpscrypto"),
  ]
  let linkerSettingsForTest: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "./Sources/prebuilt/aarch64-unknown-linux-gnu"])
  ]
#endif

var customSettings: [SwiftSetting] = []

#if TEST_CREDENTIALS
  print("Using Test Credentials. Replace for Production")
  customSettings.append(
    .define("test_credentials")
  )
#endif

let package = Package(
  name: "FPSSDK",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "swift_fpssdk", type: .dynamic, targets: ["fpssdk_server"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.3.0"),
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
    // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
  ],
  targets: [
    .systemLibrary(name: "prebuilt"),
    .target(
      name: "fpssdk_server",
      dependencies: [
        .target(name: "src"),
      ],
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "."])
      ]
    ),
    .executableTarget(
      name: "fpssdk_local",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .target(name: "src"),
      ]
    ),
    .executableTarget(
        name: "fpssdk_server_vapor",
        dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
            .target(name: "src"),
        ],
        swiftSettings: [
          .enableExperimentalFeature("StrictConcurrency"),
        ]
    ),
    .target(
      name: "src",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "_CryptoExtras", package: "swift-crypto"),
        .target(name: "prebuilt"),
      ],
      resources: [
        .process("extension/credentials"),
      ],
      swiftSettings: customSettings,
      linkerSettings: linkerSettings
    ),
    .testTarget(
      name: "fpssdk_test",
      dependencies: ["src"],
      linkerSettings: linkerSettingsForTest
    ),
  ],
  swiftLanguageModes: [.v6]
)

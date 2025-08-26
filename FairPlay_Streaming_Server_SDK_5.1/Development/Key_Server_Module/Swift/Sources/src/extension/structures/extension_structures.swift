//
// Copyright © 2023-2024 Apple Inc. All rights reserved.
//

public struct SDKExtension {}

public struct FPSOperationExtension {}

public struct AssetInfoExtension {
  var contentType: extension_constants.ContentType = .unknown
}

public struct ServerCtxExtension {
  var contentType: extension_constants.ContentType = .unknown
}

public struct FPSResultsExtension {}

public struct FPSResultExtension {}

public struct SPCDataExtension {}

public struct CKCDataExtension {
  var requiredSecurityLevel: extension_constants.FPSSecurityLevel = .main
}

public struct SPCContainerExtension {}

public struct ClientFeaturesExtension {}

public struct KeyDurationExtension {}

# About FairPlay Streaming in Safari

These HTML samples show how to implement a FairPlay streaming client in Safari on macOS or iOS.

For additional information about FairPlay streaming in Safari, see the FairPlay Streaming Programming Guide.

## Requirements

### Runtime

Safari on macOS or iOS.

## HTTP Live Streaming (HLS)

- `fps_safari_hls_example.html` shows how to interact with a key server for basic streaming of HLS playlists.

- `fps_safari_hls_key_renewal.html` shows how to request periodic license renewal.

## Media Source Extensions (MSE)

- `fps_safari_mse_unmuxed_same_key.html` shows how to use the same key for all streams.

- `fps_safari_mse_unmuxed_multiple_keys.html` shows how to use different keys for different streams.

- `fps_safari_mse_unmuxed_key_renewal.html` shows how to request periodic license renewal.

- `fps_safari_mse_unmuxed_key_rotation.html` shows how to rotate keys during playback.

## Support Files

- `fps_safari_support.js` contains JavaScript utility functions used by all of the above HTML samples.

## Test Streams

- Test streams for HLS can be downloaded from the [FairPlay Streaming page](https://developer.apple.com/streaming/fps/) on the Apple Developer website.

– Test streams for MSE can be found in the `content` folder provided alongside the MSE samples listed above.

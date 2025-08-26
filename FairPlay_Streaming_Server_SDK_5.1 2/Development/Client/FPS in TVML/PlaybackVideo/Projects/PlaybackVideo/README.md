# PlaybackVideo

Play encrypted media content in a TVML application using the built-in media player and FairPlay Streaming.

## Overview

The [TVML](https://developer.apple.com/documentation/TVML) frameworks provide several built-in ways to play media items. This sample creates a client-server connection to retrieve information about videos stored on a server. The sample uses JavaScript to load an initial TVML document from the server. The retrieved information is parsed into a document and displayed on the TV. The user selects a video from a list in the document and the sample plays the video using the built-in [TVMLJKit JS](https://developer.apple.com/documentation/tvmljs) media player and [FairPlay Streaming](https://developer.apple.com/streaming/fps/).

## Configure the sample code project

* Build the sample with Xcode 13.4.1 or later, and tvOS 15.0 or later.
* This sample runs on physical tvOS devices with tvOS 15.0 or later.

## Structure

The project is split into two parts:

- `Projects/PlaybackVideo`: This directory contains the Xcode project and related files. The `AppDelegate.swift` file handles the setup of the TVMLKit framework and launching the JavaScript context to manage the app.

- `Server/PlaybackVideo`: This directory contains the main `application.js` JavaScript file and other resources. 

> Important: The `Server/PlaybackVideo` directory must be hosted on a web server that is accessible from the simulator or device.

## Usage notes

The following adjustments must be made for the sample functionality to meet the needs of the integrator:
 
- Update `serverCertificatePath` to a URL to your FPS certificate.
- Update `keyServerURL` to a URL to your Key Security Module (KSM).
- Update the SPC extraction from the HTTP `POST` request to the KSM according to your own client protocol (see the `getKey` function).
- Update the file `videos.json` with your own encrypted media playlist URL's (`.m3u8`) and other metadata.

> Important: The sections requiring modification are marked with the "ADAPT" comment in the sample code.
 
## Local server instructions

To try this sample with a local web server in the Apple TV Simulator, setup a local server on your machine:

1. In Finder, navigate to the `Server` directory inside of the `PlaybackVideo` project directory.
2. In Terminal, enter at the prompt, `cd` followed by a space.
3. Drag the `Server` folder from the Finder window into the Terminal window, and press Return. This changes the directory to that folder.
4. In Terminal, enter `ruby -run -ehttpd . -p9001` to run the server. This will start a single server instance that can be used when running the sample in the workspace.
5. Build and run the app.

After testing the sample app in Apple TV Simulator, you can close the local server by pressing Control-C in Terminal. Closing the Terminal window also kills the server.

## Remote server instructions

To try the sample with a remote server on an actual Apple TV device, make the following changes to the application:

1. Open the `PlaybackVideo.xcodeproj` project in Xcode
2. Change the `tvBaseURL` property in `AppDelegate.swift` to match the URL hosting the contents of the `Server` directory.
3. Copy the `Server` folder to the remove server.
4. Select the target Apple TV device in Xcode.
5. Build and run the app in Xcode.

## Get the media metadata from the server

The server contains the metadata for the various videos to play, such as the title, description, URL, and so on. At program startup, the sample loads this information from the server and stores it in the `allVideos` variable.

```
 // Get the video URLs from the server.
 videosXHR.open("GET", videosURL);
 videosXHR.responseType = "json";
 videosXHR.onload = () => {
     allVideos = videosXHR.response;
     navigationDocument.replaceDocument(document, loadingDocument);
 }
```

## Play media using the built-in player and FairPlay Streaming

The sample displays a list of the videos in a single document for the user to choose. Each video in the list is a [Lockup Element](https://developer.apple.com/documentation/tvml/lockup-elements). When the user selects a lockup, the app uses the onselect attribute to call the `presentVideo` method. The lockup passes an index into the `allVideos` variable for the selected video to the `presentVideo` method.

```
<listItemLockup onselect="presentVideo(1)">
    <title>Sample Video</title>
</listItemLockup>

```

To play the encrypted video, the sample first creates a [`MediaItem`][MediaItemLink] for the video. 

To support FairPlay Streaming playback, the app sets the following required property attributes on the `MediaItem`: [`loadAssetID`](https://developer.apple.com/documentation/tvmljs/mediaitem/1627392-loadassetid), [`loadCertificate`](https://developer.apple.com/documentation/tvmljs/mediaitem/1627435-loadcertificate) and [`loadKey`](https://developer.apple.com/documentation/tvmljs/mediaitem/1627379-loadkey). These properties specify callback functions. 
The `loadAssetID` callback loads the asset identifier for an item. The `loadCertificate` callback loads the security certificate for an item. The `loadKey` callback loads the security key for an item. 

```
function createMediaItem(mediaInfo) {
    
    const mediaItem = new MediaItem("video");
    for (let key in mediaInfo) {
        // Set the available media item properties on the media item.
        mediaItem[key] = mediaInfo[key];
    }
    
    /*
     Specify callback functions to load the asset identifier, security
     certificate, and security key for playback of FairPlay Streaming
     encrypted media.
    */
    mediaItem.loadAssetID = readAssetID;
    mediaItem.loadCertificate = getCertificate;
    mediaItem.loadKey = getKey;

    return mediaItem;
}
```

Next, the app creates a [`Playlist`][PlaylistLink] object to hold the `MediaItem`, and adds the `MediaItem` to the `Playlist`. The app then creates a media [`Player`][PlayerLink] that displays the UI for playing video. Finally, to play the video, the app associates the `Player` with the `Playlist`, and calls the `Player` [`play`](https://developer.apple.com/documentation/tvmljs/player/1627432-play) function.

```
// Push the the video's media item onto a new playlist.
const playlist = new Playlist();
playlist.push(mediaItem);

// Create a Player and use it to play the playlist.
const player = new Player();
player.playlist = playlist;
player.play();

```

## Debugging

To help debug and experiment you can use the [Safari WebInspector](https://developer.apple.com/safari/tools/) to attach to the JavaScript context. WebInspector provides a full JavaScript debugging environment. You'll need to turn on the Develop menu from Safari > Preferences > Advanced. Xcode then lists your devices and the JavaScript contexts available for debugging in the drop down menu.

## Security

The sample's `Info.plist` file disables App Transport Security (ATS) for the localhost domain. This is only to simplify the process of trying the sample. Your own apps should rely on properly secured servers that do not require disabling ATS.

[MediaItemLink]:https://developer.apple.com/documentation/tvmljs/mediaitem
[PlaylistLink]:https://developer.apple.com/documentation/tvmljs/playlist
[PlayerLink]:https://developer.apple.com/documentation/tvmljs/player

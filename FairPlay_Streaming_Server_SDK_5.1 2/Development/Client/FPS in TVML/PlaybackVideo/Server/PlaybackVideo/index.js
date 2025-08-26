/*
Copyright (C) 2022 Apple Inc. All Rights Reserved.
See the LICENSE folder for this sample’s licensing information.

Abstract:
 Functions to present and play videos encrypted using FairPlay Streaming.
*/

// Get a reference to the loading template pushed in application.js.
const loadingDocument = getActiveDocument();

// Create a DocumentLoader to handle fetching templates.
const documentLoader = new DocumentLoader(baseURL + "PlaybackVideo/");

// Store the video metadata loaded from JSON using XMLHttpRequest.
let allVideos;

// ADAPT: The path to the FPS certificate on your server.
let serverCertificatePath = "http://myserver.com/cert.der";

/*
 ADAPT: The URL to the Key Security Module (KSM) that processes the SPC and
 returns a CKC.
*/
let keyServerURL = "http://myserver.com/ksm";

// Fetch the list template from the server to show as the root document.
documentLoader.fetch({
                     url: "/Index.xml",
                     success: (document) => {
                         // Show the loaded document instead of the loading template.
                         const videosXHR = new XMLHttpRequest();
                         const videosURL = documentLoader.prepareURL("/videos.json");
                         // Get the video URLs from the server.
                         videosXHR.open("GET", videosURL);
                         videosXHR.responseType = "json";
                         videosXHR.onload = () => {
                             allVideos = videosXHR.response;
                             navigationDocument.replaceDocument(document, loadingDocument);
                         }
                         videosXHR.onerror = () => {
                             const alertDocument = createLoadErrorAlertDocument(videosURL, videosXHR);
                             navigationDocument.presentModal(alertDocument);
                         }
                         videosXHR.send();
                     },
                     error: (xhr) => {
                         // Create an alert document from the XHR error.
                         const alertDocument = createLoadErrorAlertDocument(xhr);
                         // Show the alert document instead of the loading template.
                         navigationDocument.replaceDocument(alertDocument, loadingDocument);
                     }
                     });

// MARK: - Media Playback

// Presents and plays a video.
function presentVideo(index) {

    // Get the metadata for the selected video.
    const videoInfo = allVideos[index];

    // Create a MediaItem from the video metadata.
    const mediaItem = createMediaItem(videoInfo);
    
    // Create a new Playlist--an array of media items to play in the app.
    const playlist = new Playlist();
    // Add the video's MediaItem to the new Playlist.
    playlist.push(mediaItem);
    
    /*
    Create a Player to play the items in the Playlist. The player displays the
    UI for playing video and audio.
    */
    const player = new Player();
    // Assign the playlist to the player.
    player.playlist = playlist;
    // Play the MediaItem.
    player.play();
}

/*
 Convenience function to create a MediaItem object from a set of video information.
*/
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

// MARK: - FairPlay Streaming

// A callback function to load the asset identifier.
function readAssetID(url, callback) {
    
    var assetID = extractContentId(url);
    
    if (assetID != null) {
        callback(btoa(assetID));
    } else {
        callback(null, "Error parsing asset ID from URI: " + uri);
    }
}

// A convenience function to extract the content identifier from the URI.
var extractContentId = function (initData) {
    var uri = initData;
    var uriParts = uri.split('://');
    var protocol = uriParts[0].slice(-3);
    var contentId = uriParts.length > 0 ? uriParts[1] : '';
    return protocol.toLowerCase() == 'skd' ? contentId : '';
};

// A callback function to load the security certificate.
function getCertificate(url, callback) {
    
    var request = new XMLHttpRequest();
    // Set the method, URL, and synchronous flag for the request.
    request.open('GET', serverCertificatePath, false);
    request.setRequestHeader('Pragma', 'Cache-Control: no-cache');
    request.setRequestHeader("Cache-Control", "max-age=0");
    request.send();
    
    if (request.status === 200) {
        console.log("Got the certificate!");
        var certText = request.responseText.trim();
        console.log(certText);
        callback(certText);
    } else {
        console.log("Failed to get the certificate!");
        callback(null, "Error requesting certificate from URL: " + serverCertificatePath);
    }
}

/*
 A callback function that loads and returns the security key.
 This function assumes the Key Security Module understands the following POST
 format:
    {"spc":requestData}
 
 // ADAPT: Partners must tailor this code to their own protocol.
*/
function getKey(url, requestData, callback) {

    var request = new XMLHttpRequest();
    request.responseType = 'text';
    
    // Define the spc data as a JSON object.
    var data = { "spc" : requestData};
    
    /*
     Convert spc data object literal into a JSON string so it can be sent with
     an HTTP POST request to the server.
    */
    var json = JSON.stringify(data);
    // Send the spc to the Key Server.
    request.open('POST', keyServerURL, false);
    request.setRequestHeader("Content-type", "application/json");
    request.send(json);
    
    if (request.status === 200) {
        console.log("Got CKC!");
        var keyText = request.responseText;
        callback(keyText);
    } else {
        console.log("Failed to get CKC!");
        callback(null, "Error requesting CKC from URL: " + keyServerURL);
    }
}

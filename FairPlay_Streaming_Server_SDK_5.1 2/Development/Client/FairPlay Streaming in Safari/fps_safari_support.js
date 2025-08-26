
// See LICENSE.txt for this sample code's licensing information.

function uInt8ArrayToString(array) {
    return String.fromCharCode.apply(null, array);
}

function stringToUInt8Array(str)
{
    return Uint8Array.from(str, c => c.charCodeAt(0));
}

function base64DecodeUint8Array(input) {
    return Uint8Array.from(atob(input), c => c.charCodeAt(0));
}

function base64EncodeUint8Array(input) {
    return btoa(uInt8ArrayToString(input));
}

function waitFor(target, type) {
    return new Promise(resolve => {
        target.addEventListener(type, resolve, { once: true });
    });
}

async function fetchBuffer(url) {
    let result = await fetch(url);
    let buffer = await result.arrayBuffer();
    return buffer;
}

async function fetchAndAppend(sourceBuffer, url) {
    let buffer = await fetchBuffer(url);
    sourceBuffer.appendBuffer(buffer);
    await waitFor(sourceBuffer, 'updateend');
}

async function fetchAndWaitForEncrypted(video, sourceBuffer, url) {
    let updateEndPromise = fetchAndAppend(sourceBuffer, url);
    let event = await waitFor(video, 'encrypted');
    let session = await encrypted(event);
    await updateEndPromise;
    return session;
}

async function runAndWaitForLicenseRequest(session, callback) {
    let licenseRequestPromise = waitFor(session, 'message');
    await callback();
    let message = await licenseRequestPromise;
    
    let response = await getResponse(message);
    await session.update(response);
}

async function loadCertificate()
{
    try {
        let response = await fetch(serverCertificatePath);
        window.certificate = await response.arrayBuffer();
        startVideo();
    } catch(e) {
        window.console.error(`Could not load certificate at ${serverCertificatePath}`);
    }
}

/*
    This function assumes the Key Server Module understands the following JSON-encoded POST format:
 
    { "fairplay-streaming-request" : {
            "version": <version>,
            "streaming-keys" : [{
                "id" : <key id>
                "uri" : <key uri>
                "spc" : <spc>
            }, ... ]
        }
    }

    It assumes the Key Server Module will respond in the following JSON-encoded format:
 
    {
        "fairplay-streaming-response" : {
            "streaming-keys" : [ <key payload>, ... ]
        }
    }
 
    Your own KSM protocol may be different.
*/
async function getResponse(event, spcPath, keyURI) { // ADAPT: Tailor this to your own protocol.
    let licenseResponse = await fetch(spcPath, {
        method: 'POST',
        headers: new Headers({'Content-type': 'application/x-www-form-urlencoded'}),
        body: JSON.stringify({
            "fairplay-streaming-request" : {
                "version" : 1,
                "streaming-keys" : [{
                    "id" : 1,
                    "uri" : keyURI,
                    "spc" : base64EncodeUint8Array(new Uint8Array(event.message)),
                }]
            }
        }),
    });
    let license = await licenseResponse.text();
    responseObject = JSON.parse(license.trim());
    let keyResponse = responseObject["fairplay-streaming-response"]["streaming-keys"][0];
    return base64DecodeUint8Array(keyResponse.ckc);
}


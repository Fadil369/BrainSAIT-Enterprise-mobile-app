/*
Copyright (C) 2022 Apple Inc. All Rights Reserved.
See the LICENSE folder for this sample’s licensing information.

Abstract:
 The main application JavaScript file.
*/

// Set to the base URL of your app's server when the app launches.
var baseURL;

/*
Invoked after the system parses the application JavaScript into a JavaScript context.
The system passes the handler an object containing the options passed in for launch.
You define these options in the Swift or Objective-C client code. Use the options to
communicate data as well as state information to your JavaScript code.
*/
App.onLaunch = function(options) {
    /*
    Use the launch options to determine the base URL for remote server fetches.
    The app uses the baseURL to resolve the URLs in XML files.
    */
    baseURL = options.baseURL;

    // Show a loading spinner while the system evaluates additional JavaScript files.
    const loadingDocument = createLoadingDocument();
    navigationDocument.pushDocument(loadingDocument);

    console.log("Loading main script: " + options.mainScript);

    // Load code from the utilities directory and the main application script.
    const scriptURLs = [
        "Utilities/DocumentLoader.js",
        options.mainScript
    ].map(
        moduleName => baseURL + moduleName
    );

    // Verify and execute the TVMLKit JS files.
    evaluateScripts(scriptURLs, function(scriptsAreLoaded) {
        if (scriptsAreLoaded) {
            console.log("Scripts successfully evaluated.");
        } else {
            /*
            Handle the error cases. Present a readable and user friendly error
            message to the user in an alert dialog.
            */
            const alertDocument = createEvalErrorAlertDocument();
            navigationDocument.replaceDocument(alertDocument, loadingDocument);
            throw new EvalError("application.js: unable to evaluate scripts.");
        }
    });
};

/*
Convenience function to create a TVML loading document with a specified title.
*/
function createLoadingDocument(title) {
    console.log("createLoadingDocument()")
    
    // If no title has been specified, fall back to "Loading...".
    title = title || "Loading...";

    const template = `<?xml version="1.0" encoding="UTF-8" ?>
        <document>
            <loadingTemplate>
                <activityIndicator>
                    <title>${title}</title>
                </activityIndicator>
            </loadingTemplate>
        </document>
    `;
    return new DOMParser().parseFromString(template, "application/xml");
}

/*
Convenience function to create a TVML alert document with a title and
description.
*/
function createAlertDocument(title, description) {
    const template = `<?xml version="1.0" encoding="UTF-8" ?>
        <document>
            <alertTemplate>
                <title>${title}</title>
                <description>${description}</description>
            </alertTemplate>
        </document>
    `;
    return new DOMParser().parseFromString(template, "application/xml");
}

/*
Convenience function to create a TVML alert for failed evaluateScripts.
*/
function createEvalErrorAlertDocument() {
    const title = "Evaluate Scripts Error";
    const description = [
        "There was an error attempting to evaluate the external JavaScript files.",
        "Please check your network connection and try again later."
    ].join("\n\n");
    return createAlertDocument(title, description);
}

/*
Convenience function to create a TVML alert for a failed XMLHttpRequest.
*/
function createLoadErrorAlertDocument(url, xhr) {
    const title = (xhr.status) ? `Fetch Error ${xhr.status}` : "Fetch Error";
    const description = `Could not load document:\n${url}\n(${xhr.statusText})`;
    return createAlertDocument(title, description);
}

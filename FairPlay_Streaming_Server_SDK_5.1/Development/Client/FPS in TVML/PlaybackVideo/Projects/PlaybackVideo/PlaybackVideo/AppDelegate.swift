/*
Copyright (C) 2022 Apple Inc. All Rights Reserved.
See the LICENSE folder for this sample’s licensing information.

Abstract:
The application-specific delegate class.
*/

import UIKit
import TVMLKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TVApplicationControllerDelegate {
	// MARK: Properties
	
	var window: UIWindow?
	
	var appController: TVApplicationController?
	
    /*
    ADAPT: If you're hosting the server files on a remote server, change the
    tvBaseURL property to match the URL hosting the contents of the Server directory.
    */
    static let tvBaseURL = "http://localhost:9001/"

    static let tvBootURL = "\(AppDelegate.tvBaseURL)application.js"

    static let tvMainScript = "PlaybackVideo/index.js"
	
	// MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		window = UIWindow(frame: UIScreen.main.bounds)
		
		/*
        Create the TVApplicationControllerContext for this app and set
        the properties to pass to the App.onLaunch function in JavaScript.
		*/
		let appControllerContext = TVApplicationControllerContext()
		
		if let javaScriptURL = URL(string: AppDelegate.tvBootURL) {
			appControllerContext.javaScriptApplicationURL = javaScriptURL
		}
		
		appControllerContext.launchOptions["baseURL"] = AppDelegate.tvBaseURL
		appControllerContext.launchOptions["mainScript"] = AppDelegate.tvMainScript
		
		if let launchOptions = launchOptions {
			for (kind, value) in launchOptions {
				appControllerContext.launchOptions[kind.rawValue] = value
			}
		}
		
		// Create a TVApplicationControlle` with the context and app window.
		appController = TVApplicationController(context: appControllerContext, window: window, delegate: self)
		
		return true
	}
	
	func appController(_ appController: TVApplicationController, didFail error: Error) {
		
		let title = "Error Launching Application"
		let message = error.localizedDescription
		let alertController = UIAlertController(title: title, message: message, preferredStyle:.alert )
		
		self.appController?.navigationController.present(alertController, animated: true, completion: nil)
	}
}

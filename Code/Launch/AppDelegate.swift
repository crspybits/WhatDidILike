//
//  AppDelegate.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import SMCoreLib
import DropDown

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        DropDown.startListeningToKeyboard()
        Fabric.with([Crashlytics.self])
        
        Log.minLevel = .verbose
        
        let coreDataSession = CoreData(options: [
            CoreDataBundleModelName: "WhatDidILike",
            CoreDataSqlliteBackupFileName: "~WhatDidILike.sqlite",
            CoreDataSqlliteFileName: "WhatDidILike.sqlite",
            CoreDataLightWeightMigration: true
        ]);
        
        CoreData.registerSession(coreDataSession, forName: CoreDataExtras.sessionName)

#if DEBUG
        let numberPlaces = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: Place.entityName()).count
        let numberLocations = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: Location.entityName()).count
        let numberItems = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: Item.entityName()).count
        let numberComments = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: Comment.entityName()).count
        let numberImages = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: Image.entityName()).count
    
        Log.msg("Stats on Core Data objects: ")
        Log.msg("\tplaces: \(String(describing: numberPlaces))")
        Log.msg("\tlocations: \(String(describing: numberLocations))")
        Log.msg("\titems: \(String(describing: numberItems))")
        Log.msg("\tcomments: \(String(describing: numberComments))")
        Log.msg("\timages: \(String(describing: numberImages))")
        
        Log.msg("Documents: \(String(describing: FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY)))")
#endif

        // TODO: Add a UI instead of assigning a constant.
        Parameters.userName.stringValue = "Christopher Prince"
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }


}


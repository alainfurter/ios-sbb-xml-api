//
//  AppDelegate.m
//  SBBXMLAPI
//
//  Created by Alain on 10.06.13.
//  Copyright (c) 2013 Zone Zero Apps. All rights reserved.
//

#import "AppDelegate.h"

#import "SBBAPIController.h"
#import "SelectStationsViewController.h"


@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self managedObjectContext];
    
    [[SBBAPIController sharedSBBAPIController] setSBBConReqNumberOfConnectionsForRequest: 4];
    [[SBBAPIController sharedSBBAPIController] setSBBConScrNumberOfConnectionsForRequest: 4];
    [[SBBAPIController sharedSBBAPIController] setSBBStbReqNumberOfConnectionsForRequest: 40];
    [[SBBAPIController sharedSBBAPIController] setSBBStbScrNumberOfConnectionsForRequest: 40];
    
    NSString *languageCode = [[NSLocale preferredLanguages] objectAtIndex:0];
        
    NSUInteger apiLanguageCode = reqEnglish;
    if ([languageCode isEqualToString:@"en"]) {
        apiLanguageCode = reqEnglish;
    } else if ([languageCode isEqualToString:@"de"]) {
        apiLanguageCode = reqGerman;
    } else if ([languageCode isEqualToString:@"fr"]) {
        apiLanguageCode = reqFrench;
    } else if ([languageCode isEqualToString:@"it"]) {
        apiLanguageCode = reqItalian;
    }
    [[SBBAPIController sharedSBBAPIController] setSBBAPILanguageLocale: apiLanguageCode];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    
    self.selectStationsViewController = [[SelectStationsViewController alloc] init];
    self.selectStationsViewController.managedObjectContext = self.managedObjectContext;
    self.selectStationsViewController.view.frame = self.window.bounds;
    
    self.navigationController = [[UINavigationController alloc] initWithRootViewController: self.selectStationsViewController];
    self.navigationController.navigationBar.backgroundColor = [UIColor darkGrayColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
    
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
        
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Swiss_Trains" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Stations" ofType:@"sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath: defaultStorePath];
        
    NSDictionary* store_options_dict = [NSDictionary
                                        dictionaryWithObject:[NSNumber numberWithBool:YES]
                                        forKey:NSReadOnlyPersistentStoreOption];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:store_options_dict error:&error]) {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

@end

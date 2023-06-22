//
//  AppDelegate.h
//  SBBXMLAPI
//
//  Created by Alain on 10.06.13.
//  Copyright (c) 2013 Zone Zero Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectStationsViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) SelectStationsViewController *selectStationsViewController;

// Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

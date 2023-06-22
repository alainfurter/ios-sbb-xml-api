//
//  StationPickerViewController.h
//  SBB XML API Controller
//
//  Created by Alain on 13.12.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StationsCell.h"
#import "Station.h"

#import "Stations.h"

#import "NSManagedObjectContext+Blocks.h"

#import "SBBAPIController.h"
#import "Reachability.h"

enum stationTypeIndexes {
    startStationType = 1,
    endStationType = 2,
    viaStationType = 3
};

enum stationpickerType {
    connectionsStationpickerType = 1,
    stationboardStationpickerType = 2
};

@class StationPickerViewController;

@protocol StationPickerViewControllerDelegate <NSObject>
- (void)didSelectStationWithStationTypeIndex:(StationPickerViewController *)controller stationTypeIndex:(NSUInteger)index station:(Station *)station;
@end

@interface StationPickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak) id <StationPickerViewControllerDelegate> delegate;

@property (assign) NSUInteger stationTypeIndex;
@property (assign) NSUInteger stationpickerType;

- (void) clearStationSetting;

@end

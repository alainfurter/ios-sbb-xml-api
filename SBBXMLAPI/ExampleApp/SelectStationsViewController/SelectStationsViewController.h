//
//  SelectStationsViewController.h
//  SBBXMLAPI
//
//  Created by Alain on 10.06.13.
//  Copyright (c) 2013 Zone Zero Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StationPickerViewController.h"

@interface SelectStationsViewController : UIViewController <StationPickerViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

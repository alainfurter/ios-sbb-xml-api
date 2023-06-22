//
//  StationsCell.h
//  SBB XML API Controller
//
//  Created by Alain on 20.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StationsCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSString *stationId;
@property (nonatomic, strong) NSNumber *stationlat;
@property (nonatomic, strong) NSNumber *stationlng;

@end

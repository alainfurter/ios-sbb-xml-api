//
//  ConnectionsDetailviewCell.h
//  Swiss Trains
//
//  Created by Alain on 28.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConnectionsDetailviewCell : UITableViewCell

@property (strong, nonatomic) UILabel *startStationLabel;
@property (strong, nonatomic) UILabel *startTimeLabel;
@property (strong, nonatomic) UILabel *endStationLabel;
@property (strong, nonatomic) UILabel *endTimeLabel;
//@property (strong, nonatomic) UILabel *durationLabel;
//@property (strong, nonatomic) UILabel *distanceLabel;
@property (strong, nonatomic) UILabel *transportInfoLabel;
@property (strong, nonatomic) UILabel *transportCapacity1stLabel;
@property (strong, nonatomic) UILabel *transportCapacity2ndLabel;
@property (strong, nonatomic) UILabel *startStationTrackLabel;
@property (strong, nonatomic) UILabel *endStationTrackLabel;

//@property (strong, nonatomic) UILabel *startExpectedTimeLabel;
//@property (strong, nonatomic) UILabel *endExpectedTimeLabel;
//@property (strong, nonatomic) UILabel *startStationExpectedTrackLabel;
//@property (strong, nonatomic) UILabel *endStationExpectedTrackLabel;

@property (strong, nonatomic) UILabel *transportTypeLabel;
@property (strong, nonatomic) UILabel *transportNameLabel;

@end

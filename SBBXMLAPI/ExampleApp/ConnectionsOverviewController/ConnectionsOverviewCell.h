//
//  ConnectionsOverviewCell.h
//  Swiss Trains
//
//  Created by Alain on 28.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConnectionsOverviewCell : UITableViewCell

@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UILabel *departureTimeLabel;
@property (strong, nonatomic) UILabel *arrivalTimeLabel;
@property (strong, nonatomic) UIImageView *departureImageView;
@property (strong, nonatomic) UIImageView *arrivalImageView;
@property (strong, nonatomic) UILabel *changesLabel;

@end

//
//  ConnectionsOverviewCell.m
//  Swiss Trains
//
//  Created by Alain on 28.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "ConnectionsOverviewCell.h"

@implementation ConnectionsOverviewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        CGRect frame = self.frame;
        frame.size.height = 142;
        self.frame = frame;
                
        self.timeLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 10, 200, 40)];
        _timeLabel.font = [UIFont boldSystemFontOfSize: 15.0];
        _timeLabel.textColor = [UIColor blackColor];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.textAlignment = NSTextAlignmentLeft;
        
        self.changesLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 60, 200, 20)];
        self.changesLabel.font = [UIFont boldSystemFontOfSize: 15.0];
        self.changesLabel.textColor = [UIColor blackColor];
        self.changesLabel.backgroundColor = [UIColor clearColor];
        self.changesLabel.textAlignment = NSTextAlignmentLeft;
                
        self.departureTimeLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 96, 200, 12)];
        _departureTimeLabel .font = [UIFont boldSystemFontOfSize: 15.0];
        _departureTimeLabel .textColor = [UIColor blackColor];
        _departureTimeLabel .backgroundColor = [UIColor clearColor];
        _departureTimeLabel .textAlignment = NSTextAlignmentLeft;
        
        self.arrivalTimeLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 115, 200, 12)];
        _arrivalTimeLabel.font = [UIFont boldSystemFontOfSize: 15.0];
        _arrivalTimeLabel.textColor = [UIColor blackColor];
        _arrivalTimeLabel.backgroundColor = [UIColor clearColor];
        _arrivalTimeLabel.textAlignment = NSTextAlignmentLeft;
        
        [self.contentView addSubview: _timeLabel];
        [self.contentView addSubview: _changesLabel];
                
        [self.contentView addSubview: _departureTimeLabel];
        [self.contentView addSubview: _arrivalTimeLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end

//
//  ConnectionsDetailviewCell.m
//  Swiss Trains
//
//  Created by Alain on 28.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "ConnectionsDetailviewCell.h"

#define DTCELLVIEWHEIGHT 142.0
 
@implementation ConnectionsDetailviewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        CGRect frame = self.frame;
        frame.size.height = DTCELLVIEWHEIGHT;
        self.frame = frame;
                
        self.clipsToBounds = YES;
        self.contentView.clipsToBounds = YES;
                        
        self.startStationLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 5, 224, 30)];
        _startStationLabel.font = [UIFont boldSystemFontOfSize: 12.0];
        _startStationLabel.textColor = [UIColor blackColor];
        _startStationLabel.backgroundColor = [UIColor clearColor];
        _startStationLabel.textAlignment = NSTextAlignmentLeft;
        
        self.startTimeLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 35, 40, 10)];
        _startTimeLabel.font = [UIFont systemFontOfSize: 12.0];
        _startTimeLabel.textColor = [UIColor blackColor];
        _startTimeLabel.backgroundColor = [UIColor clearColor];
        _startTimeLabel.textAlignment = NSTextAlignmentLeft;
                
        self.startStationTrackLabel = [[UILabel alloc] initWithFrame: CGRectMake(self.frame.size.width - 85, 22, 40, 10)];
        _startStationTrackLabel.font = [UIFont systemFontOfSize: 12.0];
        _startStationTrackLabel.textColor = [UIColor blackColor];
        _startStationTrackLabel.backgroundColor = [UIColor clearColor];
        _startStationTrackLabel.textAlignment = NSTextAlignmentRight;
        
        self.endStationLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, self.bounds.size.height - 45, 224, 30)];
        _endStationLabel.font = [UIFont boldSystemFontOfSize: 12.0];
        _endStationLabel.textColor = [UIColor blackColor];
        _endStationLabel.backgroundColor = [UIColor clearColor];
        _endStationLabel.textAlignment = NSTextAlignmentLeft;
        
        self.endTimeLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, self.bounds.size.height - 15, 40, 10)];
        _endTimeLabel.font = [UIFont systemFontOfSize: 12.0];
        _endTimeLabel.textColor = [UIColor blackColor];
        _endTimeLabel.backgroundColor = [UIColor clearColor];
        _endTimeLabel.textAlignment = NSTextAlignmentLeft;
        
        self.endStationTrackLabel = [[UILabel alloc] initWithFrame: CGRectMake(self.frame.size.width - 85, self.bounds.size.height - 33, 40, 10)];
        self.endStationTrackLabel.font = [UIFont systemFontOfSize: 12.0];
        self.endStationTrackLabel.textColor = [UIColor blackColor];
        self.endStationTrackLabel.backgroundColor = [UIColor clearColor];
        self.endStationTrackLabel.textAlignment = NSTextAlignmentRight;
                
        self.transportInfoLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 85, 80, 10)];
        _transportInfoLabel.font = [UIFont systemFontOfSize: 9.0];
        _transportInfoLabel.textColor = [UIColor blackColor];
        _transportInfoLabel.backgroundColor = [UIColor clearColor];
        _transportInfoLabel.textAlignment = NSTextAlignmentLeft;
        
        self.transportCapacity1stLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 85, 20, 10)];
        _transportCapacity1stLabel.font = [UIFont systemFontOfSize: 9.0];
        _transportCapacity1stLabel.textColor = [UIColor blackColor];
        _transportCapacity1stLabel.backgroundColor = [UIColor clearColor];
        _transportCapacity1stLabel.textAlignment = NSTextAlignmentLeft;
                
        self.transportCapacity2ndLabel = [[UILabel alloc] initWithFrame: CGRectMake(37, 85, 20, 10)];
        _transportCapacity2ndLabel.font = [UIFont systemFontOfSize: 9.0];
        _transportCapacity2ndLabel.textColor = [UIColor blackColor];
        _transportCapacity2ndLabel.backgroundColor = [UIColor clearColor];
        _transportCapacity2ndLabel.textAlignment = NSTextAlignmentLeft;
        
        self.transportNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(100, 63, 80, 20)];
        _transportNameLabel.font = [UIFont systemFontOfSize: 9.0];
        _transportNameLabel.textColor = [UIColor blackColor];
        _transportNameLabel.backgroundColor = [UIColor clearColor];
        _transportNameLabel.textAlignment = NSTextAlignmentLeft;
        
        self.transportTypeLabel = [[UILabel alloc] initWithFrame: CGRectMake(8, 58, 80, 30)];
        _transportTypeLabel.font = [UIFont systemFontOfSize: 9.0];
        _transportTypeLabel.textColor = [UIColor blackColor];
        _transportTypeLabel.backgroundColor = [UIColor clearColor];
        _transportTypeLabel.textAlignment = NSTextAlignmentLeft;
                
        [self.contentView addSubview: _startStationLabel];
        [self.contentView addSubview: _endStationLabel];
        
        [self.contentView addSubview: _startTimeLabel];
        [self.contentView addSubview: _endTimeLabel];
        
        [self.contentView addSubview: _startStationTrackLabel];
        [self.contentView addSubview: _endStationTrackLabel];
                
        [self.contentView addSubview: _transportInfoLabel];
        
        [self.contentView addSubview: _transportTypeLabel];
        [self.contentView addSubview: _transportNameLabel];
        
        [self.contentView addSubview: _transportCapacity1stLabel];
        [self.contentView addSubview: _transportCapacity2ndLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end






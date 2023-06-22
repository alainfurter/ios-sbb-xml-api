//
//  StationsCell.m
//  SBB XML API Controller
//
//  Created by Alain on 20.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "StationsCell.h"

@implementation StationsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {        
        CGRect cellFrame = self.contentView.frame;
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        self.titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(5, 5, cellFrame.size.width - 5, 15)];
        self.titleLabel.font = [UIFont systemFontOfSize:14.0];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview: self.titleLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end

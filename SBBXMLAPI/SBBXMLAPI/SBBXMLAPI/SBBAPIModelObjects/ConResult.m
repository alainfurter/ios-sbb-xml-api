//
//  ConResult.m
//  Swiss Trains
//
//  Created by Alain on 29.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "ConResult.h"

@implementation ConResult

- (id)init {
    self = [super init];
    if (self) {
        self.connectionInfoList = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

@end

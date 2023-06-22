//
//  Stations.m
//  SBB XML API Controller
//
//  Created by Alain on 20.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "Stations.h"


@implementation Stations

@dynamic stationname;
@dynamic searchstationname;
@dynamic searchstationname2;
@dynamic latitude;
@dynamic longitude;
@dynamic externalid;

@synthesize distance;

- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D coordinate;
	
	coordinate.longitude =  [[self valueForKey:@"longitude"] floatValue];
	coordinate.latitude = [[self valueForKey:@"latitude"] floatValue];
	
	return coordinate;
}

- (NSString *)title
{
	return [NSString stringWithFormat:@"%@", [self valueForKey:@"stationname"]];
}

- (NSString *)subtitle
{
	return nil;
    return [NSString stringWithFormat:@"%@", [self valueForKey:@"searchstationname"]];
}

- (NSString *)getFormmattedStationDistance {
    if (self.distance > 1000) {
        NSUInteger distanceInKs = self.distance / 1000;
        NSUInteger distanceRest = self.distance - distanceInKs * 1000;
        NSUInteger distanceInHundreds = distanceRest / 100;
        return [NSString stringWithFormat: @"%d.%d km", distanceInKs, distanceInHundreds];
    } else {
        return [NSString stringWithFormat: @"%.0f m", self.distance];
    }
}

@end

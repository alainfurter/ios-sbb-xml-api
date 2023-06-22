//
//  ConnectionsDetailviewController.m
//  SBBXMLAPI
//
//  Created by Alain on 10.06.13.
//  Copyright (c) 2013 Zone Zero Apps. All rights reserved.
//

#import "ConnectionsDetailviewController.h"
#import "ConnectionsDetailviewCell.h"

#import "SBBAPIController.h"

@interface ConnectionsDetailviewController ()

@end

@implementation ConnectionsDetailviewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.connectionResultIndex = 0;
        
        self.view.backgroundColor = [UIColor whiteColor];
    
        self.tableView.rowHeight = 142;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.separatorColor = [UIColor blackColor];
        self.tableView.backgroundColor = [UIColor clearColor];
        [self.tableView registerClass:[ConnectionsDetailviewCell class] forCellReuseIdentifier: @"ConnectionsDetailviewCell"];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_connectionResultIndex < [[SBBAPIController sharedSBBAPIController] getNumberOfConnectionResults]) {
        return [[SBBAPIController sharedSBBAPIController] getNumberOfConsectionsForConnectionResultWithIndex: _connectionResultIndex];
        
    }
    
    return 0;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger consectionsCount = [[SBBAPIController sharedSBBAPIController] getNumberOfConsectionsForConnectionResultWithIndex: _connectionResultIndex];
    ConSection *conSection = [[SBBAPIController sharedSBBAPIController] getConsectionForConnectionResultWithIndexAndConsectionIndex: _connectionResultIndex consectionIndex: indexPath.row];
    
    ConnectionsDetailviewCell *detailViewCell = (ConnectionsDetailviewCell *)cell;
    NSString *startStationName; NSString *endStationName;
    
    startStationName = [[SBBAPIController sharedSBBAPIController] getDepartureStationNameForConsection: conSection];
    endStationName = [[SBBAPIController sharedSBBAPIController] getArrivalStationNameForConsection: conSection];
        
    if (indexPath.row == 0) {
        NSString *betterStartName = [[SBBAPIController sharedSBBAPIController] getBetterDepartureStationNameForConnectionResultWithIndex: _connectionResultIndex];
        startStationName = betterStartName;
    }
    if (indexPath.row == (consectionsCount - 1)) {
        NSString *betterEndName = [[SBBAPIController sharedSBBAPIController] getBetterArrivalStationNameForConnectionResultWithIndex: _connectionResultIndex];
        endStationName = betterEndName;
    }
    
    detailViewCell.startStationLabel.text = startStationName;
    detailViewCell.endStationLabel.text = endStationName;
        
    detailViewCell.startTimeLabel.text = [[SBBAPIController sharedSBBAPIController] getDepartureTimeForConsection: conSection];
    detailViewCell.endTimeLabel.text = [[SBBAPIController sharedSBBAPIController] getArrivalTimeForConsection: conSection];
            
    if ([[SBBAPIController sharedSBBAPIController] isConsectionOfTypeWalk:conSection]) {
        NSString *walkDurationInfo = [[conSection walk] getFormattedDurationStringFromDuration];
        NSString *walkDistanceInfo = [NSString stringWithFormat:@"%@", [[conSection walk] getFormattedMetresStringFromDistance]];
        NSString *walkInfo = [NSString stringWithFormat:@"%@ / %@", walkDurationInfo, walkDistanceInfo];
        detailViewCell.transportInfoLabel.text = walkInfo;
        
        detailViewCell.transportCapacity1stLabel.text = nil;
        detailViewCell.transportCapacity2ndLabel.text = nil;
        
        detailViewCell.startStationTrackLabel.text = nil;
        detailViewCell.endStationTrackLabel.text = nil;
                        
    } else if ([[SBBAPIController sharedSBBAPIController] isConsectionOfTypeJourney:conSection]) {

        NSString *journeyDirectionString = [[conSection journey] journeyDirection];
        detailViewCell.transportInfoLabel.text = journeyDirectionString;
        
        NSString *startTrack = [[SBBAPIController sharedSBBAPIController] getDeparturePlatformForConsection: conSection];
        NSString *endTrack = [[SBBAPIController sharedSBBAPIController] getArrivalPlatformForConsection: conSection];
                
        detailViewCell.startStationTrackLabel.text = startTrack;
        detailViewCell.endStationTrackLabel.text = endTrack;
                
        NSNumber *capacity1st = [[SBBAPIController sharedSBBAPIController] getCapacity1stForConsection: conSection];
        NSNumber *capacity2nd = [[SBBAPIController sharedSBBAPIController] getCapacity2ndForConsection: conSection];
        
        if (capacity1st && capacity2nd) {
            
            BOOL firstok = ([capacity1st integerValue] >= 0 && [capacity1st integerValue] <= 3);
            BOOL secondok = ([capacity2nd integerValue] >= 0 && [capacity2nd integerValue] <= 3);
            
            if (firstok && secondok) {
                detailViewCell.transportCapacity1stLabel.text = [NSString stringWithFormat:@"%@ %@",  @"1.", capacity1st];
                detailViewCell.transportCapacity2ndLabel.text = [NSString stringWithFormat:@"%@ %@",  @"2.", capacity2nd];
                detailViewCell.transportInfoLabel.text = nil;
            } else {
                detailViewCell.transportCapacity1stLabel.text = nil;
                detailViewCell.transportCapacity2ndLabel.text = nil;
            }
            
        } else {
            detailViewCell.transportCapacity1stLabel.text = nil;
            detailViewCell.transportCapacity2ndLabel.text = nil;
        }
    }
    
    detailViewCell.transportNameLabel.text = [[SBBAPIController sharedSBBAPIController] getTransportNameWithConsection:conSection];
    detailViewCell.transportTypeLabel.text = [[SBBAPIController sharedSBBAPIController] getTransportTypeWithConsection:conSection];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 142;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"ConnectionsDetailviewCell"];
    
    [self configureCell: cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return  NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

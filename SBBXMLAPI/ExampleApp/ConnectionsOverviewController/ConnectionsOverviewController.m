//
//  ConnectionsOverviewController.m
//  SBBXMLAPI
//
//  Created by Alain on 10.06.13.
//  Copyright (c) 2013 Zone Zero Apps. All rights reserved.
//

#import "ConnectionsOverviewController.h"

#import "ConnectionsOverviewCell.h"
#import "SBBAPIController.h"

#import "ConnectionsDetailviewController.h"

@interface ConnectionsOverviewController ()

@end

@implementation ConnectionsOverviewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor whiteColor];
        self.view.frame = CGRectMake(0, 0, 320, 460);
        self.tableView.frame = CGRectMake(0, 0, 320, 460);
        self.tableView.contentSize = CGSizeMake(320, 460);
        
        self.tableView.rowHeight = 142;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.separatorColor = [UIColor blackColor];
        self.tableView.backgroundColor = [UIColor clearColor];
        [self.tableView registerClass:[ConnectionsOverviewCell class] forCellReuseIdentifier: @"ConnectionsOverviewCell"];
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
    if ([[SBBAPIController sharedSBBAPIController] getConnectionResults]) {
        return [[SBBAPIController sharedSBBAPIController] getNumberOfConnectionResults];
    }
    return 0;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    ConOverview *overView = [[SBBAPIController sharedSBBAPIController] getOverviewForConnectionResultWithIndex: indexPath.row];
    ConSection *firstConSection = [[SBBAPIController sharedSBBAPIController] getFirstConsectionForConnectionResultWithIndex:indexPath.row];
    ConSection *lastConSection = [[SBBAPIController sharedSBBAPIController] getLastConsectionForConnectionResultWithIndex: indexPath.row];
    
    ConnectionsOverviewCell *overViewCell = (ConnectionsOverviewCell *)cell;
    
    NSString *durationHours = [overView getHoursStringFromDuration];
    NSString *durationMinutes = [overView getMinutesStringFromDuration];
    overViewCell.timeLabel.text = [NSString stringWithFormat: @"Duration: %@:%@", durationHours, durationMinutes];

    overViewCell.changesLabel.text = [NSString stringWithFormat: @"Transfers: %@", [overView transfers]];
        
    // Better use the departure time of the first consection as overall connection departure time
    // and the arrival time of the last consection as overall connection arrival time
    // instead of the departure and arrival time of the overview itself.
    // The reason is that the overview not include the overall departure and arrival time
    // if the first or the last consection is a walking path. In this cases the departure and
    // arrival time is only taken from the first consection with a journey.
    overViewCell.departureTimeLabel.text = [NSString stringWithFormat: @"Departure: %@", [[SBBAPIController sharedSBBAPIController] getDepartureTimeForConsection: firstConSection]];
    overViewCell.arrivalTimeLabel.text = [NSString stringWithFormat: @"Arrival: %@", [[SBBAPIController sharedSBBAPIController] getArrivalTimeForConsection: lastConSection]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 142;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConnectionsOverviewCell"];
        
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
     NSUInteger selectedConnectionIndex = indexPath.row;
    
    ConnectionsDetailviewController *connectionsDetailviewController = [[ConnectionsDetailviewController alloc] initWithStyle:UITableViewStylePlain];
    connectionsDetailviewController.connectionResultIndex = selectedConnectionIndex;
    
    [self.navigationController pushViewController:connectionsDetailviewController animated:YES];

}

@end

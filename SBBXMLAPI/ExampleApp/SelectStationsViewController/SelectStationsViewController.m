//
//  SelectStationsViewController.m
//  SBBXMLAPI
//
//  Created by Alain on 10.06.13.
//  Copyright (c) 2013 Zone Zero Apps. All rights reserved.
//

#import "SelectStationsViewController.h"
#import "ConnectionsOverviewController.h"

@interface SelectStationsViewController ()

@property (strong, nonatomic) UIButton *startStationButton;
@property (strong, nonatomic) UIButton *endStationButton;

@property (strong, nonatomic) UIButton *getConnectionsButton;

@property (strong, nonatomic) NSString *startStationName;
@property (strong, nonatomic) NSString *startStationID;
@property (strong, nonatomic) NSNumber *startStationLatitude;
@property (strong, nonatomic) NSNumber *startStationLongitude;

@property (strong, nonatomic) NSString *endStationName;
@property (strong, nonatomic) NSString *endStationID;
@property (strong, nonatomic) NSNumber *endStationLatitude;
@property (strong, nonatomic) NSNumber *endStationLongitude;

@property (strong, nonatomic) NSString *viaStationName;
@property (strong, nonatomic) NSString *viaStationID;

@end

@implementation SelectStationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.startStationButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _startStationButton.backgroundColor = [UIColor whiteColor];
        _startStationButton.frame = CGRectMake(20, 50, 280, 36);
        _startStationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _startStationButton.showsTouchWhenHighlighted = YES;
        [_startStationButton addTarget: self action: @selector(selectStartStation:) forControlEvents:UIControlEventTouchUpInside];
        [_startStationButton setTitle:@"From:" forState:UIControlStateNormal];
        [self.view addSubview: _startStationButton];
        
        self.endStationButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _endStationButton.backgroundColor = [UIColor whiteColor];
        _endStationButton.frame = CGRectMake(20, 100, 280, 36);
        _endStationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _endStationButton.showsTouchWhenHighlighted = YES;
        [_endStationButton addTarget: self action: @selector(selectEndStation:) forControlEvents:UIControlEventTouchUpInside];
        [_endStationButton setTitle:@"To:" forState:UIControlStateNormal];
        [self.view addSubview: _endStationButton];
        
        self.getConnectionsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _getConnectionsButton.backgroundColor = [UIColor whiteColor];
        _getConnectionsButton.frame = CGRectMake(20, 150, 280, 36);
        _getConnectionsButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _getConnectionsButton.showsTouchWhenHighlighted = YES;
        [_getConnectionsButton addTarget: self action: @selector(getConnections:) forControlEvents:UIControlEventTouchUpInside];
        [_getConnectionsButton setTitle:@"Get connections" forState:UIControlStateNormal];
        [self.view addSubview: _getConnectionsButton];
        
        
    }
    return self;
}

- (void) selectStartStation:(id)sender {
    StationPickerViewController *stationPickerViewController = [[StationPickerViewController alloc] init];
    stationPickerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    stationPickerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    stationPickerViewController.managedObjectContext = self.managedObjectContext;
    stationPickerViewController.delegate = self;
    
    stationPickerViewController.stationTypeIndex = startStationType;
    stationPickerViewController.stationpickerType = connectionsStationpickerType;
    [stationPickerViewController clearStationSetting];
    
    [self.navigationController presentViewController: stationPickerViewController animated: YES completion: nil];
}

- (void) selectEndStation:(id)sender {
    StationPickerViewController *stationPickerViewController = [[StationPickerViewController alloc] init];
    stationPickerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    stationPickerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    stationPickerViewController.managedObjectContext = self.managedObjectContext;
    stationPickerViewController.delegate = self;
    
    stationPickerViewController.stationTypeIndex = endStationType;
    stationPickerViewController.stationpickerType = connectionsStationpickerType;
    [stationPickerViewController clearStationSetting];
    
    [self.navigationController presentViewController: stationPickerViewController animated: YES completion: nil];
}

- (void) getConnections:(id)sender {
    if ([[SBBAPIController sharedSBBAPIController] isRequestInProgress]) {
        [[SBBAPIController sharedSBBAPIController] cancelAllSBBAPIOperations];
    }
    
    // For setting a start GPS position instead of a station, set the latitude and longitute to a location and set the name and station id to NIL
    // For setting an start Adress instead of a station, set the latitude and longitute to a location, set the name to the address and station id to NIL
    Station *startStation = [[Station alloc] init];
    [startStation setStationName: self.startStationName];
    [startStation setStationId: self.startStationID];
    [startStation setLatitude: self.startStationLatitude];
    [startStation setLongitude: self.startStationLongitude];
    
    // For setting an end GPS position instead of a station, set the latitude and longitute to a location and set the name and station id to NIL
    // For setting an end Adress instead of a station, set the latitude and longitute to a location, set the name to the address and station id to NIL
    Station *endStation = [[Station alloc] init];
    [endStation setStationName: self.endStationName];
    [endStation setStationId: self.endStationID];
    [endStation setLatitude: self.endStationLatitude];
    [endStation setLongitude: self.endStationLongitude];
    
    // To implement if necessary
    Station *viaStation = nil;
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if (internetStatus == NotReachable)
    {
        // Show no network error message
        // To implement
        
        return;
    }
    
    if ((!self.startStationName && !self.endStationName) || [self.startStationName isEqualToString: self.endStationName])
	{        
        // Show stations identical message
        // To implement
        
		return;
	}
    
    // Change with your own date from date picker or other source
    NSDate *connectionTime = [NSDate date];
    
    // YES = date/time is departure time, NO = date/time is arrival time
    BOOL isDepartureTime = YES;
    
    [[SBBAPIController sharedSBBAPIController] sendConReqXMLConnectionRequest: startStation
                                                                   endStation: endStation
                                                                   viaStation: viaStation
                                                                      conDate: connectionTime
                                                                departureTime: isDepartureTime
                                                                 successBlock: ^(NSUInteger numberofresults){
                                                                     
                                                                     if (numberofresults > 0) {
                                                                         [self showConnectionsResult];
                                                                     } else {
                                                                         // Show no results error message
                                                                         // To implment
                                                                     }
                                                                 }
                                                                 failureBlock: ^(NSUInteger errorcode){
                                                                     
                                                                     if (errorcode == kConReqRequestFailureConnectionFailed) {
                                                                         // Show connection failed error message
                                                                         // To implement
                                                                     } else if (errorcode == kSbbReqStationsNotDefined) {
                                                                         // Show stations not defined or not available
                                                                         // To implement
                                                                     } else if (errorcode == kConReqRequestFailureCancelled) {
                                                                         // Nothing to do
                                                                     } else if (errorcode == kConRegRequestFailureNoNewResults) {
                                                                         // Show no new results error message
                                                                         // To implement
                                                                     } else {
                                                                         // Show undefined error message
                                                                         // To implement
                                                                     }
                                                                 }];
    
}

- (void) showConnectionsResult {
    ConnectionsOverviewController *connectionsOverviewController = [[ConnectionsOverviewController alloc] initWithStyle: UITableViewStylePlain];
    
    [self.navigationController pushViewController:connectionsOverviewController animated:YES];
}

#pragma mark -
#pragma mark Stationpickercontroller delegate

- (void)didSelectStationWithStationTypeIndex:(StationPickerViewController *)controller stationTypeIndex:(NSUInteger)index station:(Station *)station {
    if (station) {
        if ((station.stationName && station.stationId) || (station.stationName && !station.stationId && station.latitude && station.longitude)) {            
            if (index == startStationType) {
                self.startStationName = station.stationName;
                self.startStationID = station.stationId;
                self.startStationLatitude = station.latitude;
                self.startStationLongitude = station.longitude;
                [_startStationButton setTitle: [NSString stringWithFormat: @"%@ %@", @"From:", station.stationName] forState: UIControlStateNormal];
            } else if (index == endStationType) {
                self.endStationName = station.stationName;
                self.endStationID = station.stationId;
                self.endStationLatitude = station.latitude;
                self.endStationLongitude = station.longitude;
                [_endStationButton setTitle: [NSString stringWithFormat: @"%@ %@", @"To:", station.stationName] forState: UIControlStateNormal];
            } else if (index == viaStationType) {
                // To implement if necessary
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  StationPickerViewController.m
//  SBB XML API Controller
//
//  Created by Alain on 13.12.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "StationPickerViewController.h"

#define BUTTONHEIGHT 36.0
#define TEXTFIELDHEIGHT 30.0
#define SEGMENTHEIGHT 18.0
#define TOOLBARHEIGHT 34.0
#define SCALEFACTORTOOLBARBUTTON 1.0

#define STATIONLEGAL          @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890ÄÖÜÉÈÀÙÌÇÂÊÎÔÛËÏÜŸÒÓäöüéèàùìçâêîôûëïüÿòó "
#define STATIONILLEGAL        @"-/:;()$&@\".,?![]{}#%^*+=_\\|~<>€£¥•"
#define NUMBERLEGAL           @"1234567890"

#define VALIDATIONKEYBOARDTIMEPASSED -1

@interface StationPickerViewController ()

@property (strong, nonatomic) UIView *searchContainerView;

@property (strong, nonatomic) UITableView *stationsTableView;

@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) UIActivityIndicatorView *searchactivityindicator;

@property (strong, nonatomic) NSArray *filteredSearchResults;

@property (strong, nonatomic) UITextField *stationTextField;

@property (strong, nonatomic) UIButton *backButton;

@property (strong, nonatomic) NSString *stationName;
@property (strong, nonatomic) NSString *stationID;
@property (strong, nonatomic) NSNumber *stationlat;
@property (strong, nonatomic) NSNumber *stationlng;

@property (strong, nonatomic) CAShapeLayer *separatorLineLayer;

@property (strong, nonatomic) NSArray *stationsToCurrentLocation;
@property (strong, nonatomic) NSArray *sortedStationsToCurrentLocation;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) NSDate *userLocationDate;

@property (strong, nonatomic) dispatch_queue_t fetchrequestresultsortingqueue;

@end

@implementation StationPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor whiteColor];
                        
        self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        [_backButton setTitle:@"Back" forState:UIControlStateNormal];         
        _backButton.imageView.contentMode = UIViewContentModeCenter;
        _backButton.frame = CGRectMake(5, 0, 60, BUTTONHEIGHT);
        _backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _backButton.showsTouchWhenHighlighted = YES;
        [_backButton addTarget: self action: @selector(pushBackController:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview: _backButton];
        
        self.searchContainerView = [[UIView alloc] initWithFrame: CGRectMake(0, TOOLBARHEIGHT, 320, self.view.frame.size.height - TOOLBARHEIGHT)];
        [self.view addSubview: _searchContainerView];
        
        self.stationTextField = [[UITextField alloc] initWithFrame:CGRectMake(8, 6, self.view.frame.size.width - 12, TEXTFIELDHEIGHT)];
        _stationTextField.borderStyle = UITextBorderStyleRoundedRect;
        _stationTextField.font = [UIFont systemFontOfSize:15];
        _stationTextField.placeholder = NSLocalizedString(@"Current location", @"Station text field default text");
        _stationTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _stationTextField.keyboardType = UIKeyboardTypeDefault;
        _stationTextField.returnKeyType = UIReturnKeyGo;
        _stationTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _stationTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _stationTextField.delegate = self;
        _stationTextField.tag = 1;
        [_searchContainerView addSubview:_stationTextField];
        
        self.stationsTableView = [[UITableView alloc] initWithFrame: CGRectMake(0, 6 + TEXTFIELDHEIGHT + 4, self.searchContainerView.bounds.size.width, self.searchContainerView.bounds.size.height -6 - TEXTFIELDHEIGHT - 4) style:UITableViewStylePlain];
        [self.searchContainerView addSubview: _stationsTableView];
        
        _stationsTableView.rowHeight = 25.0f;
        _stationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _stationsTableView.backgroundColor = [UIColor clearColor];
        [_stationsTableView registerClass:[StationsCell class] forCellReuseIdentifier: @"StationsCell"];
        
        _stationsTableView.dataSource = self;
        _stationsTableView.delegate = self;
        
        self.separatorLineLayer = CAShapeLayer.layer;
        [self.view.layer addSublayer:_separatorLineLayer];
        _separatorLineLayer.strokeColor = [UIColor blackColor].CGColor;
        _separatorLineLayer.lineWidth = .5;
        _separatorLineLayer.fillColor = nil;
        [self.searchContainerView.layer addSublayer: _separatorLineLayer];
        
        CGRect ownframe = _searchContainerView.frame;
        CGFloat lineWidth = _separatorLineLayer.lineWidth;
        UIBezierPath *borderBottomPath = [UIBezierPath bezierPathWithRect: CGRectMake(ownframe.origin.x, 6 + TEXTFIELDHEIGHT + 4 - lineWidth, ownframe.size.width, lineWidth)];
        self.separatorLineLayer.path = borderBottomPath.CGPath;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
        [nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
        
        self.fetchrequestresultsortingqueue = dispatch_queue_create("ch.fasoft.sbbxmlapi.fetchrequestresultsortingqueue", NULL);
        
        self.searchactivityindicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        CGRect textfieldframe = _stationTextField.frame;
        textfieldframe.origin.x = _stationTextField.frame.size.width - 48;
        textfieldframe.origin.y = 5;
        textfieldframe.size.width = _searchactivityindicator.frame.size.width;
        textfieldframe.size.height = _searchactivityindicator.frame.size.height;
        _searchactivityindicator.frame = textfieldframe;
        [_stationTextField addSubview: _searchactivityindicator];
        _searchactivityindicator.alpha = 0.0;
    }
    return self;
}

- (void) pushBackController:(id)sender {
    
    [[SBBAPIController sharedSBBAPIController] cancelAllSBBAPIValOperations];
    
    if (_searchResults != nil) {
        self.searchResults = nil;
    }
    
    [self dismissViewControllerAnimated: YES completion: nil];
}

- (NSString *)removeDoublespacesInStringAndLeadingWhitespaces:(NSString *)string {
    
    NSString *trimmedstring = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
    
    NSArray *parts = [trimmedstring componentsSeparatedByCharactersInSet:whitespaces];
    NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
    return [filteredArray componentsJoinedByString:@" "];
}

- (void)fetchStationsForSearchText:(NSString*)searchText {
    
    NSString *filteredSearchText = [self removeDoublespacesInStringAndLeadingWhitespaces: searchText];
        
    if (!(filteredSearchText && filteredSearchText.length)) {
        self.searchResults = nil;
        [_stationsTableView reloadData];
        return;
    }
    
    NSArray *searchTextSplit = [filteredSearchText componentsSeparatedByString: @" "];
    NSMutableArray *searchresults = [NSMutableArray array];
        
    if (searchTextSplit && searchTextSplit.count > 0) {
        NSString *searchtextstring = [searchTextSplit objectAtIndex: 0];
                
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sn beginswith[cd] %@", searchtextstring];
        
        NSString *firstLetter = [searchtextstring substringToIndex:1];

        if ([[firstLetter uppercaseString] isEqualToString: @"Ä"]) {
            firstLetter = @"a";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ö"]) {
            firstLetter = @"o";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ü"]) {
            firstLetter = @"u";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"É"]) {
            firstLetter = @"e";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"È"]) {
            firstLetter = @"e";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"À"]) {
            firstLetter = @"a";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ù"]) {
            firstLetter = @"u";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ì"]) {
            firstLetter = @"i";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ç"]) {
            firstLetter = @"c";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Â"]) {
            firstLetter = @"a";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ê"]) {
            firstLetter = @"e";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Î"]) {
            firstLetter = @"i";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ô"]) {
            firstLetter = @"o";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Û"]) {
            firstLetter = @"u";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ë"]) {
            firstLetter = @"e";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ï"]) {
            firstLetter = @"i";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ü"]) {
            firstLetter = @"u";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ÿ"]) {
            firstLetter = @"y";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ò"]) {
            firstLetter = @"o";
        }
        if ([[firstLetter uppercaseString] isEqualToString: @"Ó"]) {
            firstLetter = @"o";
        }
        
        NSCharacterSet *numberSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        NSRange nr = [firstLetter rangeOfCharacterFromSet:numberSet];
        NSString *relationTo;
        if (nr.location != NSNotFound) {
            relationTo = [NSString stringWithFormat: @"numsTo"];
            firstLetter = @"NUMS";
        } else {
            relationTo = [NSString stringWithFormat: @"%@To", [firstLetter lowercaseString]];
        }
        
        NSManagedObjectContext *context = self.managedObjectContext;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity: [NSEntityDescription entityForName:[firstLetter uppercaseString] inManagedObjectContext:context]];
        [request setPredicate: predicate];
        
        [request setFetchBatchSize:100];
        
        NSString *sortKeyM = @"snp";
        NSString *sortKeyP2 = [NSString stringWithFormat: @"%@.firstlettercode", relationTo];
        NSString *sortKeyP1 = [NSString stringWithFormat: @"%@.transportcode", relationTo];
        
        NSSortDescriptor *stationSortDescM = [[NSSortDescriptor alloc] initWithKey:sortKeyM ascending:YES];
        NSSortDescriptor *stationSortDescP1 = [[NSSortDescriptor alloc] initWithKey:sortKeyP1 ascending:NO];
        NSSortDescriptor *stationSortDescP2 = [[NSSortDescriptor alloc] initWithKey:sortKeyP2 ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: stationSortDescM ,stationSortDescP1, stationSortDescP2, nil];
        
        [request setSortDescriptors:sortDescriptors];
        
        [request setFetchLimit:200];
                
        [context executeFetchRequestInBackground: request onComplete:^(NSArray *results) {
            if (searchTextSplit.count > 1) {
                
                dispatch_async(_fetchrequestresultsortingqueue, ^(void) {
                    
                    NSArray *filteredArray = [results objectsAtIndexes:[results indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        
                        NSManagedObject *currentObject = (NSManagedObject *)obj;
                        NSString *entityName = currentObject.entity.name;
                        NSString *relationName = [NSString stringWithFormat: @"%@To", [entityName lowercaseString]];
                        NSManagedObject *station = (NSManagedObject *)[currentObject valueForKey: relationName];
                        NSString *stationname = [station valueForKey: @"stationname"];
                        NSString *teststring = [searchTextSplit objectAtIndex: 1];
                        
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", teststring];
                        BOOL result = [predicate evaluateWithObject:stationname];
                        return result;
                        
                    }]];
                    
                    [searchresults addObjectsFromArray: filteredArray];
                    
                    if (searchresults && searchresults.count > 0) {
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            self.searchResults = nil;
                            self.searchResults = searchresults;
                        
                            [_stationsTableView reloadData];
                            
                        });
                    } else {
                        self.searchResults = nil;
                        
                        [_stationsTableView reloadData];
                    }
                });
                
            } else {
                [searchresults addObjectsFromArray: results];
                
                if (searchresults && searchresults.count > 0) {
                    self.searchResults = nil;
                    self.searchResults = searchresults;
                                        
                    [_stationsTableView reloadData];
                } else {
                    self.searchResults = nil;
                                        
                    [_stationsTableView reloadData];
                }
            }
        }
                                         onError:^(NSError *error) {
                                             NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                             return;
                                         }];
        
        
    }
}

#pragma mark -
#pragma mark Table view data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_searchResults count] > 0) {
        _stationsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    } else {
        _stationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return [self.searchResults count];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (_searchResults) {
        NSManagedObject *currentObject = [self.searchResults objectAtIndex: indexPath.row];
        NSString *entityName = currentObject.entity.name;
        NSString *relationName = [NSString stringWithFormat: @"%@To", [entityName lowercaseString]];
        
        NSManagedObject *station = (NSManagedObject *)[currentObject valueForKey: relationName];
        StationsCell *stationsCell = (StationsCell *)cell;
        [stationsCell.titleLabel setText: [station valueForKey: @"stationname"]];
        stationsCell.stationId = [station valueForKey: @"externalid"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if ([tableView isEqual: _stationsTableView]) {
        cell = (StationsCell *)[tableView dequeueReusableCellWithIdentifier:@"StationsCell"];
    }

    [self configureCell: cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath: indexPath animated: NO];
    
    Station *station = [[Station alloc] init];
    
    [[SBBAPIController sharedSBBAPIController] cancelAllSBBAPIValOperations];
    
    StationsCell *stationCell = (StationsCell *)[tableView cellForRowAtIndexPath: indexPath];
    self.stationName = stationCell.titleLabel.text;
    
    self.stationID = stationCell.stationId;
    self.stationlat = stationCell.stationlat;
    self.stationlng = stationCell.stationlng;
    
    station.stationName = self.stationName;
    station.stationId = self.stationID;
    station.latitude = self.stationlat;
    station.longitude = self.stationlng;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectStationWithStationTypeIndex:stationTypeIndex:station:)])
    {
        [self.delegate didSelectStationWithStationTypeIndex: self stationTypeIndex: self.stationTypeIndex station: station];
    }
    
    [self.stationTextField resignFirstResponder];
    
    if (self.searchResults != nil) {
        self.searchResults = nil;
    }
    
    [self.stationsTableView reloadData];
    
    [self dismissViewControllerAnimated: YES completion: nil];

}

// override to support editing the table view
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}

#pragma mark -
#pragma mark Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    NSValue *aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    
    NSTimeInterval animationDuration = 0.300000011920929;
    CGRect frame = self.stationsTableView.frame;
    frame.size.height = self.view.frame.size.height - BUTTONHEIGHT - 4 - TEXTFIELDHEIGHT - 4 - keyboardSize.height;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    self.stationsTableView.frame = frame;
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
        
    NSTimeInterval animationDuration = 0.300000011920929;
    CGRect frame = self.stationsTableView.frame;
    frame.size.height = self.view.frame.size.height - BUTTONHEIGHT - 4 - TEXTFIELDHEIGHT - 4;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    self.stationsTableView.frame = frame;
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self fetchStationsForSearchText: textField.text];
    [textField resignFirstResponder];
	return (YES);
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = @"";
    [self fetchStationsForSearchText: textField.text];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSCharacterSet *cs;
	NSString *filtered;
        
    [[SBBAPIController sharedSBBAPIController] cancelAllSBBAPIValOperations];
        
    const char * _char = [string cStringUsingEncoding:NSUTF8StringEncoding];
    int isBackSpace = strcmp(_char, "\b");
    
    if (isBackSpace == -8) {
        //NSLog(@"Characters in range is backspace");
        NSString *textfieldText = textField.text;
        if ([textfieldText length]>0) {
            NSString *searchString = [textfieldText substringToIndex:[textfieldText length]-1];
            [self fetchStationsForSearchText: searchString];
            return YES;
        }
        
        [self fetchStationsForSearchText: nil];
        return YES;
    }
    
	if (textField.text.length >= 35 && range.length == 0)
	{
		// max station name reached
        return(NO);
	}
    
    cs = [[NSCharacterSet characterSetWithCharactersInString:STATIONLEGAL] invertedSet];
    filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    NSString *searchString = [textField.text stringByAppendingString: filtered];
    [self fetchStationsForSearchText: searchString];
    return [string isEqualToString:filtered];
}

- (void) clearStationSetting {
    self.stationTextField.text = nil;
    self.stationName = nil;
    self.stationID = nil;
    self.stationlat = nil;
    self.stationlng = nil;
}

// ------------------------------------------------------------------------------------------------------

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [[SBBAPIController sharedSBBAPIController] cancelAllSBBAPIValOperations];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];

    [self fetchStationsForSearchText: nil];
    [self.stationTextField becomeFirstResponder];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

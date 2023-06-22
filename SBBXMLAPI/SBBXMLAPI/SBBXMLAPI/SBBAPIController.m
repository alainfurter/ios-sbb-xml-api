//
//  SBBAPIController.m
//  SBB XML API Controller
//
//  Created by Alain on 29.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "SBBAPIController.h"

//--------------------------------------------------------------------------------

#define kSBBXMLAPI_BASE_URL                 @"http://fahrplan.sbb.ch/"
#define kSBBXMLAPI_URL_PATH                 @"bin/extxml.exe"

#define kSBBXMLAPI_KEY                      @"YJpyuPISerpXNNRTo50fNMP0yVu7L6IMuOaBgS0Xz89l3f6I3WhAjnto4kS9oz1"

//--------------------------------------------------------------------------------

#define kErrorWritingSpoolfile              @"Error writing the spoolfile"
#define kErrorInvalidValueInRequest         @"Invalid value"
#define kErrorNoTrainsInResult              @"No trains in result"
#define kErrorNoMessageAvailable            @"No message available"
#define kErrorStationDoesNotExist           @"station does not exist"
#define kErrorStationsToClose               @"Departure/Arrival are too near" //Code K895
#define kErrorStationNotDefined             @"No connections found; at least one station doesn't exist in the requested timetable pool" //Code K899

//--------------------------------------------------------------------------------

#define kConReq_XML_SOURCE                  @"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?><ReqC lang=\"APILOCALE\" prod=\"iPhone3.1\" ver=\"2.3\" accessId=\"YJpyuPISerpXNNRTo50fNMP0yVu7L6IMuOaBgS0Xz89l3f6I3WhAjnto4kS9oz1\"><ConReq>STARTXMLENDXMLCONVIAXML<ReqT a=\"ARRDEPCODE\" date=\"CONDATE\" time=\"CONTIME\" /><RFlags b=\"0\" f=\"NUMBEROFREQUESTS\" sMode=\"N\"/></ConReq></ReqC>"

#define kConReq_XML_VIA_SOURCE              @"<Via><Station name=\"VIASTATIONNAME\" externalId=\"VIASTATIONID\"/><Prod prod=\"VIAPRODUCTCODE\"/></Via>"

#define kConReq_XML_START_STATION_SOURCE    @"<Start><Station name=\"STARTSTATIONNAME\" externalId=\"STARTSTATIONID\"/><Prod prod=\"PRODUCTCODE\"/></Start>"
#define kConReq_XML_START_POI_SOURCE        @"<Start><Coord type=\"WGS84\" z=\"\" y=\"LATITUDE\" x=\"LONGITUDE\"/><Prod  prod=\"PRODUCTCODE\"/></Start>"

#define kConReq_XML_END_STATION_SOURCE      @"<Dest><Station name=\"ENDSTATIONNAME\" externalId=\"ENDSTATIONID\"/></Dest>"
#define kConReq_XML_END_POI_SOURCE          @"<Dest><Coord type=\"WGS84\" z=\"\" y=\"LATITUDE\" x=\"LONGITUDE\"/></Dest>"

#define kConScr_XML_SOURCE               @"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?><ReqC lang=\"APILOCALE\" prod=\"iPhone3.1\" ver=\"2.3\" accessId=\"YJpyuPISerpXNNRTo50fNMP0yVu7L6IMuOaBgS0Xz89l3f6I3WhAjnto4kS9oz1\"><ConScrReq scrDir=\"CONSCRDIRFLAG\" nrCons=\"NUMBEROFREQUESTS\"><ConResCtxt>CONSCRREQUESTID</ConResCtxt></ConScrReq></ReqC>"

//--------------------------------------------------------------------------------

#define kStbReq_XML_SOURCE                  @"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?><ReqC ver=\"1.7\" prod=\"testsystem\" lang=\"APILOCALE\" accessId=\"YJpyuPISerpXNNRTo50fNMP0yVu7L6IMuOaBgS0Xz89l3f6I3WhAjnto4kS9oz1\"><STBReq boardType=\"STBREQTYPE\" maxJourneys=\"STBREQNUM\"><Time>STBTIME</Time><Period><DateBegin><Date>STBDATE</Date></DateBegin><DateEnd><Date>STBDATE</Date></DateEnd></Period><TableStation externalId=\"STBSTATIONID\"/><ProductFilter>PRODUCTCODE</ProductFilter>DIRECTIONFILTER</STBReq></ReqC>"

#define kStbReq_XML_DIR_SOURCE              @"<DirectionFilter externalId=\"DIRSTATIONID\"/>"

//--------------------------------------------------------------------------------

#define kJourneyReq_XML_SOURCE              @"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?><ReqC lang=\"APILOCALE\" prod=\"iPhone3.1\" ver=\"2.3\" accessId=\"YJpyuPISerpXNNRTo50fNMP0yVu7L6IMuOaBgS0Xz89l3f6I3WhAjnto4kS9oz1\"><JourneyReq date=\"JRNDATE\" externalId=\"STATIONID\" time=\"JRNTIME\" type=\"JRNREQTYPE\"><JHandle tNr=\"JRNTNR\" cycle=\"JRNCYCLE\" puic=\"JRNPUIC\"/></JourneyReq></ReqC>"

//--------------------------------------------------------------------------------

#define kValidationReq_XML_SOURCE           @"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?><ReqC lang=\"APILOCALE\" prod=\"iPhone3.1\" ver=\"2.3\" accessId=\"YJpyuPISerpXNNRTo50fNMP0yVu7L6IMuOaBgS0Xz89l3f6I3WhAjnto4kS9oz1\"><LocValReq id=\"INPUTID\" sMode=\"1\"><ReqLoc match=\"STATIONNAME\" type=\"ALLTYPE\"/></LocValReq></ReqC>"

#define kClosestStationsReq_XML_SOURCE      @"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?><ReqC ver=\"1.1\" prod=\"JP\" lang=\"APILOCALE\" clientVersion=\"2.1.7\"><LocValReq id=\"INPUTID\" sMode=\"1\"><Coord x=\"LONGITUDE\" y=\"LATITUDE\" type=\"ST\"></Coord></LocValReq></ReqC>"

//--------------------------------------------------------------------------------

#define kPRODUCT_CODE_ALL                   @"1111111111000000"
#define kPRODUCT_CODE_LONGDISTANCETRAIN     @"1110000000000000"
#define kPRODUCT_CODE_REGIOTRAIN            @"0001110000000000"
#define kPRODUCT_CODE_TRAM_BUS              @"0000001111000000"

@interface SBBAPIController ()

@property (strong, nonatomic) NSOperationQueue *conreqBackgroundOpQueue;
@property (strong, nonatomic) NSOperationQueue *stbreqBackgroundOpQueue;
@property (strong, nonatomic) NSOperationQueue *valreqBackgroundOpQueue;
@property (strong, nonatomic) NSOperationQueue *stareqBackgroundOpQueue;

@property (strong, nonatomic) Connections *connectionsResult;

@property (strong, nonatomic) StationboardResults *stationboardResult;
@property (strong, nonatomic) StationboardResults *stationboardResultFastTrainOnly;
@property (strong, nonatomic) StationboardResults *stationboardResultRegioTrainOnly;
@property (strong, nonatomic) StationboardResults *stationboardResultTramBusOnly;

@property (strong, nonatomic) Journey *journeyResult;

@property (strong, nonatomic) AFHTTPClient *conreqHttpClient;
@property (strong, nonatomic) AFHTTPClient *stbreqHttpClient;

@property (strong, nonatomic) AFHTTPClient *valreqHttpClient;
@property (strong, nonatomic) AFHTTPClient *stareqHttpClient;

@property (assign) __block BOOL conreqRequestInProgress;
@property (assign) __block BOOL stbreqRequestInProgress;
@property (assign) __block BOOL valreqRequestInProgress;
@property (assign) __block BOOL stareqRequestInProgress;

//@property (assign) __block BOOL conreqRequestCancelledFlag;
@property (assign) __block BOOL conscrRequestCancelledFlag;
//@property (assign) __block BOOL stbreqRequestCancelledFlag;
@property (assign) __block BOOL stbscrRequestCancelledFlag;
//@property (assign) __block BOOL rssreqRequestCancelledFlag;

@property (assign) NSUInteger sbbApiLanguageLocale;

@property (assign) NSUInteger sbbConReqNumberOfConnectionsForRequest;
@property (assign) NSUInteger sbbConScrNumberOfConnectionsForRequest;
@property (assign) NSUInteger sbbStbReqNumberOfConnectionsForRequest;
@property (assign) NSUInteger sbbStbScrNumberOfConnectionsForRequest;

@property (assign) NSUInteger sbbApiConreqTimeout;
@property (assign) NSUInteger sbbApiStbreqTimeout;
@property (assign) NSUInteger sbbApiValreqTimeout;
@property (assign) NSUInteger sbbApiStareqTimeout;

@end

@implementation SBBAPIController

+ (SBBAPIController *)sharedSBBAPIController
{
    static SBBAPIController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SBBAPIController alloc] init];
        
        sharedInstance.conreqRequestInProgress = NO;
        sharedInstance.stbreqRequestInProgress = NO;
        sharedInstance.valreqRequestInProgress = NO;
        sharedInstance.stareqRequestInProgress = NO;
        
        sharedInstance.sbbApiLanguageLocale = reqEnglish;
        
        sharedInstance.sbbConReqNumberOfConnectionsForRequest = 4;
        sharedInstance.sbbConScrNumberOfConnectionsForRequest = 4;
        sharedInstance.sbbStbReqNumberOfConnectionsForRequest = 40;
        sharedInstance.sbbStbScrNumberOfConnectionsForRequest = 40;
        
        sharedInstance.sbbApiConreqTimeout = SBBAPIREQUESTCONREQSTANDARDTIMEOUT;
        sharedInstance.sbbApiStbreqTimeout = SBBAPIREQUESTSTBREQSTANDARDTIMEOUT;
        sharedInstance.sbbApiValreqTimeout = SBBAPIREQUESTVALREQSTANDARDTIMEOUT;
        sharedInstance.sbbApiStareqTimeout = SBBAPIREQUESTVALREQSTANDARDTIMEOUT;
                
        sharedInstance.conreqBackgroundOpQueue = [[NSOperationQueue alloc] init];
        sharedInstance.stbreqBackgroundOpQueue = [[NSOperationQueue alloc] init];
        sharedInstance.valreqBackgroundOpQueue = [[NSOperationQueue alloc] init];
        sharedInstance.stareqBackgroundOpQueue = [[NSOperationQueue alloc] init];
    });
    
    return sharedInstance;
}

- (void) setSBBAPILanguageLocale:(NSUInteger)languagelocale {
    if (languagelocale == reqEnglish || languagelocale == reqGerman || languagelocale == reqFrench || languagelocale == reqItalian) {
        self.sbbApiLanguageLocale = languagelocale;
    }
}

- (void) setSBBAPIConreqTimeout:(NSUInteger)timeout {
    self.sbbApiConreqTimeout = timeout;
}

- (void) setSBBAPIStbreqTimeout:(NSUInteger)timeout {
    self.sbbApiStbreqTimeout = timeout;
}

- (void) setSBBConReqNumberOfConnectionsForRequest:(NSUInteger)numberofconnections {
    if (numberofconnections > 4) {
        self.sbbConReqNumberOfConnectionsForRequest = numberofconnections;
    }
}

- (void) setSBBConScrNumberOfConnectionsForRequest:(NSUInteger)numberofconnections {
    if (numberofconnections > 4) {
        self.sbbConScrNumberOfConnectionsForRequest = numberofconnections;
    }
}

- (void) setSBBStbReqNumberOfConnectionsForRequest:(NSUInteger)numberofconnections {
    if (numberofconnections > 4) {
        self.sbbStbReqNumberOfConnectionsForRequest = numberofconnections;
    }
}

- (void) setSBBStbScrNumberOfConnectionsForRequest:(NSUInteger)numberofconnections {
    if (numberofconnections > 4) {
        self.sbbStbScrNumberOfConnectionsForRequest = numberofconnections;
    }
}

- (void) logTimeStampWithText:(NSString *)text {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss:SS yyyyMMdd"];
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:1]];
    NSString *dateString = [dateFormatter stringFromDate: [NSDate date]];
    NSLog(@"%@, %@", text, dateString);
}

- (void) sendConReqXMLConnectionRequest:(Station *)startStation endStation:(Station *)endStation viaStation:(Station *)viaStation conDate:(NSDate *)condate departureTime:(BOOL)departureTime successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {

    if (!startStation || !endStation || !condate) {
        return;
    }
            
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate: condate];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeString = [timeFormatter stringFromDate: condate];
    
    NSString *xmlString = kConReq_XML_SOURCE;
    NSString *xmlStartString;
    NSString *xmlEndString;
        
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    if (startStation.stationName && startStation.stationId) {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"Start station set");
        #endif
        
        xmlStartString = kConReq_XML_START_STATION_SOURCE;
        xmlStartString = [xmlStartString stringByReplacingOccurrencesOfString: @"STARTSTATIONNAME" withString: [startStation stationName]];
        xmlStartString = [xmlStartString stringByReplacingOccurrencesOfString: @"STARTSTATIONID" withString: [startStation stationId]];
        xmlStartString = [xmlStartString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_ALL];
    } else {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"Start poi set: %.6f, %.6f", [[startStation latitude] floatValue], [[startStation longitude] floatValue]);
        #endif        
        
        xmlStartString = kConReq_XML_START_POI_SOURCE;
        int latitude = (int)([[startStation latitude] floatValue] * 1000000);
        int longitude = (int)([[startStation longitude] floatValue] * 1000000);
        
        xmlStartString = [xmlStartString stringByReplacingOccurrencesOfString: @"LATITUDE" withString: [NSString stringWithFormat: @"%d", latitude]];
        xmlStartString = [xmlStartString stringByReplacingOccurrencesOfString: @"LONGITUDE" withString: [NSString stringWithFormat: @"%d", longitude]];
        xmlStartString = [xmlStartString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_ALL];
    }
    
    if (endStation.stationName && endStation.stationId) {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"End station set");
        #endif
        
        xmlEndString = kConReq_XML_END_STATION_SOURCE;
        xmlEndString = [xmlEndString stringByReplacingOccurrencesOfString: @"ENDSTATIONNAME" withString: [endStation stationName]];
        xmlEndString = [xmlEndString stringByReplacingOccurrencesOfString: @"ENDSTATIONID" withString: [endStation stationId]];
    } else {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"End poi set: %.6f, %.6f", [[endStation latitude] floatValue], [[endStation longitude] floatValue]);
        #endif
        
        int latitude = (int)([[endStation latitude] floatValue] * 1000000);
        int longitude = (int)([[endStation longitude] floatValue] * 1000000);
        xmlEndString = kConReq_XML_END_POI_SOURCE;
        xmlEndString = [xmlEndString stringByReplacingOccurrencesOfString: @"LATITUDE" withString: [NSString stringWithFormat: @"%d", latitude]];
        xmlEndString = [xmlEndString stringByReplacingOccurrencesOfString: @"LONGITUDE" withString: [NSString stringWithFormat: @"%d", longitude]];
    }
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    NSString *numberofrequestsstring = [NSString stringWithFormat: @"%d", self.sbbConReqNumberOfConnectionsForRequest];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"NUMBEROFREQUESTS" withString: numberofrequestsstring];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STARTXML" withString: xmlStartString];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"ENDXML" withString: xmlEndString];
    
    if (viaStation) {
        NSString *xmlViaString = kConReq_XML_VIA_SOURCE;
        xmlViaString = [xmlViaString stringByReplacingOccurrencesOfString: @"VIASTATIONNAME" withString: [viaStation stationName]];
        xmlViaString = [xmlViaString stringByReplacingOccurrencesOfString: @"VIASTATIONID" withString: [viaStation stationId]];
        xmlViaString = [xmlViaString stringByReplacingOccurrencesOfString: @"VIAPRODUCTCODE" withString: kPRODUCT_CODE_ALL];
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONVIAXML" withString: xmlViaString];
        
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONVIAXML" withString: @""];
    }
    
    if (departureTime) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"ARRDEPCODE" withString: @"0"];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"ARRDEPCODE" withString: @"1"];
    }
    
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONDATE" withString: dateString];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONTIME" withString: timeString];
    
    
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
            
    self.conreqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.conreqHttpClient) {
        [self.conreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.conreqHttpClient = nil;
    }

    self.conreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.conreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.conreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiConreqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
  
        #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Conreq end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Conreq cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kConReqRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *conreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakConreqDecodingXMLOperation = conreqDecodingXMLOperation;
        
        [conreqDecodingXMLOperation addExecutionBlock: ^(void) {
            
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_conreq_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
                        
            Connections *tempConnections = nil;
            tempConnections = [[Connections alloc] init];
            
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                #ifdef SBBAPILogLevelCancel
                if (!weakConreqDecodingXMLOperation) {
                    NSLog(@"Weak reference not set");
                } else {
                    if ([weakConreqDecodingXMLOperation isConcurrent]) {
                        NSLog(@"Conreq op is concurrent");
                    }
                    if ([weakConreqDecodingXMLOperation isExecuting]) {
                        NSLog(@"Conreq op is executing");
                    }
                    if ([weakConreqDecodingXMLOperation isFinished]) {
                        NSLog(@"Conreq op is finished");
                    }
                }
                #endif
                
                
                if ([weakConreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Conreq cancelled. Con queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kConReqRequestFailureCancelled);
                        }];
                    }
                    return;
                }
                
                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *conResNode = [xmlResponse nodeForXPath: @"//ConRes" error: nil];
                    if (conResNode) {
                        NSString *direction = [[(CXMLElement *)conResNode attributeForName: @"dir"] stringValue];
                        tempConnections.direction = direction;
                        tempConnections.searchdate = condate;
                        tempConnections.searchdateisdeparturedate = departureTime;
                        
                        for (CXMLElement *conResElement in [conResNode children]) {
                            
                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                #ifdef SBBAPILogLevelCancel
                                NSLog(@"Conreq cancelled. Con queue block. For each 1");
                                #endif
                                
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                        failureBlock(kConReqRequestFailureCancelled);
                                    }];
                                }
                                return;
                            }
                            
                            #ifdef SBBAPILogLevelFull
                            NSLog(@"Current child: %@", [conResElement name]);
                            #endif
                            
                            if ([[conResElement name] isEqualToString: @"ConResCtxt"]) {
                                NSString *conId = [conResElement stringValue];
                                NSArray *conIdSplit = [conId componentsSeparatedByString: @"#"];
                                if (conIdSplit && conIdSplit.count == 2) {
                                    tempConnections.conIdexconscrid = [conIdSplit objectAtIndex: 0];
                                    tempConnections.conscridbackwards = [NSNumber numberWithInt: [[conIdSplit objectAtIndex: 1] integerValue]];
                                    tempConnections.conscridforward = [NSNumber numberWithInt: [[conIdSplit objectAtIndex: 1] integerValue]];
                                    
                                    #ifdef SBBAPILogLevelFull
                                    NSLog(@"Conidex: %@, conidback, conidfwd: %d", [conIdSplit objectAtIndex: 0], [[conIdSplit objectAtIndex: 1] integerValue]);
                                    #endif
                                }
                                tempConnections.conId = [conResElement stringValue];
                                
                                #ifdef SBBAPILogLevelFull
                                NSLog(@"ConRes id: %@",tempConnections.conId);
                                #endif
                            }
                        }
                        
                        CXMLNode *connections = [xmlResponse nodeForXPath: @"//ConnectionList" error: nil];
                        if (connections) {
                            for (CXMLElement *currentConnection in [connections children]) {
                                
                                if ([weakConreqDecodingXMLOperation isCancelled]) {
                                    #ifdef SBBAPILogLevelCancel
                                    NSLog(@"Conreq cancelled. Con queue block. For each 2");
                                    #endif
                                    
                                    if (failureBlock) {
                                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                            failureBlock(kConReqRequestFailureCancelled);
                                        }];
                                    }
                                    return;
                                }
                                
                                ConResult *conResult = [[ConResult alloc] init];
                                NSString *connectionId = [[currentConnection attributeForName: @"id"] stringValue];
                                conResult.conResId = connectionId;
                                conResult.searchdate = condate;
                                conResult.searchdateisdeparturedate = departureTime;
                                
                                #ifdef SBBAPILogLevelFull
                                NSLog(@"Connection id: %@", conResult.conResId);
                                #endif
                                
                                for (CXMLElement *currentConnectionElement in [currentConnection children]) {
                                    
                                    if ([weakConreqDecodingXMLOperation isCancelled]) {
                                        #ifdef SBBAPILogLevelCancel
                                        NSLog(@"Conreq cancelled. Con queue block. For each 3");
                                        #endif
                                        
                                        if (failureBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                failureBlock(kConReqRequestFailureCancelled);
                                            }];
                                        }
                                        return;
                                    }
                                    
                                    if ([[currentConnectionElement name] isEqualToString: @"Overview"]) {
                                        ConOverview *conOverView = [[ConOverview alloc] init];
                                        for (CXMLElement *currentOverviewElement in [currentConnectionElement children]) {
                                            
                                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Conreq cancelled. Con queue block. For each 4");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kConReqRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Overview element: %@", [currentOverviewElement name]);
                                            #endif
                                            
                                            if ([[currentOverviewElement name] isEqualToString: @"Date"]) {
                                                NSString *dateString = [currentOverviewElement stringValue];
                                                conOverView.date = dateString;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Overview date: %@", dateString);
                                                #endif
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Departure"]) {
                                                BasicStop *departureStop = [[BasicStop alloc] init];
                                                departureStop.basicStopType = departureType;
                                                Dep *dep = [[Dep alloc] init];
                                                departureStop.dep = dep;
                                                
                                                CXMLNode *departureElements = [currentOverviewElement childAtIndex: 0];
                                                
                                                for (CXMLElement *departureElement in [departureElements children]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Departure element name: %@", [departureElement name]);
                                                    #endif
                                                    
                                                    if ([[departureElement name] isEqualToString: @"Station"]) {
                                                        Station *departureStation = [[Station alloc] init];
                                                        departureStation.stationName = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"name"] stringValue]];
                                                        departureStation.stationId = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"externalId"] stringValue]];
                                                        double latitude = [[[departureElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                        double longitude = [[[departureElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                        departureStation.latitude = [NSNumber numberWithFloat: latitude];
                                                        departureStation.longitude = [NSNumber numberWithFloat: longitude];
                                                        departureStop.station = departureStation;
                                                    } else if ([[departureElement name] isEqualToString: @"Dep"]) {
                                                        for (CXMLElement *currentDepElement in [departureElement children]) {
                                                            if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                                departureStop.dep.timeString = [currentDepElement stringValue];
                                                            } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                                CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                departureStop.dep.platform = platformString;
                                                            }
                                                        }
                                                    } else if ([[departureElement name] isEqualToString: @"StopPrognosis"]) {
                                                        for (CXMLElement *currentDepElement in [departureElement children]) {
                                                            if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                                NSString *capstring = [currentDepElement stringValue];
                                                                departureStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                            } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                                NSString *capstring = [currentDepElement stringValue];
                                                                departureStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                            } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                                NSString *statusstring = [currentDepElement stringValue];
                                                                departureStop.scheduled = statusstring;
                                                            } else if ([[currentDepElement name] isEqualToString: @"Dep"]) {
                                                                for (CXMLElement *currentDepProgElement in [currentDepElement children]) {
                                                                    if ([[currentDepProgElement name] isEqualToString: @"Time"]) {
                                                                        // To implement time changes
                                                                        NSString *depTimeChange = [currentDepProgElement stringValue];
                                                                        departureStop.dep.expectedTimeString = depTimeChange;
                                                                    } else if ([[currentDepProgElement name] isEqualToString: @"Platform"]) {
                                                                        // To implement track changes
                                                                        NSString *depTrackChange = [currentDepProgElement stringValue];
                                                                        departureStop.dep.expectedPlatform = depTrackChange;
                                                                    }
                                                                }
                                                                NSString *statusstring = [currentDepElement stringValue];
                                                                departureStop.scheduled = statusstring;
                                                            }
                                                        }
                                                    }
                                                }
                                                conOverView.departure = departureStop;
                                                
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Arrival"]) {
                                                BasicStop *arrivalStop = [[BasicStop alloc] init];
                                                arrivalStop.basicStopType = arrivalType;
                                                Arr *arr = [[Arr alloc] init];
                                                arrivalStop.arr = arr;
                                                
                                                CXMLNode *arrivalElements = [currentOverviewElement childAtIndex: 0];
                                                
                                                for (CXMLElement *arrivalElement in [arrivalElements children]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Arrival element name: %@", [arrivalElement name]);
                                                    #endif
                                                    
                                                    if ([[arrivalElement name] isEqualToString: @"Station"]) {
                                                        Station *arrivalStation = [[Station alloc] init];
                                                        arrivalStation.stationName = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"name"] stringValue]];
                                                        arrivalStation.stationId = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"externalId"] stringValue]];
                                                        double latitude = [[[arrivalElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                        double longitude = [[[arrivalElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                        arrivalStation.latitude = [NSNumber numberWithFloat: latitude];
                                                        arrivalStation.longitude = [NSNumber numberWithFloat: longitude];
                                                        arrivalStop.station = arrivalStation;
                                                    } else if ([[arrivalElement name] isEqualToString: @"Arr"]) {
                                                        //Arr *arr = [[Arr alloc] init];
                                                        for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                            if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                                arrivalStop.arr.timeString = [currentArrElement stringValue];
                                                                //arrivalStop.arr = arr;
                                                            } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                                CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                arrivalStop.arr.platform = platformString;
                                                            }
                                                        }
                                                    } else if ([[arrivalElement name] isEqualToString: @"StopPrognosis"]) {
                                                        for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                            if ([[currentArrElement name] isEqualToString: @"Arr"]) {
                                                                for (CXMLElement *currentArrProgElement in [currentArrElement children]) {
                                                                    if ([[currentArrProgElement name] isEqualToString: @"Time"]) {
                                                                        // To implement time changes
                                                                        NSString *arrTimeChange = [currentArrProgElement stringValue];
                                                                        arrivalStop.arr.expectedTimeString = arrTimeChange;
                                                                    } else if ([[currentArrProgElement name] isEqualToString: @"Platform"]) {
                                                                        // To implement track changes
                                                                        NSString *arrTrackChange = [currentArrProgElement stringValue];
                                                                        arrivalStop.arr.expectedPlatform = arrTrackChange;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                }
                                                conOverView.arrival = arrivalStop;
                                                
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Transfers"]) {
                                                NSString *transfers = [currentOverviewElement stringValue];
                                                conOverView.transfers = transfers;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Overview transfers: %@", transfers);
                                                #endif
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Duration"]) {
                                                CXMLNode *durationTimeElement = [currentOverviewElement childAtIndex: 0];
                                                NSString *timeString = [(CXMLElement *)durationTimeElement stringValue];
                                                conOverView.duration = timeString;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Overview duration: %@", timeString);
                                                #endif
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Products"]) {
                                                NSString *productString = nil;
                                                for (CXMLElement *currentProduct in [currentOverviewElement children]) {
                                                    NSString *productCategory = [[(CXMLElement *)currentProduct attributeForName: @"cat"] stringValue];
                                                    if (!productString) productString = @"";
                                                    productString = [productString stringByAppendingFormat: @"|%@", [productCategory stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
                                                }
                                                if (productString) {
                                                    productString = [productString substringFromIndex: 1];
                                                    conOverView.products = productString;
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Overview products: %@", productString);
                                                    #endif
                                                }
                                            }
                                            
                                        }
                                        conResult.overView = conOverView;
                                    } else if ([[currentConnectionElement name] isEqualToString: @"ConSectionList"]) {
                                        ConSectionList *conSectionList = [[ConSectionList alloc] init];
                                        
                                        for (CXMLElement *currentConSectionElement in [currentConnectionElement children]) {
                                            
                                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Conreq cancelled. Con queue block. For each 5");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kConReqRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            ConSection *conSection = [[ConSection alloc] init];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Consection element: %@", [currentConSectionElement name]);
                                            #endif
                                            
                                            for (CXMLElement *currentConSectionDetailElement in [currentConSectionElement children]) {
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Consection detail element: %@", [currentConSectionDetailElement name]);
                                                #endif
                                                
                                                if ([[currentConSectionDetailElement name] isEqualToString: @"Departure"]) {
                                                    BasicStop *departureStop = [[BasicStop alloc] init];
                                                    departureStop.basicStopType = departureType;
                                                    Dep *dep = [[Dep alloc] init];
                                                    departureStop.dep = dep;
                                                    CXMLNode *departureElements = [currentConSectionDetailElement childAtIndex: 0];
                                                    
                                                    for (CXMLElement *departureElement in [departureElements children]) {
                                                        
                                                        if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                            #ifdef SBBAPILogLevelCancel
                                                            NSLog(@"Conreq cancelled. Con queue block. For each 6");
                                                            #endif
                                                            
                                                            if (failureBlock) {
                                                                [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                                    failureBlock(kConReqRequestFailureCancelled);
                                                                }];
                                                            }
                                                            return;
                                                        }
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Consection detail element departure: %@", [departureElement name]);
                                                        #endif
                                                        
                                                        if ([[departureElement name] isEqualToString: @"Station"]) {
                                                            Station *departureStation = [[Station alloc] init];
                                                            departureStation.stationName = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"name"] stringValue]];
                                                            departureStation.stationId = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"externalId"] stringValue]];
                                                            double latitude = [[[departureElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[departureElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            departureStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            departureStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            departureStop.station = departureStation;
                                                        } else if ([[departureElement name] isEqualToString: @"Dep"]) {
                                                            for (CXMLElement *currentDepElement in [departureElement children]) {
                                                                if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                                    departureStop.dep.timeString = [currentDepElement stringValue];
                                                                } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                                    CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                                    NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                    departureStop.dep.platform = platformString;
                                                                }
                                                            }
                                                        } else if ([[departureElement name] isEqualToString: @"Address"]) {     // Currenty no name check
                                                            Station *departureStation = [[Station alloc] init];
                                                            departureStation.stationName = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"name"] stringValue]];
                                                            double latitude = [[[departureElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[departureElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            departureStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            departureStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            departureStop.station = departureStation;
                                                        } else if ([[departureElement name] isEqualToString: @"StopPrognosis"]) {
                                                            for (CXMLElement *currentDepElement in [departureElement children]) {
                                                                if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                                    NSString *capstring = [currentDepElement stringValue];
                                                                    departureStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                                } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                                    NSString *capstring = [currentDepElement stringValue];
                                                                    departureStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                                } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                                    NSString *statusstring = [currentDepElement stringValue];
                                                                    departureStop.scheduled = statusstring;
                                                                } else if ([[currentDepElement name] isEqualToString: @"Dep"]) {
                                                                    for (CXMLElement *currentDepProgElement in [currentDepElement children]) {
                                                                        if ([[currentDepProgElement name] isEqualToString: @"Time"]) {
                                                                            // To implement time changes
                                                                            NSString *depTimeChange = [currentDepProgElement stringValue];
                                                                            departureStop.dep.expectedTimeString = depTimeChange;
                                                                        } else if ([[currentDepProgElement name] isEqualToString: @"Platform"]) {
                                                                            // To implement track changes
                                                                            NSString *depTrackChange = [currentDepProgElement stringValue];
                                                                            departureStop.dep.expectedPlatform = depTrackChange;
                                                                        }
                                                                    }
                                                                    NSString *statusstring = [currentDepElement stringValue];
                                                                    departureStop.scheduled = statusstring;
                                                                }
                                                            }
                                                        }
                                                    }
                                                    conSection.departure = departureStop;
                                                    
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Arrival"]) {
                                                    BasicStop *arrivalStop = [[BasicStop alloc] init];
                                                    arrivalStop.basicStopType = arrivalType;
                                                    Arr *arr = [[Arr alloc] init];
                                                    arrivalStop.arr = arr;
                                                    CXMLNode *arrivalElements = [currentConSectionDetailElement childAtIndex: 0];
                                                    
                                                    for (CXMLElement *arrivalElement in [arrivalElements children]) {
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Consection detail element arrival: %@", [arrivalElement name]);
                                                        #endif
                                                        
                                                        if ([[arrivalElement name] isEqualToString: @"Station"]) {
                                                            Station *arrivalStation = [[Station alloc] init];
                                                            arrivalStation.stationName = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"name"] stringValue]];
                                                            arrivalStation.stationId = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"externalId"] stringValue]];
                                                            double latitude = [[[arrivalElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[arrivalElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            arrivalStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            arrivalStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            arrivalStop.station = arrivalStation;
                                                        } else if ([[arrivalElement name] isEqualToString: @"Arr"]) {
                                                            for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                                if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                                    arrivalStop.arr.timeString = [currentArrElement stringValue];
                                                                } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                                    CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                                    NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                    arrivalStop.arr.platform = platformString;
                                                                }
                                                            }
                                                        } else if ([[arrivalElement name] isEqualToString: @"Address"]) {       // Currenty no name check
                                                            Station *arrivalStation = [[Station alloc] init];
                                                            arrivalStation.stationName = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"name"] stringValue]];
                                                            double latitude = [[[arrivalElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[arrivalElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            arrivalStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            arrivalStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            arrivalStop.station = arrivalStation;
                                                        } else if ([[arrivalElement name] isEqualToString: @"StopPrognosis"]) {
                                                            for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                                if ([[currentArrElement name] isEqualToString: @"Arr"]) {
                                                                    for (CXMLElement *currentArrProgElement in [currentArrElement children]) {
                                                                        if ([[currentArrProgElement name] isEqualToString: @"Time"]) {
                                                                            // To implement time changes
                                                                            NSString *arrTimeChange = [currentArrProgElement stringValue];
                                                                            arrivalStop.arr.expectedTimeString = arrTimeChange;
                                                                        } else if ([[currentArrProgElement name] isEqualToString: @"Platform"]) {
                                                                            // To implement track changes
                                                                            NSString *arrTrackChange = [currentArrProgElement stringValue];
                                                                            arrivalStop.arr.expectedPlatform = arrTrackChange;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    conSection.arrival = arrivalStop;
                                                    
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Journey"]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though journey type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = journeyType;
                                                    Journey *journey = [[Journey alloc] init];
                                                    for (CXMLElement *currentJourneyElement in [currentConSectionDetailElement children]) {
                                                        if ([[currentJourneyElement name] isEqualToString: @"JHandle"]) {
                                                            NSString *journeytnr = [[currentJourneyElement attributeForName: @"tNr"] stringValue];
                                                            NSString *journeypuic = [[currentJourneyElement attributeForName: @"puic"] stringValue];
                                                            NSString *journeycycle = [[currentJourneyElement attributeForName: @"cycle"] stringValue];
                                                            
                                                            #ifdef SBBAPILogLevelFull
                                                            NSLog(@"Consection detail element journey handle attribute element type: %@, %@, %@", journeytnr, journeypuic, journeycycle);
                                                            #endif
                                                            
                                                            JourneyHandle *journeyhandle = [[JourneyHandle alloc] init];
                                                            journeyhandle.tnr = journeytnr;
                                                            journeyhandle.puic = journeypuic;
                                                            journeyhandle.cycle = journeycycle;
                                                            journey.journeyHandle = journeyhandle;
                                                        } else if ([[currentJourneyElement name] isEqualToString: @"JourneyAttributeList"]) {
                                                            for (CXMLElement *journeyAttributeElement in [currentJourneyElement children]) {
                                                                CXMLNode *journeyAttributeElementDetail = [journeyAttributeElement childAtIndex: 0];
                                                                
                                                                NSString *attributeType = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"type"] stringValue];
                                                                
                                                                #ifdef SBBAPILogLevelFull
                                                                NSLog(@"Consection detail element journey attribute element type: %@", attributeType);
                                                                #endif
                                                                
                                                                if ([attributeType isEqualToString: @"NAME"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            NSString *journeyName = [[journeyAttributeVariantElement stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                            journey.journeyName = journeyName;
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Name attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"CATEGORY"]) {
                                                                    NSString *categoryCode = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"code"] stringValue];
                                                                    journey.journeyCategoryCode = categoryCode;
                                                                        
                                                                    #ifdef SBBAPILogLevelFull
                                                                    NSLog(@"Category attribute variant element code: %@", categoryCode);
                                                                    #endif
                                                                    
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyCategoryName = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Category attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"NUMBER"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyNumber = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Number attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"ADMINISTRATION"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyAdministration = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Administration attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"OPERATOR"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyOperator = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Operator attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"DIRECTION"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyDirection = [self fromISOLatinToUTF8: [journeyAttributeVariantElement stringValue]];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Direction attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        } else if ([[currentJourneyElement name] isEqualToString: @"PassList"]) {
                                                            for (CXMLElement *journeyPasslistElement in [currentJourneyElement children]) {
                                                                
                                                                BasicStop *basicStop = [[BasicStop alloc] init];
                                                                basicStop.basicStopType = arrivalType;
                                                                Dep *dep = [[Dep alloc] init];
                                                                Arr *arr = [[Arr alloc] init];
                                                                basicStop.dep = dep;
                                                                basicStop.arr = arr;
                                                                                                                                
                                                                for (CXMLElement *basicStopElement in [journeyPasslistElement children]) {
                                                                    
                                                                    #ifdef SBBAPILogLevelFull
                                                                    NSLog(@"Consection detail element arrival: %@", [basicStopElement name]);
                                                                    #endif
                                                                    
                                                                    if ([[basicStopElement name] isEqualToString: @"Station"]) {
                                                                        Station *station = [[Station alloc] init];
                                                                        station.stationName = [self fromISOLatinToUTF8: [[basicStopElement attributeForName: @"name"] stringValue]];
                                                                        station.stationId = [self fromISOLatinToUTF8: [[basicStopElement attributeForName: @"externalId"] stringValue]];
                                                                        double latitude = [[[basicStopElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                                        double longitude = [[[basicStopElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                                        station.latitude = [NSNumber numberWithFloat: latitude];
                                                                        station.longitude = [NSNumber numberWithFloat: longitude];
                                                                        basicStop.station = station;
                                                                    } else if ([[basicStopElement name] isEqualToString: @"Arr"]) {
                                                                        for (CXMLElement *currentArrElement in [basicStopElement children]) {
                                                                            if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                                                basicStop.arr.timeString = [currentArrElement stringValue];
                                                                            } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                                                CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                                basicStop.arr.platform = platformString;
                                                                            }
                                                                        }
                                                                    } else if ([[basicStopElement name] isEqualToString: @"Dep"]) {
                                                                        for (CXMLElement *currentDepElement in [basicStopElement children]) {
                                                                            if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                                                basicStop.dep.timeString = [currentDepElement stringValue];
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                                                CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                                basicStop.dep.platform = platformString;
                                                                            }
                                                                        }
                                                                    } else if ([[basicStopElement name] isEqualToString: @"StopPrognosis"]) {
                                                                        for (CXMLElement *currentDepElement in [basicStopElement children]) {
                                                                            if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                                                NSString *capstring = [currentDepElement stringValue];
                                                                                basicStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                                                NSString *capstring = [currentDepElement stringValue];
                                                                                basicStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                                                NSString *statusstring = [currentDepElement stringValue];
                                                                                basicStop.scheduled = statusstring;
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Dep"]) {
                                                                                for (CXMLElement *currentDepProgElement in [currentDepElement children]) {
                                                                                    if ([[currentDepProgElement name] isEqualToString: @"Time"]) {
                                                                                        // To implement time changes
                                                                                        NSString *depTimeChange = [currentDepProgElement stringValue];
                                                                                        basicStop.dep.expectedTimeString = depTimeChange;
                                                                                    } else if ([[currentDepProgElement name] isEqualToString: @"Platform"]) {
                                                                                        // To implement track changes
                                                                                        NSString *depTrackChange = [currentDepProgElement stringValue];
                                                                                        basicStop.dep.expectedPlatform = depTrackChange;
                                                                                    }
                                                                                }
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Arr"]) {
                                                                                for (CXMLElement *currentArrProgElement in [currentDepElement children]) {
                                                                                    if ([[currentArrProgElement name] isEqualToString: @"Time"]) {
                                                                                        // To implement time changes
                                                                                        NSString *arrTimeChange = [currentArrProgElement stringValue];
                                                                                        basicStop.arr.expectedTimeString = arrTimeChange;
                                                                                    } else if ([[currentArrProgElement name] isEqualToString: @"Platform"]) {
                                                                                        // To implement track changes
                                                                                        NSString *arrTrackChange = [currentArrProgElement stringValue];
                                                                                        basicStop.arr.expectedPlatform = arrTrackChange;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                [journey.passList addObject: basicStop];
                                                            }
                                                        } else if ([[currentJourneyElement name] isEqualToString: @"JProg"]) {
                                                            // To implement
                                                            BOOL journeyOnTime = YES;
                                                            for (CXMLElement *currentJourneyProgElement in [currentJourneyElement children]) {
                                                                if ([[currentJourneyProgElement name] isEqualToString: @"JStatus"]) {
                                                                    NSString *journeyStatus = [currentJourneyProgElement stringValue];
                                                                    if ([journeyStatus isEqualToString: @"SCHEDULED"]) {
                                                                        
                                                                        #ifdef SBBAPILogLevelFull
                                                                        NSLog(@"Journey is on schedule");
                                                                        #endif
                                                                        
                                                                        journeyOnTime = YES;
                                                                    } else if ([journeyStatus isEqualToString: @"DELAY"]) {
                                                                        
                                                                        #ifdef SBBAPILogLevelFull
                                                                        NSLog(@"Journey is delayed");
                                                                        #endif
                                                                        
                                                                        journeyOnTime = NO;
                                                                    }
                                                                }
                                                            }
                                                            journey.journeyIsDelayed = !journeyOnTime;
                                                        }
                                                    }
                                                    conSection.journey = journey;
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Stations is passlist of journey: %d", conSection.journey.passList.count);
                                                    #endif
                                                    
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Walk"]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though walk type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = walkType;
                                                    Walk *walk = [[Walk alloc] init];
                                                    NSString *walkDistance = [[(CXMLElement *)currentConSectionDetailElement attributeForName: @"length"] stringValue];
                                                    walk.distance = walkDistance;
                                                    for (CXMLElement *currentWalkElement in [currentConSectionDetailElement children]) {
                                                        if ([[currentWalkElement name] isEqualToString: @"Duration"]) {
                                                            CXMLNode *durationTimeElement = [currentWalkElement childAtIndex: 0];
                                                            NSString *timeString = [(CXMLElement *)durationTimeElement stringValue];
                                                            walk.duration = timeString;
                                                        }
                                                    }
                                                    conSection.walk = walk;
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"GisRoute"]) {      // Current implement as WALK
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though gisroute type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = walkType;
                                                    Walk *walk = [[Walk alloc] init];
                                                    for (CXMLElement *currentGisRouteElement in [currentConSectionDetailElement children]) {
                                                        if ([[currentGisRouteElement name] isEqualToString: @"Duration"]) {
                                                            CXMLNode *durationTimeElement = [currentGisRouteElement childAtIndex: 0];
                                                            NSString *timeString = [(CXMLElement *)durationTimeElement stringValue];
                                                            walk.duration = timeString;
                                                        } else if ([[currentGisRouteElement name] isEqualToString: @"Distance"]) {
                                                            NSString *walkDistance = [currentGisRouteElement stringValue];
                                                            walk.distance = walkDistance;
                                                        }
                                                    }
                                                    conSection.walk = walk;
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Transfer"]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though transfer type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = journeyType;
                                                    Journey *journey = [[Journey alloc] init];
                                                    journey.journeyDirection = @"-";
                                                    journey.journeyAdministration = nil;
                                                    journey.journeyCategoryName = @"TRANS.";
                                                    journey.journeyCategoryCode = @"9";
                                                    journey.journeyHandle = nil;
                                                    journey.journeyIsDelayed = NO;
                                                    journey.journeyName = @"TRANS.";
                                                    journey.journeyNumber = @"0";
                                                    journey.journeyOperator = @"-";
                                                    
                                                    conResult.hasTransferInConSections = YES;
                                                    
                                                    conSection.journey = journey;
                                                }
                                            }
                                            [conSectionList.conSections addObject: conSection];
                                        }
                                        conResult.conSectionList = conSectionList;
                                    } else if ([[currentConnectionElement name] isEqualToString: @"IList"]) {
                                        // To implement
                                        for (CXMLElement *currentInfoElement in [currentConnectionElement children]) {
                                            
                                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Conreq cancelled. Con queue block. For each 7");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kConReqRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            NSString *headerText = [[currentInfoElement attributeForName: @"header"] stringValue];
                                            NSString *leadText = [[currentInfoElement attributeForName: @"lead"] stringValue];
                                            NSString *textText = [[currentInfoElement attributeForName: @"text"] stringValue];
                                            ConnectionInfo *currentConnectionInfo = [[ConnectionInfo alloc] init];
                                            currentConnectionInfo.header = [self fromISOLatinToUTF8: headerText];
                                            currentConnectionInfo.lead = [self fromISOLatinToUTF8: leadText];
                                            currentConnectionInfo.text = [self fromISOLatinToUTF8: textText];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Connection info: %@, %@, %@", headerText, leadText, textText);
                                            #endif
                                            
                                            [conResult.connectionInfoList addObject: currentConnectionInfo];
                                        }
                                    }
                                }
                                                                
                                if (conResult) {
                                    if (startStation.stationName) {
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Setting better startstation name: %@", startStation.stationName);
                                        #endif
                                        
                                        conResult.knownBetterStartLocationName = startStation.stationName;
                                        tempConnections.knownBetterStartLocationName = startStation.stationName;
                                        if ([conResult conSectionList] && [[conResult conSectionList] conSections] && ([[[conResult conSectionList] conSections] count]>0)) {
                                            ConSection *startSection = [[[conResult conSectionList] conSections] objectAtIndex: 0];
                                            if ([startSection departure] && [[startSection departure] station]) {
                                                Station *departureStation = [[startSection departure] station];
                                                departureStation.stationName = startStation.stationName;
                                            }
                                        }
                                    } else {
                                        conResult.knownBetterStartLocationName = nil;
                                    }
                                    if (endStation.stationName) {
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Setting better endstation name: %@", endStation.stationName);
                                        #endif
                                        
                                        conResult.knownBetterEndLocationName = endStation.stationName;
                                        tempConnections.knownBetterEndLocationName = endStation.stationName;
                                        if ([conResult conSectionList] && [[conResult conSectionList] conSections] && ([[[conResult conSectionList] conSections] count]>0)) {
                                            ConSection *endSection = [[[conResult conSectionList] conSections] lastObject];
                                            if ([endSection departure] && [[endSection arrival] station]) {
                                                Station *arrivalStation = [[endSection arrival] station];
                                                arrivalStation.stationName = endStation.stationName;
                                            }
                                        }
                                    } else {
                                        conResult.knownBetterEndLocationName = nil;
                                    }
                                    
                                    if (conResult.hasTransferInConSections) {
                                        for (ConSection *currentConSection in conResult.conSectionList.conSections) {
                                            if ([[currentConSection.journey journeyCategoryName] isEqualToString: @"TRANS."]) {
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Transfer type add passlist stations");
                                                #endif
                                                [currentConSection.journey.passList addObject: currentConSection.departure];
                                                [currentConSection.journey.passList addObject: currentConSection.arrival];
                                            }
                                        }
                                    }
                                }
                                
                                [tempConnections.conResults addObject: conResult];
                                
                                #ifdef SBBAPILogLevelXMLReqRes
                                NSLog(@"ConRes: %@", conResult);
                                NSLog(@"ConRes #: %d", tempConnections.conResults.count);
                                #endif
                            }
                        } 
                    }
                }
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }
                        
            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Conreq decoding xml"];
            #endif
            
            self.conreqRequestInProgress = NO;
            
            #ifdef SBBAPILogLevelCancel
            if (!weakConreqDecodingXMLOperation) {
                NSLog(@"Weak reference not set");
            } else {
                if ([weakConreqDecodingXMLOperation isConcurrent]) {
                    NSLog(@"Conreq op is concurrent");
                }
                if ([weakConreqDecodingXMLOperation isExecuting]) {
                    NSLog(@"Conreq op is executing");
                }
                if ([weakConreqDecodingXMLOperation isFinished]) {
                    NSLog(@"Conreq op is finished");
                }
            }
            #endif
            
            if ([weakConreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Conreq cancelled. Con queue block. End. MainQueue call");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kConReqRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (tempConnections && tempConnections.conResults.count > 0) {
                
                            self.connectionsResult = tempConnections;
                            
                            #ifdef SBBAPILogLevelXMLReqRes
                            NSLog(@"Connections result: %@", self.connectionsResult);
                            #endif
                            
                            NSUInteger numberofnewresults = 0;
                            numberofnewresults = self.connectionsResult.conResults.count;

                            successBlock(numberofnewresults);
                            
                        } else {
                            if (failureBlock) {
                                failureBlock(kConRegRequestFailureNoNewResults);
                            }
                        }
                    }];
                }
            }
        }];
        [_conreqBackgroundOpQueue addOperation: conreqDecodingXMLOperation];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        self.conreqRequestInProgress = NO;
                
        if (failureBlock) {
            failureBlock(kConReqRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
    [self logTimeStampWithText:@"Conreq start operation"];
    #endif
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

- (void) sendConScrXMLConnectionRequest:(NSUInteger)directionflag successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {
            
    NSString *xmlString = kConScr_XML_SOURCE;

    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    
    if (!self.connectionsResult)  {
        NSUInteger kConScrRequestFailureNoConnectionResult = 41;
        if (failureBlock) {
            failureBlock(kConScrRequestFailureNoConnectionResult);
        }
    }
    if (!self.connectionsResult.direction || !self.connectionsResult.conId)  {
        NSUInteger kConScrRequestFailureNoConnectionId = 42;
        if (failureBlock) {
            failureBlock(kConScrRequestFailureNoConnectionId);
        }
    }
    if (!self.connectionsResult.conIdexconscrid || !self.connectionsResult.conscridbackwards || !self.connectionsResult.conscridforward)  {
        NSUInteger kConScrRequestFailureNoIdExOrBackFwdNumber = 43;
        if (failureBlock) {
            failureBlock(kConScrRequestFailureNoIdExOrBackFwdNumber);
        }
    }
    
    int conIdNumber = 0;
    if (directionflag == conscrBackward) {
          xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONSCRDIRFLAG" withString: @"B"];
          conIdNumber = [self.connectionsResult.conscridbackwards integerValue];
    } else if (directionflag == conscrForward) {
         xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONSCRDIRFLAG" withString: @"F"];
         conIdNumber = [self.connectionsResult.conscridforward integerValue];
    }
    
    NSString *connectionId = [NSString stringWithFormat: @"%@#%d", self.connectionsResult.conIdexconscrid, conIdNumber];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"Connectionindex id: %@", connectionId);
    #endif 
    
    NSDate *connectiondate = self.connectionsResult.searchdate;
    BOOL connectiondateisdeparture = self.connectionsResult.searchdateisdeparturedate;
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"CONSCRREQUESTID" withString: connectionId];
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    NSString *numberofrequestsstring = [NSString stringWithFormat: @"%d", self.sbbConReqNumberOfConnectionsForRequest];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"NUMBEROFREQUESTS" withString: numberofrequestsstring];
        
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
        
    self.conreqRequestInProgress = YES;
 
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.conreqHttpClient) {
        [self.conreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.conreqHttpClient = nil;
    }
    
    self.conreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.conreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.conreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiConreqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Conscr end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Conscr cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kConScrRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *conreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakConreqDecodingXMLOperation = conreqDecodingXMLOperation;
        
        [conreqDecodingXMLOperation addExecutionBlock: ^(void) {
            
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_conreq_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
                    
            Connections *tempConnections = nil;
            tempConnections = [[Connections alloc] init];
            
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakConreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Conscr cancelled. Con queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kConScrRequestFailureCancelled);
                        }];
                    }
                    return;
                }
                
                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *conResNode = [xmlResponse nodeForXPath: @"//ConRes" error: nil];
                    if (conResNode) {
                        NSString *direction = [[(CXMLElement *)conResNode attributeForName: @"dir"] stringValue];
                        tempConnections.direction = direction;
                        tempConnections.searchdate = connectiondate;
                        tempConnections.searchdateisdeparturedate = connectiondateisdeparture;
                        
                        #ifdef SBBAPILogLevelFull
                        NSLog(@"ConRes direction: %@", tempConnections.direction);
                        #endif
                        
                        for (CXMLElement *conResElement in [conResNode children]) {
                            
                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                #ifdef SBBAPILogLevelCancel
                                NSLog(@"Conscr cancelled. Con queue block. For each 1");
                                #endif
                                
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                        failureBlock(kConScrRequestFailureCancelled);
                                    }];
                                }
                                return;
                            }
                            
                            #ifdef SBBAPILogLevelFull
                            NSLog(@"Current child: %@", [conResElement name]);
                            #endif
                            
                            if ([[conResElement name] isEqualToString: @"ConResCtxt"]) {
                                NSString *conId = [conResElement stringValue];
                                NSArray *conIdSplit = [conId componentsSeparatedByString: @"#"];
                                if (conIdSplit && conIdSplit.count == 2) {
                                    if (directionflag == conscrBackward) {
                                        tempConnections.conscridbackwards = [NSNumber numberWithInt: [[conIdSplit objectAtIndex: 1] integerValue]];
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Conidex: %@, conidback %d", [conIdSplit objectAtIndex: 0], [[conIdSplit objectAtIndex: 1] integerValue]);
                                        #endif
                                    } else if (directionflag == conscrForward) {
                                        tempConnections.conscridforward = [NSNumber numberWithInt: [[conIdSplit objectAtIndex: 1] integerValue]];
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Conidex: %@, conidfwd: %d", [conIdSplit objectAtIndex: 0], [[conIdSplit objectAtIndex: 1] integerValue]);
                                        #endif
                                    }
                                }
                                tempConnections.conId = [conResElement stringValue];
                                
                                #ifdef SBBAPILogLevelFull
                                NSLog(@"ConRes id: %@",tempConnections.conId);
                                #endif
                            }
                        }
                        
                        CXMLNode *connections = [xmlResponse nodeForXPath: @"//ConnectionList" error: nil];
                        if (connections) {
                            for (CXMLElement *currentConnection in [connections children]) {
                                
                                if ([weakConreqDecodingXMLOperation isCancelled]) {
                                    #ifdef SBBAPILogLevelCancel
                                    NSLog(@"Conscr cancelled. Con queue block. For each 2");
                                    #endif
                                    
                                    if (failureBlock) {
                                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                            failureBlock(kConScrRequestFailureCancelled);
                                        }];
                                    }
                                    return;
                                }
                                
                                ConResult *conResult = [[ConResult alloc] init];
                                NSString *connectionId = [[currentConnection attributeForName: @"id"] stringValue];
                                conResult.conResId = connectionId;
                                conResult.searchdate = connectiondate;
                                conResult.searchdateisdeparturedate = connectiondateisdeparture;
                                
                                #ifdef SBBAPILogLevelFull
                                NSLog(@"Connection id: %@", conResult.conResId);
                                #endif
                                
                                for (CXMLElement *currentConnectionElement in [currentConnection children]) {
                                    
                                    if ([weakConreqDecodingXMLOperation isCancelled]) {
                                        #ifdef SBBAPILogLevelCancel
                                        NSLog(@"Conscr cancelled. Con queue block. For each 3");
                                        #endif
                                        
                                        if (failureBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                failureBlock(kConScrRequestFailureCancelled);
                                            }];
                                        }
                                        return;
                                    }
                                    
                                    if ([[currentConnectionElement name] isEqualToString: @"Overview"]) {
                                        ConOverview *conOverView = [[ConOverview alloc] init];
                                        for (CXMLElement *currentOverviewElement in [currentConnectionElement children]) {
                                            
                                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Conscr cancelled. Con queue block. For each 4");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kConScrRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Overview element: %@", [currentOverviewElement name]);
                                            #endif
                                            
                                            if ([[currentOverviewElement name] isEqualToString: @"Date"]) {
                                                NSString *dateString = [currentOverviewElement stringValue];
                                                conOverView.date = dateString;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Overview date: %@", dateString);
                                                #endif
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Departure"]) {
                                                BasicStop *departureStop = [[BasicStop alloc] init];
                                                departureStop.basicStopType = departureType;
                                                Dep *dep = [[Dep alloc] init];
                                                departureStop.dep = dep;
                                                
                                                CXMLNode *departureElements = [currentOverviewElement childAtIndex: 0];
                                                
                                                for (CXMLElement *departureElement in [departureElements children]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Departure element name: %@", [departureElement name]);
                                                    #endif
                                                    
                                                    if ([[departureElement name] isEqualToString: @"Station"]) {
                                                        Station *departureStation = [[Station alloc] init];
                                                        departureStation.stationName = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"name"] stringValue]];
                                                        departureStation.stationId = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"externalId"] stringValue]];
                                                        double latitude = [[[departureElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                        double longitude = [[[departureElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                        departureStation.latitude = [NSNumber numberWithFloat: latitude];
                                                        departureStation.longitude = [NSNumber numberWithFloat: longitude];
                                                        departureStop.station = departureStation;
                                                    } else if ([[departureElement name] isEqualToString: @"Dep"]) {
                                                        for (CXMLElement *currentDepElement in [departureElement children]) {
                                                            if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                                departureStop.dep.timeString = [currentDepElement stringValue];
                                                            } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                                CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                departureStop.dep.platform = platformString;
                                                            }
                                                        }
                                                    } else if ([[departureElement name] isEqualToString: @"StopPrognosis"]) {
                                                        for (CXMLElement *currentDepElement in [departureElement children]) {
                                                            if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                                NSString *capstring = [currentDepElement stringValue];
                                                                departureStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                            } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                                NSString *capstring = [currentDepElement stringValue];
                                                                departureStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                            } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                                NSString *statusstring = [currentDepElement stringValue];
                                                                departureStop.scheduled = statusstring;
                                                            } else if ([[currentDepElement name] isEqualToString: @"Dep"]) {
                                                                for (CXMLElement *currentDepProgElement in [currentDepElement children]) {
                                                                    if ([[currentDepProgElement name] isEqualToString: @"Time"]) {
                                                                        // To implement time changes
                                                                        NSString *depTimeChange = [currentDepProgElement stringValue];
                                                                        departureStop.dep.expectedTimeString = depTimeChange;
                                                                    } else if ([[currentDepProgElement name] isEqualToString: @"Platform"]) {
                                                                        // To implement track changes
                                                                        NSString *depTrackChange = [currentDepProgElement stringValue];
                                                                        departureStop.dep.expectedPlatform = depTrackChange;
                                                                    }
                                                                }
                                                                NSString *statusstring = [currentDepElement stringValue];
                                                                departureStop.scheduled = statusstring;
                                                            }
                                                        }
                                                    }
                                                }
                                                conOverView.departure = departureStop;
                                                
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Arrival"]) {
                                                BasicStop *arrivalStop = [[BasicStop alloc] init];
                                                arrivalStop.basicStopType = arrivalType;
                                                Arr *arr = [[Arr alloc] init];
                                                arrivalStop.arr = arr;
                                                
                                                CXMLNode *arrivalElements = [currentOverviewElement childAtIndex: 0];
                                                
                                                for (CXMLElement *arrivalElement in [arrivalElements children]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Arrival element name: %@", [arrivalElement name]);
                                                    #endif
                                                    
                                                    if ([[arrivalElement name] isEqualToString: @"Station"]) {
                                                        Station *arrivalStation = [[Station alloc] init];
                                                        arrivalStation.stationName = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"name"] stringValue]];
                                                        arrivalStation.stationId = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"externalId"] stringValue]];
                                                        double latitude = [[[arrivalElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                        double longitude = [[[arrivalElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                        arrivalStation.latitude = [NSNumber numberWithFloat: latitude];
                                                        arrivalStation.longitude = [NSNumber numberWithFloat: longitude];
                                                        arrivalStop.station = arrivalStation;
                                                    } else if ([[arrivalElement name] isEqualToString: @"Arr"]) {
                                                        for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                            if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                                arrivalStop.arr.timeString = [currentArrElement stringValue];
                                                            } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                                CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                arrivalStop.arr.platform = platformString;
                                                            }
                                                        }
                                                    } else if ([[arrivalElement name] isEqualToString: @"StopPrognosis"]) {
                                                        for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                            if ([[currentArrElement name] isEqualToString: @"Arr"]) {
                                                                for (CXMLElement *currentArrProgElement in [currentArrElement children]) {
                                                                    if ([[currentArrProgElement name] isEqualToString: @"Time"]) {
                                                                        // To implement time changes
                                                                        NSString *arrTimeChange = [currentArrProgElement stringValue];
                                                                        arrivalStop.arr.expectedTimeString = arrTimeChange;
                                                                    } else if ([[currentArrProgElement name] isEqualToString: @"Platform"]) {
                                                                        // To implement track changes
                                                                        NSString *arrTrackChange = [currentArrProgElement stringValue];
                                                                        arrivalStop.arr.expectedPlatform = arrTrackChange;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                }
                                                conOverView.arrival = arrivalStop;
                                                
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Transfers"]) {
                                                NSString *transfers = [currentOverviewElement stringValue];
                                                conOverView.transfers = transfers;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Overview transfers: %@", transfers);
                                                #endif
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Duration"]) {
                                                CXMLNode *durationTimeElement = [currentOverviewElement childAtIndex: 0];
                                                NSString *timeString = [(CXMLElement *)durationTimeElement stringValue];
                                                conOverView.duration = timeString;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Overview duration: %@", timeString);
                                                #endif
                                            }
                                            if ([[currentOverviewElement name] isEqualToString: @"Products"]) {
                                                NSString *productString = nil;
                                                for (CXMLElement *currentProduct in [currentOverviewElement children]) {
                                                    NSString *productCategory = [[(CXMLElement *)currentProduct attributeForName: @"cat"] stringValue];
                                                    //NSLog(@"Overview product category: %@", productCategory);
                                                    if (!productString) productString = @"";
                                                    productString = [productString stringByAppendingFormat: @"|%@", [productCategory stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
                                                    //NSLog(@"Overview product category string: %@", productString);
                                                }
                                                if (productString) {
                                                    productString = [productString substringFromIndex: 1];
                                                    conOverView.products = productString;
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Overview products: %@", productString);
                                                    #endif
                                                }
                                            }
                                            
                                        }
                                        conResult.overView = conOverView;
                                    } else if ([[currentConnectionElement name] isEqualToString: @"ConSectionList"]) {
                                        ConSectionList *conSectionList = [[ConSectionList alloc] init];
                                        
                                        for (CXMLElement *currentConSectionElement in [currentConnectionElement children]) {
                                            
                                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Conscr cancelled. Con queue block. For each 5");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kConScrRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            ConSection *conSection = [[ConSection alloc] init];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Consection element: %@", [currentConSectionElement name]);
                                            #endif
                                            
                                            for (CXMLElement *currentConSectionDetailElement in [currentConSectionElement children]) {
                                                
                                                if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                    #ifdef SBBAPILogLevelCancel
                                                    NSLog(@"Conscr cancelled. Con queue block. For each 6");
                                                    #endif
                                                    
                                                    if (failureBlock) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                            failureBlock(kConScrRequestFailureCancelled);
                                                        }];
                                                    }
                                                    return;
                                                }
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Consection detail element: %@", [currentConSectionDetailElement name]);
                                                #endif
                                                
                                                if ([[currentConSectionDetailElement name] isEqualToString: @"Departure"]) {
                                                    BasicStop *departureStop = [[BasicStop alloc] init];
                                                    departureStop.basicStopType = departureType;
                                                    Dep *dep = [[Dep alloc] init];
                                                    departureStop.dep = dep;
                                                    CXMLNode *departureElements = [currentConSectionDetailElement childAtIndex: 0];
                                                    
                                                    for (CXMLElement *departureElement in [departureElements children]) {
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Consection detail element departure: %@", [departureElement name]);
                                                        #endif
                                                        
                                                        if ([[departureElement name] isEqualToString: @"Station"]) {
                                                            Station *departureStation = [[Station alloc] init];
                                                            departureStation.stationName = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"name"] stringValue]];
                                                            departureStation.stationId = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"externalId"] stringValue]];
                                                            double latitude = [[[departureElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[departureElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            departureStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            departureStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            departureStop.station = departureStation;
                                                        } else if ([[departureElement name] isEqualToString: @"Dep"]) {
                                                            for (CXMLElement *currentDepElement in [departureElement children]) {
                                                                if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                                    departureStop.dep.timeString = [currentDepElement stringValue];
                                                                } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                                    CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                                    NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                    departureStop.dep.platform = platformString;
                                                                }
                                                            }
                                                        } else if ([[departureElement name] isEqualToString: @"Address"]) {     // Currenty no name check
                                                            Station *departureStation = [[Station alloc] init];
                                                            departureStation.stationName = [self fromISOLatinToUTF8: [[departureElement attributeForName: @"name"] stringValue]];
                                                            double latitude = [[[departureElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[departureElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            departureStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            departureStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            departureStop.station = departureStation;
                                                        } else if ([[departureElement name] isEqualToString: @"StopPrognosis"]) {
                                                            for (CXMLElement *currentDepElement in [departureElement children]) {
                                                                if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                                    NSString *capstring = [currentDepElement stringValue];
                                                                    departureStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                                } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                                    NSString *capstring = [currentDepElement stringValue];
                                                                    departureStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                                } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                                    NSString *statusstring = [currentDepElement stringValue];
                                                                    departureStop.scheduled = statusstring;
                                                                } else if ([[currentDepElement name] isEqualToString: @"Dep"]) {
                                                                    for (CXMLElement *currentDepProgElement in [currentDepElement children]) {
                                                                        if ([[currentDepProgElement name] isEqualToString: @"Time"]) {
                                                                            // To implement time changes
                                                                            NSString *depTimeChange = [currentDepProgElement stringValue];
                                                                            departureStop.dep.expectedTimeString = depTimeChange;
                                                                        } else if ([[currentDepProgElement name] isEqualToString: @"Platform"]) {
                                                                            // To implement track changes
                                                                            NSString *depTrackChange = [currentDepProgElement stringValue];
                                                                            departureStop.dep.expectedPlatform = depTrackChange;
                                                                        }
                                                                    }
                                                                    NSString *statusstring = [currentDepElement stringValue];
                                                                    departureStop.scheduled = statusstring;
                                                                }
                                                            }
                                                        }
                                                    }
                                                    conSection.departure = departureStop;
                                                    
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Arrival"]) {
                                                    BasicStop *arrivalStop = [[BasicStop alloc] init];
                                                    arrivalStop.basicStopType = arrivalType;
                                                    Arr *arr = [[Arr alloc] init];
                                                    arrivalStop.arr = arr;
                                                    CXMLNode *arrivalElements = [currentConSectionDetailElement childAtIndex: 0];
                                                    
                                                    for (CXMLElement *arrivalElement in [arrivalElements children]) {
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Consection detail element arrival: %@", [arrivalElement name]);
                                                        #endif
                                                        
                                                        if ([[arrivalElement name] isEqualToString: @"Station"]) {
                                                            Station *arrivalStation = [[Station alloc] init];
                                                            arrivalStation.stationName = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"name"] stringValue]];
                                                            arrivalStation.stationId = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"externalId"] stringValue]];
                                                            double latitude = [[[arrivalElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[arrivalElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            arrivalStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            arrivalStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            arrivalStop.station = arrivalStation;
                                                        } else if ([[arrivalElement name] isEqualToString: @"Arr"]) {
                                                            for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                                if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                                    arrivalStop.arr.timeString = [currentArrElement stringValue];
                                                                } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                                    CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                                    NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                    arrivalStop.arr.platform = platformString;
                                                                }
                                                            }
                                                        } else if ([[arrivalElement name] isEqualToString: @"Address"]) {       // Currenty no name check
                                                            Station *arrivalStation = [[Station alloc] init];
                                                            arrivalStation.stationName = [self fromISOLatinToUTF8: [[arrivalElement attributeForName: @"name"] stringValue]];
                                                            double latitude = [[[arrivalElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                            double longitude = [[[arrivalElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                            arrivalStation.latitude = [NSNumber numberWithFloat: latitude];
                                                            arrivalStation.longitude = [NSNumber numberWithFloat: longitude];
                                                            arrivalStop.station = arrivalStation;
                                                        } else if ([[arrivalElement name] isEqualToString: @"StopPrognosis"]) {
                                                            for (CXMLElement *currentArrElement in [arrivalElement children]) {
                                                                if ([[currentArrElement name] isEqualToString: @"Arr"]) {
                                                                    for (CXMLElement *currentArrProgElement in [currentArrElement children]) {
                                                                        if ([[currentArrProgElement name] isEqualToString: @"Time"]) {
                                                                            // To implement time changes
                                                                            NSString *arrTimeChange = [currentArrProgElement stringValue];
                                                                            arrivalStop.arr.expectedTimeString = arrTimeChange;
                                                                        } else if ([[currentArrProgElement name] isEqualToString: @"Platform"]) {
                                                                            // To implement track changes
                                                                            NSString *arrTrackChange = [currentArrProgElement stringValue];
                                                                            arrivalStop.arr.expectedPlatform = arrTrackChange;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    conSection.arrival = arrivalStop;
                                                    
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Journey"]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though journey type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = journeyType;
                                                    Journey *journey = [[Journey alloc] init];
                                                    for (CXMLElement *currentJourneyElement in [currentConSectionDetailElement children]) {
                                                        if ([[currentJourneyElement name] isEqualToString: @"JHandle"]) {
                                                            NSString *journeytnr = [[currentJourneyElement attributeForName: @"tNr"] stringValue];
                                                            NSString *journeypuic = [[currentJourneyElement attributeForName: @"puic"] stringValue];
                                                            NSString *journeycycle = [[currentJourneyElement attributeForName: @"cycle"] stringValue];
                                                            
                                                            #ifdef SBBAPILogLevelFull
                                                            NSLog(@"Consection detail element journey handle attribute element type: %@, %@, %@", journeytnr, journeypuic, journeycycle);
                                                            #endif
                                                            
                                                            JourneyHandle *journeyhandle = [[JourneyHandle alloc] init];
                                                            journeyhandle.tnr = journeytnr;
                                                            journeyhandle.puic = journeypuic;
                                                            journeyhandle.cycle = journeycycle;
                                                            journey.journeyHandle = journeyhandle;
                                                        } else if ([[currentJourneyElement name] isEqualToString: @"JourneyAttributeList"]) {
                                                            for (CXMLElement *journeyAttributeElement in [currentJourneyElement children]) {
                                                                //NSLog(@"Consection detail element journey attribute element: %@", journeyAttributeElement);
                                                                CXMLNode *journeyAttributeElementDetail = [journeyAttributeElement childAtIndex: 0];
                                                                //NSLog(@"Array: %@", journeyAttributeElementDetail);
                                                                
                                                                NSString *attributeType = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"type"] stringValue];
                                                                
                                                                #ifdef SBBAPILogLevelFull
                                                                NSLog(@"Consection detail element journey attribute element type: %@", attributeType);
                                                                #endif
                                                                
                                                                if ([attributeType isEqualToString: @"NAME"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        //NSLog(@"Name attribute variant element type: %@", attributeVariantElement);
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            NSString *journeyName = [[journeyAttributeVariantElement stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                            journey.journeyName = journeyName;
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Name attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"CATEGORY"]) {
                                                                    NSString *categoryCode = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"code"] stringValue];
                                                                    journey.journeyCategoryCode = categoryCode;
                                                                    
                                                                    #ifdef SBBAPILogLevelFull
                                                                    NSLog(@"Category attribute variant element code: %@", categoryCode);
                                                                    #endif
                                                                    
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        //NSLog(@"Category attribute variant element type: %@", attributeVariantElement);
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyCategoryName = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Category attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"NUMBER"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        //NSLog(@"Number attribute variant element type: %@", attributeVariantElement);
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyNumber = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Number attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"ADMINISTRATION"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        //NSLog(@"Administration attribute variant element type: %@", attributeVariantElement);
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyAdministration = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Administration attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"OPERATOR"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyOperator = [journeyAttributeVariantElement stringValue];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Operator attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                    
                                                                } else if ([attributeType isEqualToString: @"DIRECTION"]) {
                                                                    for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                                        NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                                        //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                                        if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                                            journey.journeyDirection = [self fromISOLatinToUTF8: [journeyAttributeVariantElement stringValue]];
                                                                            
                                                                            #ifdef SBBAPILogLevelFull
                                                                            NSLog(@"Direction attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                                            #endif
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        } else if ([[currentJourneyElement name] isEqualToString: @"PassList"]) {
                                                            for (CXMLElement *journeyPasslistElement in [currentJourneyElement children]) {
                                                                //NSLog(@"Consection detail element pass list element: %@", journeyPasslistElement);
                                                                
                                                                BasicStop *basicStop = [[BasicStop alloc] init];
                                                                basicStop.basicStopType = arrivalType;
                                                                Dep *dep = [[Dep alloc] init];
                                                                Arr *arr = [[Arr alloc] init];
                                                                basicStop.dep = dep;
                                                                basicStop.arr = arr;
                                                                                                                                
                                                                for (CXMLElement *basicStopElement in [journeyPasslistElement children]) {
                                                                    
                                                                    #ifdef SBBAPILogLevelFull
                                                                    NSLog(@"Consection detail element arrival: %@", [basicStopElement name]);
                                                                    #endif
                                                                    
                                                                    if ([[basicStopElement name] isEqualToString: @"Station"]) {
                                                                        Station *station = [[Station alloc] init];
                                                                        station.stationName = [self fromISOLatinToUTF8: [[basicStopElement attributeForName: @"name"] stringValue]];
                                                                        station.stationId = [self fromISOLatinToUTF8: [[basicStopElement attributeForName: @"externalId"] stringValue]];
                                                                        double latitude = [[[basicStopElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                                        double longitude = [[[basicStopElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                                        station.latitude = [NSNumber numberWithFloat: latitude];
                                                                        station.longitude = [NSNumber numberWithFloat: longitude];
                                                                        basicStop.station = station;
                                                                    } else if ([[basicStopElement name] isEqualToString: @"Arr"]) {
                                                                        //Arr *arr = [[Arr alloc] init];
                                                                        for (CXMLElement *currentArrElement in [basicStopElement children]) {
                                                                            if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                                                basicStop.arr.timeString = [currentArrElement stringValue];
                                                                                //basicStop.arr = arr;
                                                                            } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                                                CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                                basicStop.arr.platform = platformString;
                                                                            }
                                                                        }
                                                                    } else if ([[basicStopElement name] isEqualToString: @"Dep"]) {
                                                                        //Dep *dep = [[Dep alloc] init];
                                                                        for (CXMLElement *currentDepElement in [basicStopElement children]) {
                                                                            if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                                                basicStop.dep.timeString = [currentDepElement stringValue];
                                                                                //basicStop.dep = dep;
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                                                CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                                                NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                                                basicStop.dep.platform = platformString;
                                                                            }
                                                                        }
                                                                    } else if ([[basicStopElement name] isEqualToString: @"StopPrognosis"]) {
                                                                        for (CXMLElement *currentDepElement in [basicStopElement children]) {
                                                                            if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                                                NSString *capstring = [currentDepElement stringValue];
                                                                                basicStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                                                NSString *capstring = [currentDepElement stringValue];
                                                                                basicStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                                                NSString *statusstring = [currentDepElement stringValue];
                                                                                basicStop.scheduled = statusstring;
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Dep"]) {
                                                                                for (CXMLElement *currentDepProgElement in [currentDepElement children]) {
                                                                                    if ([[currentDepProgElement name] isEqualToString: @"Time"]) {
                                                                                        // To implement time changes
                                                                                        NSString *depTimeChange = [currentDepProgElement stringValue];
                                                                                        basicStop.dep.expectedTimeString = depTimeChange;
                                                                                    } else if ([[currentDepProgElement name] isEqualToString: @"Platform"]) {
                                                                                        // To implement track changes
                                                                                        NSString *depTrackChange = [currentDepProgElement stringValue];
                                                                                        basicStop.dep.expectedPlatform = depTrackChange;
                                                                                    }
                                                                                }
                                                                            } else if ([[currentDepElement name] isEqualToString: @"Arr"]) {
                                                                                for (CXMLElement *currentArrProgElement in [currentDepElement children]) {
                                                                                    if ([[currentArrProgElement name] isEqualToString: @"Time"]) {
                                                                                        // To implement time changes
                                                                                        NSString *arrTimeChange = [currentArrProgElement stringValue];
                                                                                        basicStop.arr.expectedTimeString = arrTimeChange;
                                                                                    } else if ([[currentArrProgElement name] isEqualToString: @"Platform"]) {
                                                                                        // To implement track changes
                                                                                        NSString *arrTrackChange = [currentArrProgElement stringValue];
                                                                                        basicStop.arr.expectedPlatform = arrTrackChange;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                [journey.passList addObject: basicStop];
                                                            }
                                                        } else if ([[currentJourneyElement name] isEqualToString: @"JProg"]) {
                                                            // To implement
                                                            BOOL journeyOnTime = YES;
                                                            for (CXMLElement *currentJourneyProgElement in [currentJourneyElement children]) {
                                                                if ([[currentJourneyProgElement name] isEqualToString: @"JStatus"]) {
                                                                    NSString *journeyStatus = [currentJourneyProgElement stringValue];
                                                                    if ([journeyStatus isEqualToString: @"SCHEDULED"]) {
                                                                        
                                                                        #ifdef SBBAPILogLevelFull
                                                                        NSLog(@"Journey is on schedule");
                                                                        #endif
                                                                        
                                                                        journeyOnTime = YES;
                                                                    } else if ([journeyStatus isEqualToString: @"DELAY"]) {
                                                                        
                                                                        #ifdef SBBAPILogLevelFull
                                                                        NSLog(@"Journey is delayed");
                                                                        #endif
                                                                        
                                                                        journeyOnTime = NO;
                                                                    }
                                                                }
                                                            }
                                                            journey.journeyIsDelayed = !journeyOnTime;
                                                        }
                                                    }
                                                    conSection.journey = journey;
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Stations is passlist of journey: %d", conSection.journey.passList.count);
                                                    #endif
                                                    
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Walk"]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though walk type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = walkType;
                                                    Walk *walk = [[Walk alloc] init];
                                                    NSString *walkDistance = [[(CXMLElement *)currentConSectionDetailElement attributeForName: @"length"] stringValue];
                                                    walk.distance = walkDistance;
                                                    //NSLog(@"Consection detail element walk distance: %@", walkDistance);
                                                    for (CXMLElement *currentWalkElement in [currentConSectionDetailElement children]) {
                                                        if ([[currentWalkElement name] isEqualToString: @"Duration"]) {
                                                            CXMLNode *durationTimeElement = [currentWalkElement childAtIndex: 0];
                                                            NSString *timeString = [(CXMLElement *)durationTimeElement stringValue];
                                                            walk.duration = timeString;
                                                            //NSLog(@"Consection detail element walk duration: %@", timeString);
                                                        }
                                                    }
                                                    conSection.walk = walk;
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"GisRoute"]) {      // Current implement as WALK
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though gisroute type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = walkType;
                                                    Walk *walk = [[Walk alloc] init];
                                                    for (CXMLElement *currentGisRouteElement in [currentConSectionDetailElement children]) {
                                                        if ([[currentGisRouteElement name] isEqualToString: @"Duration"]) {
                                                            CXMLNode *durationTimeElement = [currentGisRouteElement childAtIndex: 0];
                                                            NSString *timeString = [(CXMLElement *)durationTimeElement stringValue];
                                                            walk.duration = timeString;
                                                            //NSLog(@"Consection detail element gisroute duration: %@", timeString);
                                                        } else if ([[currentGisRouteElement name] isEqualToString: @"Distance"]) {
                                                            NSString *walkDistance = [currentGisRouteElement stringValue];
                                                            walk.distance = walkDistance;
                                                            //NSLog(@"Consection detail element gisroute distance: %@", walkDistance);
                                                        }
                                                    }
                                                    conSection.walk = walk;
                                                } else if ([[currentConSectionDetailElement name] isEqualToString: @"Transfer"]) {
                                                    
                                                    #ifdef SBBAPILogLevelFull
                                                    NSLog(@"Consection passing though transfer type");
                                                    #endif
                                                    
                                                    conSection.conSectionType = journeyType;
                                                    Journey *journey = [[Journey alloc] init];
                                                    journey.journeyDirection = @"-";
                                                    journey.journeyAdministration = nil;
                                                    journey.journeyCategoryName = @"TRANS.";
                                                    journey.journeyCategoryCode = @"9";
                                                    journey.journeyHandle = nil;
                                                    journey.journeyIsDelayed = NO;
                                                    journey.journeyName = @"TRANS.";
                                                    journey.journeyNumber = @"0";
                                                    journey.journeyOperator = @"-";
                                                    
                                                    conResult.hasTransferInConSections = YES;
                                                    
                                                    conSection.journey = journey;
                                                }
                                            }
                                            [conSectionList.conSections addObject: conSection];
                                        }
                                        conResult.conSectionList = conSectionList;
                                    } else if ([[currentConnectionElement name] isEqualToString: @"IList"]) {
                                        // To implement
                                        for (CXMLElement *currentInfoElement in [currentConnectionElement children]) {
                                            
                                            if ([weakConreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Conscr cancelled. Con queue block. For each 7");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kConScrRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            NSString *headerText = [[currentInfoElement attributeForName: @"header"] stringValue];
                                            NSString *leadText = [[currentInfoElement attributeForName: @"lead"] stringValue];
                                            NSString *textText = [[currentInfoElement attributeForName: @"text"] stringValue];
                                            ConnectionInfo *currentConnectionInfo = [[ConnectionInfo alloc] init];
                                            currentConnectionInfo.header = [self fromISOLatinToUTF8: headerText];
                                            currentConnectionInfo.lead = [self fromISOLatinToUTF8: leadText];
                                            currentConnectionInfo.text = [self fromISOLatinToUTF8: textText];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Connection info: %@, %@, %@", headerText, leadText, textText);
                                            #endif
                                            
                                            [conResult.connectionInfoList addObject: currentConnectionInfo];
                                        }
                                    }
                                }
                                                                
                                if (conResult) {
                                    if (self.connectionsResult.knownBetterStartLocationName) {
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Setting better startstation name: %@", self.connectionsResult.knownBetterStartLocationName);
                                        #endif
                                        
                                        conResult.knownBetterStartLocationName = self.connectionsResult.knownBetterStartLocationName;
                                        if ([conResult conSectionList] && [[conResult conSectionList] conSections] && ([[[conResult conSectionList] conSections] count]>0)) {
                                            ConSection *startSection = [[[conResult conSectionList] conSections] objectAtIndex: 0];
                                            if ([startSection departure] && [[startSection departure] station]) {
                                                Station *departureStation = [[startSection departure] station];
                                                departureStation.stationName = self.connectionsResult.knownBetterStartLocationName;
                                            }
                                        }
                                    } else {
                                        conResult.knownBetterStartLocationName = nil;
                                    }
                                    if (self.connectionsResult.knownBetterEndLocationName) {
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Setting better endstation name: %@", self.connectionsResult.knownBetterEndLocationName);
                                        #endif
                                        
                                        conResult.knownBetterEndLocationName = self.connectionsResult.knownBetterEndLocationName;
                                        if ([conResult conSectionList] && [[conResult conSectionList] conSections] && ([[[conResult conSectionList] conSections] count]>0)) {
                                            ConSection *endSection = [[[conResult conSectionList] conSections] lastObject];
                                            if ([endSection departure] && [[endSection arrival] station]) {
                                                Station *arrivalStation = [[endSection arrival] station];
                                                arrivalStation.stationName = self.connectionsResult.knownBetterEndLocationName;
                                            }
                                        }
                                    } else {
                                        conResult.knownBetterEndLocationName = nil;
                                    }
                                    
                                    if (conResult.hasTransferInConSections) {
                                        for (ConSection *currentConSection in conResult.conSectionList.conSections) {
                                            if ([[currentConSection.journey journeyCategoryName] isEqualToString: @"TRANS."]) {
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Transfer type add passlist stations");
                                                #endif
                                                [currentConSection.journey.passList addObject: currentConSection.departure];
                                                [currentConSection.journey.passList addObject: currentConSection.arrival];
                                            }
                                        }
                                    }
                                }
                                
                                [tempConnections.conResults addObject: conResult];
                                
                                #ifdef SBBAPILogLevelXMLReqRes
                                NSLog(@"ConScrRes: %@", conResult);
                                NSLog(@"ConScrRes #: %d", tempConnections.conResults.count);
                                #endif
                            }
                        }
                    }
                }
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }
            
            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Conscr end decoding xml"];
            #endif
            
            self.conreqRequestInProgress = NO;
            
            if ([weakConreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Conscr cancelled. Con queue block. End. MainQueue call");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kConScrRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (tempConnections && tempConnections.conResults.count > 0) {
                                                        
                            NSUInteger numberofnewresults = self.connectionsResult.conResults.count;
                            
                            #ifdef SBBAPILogLevelXMLReqRes
                            NSLog(@"ConScrRes before #: %d", self.connectionsResult.conResults.count);
                            #endif
                            
                            if (directionflag == conscrBackward) {
                                for (ConResult *currentconResult in [tempConnections.conResults reverseObjectEnumerator]) {
                                    [self.connectionsResult.conResults insertObject: currentconResult atIndex: 0];
                                }
                                self.connectionsResult.conscridbackwards = tempConnections.conscridbackwards;
                            } else if (directionflag == conscrForward) {
                                for (ConResult *currentconResult in tempConnections.conResults) {
                                    [self.connectionsResult.conResults addObject: currentconResult];
                                }
                                self.connectionsResult.conscridforward = tempConnections.conscridforward;
                            }
                            
                            #ifdef SBBAPILogLevelXMLReqRes
                            NSLog(@"ConScrRes after #: %d", self.connectionsResult.conResults.count);
                            #endif
                            
                            numberofnewresults = self.connectionsResult.conResults.count - numberofnewresults;
                            
                            successBlock(numberofnewresults);
                            
                        } else {
                            if (tempConnections && tempConnections.conResults.count == 0) {
                                if (failureBlock) {
                                    failureBlock(kConScrRequestFailureNoNewResults);
                                }
                            } else {
                                if (failureBlock) {
                                    failureBlock(kConScrRequestFailureCancelled);
                                }
                            }
                        }

                    }];
                }
            }
        }];
        [_conreqBackgroundOpQueue addOperation: conreqDecodingXMLOperation];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        self.conreqRequestInProgress = NO;
        
        //NSUInteger kConScrRequestFailureConnectionFailed = 45;
        if (failureBlock) {
            failureBlock(kConScrRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Conscr start operation"];
    #endif
    
    if (self.conscrRequestCancelledFlag) {
        self.conscrRequestCancelledFlag = NO;
        if (failureBlock) {
            failureBlock(kConScrRequestFailureCancelled);
        }
    }
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

- (BOOL) isRequestInProgress {
    
    #ifdef SBBAPILogLevelCancel
    NSString *conreqstr = self.conreqRequestInProgress?@"Y":@"N";
    NSString *stbreqstr = self.stbreqRequestInProgress?@"Y":@"N";
    NSString *rssreqstr = self.rssreqRequestInProgress?@"Y":@"N";    
    NSLog(@"Check if sbb api request in progress. Conreq: %@, Stbreq: %@, Rssreq: %@", conreqstr, stbreqstr, rssreqstr);
    #endif
    
    return (self.conreqRequestInProgress || self.stbreqRequestInProgress);
}

- (void) cancelAllSBBAPIOperations {
    #ifdef SBBAPILogLevelCancel
    NSLog(@"SBB API cancel ALL operations request");
    #endif
    [_conreqBackgroundOpQueue cancelAllOperations];
    self.conreqRequestInProgress = NO;
    
    if (self.conreqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations conreq. kill http client");
        #endif
        [[self.conreqHttpClient operationQueue] cancelAllOperations];
        //self.conreqHttpClient = nil;
    }
    
    [_stbreqBackgroundOpQueue cancelAllOperations];
    self.stbreqRequestInProgress = NO;
    if (self.stbreqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations stbreq. kill http client");
        #endif
        [[self.stbreqHttpClient operationQueue] cancelAllOperations];
        //self.stbreqHttpClient = nil;
    }
    
    [_valreqBackgroundOpQueue cancelAllOperations];
    self.valreqRequestInProgress = NO;
    if (self.valreqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations valreq. kill http client");
        #endif
        [[self.valreqHttpClient operationQueue] cancelAllOperations];
        //self.valreqHttpClient = nil;
    }
    [_stareqBackgroundOpQueue cancelAllOperations];
    self.stareqRequestInProgress = NO;
    if (self.stareqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations stareq. kill http client");
        #endif
        [[self.stareqHttpClient operationQueue] cancelAllOperations];
        //self.valreqHttpClient = nil;
    }
}

- (void) cancelAllSBBAPIConreqOperations {
    #ifdef SBBAPILogLevelCancel
    NSLog(@"SBB API cancel Conreq operations request");
    #endif
    
    [_conreqBackgroundOpQueue cancelAllOperations];
    self.conreqRequestInProgress = NO;
    if (self.conreqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations conreq. kill http client");
        #endif
        [[self.conreqHttpClient operationQueue] cancelAllOperations];
        //self.conreqHttpClient = nil;
    }
}

- (void) cancelAllSBBAPIStbreqOperations {
    #ifdef SBBAPILogLevelCancel
    NSLog(@"SBB API cancel Stbreq operations request");
    #endif
    
    [_stbreqBackgroundOpQueue cancelAllOperations];
    self.stbreqRequestInProgress = NO;
    if (self.stbreqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations stbreq. kill http client");
        #endif
        [[self.stbreqHttpClient operationQueue] cancelAllOperations];
        //self.stbreqHttpClient = nil;
    }
}

- (void) cancelAllSBBAPIValOperations {
    #ifdef SBBAPILogLevelCancel
    NSLog(@"SBB API cancel Val operations request");
    #endif
    
    [_valreqBackgroundOpQueue cancelAllOperations];
    self.valreqRequestInProgress = NO;
    if (self.valreqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations valreq. kill http client");
        #endif
        [[self.valreqHttpClient operationQueue] cancelAllOperations];
        //self.rssreqHttpClient = nil;
    }
}

- (void) cancelAllSBBAPIStaOperations {
    #ifdef SBBAPILogLevelCancel
    NSLog(@"SBB API cancel Sta operations request");
    #endif
    
    [_stareqBackgroundOpQueue cancelAllOperations];
    self.stareqRequestInProgress = NO;
    if (self.stareqHttpClient) {
        #ifdef SBBAPILogLevelCancel
        NSLog(@"SBB API cancel operations valreq. kill http client");
        #endif
        [[self.stareqHttpClient operationQueue] cancelAllOperations];
        //self.rssreqHttpClient = nil;
    }
}

- (NSString *) fromISOLatinToUTF8: (NSString *) input
{
	if (!input) return (nil);
	NSData *tempData = [input dataUsingEncoding: NSISOLatin1StringEncoding];
	NSString *utfString = [[NSString alloc] initWithData: tempData encoding:NSUTF8StringEncoding];
	return (utfString);
}

- (Connections *)getConnectionsresults {
    return self.connectionsResult;
}

- (NSArray *) getConnectionResults {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            if ([[self.connectionsResult conResults] count] > 0) {
                 return [[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults];
            }
        }
    }
    return  nil;
}

- (NSUInteger) getNumberOfConnectionResults {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            if ([[self.connectionsResult conResults] count] > 0) {
                return [[self.connectionsResult conResults] count];
            }
        }
    }
    return  0;
}

- (ConResult *) getConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    return [[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index];
                }
            }
        }
    }
    return  nil;
}

- (NSDate *) getConnectionDateForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        return [self.connectionsResult searchdate];
    }
    return  nil;
}

- (BOOL) getConnectionDateIsDepartureFlagForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        return [self.connectionsResult searchdateisdeparturedate];
    }
    return  YES;
}

- (ConOverview *) getOverviewForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    return [[[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index] overView];
                }
            }
        }
    }
    return  nil;
}

- (NSString *) getBetterDepartureStationNameForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    NSString *stationName = [[[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index] knownBetterStartLocationName];
                    if (stationName && ([stationName length]>0)) {
                        return stationName;
                    }
                    return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");

                    ConOverview *overView = [self getOverviewForConnectionResultWithIndex: index];
                    NSString *overViewStationName = [self getDepartureStationNameForOverview: overView];
                    return overViewStationName;
                }
            }
        }
    }
    return  nil;
}

- (NSString *) getBetterArrivalStationNameForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    NSString *stationName = [[[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index] knownBetterEndLocationName];
                    if (stationName && ([stationName length]>0)) {
                        return stationName;
                    }
                    return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
                    
                    ConOverview *overView = [self getOverviewForConnectionResultWithIndex: index];
                    NSString *overViewStationName = [self getArrivalStationNameForOverview: overView];
                    return overViewStationName;

                }
            }
        }
    }
    return  nil;
}

- (void) resetConnectionsresults {
    self.connectionsResult = nil;
}

-  (NSDate *) getConnectionDateForOverview:(ConOverview *)overview {
    if (overview) {
        return [overview getDateFromDateString];
    }
    return  nil;
}

-  (NSString *) getConnectionDateStringForOverview:(ConOverview *)overview {
    if (overview) {
        return [overview getDateStringFromDateString];
    }
    return  nil;
}

-  (NSString *) getArrivalTimeForOverview:(ConOverview *)overview {
    if (overview) {
        return [[[overview arrival] arr] getFormattedTimeStringFromTime];
    }
    return  nil;
}

-  (NSString *) getDepartureTimeForOverview:(ConOverview *)overview {
    if (overview) {
        return [[[overview departure] dep] getFormattedTimeStringFromTime];
    }
    return  nil;
}

-  (NSString *) getArrivalStationNameForOverview:(ConOverview *)overview {
    if (overview) {
        if ([[[[overview arrival] station] stationName] isEqualToString: @"unknown"]) {
            return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
        }
        return [[[overview arrival] station] stationName];
    }
    return nil;
}

-  (NSString *) getDepartureStationNameForOverview:(ConOverview *)overview {
    if (overview) {
        if ([[[[overview departure] station] stationName] isEqualToString: @"unknown"]) {
            return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
        }
        return [[[overview departure] station] stationName];
    }
    return nil;
}

-  (NSNumber *) getCapacity1stForOverview:(ConOverview *)overview {
    if (overview) {
        return [[overview departure] capacity1st];
    }
    return nil;
}

-  (NSNumber *) getCapacity2ndForOverview:(ConOverview *)overview {
    if (overview) {
        return [[overview departure] capacity2nd];
    }
    return nil;
}

- (NSArray *) getConsectionsForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    ConResult *conResult = [[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index];
                    return [[conResult conSectionList] conSections];
                }
            }
        }
    }
    return  nil;
}

- (NSUInteger) getNumberOfConsectionsForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    ConResult *conResult = [[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index];
                    if ([[[conResult conSectionList] conSections] count] > 0) {
                        return [[[conResult conSectionList] conSections] count];
                    }
                }
            }
        }
    }
    return  0;
}

- (ConSection *) getConsectionForConnectionResultWithIndexAndConsectionIndex:(NSUInteger)index consectionIndex:(NSUInteger)consectionIndex {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    ConResult *conResult = [[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index];
                    int consectionsCount = [[[conResult conSectionList] conSections] count];
                    if (consectionIndex < consectionsCount) {
                        return [[[conResult conSectionList] conSections] objectAtIndex: consectionIndex];
                    }
                }
            }
        }
    }
    return  nil;
}

- (ConSection *) getFirstConsectionForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    ConResult *conResult = [[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index];
                    int consectionsCount = [[[conResult conSectionList] conSections] count];
                    if (consectionsCount > 0) {
                        return [[[conResult conSectionList] conSections] objectAtIndex:0];
                    }
                }
            }
        }
    }
    return  nil;
}

- (ConSection *) getLastConsectionForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    ConResult *conResult = [[[[SBBAPIController sharedSBBAPIController] connectionsResult] conResults] objectAtIndex: index];
                    int consectionsCount = [[[conResult conSectionList] conSections] count];
                    if (consectionsCount > 0) {
                        return [[[conResult conSectionList] conSections] lastObject];
                    }
                }
            }
        }
    }
    return  nil;
}

- (BOOL) ConnectionResultWithIndexHasInfos:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    if ([[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList]) {
                        if ([[[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList] count] > 0) {
                            return YES;
                        }
                    }
                }
            }
        }
    }
    return  NO;
}

- (NSUInteger) getNumberOfConnectionInfosForConnectionResultWithIndex:(NSUInteger)index {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    if ([[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList]) {
                        if ([[[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList] count] > 0) {
                            return [[[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList] count];
                        }
                    }
                }
            }
        }
    }
    return  0;
}

- (ConnectionInfo *) getConnectioninfoForConnectionResultWithIndexAndConnectioninfoIndex:(NSUInteger)index infoIndex:(NSUInteger)infoIndex {
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            int conResultsCount = [[self.connectionsResult conResults] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    if ([[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList]) {
                        if ([[[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList] count] > 0) {
                            if ([[[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList] count] > infoIndex) {
                                return [[[[self.connectionsResult conResults] objectAtIndex: index] connectionInfoList] objectAtIndex: infoIndex];
                            }
                        }
                    }
                }
            }
        }
    }
    return  nil;
}

- (NSString *) getTransportTypeWithConsection:(ConSection *)conSection {
    
    NSString *transportImageName = nil;
    if ([conSection conSectionType] == walkType) {
        transportImageName = @"transportimagewalk";
        return @"WALK";
    } else if ([conSection conSectionType] == journeyType) {
        Journey *journey = [conSection journey];
        NSString *transportName = [[[journey journeyCategoryName] uppercaseString] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        NSUInteger transportType = [self getTransportTypeCodeForTransportCategoryType: transportName];
        if (transportType == transportUnknown) {
            return @"Train";
        } else if (transportType == transportFastTrain) {
            return @"Fast train";
        } else if (transportType == transportSlowTrain) {
            return @"Regio train";
        } else if (transportType == transportTram) {
            return @"Tram";
        } else if (transportType == transportBus) {
            return @"Bus";
        } else if (transportType == transportShip) {
            return @"Ship";
        } else if (transportType == transportFuni) {
            return @"Funi";
        }
        return transportImageName;
    }
    return @"Train";
}

-  (NSString *) getArrivalTimeForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection arrival] arr] getFormattedTimeStringFromTime];
    }
    return nil;
}

-  (NSString *) getDepartureTimeForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection departure] dep] getFormattedTimeStringFromTime];
    }
    return nil;
}

-  (NSString *) getExpectedArrivalTimeForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection arrival] arr] getFormattedExpectedTimeStringFromTime];
    }
    return nil;
}

-  (NSString *) getExpectedDepartureTimeForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection departure] dep] getFormattedExpectedTimeStringFromTime];
    }
    return nil;
}

-  (NSString *) getArrivalStationNameForConsection:(ConSection *)conSection {
    if (conSection) {
        if ([[[[conSection arrival] station] stationName] isEqualToString: @"unknown"]) {
            return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
        }
        return [[[conSection arrival] station] stationName];
    }
    return nil;
}

-  (NSString *) getDepartureStationNameForConsection:(ConSection *)conSection {
    if (conSection) {
        if ([[[[conSection departure] station] stationName] isEqualToString: @"unknown"]) {
            return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
        }
        return [[[conSection departure] station] stationName];
    }
    return nil;
}

-  (NSString *) getArrivalPlatformForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection arrival] arr] platform];
    }
    return nil;
}

-  (NSString *) getDeparturePlatformForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection departure] dep] platform];
    }
    return nil;
}

-  (NSString *) getExpectedArrivalPlatformForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection arrival] arr] expectedPlatform];
    }
    return nil;
}

-  (NSString *) getExpectedDeparturePlatformForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[[conSection departure] dep] expectedPlatform];
    }
    return nil;
}

-  (BOOL) isJourneyDelayedForConsection:(ConSection *)conSection {
    if (conSection) {
        if ([conSection conSectionType] == journeyType) {
            if ([conSection journey]) {
                return [[conSection journey] journeyIsDelayed];
            }
        }
    }
    return NO;
}

-  (BOOL) isConsectionOfTypeWalk:(ConSection *)conSection {
    if (conSection) {
        return ([conSection conSectionType] == walkType);
    }
    return NO;
}

-  (BOOL) isConsectionOfTypeJourney:(ConSection *)conSection {
    if (conSection) {
        return ([conSection conSectionType] == journeyType);
    }
    return NO;
}

-  (NSNumber *) getCapacity1stForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[conSection departure] capacity1st];
    }
    return nil;
}

-  (NSNumber *) getCapacity2ndForConsection:(ConSection *)conSection {
    if (conSection) {
        return [[conSection departure] capacity2nd];
    }
    return nil;
}

- (NSUInteger) getTransportTypeCodeForTransportCategoryType:(NSString *)transportCategoryType {
    if ([transportCategoryType isEqualToString: @"IR"]) {           // Fast trains...
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"ICE"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"IC"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"ICN"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"EC"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"RJ"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"TGV"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"EN"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"CNL"]) {
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"EXT"]) {   // Extra train
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"ARZ"]) {   // ???
        return transportFastTrain;
    } else if ([transportCategoryType isEqualToString: @"S"]) {
        return transportSlowTrain;
    } else if ([transportCategoryType isEqualToString: @"RE"]) {    // Regional trains...
        return transportSlowTrain;
    } else if ([transportCategoryType isEqualToString: @"R"]) {
        return transportSlowTrain;
    } else if ([transportCategoryType isEqualToString: @"BAT"]) {   // Ship...
        return transportShip;
    } else if ([transportCategoryType isEqualToString: @"BUS"]) {   // Bus...
        return transportBus;
    } else if ([transportCategoryType isEqualToString: @"TRAM"]) {  // Tram...
        return transportTram;
    } else if ([transportCategoryType isEqualToString: @"FUN"]) {   //Funiculaire...
        return transportFuni;
    } else if ([transportCategoryType isEqualToString: @"TRO"]) {   //Trolley
        return transportBus;
    } else if ([transportCategoryType isEqualToString: @"MET"]) {   //Metro
        return transportTram;
    } else if ([transportCategoryType isEqualToString: @"T"]) {   //Metro
        return transportTram;
    } else if ([transportCategoryType isEqualToString: @"NFT"]) {   //Metro
        return transportTram;
    } else if ([transportCategoryType isEqualToString: @"NFB"]) {   //Metro
        return transportBus;
    } else if ([transportCategoryType isEqualToString: @"NFO"]) {   //Metro
        return transportBus;
    }
    
    return transportUnknown;
}

- (NSString *) getTransportNameWithConsection:(ConSection *)conSection {
    NSString *transportName = nil;
    if ([conSection conSectionType] == walkType) {
        transportName = @"WALK";
        return transportName;
    } else if ([conSection conSectionType] == journeyType) {
        Journey *journey = [conSection journey];
        NSString *transportName = [journey journeyName];
        
        NSString *categoryCodeString = [journey journeyCategoryCode];
        NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
        
        if ([categoryCode integerValue] == 6 || [categoryCode integerValue] == 9) {
            if (transportName && [transportName length] >= 2) {
                NSArray *splitname = [transportName componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                if (splitname && splitname.count > 1) {
                    NSString *shortname = [splitname objectAtIndex: 0];
                    if ([shortname isEqualToString: @"T"]) {
                        shortname = @"Tram";
                    }
                    if ([shortname isEqualToString: @"NFT"]) {
                        shortname = @"Tram";
                    }
                    if ([shortname isEqualToString: @"TRO"]) {
                        shortname = @"Bus";
                    }
                    if ([shortname isEqualToString: @"NFB"]) {
                        shortname = @"Bus";
                    }
                    if ([shortname isEqualToString: @"NFO"]) {
                        shortname = @"Bus";
                    }
                    NSString *transportnamenew = [NSString stringWithFormat:@"%@ %@", shortname, [splitname objectAtIndex: 1]];
                    return transportnamenew;
                }
            }
        }
                
        // T, NFT, NFB, NFO, TRO,
        // Tram, Niederflurtram, Niederflurbus, X, Trolley
        
        return transportName;
    }
    return nil;
}

- (NSString *) getSimplifiedTransportNameWithConsection:(ConSection *)conSection {
    NSString *transportName = nil;
    if ([conSection conSectionType] == walkType) {
        transportName = @"WALK";
        return transportName;
    } else if ([conSection conSectionType] == journeyType) {
        NSString *transportName = [[self getTransportNameWithConsection: conSection] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                
        if (transportName && [transportName length] >= 2) {
            NSArray *splitname = [transportName componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            if (splitname && splitname.count > 1) {
                return [splitname objectAtIndex: 0];
            }
            return [transportName substringToIndex: 2];
        }
        return transportName;
    }
    return nil;
}

- (NSArray *) getStationsForConsection:(ConSection *)conSection {
    NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:2];
    if ([conSection conSectionType] == walkType) {
        Station *departureStation = [[Station alloc] init];
        Station *arrivalStation = [[Station alloc] init];
        departureStation.stationName = [[[conSection departure] station] stationName];
        departureStation.stationId = [[[conSection departure] station] stationId];
        departureStation.latitude = [[[conSection departure] station] latitude];
        departureStation.longitude = [[[conSection departure] station] longitude];
        [stationsArray addObject: departureStation];
        arrivalStation.stationName = [[[conSection arrival] station] stationName];
        arrivalStation.stationId = [[[conSection arrival] station] stationId];
        arrivalStation.latitude = [[[conSection arrival] station] latitude];
        arrivalStation.longitude = [[[conSection arrival] station] longitude];
        [stationsArray addObject: arrivalStation];
        return stationsArray;
    } else if ([conSection conSectionType] == journeyType) {
        NSArray *passlist = [[conSection journey] passList];
        for (int i = 0;  i < [passlist count];  i++) {
            BasicStop *currentBasicStop = (BasicStop *)[passlist objectAtIndex: i];
            [stationsArray addObject: [currentBasicStop station]];
        }
        return stationsArray;
    }
    return nil;
}

- (NSArray *) getBasicStopsForConsection:(ConSection *)conSection {
    NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:2];
    if ([conSection conSectionType] == walkType) {
        BasicStop *departureStation = [[BasicStop alloc] init];
        BasicStop *arrivalStation = [[BasicStop alloc] init];
        
        departureStation.arr = [[conSection arrival] arr];
        departureStation.dep = [[conSection departure] dep];
        departureStation.station = [[conSection departure] station];
        departureStation.basicStopType = departureType;
        departureStation.platform = [[conSection departure] platform];
        
        arrivalStation.arr = [[conSection arrival] arr];
        arrivalStation.dep = [[conSection departure] dep];
        arrivalStation.station = [[conSection arrival] station];
        arrivalStation.basicStopType = arrivalType;
        arrivalStation.platform = [[conSection arrival] platform];
        
        [stationsArray addObject: departureStation];
        [stationsArray addObject: arrivalStation];
        return stationsArray;
    } else if ([conSection conSectionType] == journeyType) {
        NSArray *passlist = [[conSection journey] passList];
        for (int i = 0;  i < [passlist count];  i++) {
            BasicStop *currentBasicStop = (BasicStop *)[passlist objectAtIndex: i];
            [stationsArray addObject: currentBasicStop];
        }
        return stationsArray;
    }
    return nil;
}

- (NSArray *) getAllBasicStopsForConnectionResultWithIndex:(NSUInteger)index {
    NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:2];
        
    if (self.connectionsResult) {
        if ([self.connectionsResult conResults]) {
            if ([[self.connectionsResult conResults] count] > 0) {
                if ([[self.connectionsResult conResults] count] > index) {
                    if ([[[[self.connectionsResult conResults] objectAtIndex: index] conSectionList] conSections]) {
                        if ([[[[[self.connectionsResult conResults] objectAtIndex: index] conSectionList] conSections] count] > 0) {
                            for (ConSection *currentConsection in [[[[self.connectionsResult conResults] objectAtIndex: index] conSectionList]  conSections]) {
                                if ([currentConsection conSectionType] == walkType) {
                                    BasicStop *departureStation = [[BasicStop alloc] init];
                                    BasicStop *arrivalStation = [[BasicStop alloc] init];
                                    
                                    departureStation.arr = [[currentConsection arrival] arr];
                                    departureStation.dep = [[currentConsection departure] dep];
                                    departureStation.station = [[currentConsection departure] station];
                                    departureStation.basicStopType = departureType;
                                    departureStation.platform = [[currentConsection departure] platform];
                                    
                                    arrivalStation.arr = [[currentConsection arrival] arr];
                                    arrivalStation.dep = [[currentConsection departure] dep];
                                    arrivalStation.station = [[currentConsection arrival] station];
                                    arrivalStation.basicStopType = arrivalType;
                                    arrivalStation.platform = [[currentConsection arrival] platform];
                                    
                                    [stationsArray addObject: departureStation];
                                    [stationsArray addObject: arrivalStation];
                                } else if ([currentConsection conSectionType] == journeyType) {
                                    NSArray *passlist = [[currentConsection journey] passList];
                                    for (int i = 0;  i < [passlist count];  i++) {
                                        BasicStop *currentBasicStop = (BasicStop *)[passlist objectAtIndex: i];
                                        [stationsArray addObject: currentBasicStop];
                                    }
                                }
                            }
                                                        
                            return stationsArray;
                        }
                    }
                }
            }
        }
    }
    return nil;
}

-  (CLLocationCoordinate2D) getCoordinatesForStation:(Station *)station {
    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(0.0, 0.0);
    if (station) {
        if ([station isKindOfClass: [Station class]]) {
            coordinates.latitude = [[station latitude] floatValue];
            coordinates.longitude = [[station longitude] floatValue];
        }
    }
    return coordinates;
}

-  (NSString *) getStationameForStation:(Station *)station {
    if (station) {
        if ([station isKindOfClass: [Station class]]) {
            if ([[station stationName] isEqualToString: @"unknown"]) {
                return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
            }
            return [station stationName];
        }
    }
    return nil;
}

-  (NSString *) getArrivalTimeForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            NSString *arrivalTimeHoursString = [[basicStop arr] getHoursStringFromTime];
            NSString *arrivalTimeMinutesString = [[basicStop arr] getMinutesStringFromTime];
            
            NSString *timeString = [NSString stringWithFormat: @"%@:%@", arrivalTimeHoursString, arrivalTimeMinutesString];
            NSString *time1 = [timeString substringToIndex: 1];

            if ([time1 isEqualToString: @"("]) {
                return  nil;
            }
            return timeString;
        }
    }
    return nil;
}

-  (NSString *) getDepartureTimeForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            NSString *departureTimeHoursString = [[basicStop dep] getHoursStringFromTime];
            NSString *departureTimeMinutesString = [[basicStop dep] getMinutesStringFromTime];
            
            NSString *timeString = [NSString stringWithFormat: @"%@:%@", departureTimeHoursString, departureTimeMinutesString];
            NSString *time1 = [timeString substringToIndex: 1];
            
            if ([time1 isEqualToString: @"("]) {
                return  nil;
            }
            return timeString;
        }
    }
    return nil;
}

-  (NSString *) getDepartureDaysForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            NSString *departureTimeDaysString = [[basicStop dep] getDaysStringFromTime];
            
            return departureTimeDaysString;
        }
    }
    return nil;
}

-  (NSString *) getExpectedArrivalTimeForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            NSString *arrivalTimeHoursString = [[basicStop arr] getExpectedHoursStringFromTime];
            NSString *arrivalTimeMinutesString = [[basicStop arr] getExpectedMinutesStringFromTime];
            
            NSString *timeString = [NSString stringWithFormat: @"%@:%@", arrivalTimeHoursString, arrivalTimeMinutesString];
            NSString *time1 = [timeString substringToIndex: 1];
            
            if ([time1 isEqualToString: @"("]) {
                return  nil;
            }
            return timeString;
        }
    }
    return nil;
}

-  (NSString *) getExpectedDepartureTimeForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            NSString *departureTimeHoursString = [[basicStop dep] getExpectedHoursStringFromTime];
            NSString *departureTimeMinutesString = [[basicStop dep] getExpectedMinutesStringFromTime];
            
            NSString *timeString = [NSString stringWithFormat: @"%@:%@", departureTimeHoursString, departureTimeMinutesString];
            NSString *time1 = [timeString substringToIndex: 1];
            
            if ([time1 isEqualToString: @"("]) {
                return  nil;
            }
            return timeString;
        }
    }
    return nil;
}

-  (NSString *) getStationNameForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            if ([[[basicStop station] stationName] isEqualToString: @"unknown"]) {
                return NSLocalizedString(@"GPS location", @"SBBAPIController unknown station text replacement");
            }
            return [[basicStop station] stationName];
        }
    }
    return nil;
}


-  (NSString *) getPlatformForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            if ([basicStop dep]) {
                return [[basicStop dep] platform];
            } else if ([basicStop arr]) {
                return [[basicStop arr] platform];
            }
            return nil;
        }
    }
    return nil;
}

-  (NSString *) getExpectedPlatformForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            if ([basicStop dep]) {
                return [[basicStop dep] expectedPlatform];
            } else if ([basicStop arr]) {
                return [[basicStop arr] expectedPlatform];
            }
            return nil;
        }
    }
    return nil;
}

-  (Station *) getStationForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            return [basicStop station];
        }
    }
    return nil;
}

-  (NSNumber *) getCapacity1stForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            return [basicStop capacity1st];
        }
    }
    return nil;
}

-  (NSNumber *) getCapacity2ndForBasicStop:(BasicStop *)basicStop {
    if (basicStop) {
        if ([basicStop isKindOfClass: [BasicStop class]]) {
            return [basicStop capacity2nd];
        }
    }
    return nil;
}

-  (NSNumber *) getLatitudeForStation:(Station *)station {
    if (station) {
        if ([station isKindOfClass: [Station class]]) {
            return [station latitude];
        }
    }
    return 0;
}

-  (NSNumber *) getLongitudeForStation:(Station *)station {
    if (station) {
        if ([station isKindOfClass: [Station class]]) {
            return [station longitude];
        }
    }
    return nil;
}

//--------------------------------------------------------------------------------
 
- (void) sendStbReqXMLStationboardRequestWithProductType:(Station *)station destination:(Station *)destination stbDate:(NSDate *)stbdate departureTime:(BOOL)departureTime productType:(NSUInteger)productType successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {
    
    if (!station.stationName || ! station.stationId || !stbdate) {
        return;
    }
        
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate: stbdate];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeString = [timeFormatter stringFromDate: stbdate];
    
    NSString *xmlString = kStbReq_XML_SOURCE;
    
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBSTATIONID" withString: [station stationId]];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBDATE" withString: dateString];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBTIME" withString: timeString];
    
    NSString *numberofrequestsstring = [NSString stringWithFormat: @"%d", self.sbbStbReqNumberOfConnectionsForRequest];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQNUM" withString: numberofrequestsstring];
    
    if (departureTime) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQTYPE" withString: @"DEP"];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQTYPE" withString: @"ARR"];
    }
    
    if (productType == stbOnlyFastTrain) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_LONGDISTANCETRAIN];
    } else if (productType == stbOnlyRegioTrain) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_REGIOTRAIN];
    } else if (productType == stbOnlyTramBus) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_TRAM_BUS];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_ALL];
    }
    
    if (destination.stationName && destination.stationId) {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"Destination station set");
        #endif
        
        NSString *xmlDirString = kStbReq_XML_DIR_SOURCE;
        xmlDirString = [xmlDirString stringByReplacingOccurrencesOfString: @"DIRSTATIONID" withString: [destination stationId]];
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"DIRECTIONFILTER" withString: xmlDirString];
        
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"DIRECTIONFILTER" withString: @""];
    }
    
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
    
    self.stbreqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.stbreqHttpClient) {
        [self.stbreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.stbreqHttpClient = nil;
    }
    
    self.stbreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.stbreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.stbreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiStbreqTimeout];
        
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Stbreq end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Stbreq cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kStbReqRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *stbreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakStbreqDecodingXMLOperation = stbreqDecodingXMLOperation;
        
        [stbreqDecodingXMLOperation addExecutionBlock: ^(void) {
            
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_stb_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
                        
            StationboardResults *tempStbResults = nil;
            tempStbResults = [[StationboardResults alloc] init];
            
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Stbreq cancelled. Stb queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kStbReqRequestFailureCancelled);
                        }];
                    }
                    return;
                }
                
                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *stbResNode = [xmlResponse nodeForXPath: @"//STBRes" error: nil];
                    if (stbResNode) {
                        CXMLNode *stbresults = [xmlResponse nodeForXPath: @"//JourneyList" error: nil];
                        if (stbresults) {
                            for (CXMLElement *currentStbResult in [stbresults children]) {
                                
                                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                    #ifdef SBBAPILogLevelCancel
                                    NSLog(@"Stbreq cancelled. Stb queue block. For each 1");
                                    #endif
                                    
                                    if (failureBlock) {
                                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                            failureBlock(kStbReqRequestFailureCancelled);
                                        }];
                                    }
                                    return;
                                }
                                
                                Journey *stbResult = [[Journey alloc] init];
                                for (CXMLElement *currentStbResultElement in [currentStbResult children]) {
                                    
                                    if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                        #ifdef SBBAPILogLevelCancel
                                        NSLog(@"Stbreq cancelled. Stb queue block. For each 2");
                                        #endif
                                        
                                        if (failureBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                failureBlock(kStbReqRequestFailureCancelled);
                                            }];
                                        }
                                        return;
                                    }
                                    
                                    if ([[currentStbResultElement name] isEqualToString: @"JHandle"]) {
                                        NSString *journeytnr = [[currentStbResultElement attributeForName: @"tNr"] stringValue];
                                        NSString *journeypuic = [[currentStbResultElement attributeForName: @"puic"] stringValue];
                                        NSString *journeycycle = [[currentStbResultElement attributeForName: @"cycle"] stringValue];
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Current journey code: %@, %@, %@", journeytnr, journeypuic, journeycycle);
                                        #endif
                                        
                                        JourneyHandle *journeyhandle = [[JourneyHandle alloc] init];
                                        journeyhandle.tnr = journeytnr;
                                        journeyhandle.puic = journeypuic;
                                        journeyhandle.cycle = journeycycle;
                                        stbResult.journeyHandle = journeyhandle;
                                    } else if ([[currentStbResultElement name] isEqualToString: @"MainStop"]) {
                                        BasicStop *mainstop = [[BasicStop alloc] init];
                                        mainstop.basicStopType = arrivalType;
                                        CXMLNode *mainstopElements = [currentStbResultElement childAtIndex: 0];
                                        
                                        for (CXMLElement *mainstopElement in [mainstopElements children]) {
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"main stop element name: %@", [mainstopElement name]);
                                            #endif
                                            
                                            if ([[mainstopElement name] isEqualToString: @"Station"]) {
                                                Station *mainstopStation = [[Station alloc] init];
                                                mainstopStation.stationName = [self fromISOLatinToUTF8: [[mainstopElement attributeForName: @"name"] stringValue]];
                                                mainstopStation.stationId = [self fromISOLatinToUTF8: [[mainstopElement attributeForName: @"externalId"] stringValue]];
                                                double latitude = [[[mainstopElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                double longitude = [[[mainstopElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                mainstopStation.latitude = [NSNumber numberWithFloat: latitude];
                                                mainstopStation.longitude = [NSNumber numberWithFloat: longitude];
                                                mainstop.station = mainstopStation;
                                            } else if ([[mainstopElement name] isEqualToString: @"Dep"]) {
                                                Dep *dep = [[Dep alloc] init];
                                                for (CXMLElement *currentDepElement in [mainstopElement children]) {
                                                    if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                        dep.timeString = [currentDepElement stringValue];
                                                        mainstop.dep = dep;
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"STB dep time: %@", dep.timeString);
                                                        #endif
                                                        
                                                    } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                        CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                        NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"STB dep platform: %@", platformString);
                                                        #endif
                                                        
                                                        dep.platform = platformString;
                                                    }
                                                }
                                            } else if ([[mainstopElement name] isEqualToString: @"Arr"]) {
                                                Arr *arr = [[Arr alloc] init];
                                                for (CXMLElement *currentArrElement in [mainstopElement children]) {
                                                    if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                        arr.timeString = [currentArrElement stringValue];
                                                        mainstop.arr = arr;
                                                    } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                        CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                        NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"STB arr platform: %@", platformString);
                                                        #endif
                                                        
                                                        arr.platform = platformString;
                                                    }
                                                }
                                            } else if ([[mainstopElement name] isEqualToString: @"StopPrognosis"]) {
                                                for (CXMLElement *currentDepElement in [mainstopElement children]) {
                                                    if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                        NSString *capstring = [currentDepElement stringValue];
                                                        mainstop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                    } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                        NSString *capstring = [currentDepElement stringValue];
                                                        mainstop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                    } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                        NSString *statusstring = [currentDepElement stringValue];
                                                        mainstop.scheduled = statusstring;
                                                    }
                                                }
                                            }
                                        }
                                        stbResult.mainstop = mainstop;
                                    } else if ([[currentStbResultElement name] isEqualToString: @"JourneyAttributeList"]) {
                                        for (CXMLElement *journeyAttributeElement in [currentStbResultElement children]) {
            
                                            CXMLNode *journeyAttributeElementDetail = [journeyAttributeElement childAtIndex: 0];
                                            
                                            NSString *attributeType = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"type"] stringValue];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Stb detail element journey attribute element type: %@", attributeType);
                                            #endif
                                            
                                            if ([attributeType isEqualToString: @"NAME"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Name attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        NSString *journeyName = [[journeyAttributeVariantElement stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        stbResult.journeyName = journeyName;
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Name attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                        
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"CATEGORY"]) {
                                                NSString *categoryCode = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"code"] stringValue];
                                                stbResult.journeyCategoryCode = categoryCode;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Category attribute variant element code: %@", categoryCode);
                                                #endif
                                                
                                                
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Category attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyCategoryName = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Category attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"NUMBER"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Number attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyNumber = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Number attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"ADMINISTRATION"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Administration attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyAdministration = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Administration attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"OPERATOR"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyOperator = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Operator attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"DIRECTION"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyDirection = [self fromISOLatinToUTF8: [journeyAttributeVariantElement stringValue]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Direction attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                            } 
                                        }
                                    }
                                }
                                if (stbResult) {
                                    
                                    #ifdef SBBAPILogLevelXMLReqRes
                                    NSLog(@"StbRes: %@", stbResult);
                                    #endif
                                    
                                    [tempStbResults.stbJourneys addObject: stbResult];
                                }
                                
                                #ifdef SBBAPILogLevelXMLReqRes
                                NSLog(@"StbRes #: %d", tempStbResults.stbJourneys.count);
                                #endif
                            }
                        }
                    }
                }
                
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }
                        
            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Stbreq end decoding xml"];
            #endif
            self.stbreqRequestInProgress = NO;
            
            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Stbreq cancelled. Stb queue block. End. MainQueue call");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kStbReqRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (tempStbResults && tempStbResults.stbJourneys.count > 0) {
                            if (productType == stbOnlyFastTrain) {
                                self.stationboardResultFastTrainOnly = tempStbResults;
                            } else if (productType == stbOnlyRegioTrain) {
                                self.stationboardResultRegioTrainOnly = tempStbResults;
                            } else if (productType == stbOnlyTramBus) {
                                self.stationboardResultTramBusOnly = tempStbResults;
                            } else {
                                self.stationboardResult = tempStbResults;
                            }
                            
                            NSUInteger numberofnewresults = 0;
                            
                            if (productType == stbOnlyFastTrain) {
                                numberofnewresults = self.stationboardResultFastTrainOnly.stbJourneys.count;
                            } else if (productType == stbOnlyRegioTrain) {
                                numberofnewresults = self.stationboardResultRegioTrainOnly.stbJourneys.count;
                            } else if (productType == stbOnlyTramBus) {
                                numberofnewresults = self.stationboardResultTramBusOnly.stbJourneys.count;
                            } else {
                                numberofnewresults = self.stationboardResult.stbJourneys.count;
                            }
                            
                            successBlock(numberofnewresults);
                            
                        } else {
                            if (failureBlock) {
                                failureBlock(kStbRegRequestFailureNoNewResults);
                            }
                        }
                    }];
                }
            }
        }];
        [_stbreqBackgroundOpQueue addOperation: stbreqDecodingXMLOperation];
         
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        
        self.stbreqRequestInProgress = NO;
        
        if (failureBlock) {
            failureBlock(kStbReqRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Stbreq start operation"];
    #endif
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}


- (void) getProductTypesWithQuickCheckStbReqXMLStationboardRequestWithProductCode:(Station *)station destination:(Station *)destination stbDate:(NSDate *)stbdate departureTime:(BOOL)departureTime gotProductTypesBlock:(void(^)(NSUInteger))gotProductTypesBlock failedToGetProductTypesBlock:(void(^)(NSUInteger))failedToGetProductTypesBlock {
        
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate: stbdate];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeString = [timeFormatter stringFromDate: stbdate];
    
    NSString *xmlString = kStbReq_XML_SOURCE;
        
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBSTATIONID" withString: [station stationId]];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBDATE" withString: dateString];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBTIME" withString: timeString];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQNUM" withString: @"120"];
    
    if (departureTime) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQTYPE" withString: @"DEP"];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQTYPE" withString: @"ARR"];
    }
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_ALL];
    
    
    if (destination.stationName && destination.stationId) {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"Destination station set");
        #endif
        
        NSString *xmlDirString = kStbReq_XML_DIR_SOURCE;
        xmlDirString = [xmlDirString stringByReplacingOccurrencesOfString: @"DIRSTATIONID" withString: [destination stationId]];
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"DIRECTIONFILTER" withString: xmlDirString];
        
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"DIRECTIONFILTER" withString: @""];
    }
    
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
    
    self.stbreqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.stbreqHttpClient) {
        [self.stbreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.stbreqHttpClient = nil;
    }
    
    self.stbreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.stbreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.stbreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiStbreqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Stbcheck end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Stbreqcheck cancelled. Op success block start");
            #endif
            
            if (failedToGetProductTypesBlock) {
                failedToGetProductTypesBlock(kStbReqRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *stbreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakStbreqDecodingXMLOperation = stbreqDecodingXMLOperation;
        
        [stbreqDecodingXMLOperation addExecutionBlock: ^(void) {
                
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_stb_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
            
            StationboardResults *tempStbResults = nil;
            tempStbResults = [[StationboardResults alloc] init];
            
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Stbreqcheck cancelled. Stb queue block. cleanedstring");
                    #endif
                    
                    if (failedToGetProductTypesBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failedToGetProductTypesBlock(kStbReqRequestFailureCancelled);
                        }];
                    }
                    return;
                }

                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *stbResNode = [xmlResponse nodeForXPath: @"//STBRes" error: nil];
                    if (stbResNode) {
                        CXMLNode *stbresults = [xmlResponse nodeForXPath: @"//JourneyList" error: nil];
                        if (stbresults) {
                            for (CXMLElement *currentStbResult in [stbresults children]) {
                                
                                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                    #ifdef SBBAPILogLevelCancel
                                    NSLog(@"Stbreq cancelled. Stb queue block. For each 1");
                                    #endif
                                    
                                    if (failedToGetProductTypesBlock) {
                                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                            failedToGetProductTypesBlock(kStbReqRequestFailureCancelled);
                                        }];
                                    }
                                    return;
                                }
                    
                                Journey *stbResult = [[Journey alloc] init];
                                for (CXMLElement *currentStbResultElement in [currentStbResult children]) {
                                    
                                    if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                        #ifdef SBBAPILogLevelCancel
                                        NSLog(@"Stbreq cancelled. Stb queue block. For each 2");
                                        #endif
                                        
                                        if (failedToGetProductTypesBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                failedToGetProductTypesBlock(kStbReqRequestFailureCancelled);
                                            }];
                                        }
                                        return;
                                    }
                                    
                                    if ([[currentStbResultElement name] isEqualToString: @"JourneyAttributeList"]) {
                                        for (CXMLElement *journeyAttributeElement in [currentStbResultElement children]) {
                                            CXMLNode *journeyAttributeElementDetail = [journeyAttributeElement childAtIndex: 0];
                                            NSString *attributeType = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"type"] stringValue];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Stb detail element journey attribute element type: %@", attributeType);
                                            #endif
                                            
                                            if ([attributeType isEqualToString: @"CATEGORY"]) {
                                                NSString *categoryCode = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"code"] stringValue];
                                                stbResult.journeyCategoryCode = categoryCode;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Category attribute variant element code: %@", categoryCode);
                                                #endif
                                            }
                                        }
                                    }
                                }
                                if (stbResult) {
                                    
                                    #ifdef SBBAPILogLevelXMLReqRes
                                    NSLog(@"StbRes: %@", stbResult);
                                    #endif
                                    
                                    [tempStbResults.stbJourneys addObject: stbResult];
                                }
                                
                                #ifdef SBBAPILogLevelXMLReqRes
                                NSLog(@"StbRes #: %d", tempStbResults.stbJourneys.count);
                                #endif
                                
                            }
                        }
                    }
                }
                
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }
                        
            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Stbcheck end decoding xml"];
            #endif
            
            self.stbreqRequestInProgress = NO;
            
            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Stbreq cancelled. Stb queue block. End. MainQueue call");
                #endif
                
                if (failedToGetProductTypesBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failedToGetProductTypesBlock(kStbReqRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (gotProductTypesBlock) {
                    
                    StationboardResults *fastTrainResult = [[StationboardResults alloc] init];
                    StationboardResults *regioTrainResult = [[StationboardResults alloc] init];
                    StationboardResults *trambusResult = [[StationboardResults alloc] init];
                    
                    for (Journey *currentJourney in tempStbResults.stbJourneys) {
                        NSString *categoryCodeString = [currentJourney journeyCategoryCode];
                        NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
                        if (([categoryCode integerValue] < 3) || ([categoryCode integerValue] == 8)) {
                            [fastTrainResult.stbJourneys addObject: currentJourney];
                        } else if (([categoryCode integerValue] >= 3) && ([categoryCode integerValue] <= 5)) {
                            [regioTrainResult.stbJourneys addObject: currentJourney];
                        } else if (([categoryCode integerValue] > 5) && ([categoryCode integerValue] != 8)) {
                            [trambusResult.stbJourneys addObject: currentJourney];
                        }
                    }
                    
                    
                    NSUInteger fastTrainCount = 0;
                    NSUInteger regioTrainCount = 0;
                    NSUInteger trambusCount = 0;
                    
                    if (fastTrainResult) {
                        if (fastTrainResult.stbJourneys) {
                            fastTrainCount = fastTrainResult.stbJourneys.count;
                        }
                    }
                    if (regioTrainResult) {
                        if (regioTrainResult.stbJourneys) {
                            regioTrainCount = regioTrainResult.stbJourneys.count;
                        }
                    }
                    if (trambusResult) {
                        if (trambusResult.stbJourneys) {
                            trambusCount = trambusResult.stbJourneys.count;
                        }
                    }

                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (tempStbResults && tempStbResults.stbJourneys.count > 0) {
                            
                            if ((fastTrainCount > 0) && (regioTrainCount == 0) && (trambusCount == 0)) {
                                gotProductTypesBlock(stbOnlyFastTrain);
                            } else if ((fastTrainCount == 0) && (regioTrainCount > 0) && (trambusCount == 0)) {
                                gotProductTypesBlock(stbOnlyRegioTrain);
                            } else if ((fastTrainCount == 0) && (regioTrainCount == 0) && (trambusCount > 0)) {
                                gotProductTypesBlock(stbOnlyTramBus);
                            } else if ((fastTrainCount > 0) && (regioTrainCount > 0) && (trambusCount == 0)) {
                                gotProductTypesBlock(stbFastAndRegioTrain);
                            } else if ((fastTrainCount > 0) && (regioTrainCount == 0) && (trambusCount > 0)) {
                                gotProductTypesBlock(stbFastTrainAndTramBus);
                            } else if ((fastTrainCount == 0) && (regioTrainCount > 0) && (trambusCount > 0)) {
                                gotProductTypesBlock(stbRegioTrainAndTramBus);
                            } else if ((fastTrainCount > 0) && (regioTrainCount > 0) && (trambusCount > 0)) {
                                gotProductTypesBlock(stbAll);
                            } else {
                                gotProductTypesBlock(stbNone);
                            }
                            
                        } else {
                            if (failedToGetProductTypesBlock) {
                                failedToGetProductTypesBlock(kStbRegRequestFailureNoNewResults);
                            }
                        }
                    }];
                }
            }
        }];
        [_stbreqBackgroundOpQueue addOperation: stbreqDecodingXMLOperation];
             
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        
        self.stbreqRequestInProgress = NO;
    
        if (failedToGetProductTypesBlock) {
            failedToGetProductTypesBlock(kStbReqRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Stbcheck start operation"];
    #endif
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

#define STBSCRTIMEDIFFINTERVAL 60*60
#define STBSCRMAXBACKANDFWD 10

- (void) sendStbScrXMLStationboardRequestWithProductType:(NSUInteger)directionflag station:(Station *)station destination:(Station *)destination stbDate:(NSDate *)stbdate departureTime:(BOOL)departureTime productType:(NSUInteger)productType successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {
    
    if (!station.stationName || ! station.stationId || !stbdate) {
        return;
    }
    
    StationboardResults *currentStationboardResultForProductType;
    
    if (productType == stbOnlyFastTrain) {
        currentStationboardResultForProductType = self.stationboardResultFastTrainOnly;
    } else if (productType == stbOnlyRegioTrain) {
        currentStationboardResultForProductType = self.stationboardResultRegioTrainOnly;
    } else if (productType == stbOnlyTramBus) {
        currentStationboardResultForProductType = self.stationboardResultTramBusOnly;
    } else {
        currentStationboardResultForProductType = self.stationboardResult;
    }
    
    if (!currentStationboardResultForProductType)  {
        NSUInteger kStbScrRequestFailureNoStationboardResult = 52;
        if (failureBlock) {
            failureBlock(kStbScrRequestFailureNoStationboardResult);
        }
    }

    if (![currentStationboardResultForProductType stbJourneys] > 0)  {
        NSUInteger kStbScrRequestFailureNoJourneysInCurrentRequest = 55;
        if (failureBlock) {
            failureBlock(kStbScrRequestFailureNoJourneysInCurrentRequest);
        }
    }
    
    NSDate *stbScrDate;
    
    if (directionflag == stbscrBackward) {
        Journey *firstJourneyInCurrentResult = [[currentStationboardResultForProductType stbJourneys] objectAtIndex: 0];
        NSString *journeydatestring;
        if ([[firstJourneyInCurrentResult mainstop] dep]) {
            journeydatestring = [[[firstJourneyInCurrentResult mainstop] dep] timeString];
        } else if ([[firstJourneyInCurrentResult mainstop] arr]) {
            journeydatestring = [[[firstJourneyInCurrentResult mainstop] arr] timeString];
        }
        NSDateFormatter *toDateTimeFormatter = [[NSDateFormatter alloc] init];
        [toDateTimeFormatter setDateFormat:@"HH:mm"];
        NSDate *firstTimeDate = [toDateTimeFormatter dateFromString: journeydatestring];
        stbScrDate = [firstTimeDate dateByAddingTimeInterval: - STBSCRTIMEDIFFINTERVAL];
    } else if (directionflag == stbscrForward) {
        Journey *lastJourneyInCurrentResult = [[currentStationboardResultForProductType stbJourneys] lastObject];
        NSString *journeydatestring;
        if ([[lastJourneyInCurrentResult mainstop] dep]) {
            journeydatestring = [[[lastJourneyInCurrentResult mainstop] dep] timeString];
        } else if ([[lastJourneyInCurrentResult mainstop] arr]) {
            journeydatestring = [[[lastJourneyInCurrentResult mainstop] arr] timeString];
        }
        NSDateFormatter *toDateTimeFormatter = [[NSDateFormatter alloc] init];
        [toDateTimeFormatter setDateFormat:@"HH:mm"];
        NSDate *firstTimeDate = [toDateTimeFormatter dateFromString: journeydatestring];
        stbScrDate = firstTimeDate;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate: stbdate];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeString = [timeFormatter stringFromDate: stbScrDate];
    
    NSString *xmlString = kStbReq_XML_SOURCE;
    
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBSTATIONID" withString: [station stationId]];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBDATE" withString: dateString];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBTIME" withString: timeString];
    
    NSString *numberofrequestsstring = [NSString stringWithFormat: @"%d", self.sbbStbScrNumberOfConnectionsForRequest];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQNUM" withString: numberofrequestsstring];
    
    if (departureTime) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQTYPE" withString: @"DEP"];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STBREQTYPE" withString: @"ARR"];
    }
    
    if (productType == stbOnlyFastTrain) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_LONGDISTANCETRAIN];
    } else if (productType == stbOnlyRegioTrain) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_REGIOTRAIN];
    } else if (productType == stbOnlyTramBus) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_TRAM_BUS];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"PRODUCTCODE" withString: kPRODUCT_CODE_ALL];
    }

    if (destination.stationName && destination.stationId) {
        
        #ifdef SBBAPILogLevelFull
        NSLog(@"Destination station set");
        #endif
        
        NSString *xmlDirString = kStbReq_XML_DIR_SOURCE;
        xmlDirString = [xmlDirString stringByReplacingOccurrencesOfString: @"DIRSTATIONID" withString: [destination stationId]];
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"DIRECTIONFILTER" withString: xmlDirString];
        
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"DIRECTIONFILTER" withString: @""];
    }
    
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
    
    self.stbreqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.stbreqHttpClient) {
        [self.stbreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.stbreqHttpClient = nil;
    }
    
    self.stbreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.stbreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.stbreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiStbreqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Stbscr cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kStbScrRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *stbreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakStbreqDecodingXMLOperation = stbreqDecodingXMLOperation;
        
        [stbreqDecodingXMLOperation addExecutionBlock: ^(void) {
                        
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_stbscr_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
                        
            StationboardResults *tempStbResults = nil;
            tempStbResults = [[StationboardResults alloc] init];
            
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Stbscr cancelled. Stb queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kStbScrRequestFailureCancelled);
                        }];
                    }
                    return;
                }
                
                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *stbResNode = [xmlResponse nodeForXPath: @"//STBRes" error: nil];
                    if (stbResNode) {
                        CXMLNode *stbresults = [xmlResponse nodeForXPath: @"//JourneyList" error: nil];
                        if (stbresults) {
                            for (CXMLElement *currentStbResult in [stbresults children]) {
                                
                                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                    #ifdef SBBAPILogLevelCancel
                                    NSLog(@"Stbscr cancelled. Stb queue block. For each 1");
                                    #endif
                                    
                                    if (failureBlock) {
                                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                            failureBlock(kStbScrRequestFailureCancelled);
                                        }];
                                    }
                                    return;
                                }
                                
                                Journey *stbResult = [[Journey alloc] init];
                                for (CXMLElement *currentStbResultElement in [currentStbResult children]) {
                                    
                                    if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                        #ifdef SBBAPILogLevelCancel
                                        NSLog(@"Stbscr cancelled. Stb queue block. For each 2");
                                        #endif
                                        
                                        if (failureBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                failureBlock(kStbScrRequestFailureCancelled);
                                            }];
                                        }
                                        return;
                                    }
                                    
                                    if ([[currentStbResultElement name] isEqualToString: @"JHandle"]) {
                                        NSString *journeytnr = [[currentStbResultElement attributeForName: @"tNr"] stringValue];
                                        NSString *journeypuic = [[currentStbResultElement attributeForName: @"puic"] stringValue];
                                        NSString *journeycycle = [[currentStbResultElement attributeForName: @"cycle"] stringValue];
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Current journey code: %@, %@, %@", journeytnr, journeypuic, journeycycle);
                                        #endif
                                        
                                        JourneyHandle *journeyhandle = [[JourneyHandle alloc] init];
                                        journeyhandle.tnr = journeytnr;
                                        journeyhandle.puic = journeypuic;
                                        journeyhandle.cycle = journeycycle;
                                        stbResult.journeyHandle = journeyhandle;
                                    } else if ([[currentStbResultElement name] isEqualToString: @"MainStop"]) {
                                        BasicStop *mainstop = [[BasicStop alloc] init];
                                        mainstop.basicStopType = arrivalType;
                                        CXMLNode *mainstopElements = [currentStbResultElement childAtIndex: 0];
                                        
                                        for (CXMLElement *mainstopElement in [mainstopElements children]) {
                                            
                                            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Stbscr cancelled. Stb queue block. For each 3");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kStbScrRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"main stop element name: %@", [mainstopElement name]);
                                            #endif
                                            
                                            if ([[mainstopElement name] isEqualToString: @"Station"]) {
                                                Station *mainstopStation = [[Station alloc] init];
                                                mainstopStation.stationName = [self fromISOLatinToUTF8: [[mainstopElement attributeForName: @"name"] stringValue]];
                                                mainstopStation.stationId = [self fromISOLatinToUTF8: [[mainstopElement attributeForName: @"externalId"] stringValue]];
                                                double latitude = [[[mainstopElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                double longitude = [[[mainstopElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                mainstopStation.latitude = [NSNumber numberWithFloat: latitude];
                                                mainstopStation.longitude = [NSNumber numberWithFloat: longitude];
                                                mainstop.station = mainstopStation;
                                            } else if ([[mainstopElement name] isEqualToString: @"Dep"]) {
                                                Dep *dep = [[Dep alloc] init];
                                                for (CXMLElement *currentDepElement in [mainstopElement children]) {
                                                    if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                        dep.timeString = [currentDepElement stringValue];
                                                        mainstop.dep = dep;
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"STB dep time: %@", dep.timeString);
                                                        #endif
                                                        
                                                    } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                        CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                        NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"STB dep platform: %@", platformString);
                                                        #endif
                                                        
                                                        dep.platform = platformString;
                                                    }
                                                }
                                            } else if ([[mainstopElement name] isEqualToString: @"Arr"]) {
                                                Arr *arr = [[Arr alloc] init];
                                                for (CXMLElement *currentArrElement in [mainstopElement children]) {
                                                    if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                        arr.timeString = [currentArrElement stringValue];
                                                        mainstop.arr = arr;
                                                    } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                        CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                        NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"STB arr platform: %@", platformString);
                                                        #endif
                                                        
                                                        arr.platform = platformString;
                                                    }
                                                }
                                            } else if ([[mainstopElement name] isEqualToString: @"StopPrognosis"]) {
                                                for (CXMLElement *currentDepElement in [mainstopElement children]) {
                                                    if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                        NSString *capstring = [currentDepElement stringValue];
                                                        mainstop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                    } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                        NSString *capstring = [currentDepElement stringValue];
                                                        mainstop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                    } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                        NSString *statusstring = [currentDepElement stringValue];
                                                        mainstop.scheduled = statusstring;
                                                    }
                                                }
                                            }
                                        }
                                        stbResult.mainstop = mainstop;
                                    } else if ([[currentStbResultElement name] isEqualToString: @"JourneyAttributeList"]) {
                                        for (CXMLElement *journeyAttributeElement in [currentStbResultElement children]) {
                                            
                                            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                                #ifdef SBBAPILogLevelCancel
                                                NSLog(@"Stbscr cancelled. Stb queue block. For each 3");
                                                #endif
                                                
                                                if (failureBlock) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                        failureBlock(kStbScrRequestFailureCancelled);
                                                    }];
                                                }
                                                return;
                                            }
 
                                            CXMLNode *journeyAttributeElementDetail = [journeyAttributeElement childAtIndex: 0];
                                                                                        
                                            NSString *attributeType = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"type"] stringValue];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Stb detail element journey attribute element type: %@", attributeType);
                                            #endif
                                            
                                            if ([attributeType isEqualToString: @"NAME"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Name attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        NSString *journeyName = [[journeyAttributeVariantElement stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        stbResult.journeyName = journeyName;
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Name attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"CATEGORY"]) {
                                                NSString *categoryCode = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"code"] stringValue];
                                                stbResult.journeyCategoryCode = categoryCode;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Category attribute variant element code: %@", categoryCode);
                                                #endif
                                                
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Category attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyCategoryName = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Category attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"NUMBER"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Number attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyNumber = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Number attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"ADMINISTRATION"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Administration attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyAdministration = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Administration attribute variant element text: %@", [journeyAttributeVariantElement
                                                                                                                     stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"OPERATOR"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyOperator = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Operator attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"DIRECTION"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        stbResult.journeyDirection = [self fromISOLatinToUTF8: [journeyAttributeVariantElement stringValue]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Direction attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if (stbResult) {
                                    
                                    #ifdef SBBAPILogLevelXMLReqRes
                                    NSLog(@"StbScrRes: %@", stbResult);
                                    #endif
                                    
                                    [tempStbResults.stbJourneys addObject: stbResult];
                                }
                                
                                #ifdef SBBAPILogLevelXMLReqRes
                                NSLog(@"StbScrRes #: %d", tempStbResults.stbJourneys.count);
                                #endif
                            }
                        }
                    }
                }
                
            } else {
                
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }
                                
            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Stbscr end decoding xml"];
            #endif
            
            self.stbreqRequestInProgress = NO;
            
            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Stbscr cancelled. Stb queue block. End. MainQueue call");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kStbScrRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    
                    NSMutableArray *currentStationboardResultKeyArrays = [NSMutableArray arrayWithCapacity:1];
                    
                    StationboardResults *currentStationboardResultForProductType;
                    
                    if (productType == stbOnlyFastTrain) {
                        currentStationboardResultForProductType = self.stationboardResultFastTrainOnly;
                    } else if (productType == stbOnlyRegioTrain) {
                        currentStationboardResultForProductType = self.stationboardResultRegioTrainOnly;
                    } else if (productType == stbOnlyTramBus) {
                        currentStationboardResultForProductType = self.stationboardResultTramBusOnly;
                    } else {
                        currentStationboardResultForProductType = self.stationboardResult;
                    }
                    
                    #ifdef SBBAPILogLevelXMLReqRes
                    NSLog(@"StbScrRes before new journeys #: %d", currentStationboardResultForProductType.stbJourneys.count);
                    #endif
                    
                    for (Journey *currentJourney in currentStationboardResultForProductType.stbJourneys) {
                        NSString *timeString;
                        if ([[currentJourney mainstop] arr]) {
                            timeString = [[[currentJourney mainstop] arr] timeString];
                        } else if ([[currentJourney mainstop] dep]) {
                            timeString = [[[currentJourney mainstop] dep] timeString];
                        }
                        NSString *journeyName = [currentJourney journeyName];
                        NSString *key = [NSString stringWithFormat: @"%@%@", journeyName, timeString];
                        [currentStationboardResultKeyArrays addObject: key];
                    }
                    
                    NSMutableArray *filteredStbResult = [NSMutableArray arrayWithCapacity:1];
                    
                    #ifdef SBBAPILogLevelXMLReqRes
                    NSLog(@"StbScrRes got with request #: %d", tempStbResults.stbJourneys.count);
                    #endif

                    if (tempStbResults.stbJourneys.count > 0) {
                        for (Journey *currentResJourney in tempStbResults.stbJourneys) {
                            NSString *timeString;
                            if ([[currentResJourney mainstop] arr]) {
                                timeString = [[[currentResJourney mainstop] arr] timeString];
                            } else if ([[currentResJourney mainstop] dep]) {
                                timeString = [[[currentResJourney mainstop] dep] timeString];
                            }
                            NSString *journeyName = [currentResJourney journeyName];
                            NSString *key = [NSString stringWithFormat: @"%@%@", journeyName, timeString];
                            if (![currentStationboardResultKeyArrays containsObject: key]) {
                                [filteredStbResult addObject: currentResJourney];
                            }
                        }
                        
                        #ifdef SBBAPILogLevelXMLReqRes
                        NSLog(@"StbScrRes after filtering #: %d", filteredStbResult.count);
                        #endif
                    }
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                
                        if (tempStbResults && tempStbResults.stbJourneys.count > 0 && filteredStbResult.count > 0) {
                            
                            NSUInteger numberofnewresults = currentStationboardResultForProductType.stbJourneys.count;
                            
                            #ifdef SBBAPILogLevelXMLReqRes
                            NSLog(@"StbScrRes before new journeys #: %d", currentStationboardResultForProductType.stbJourneys.count);
                            #endif
                  
                            if (directionflag == stbscrBackward) {
                                for (Journey *currentjrnResult in [filteredStbResult reverseObjectEnumerator]) {
                                    [currentStationboardResultForProductType.stbJourneys insertObject: currentjrnResult atIndex: 0];
                                }
                            } else if (directionflag == stbscrForward) {
                                for (ConResult *currentjrnResult in filteredStbResult) {
                                    [currentStationboardResultForProductType.stbJourneys addObject: currentjrnResult];
                                }
                            }
                            
                            #ifdef SBBAPILogLevelXMLReqRes
                            NSLog(@"StbScrRes after new journeys #: %d", currentStationboardResultForProductType.stbJourneys.count);
                            #endif
                            
                            numberofnewresults = currentStationboardResultForProductType.stbJourneys.count - numberofnewresults;
                            
                            successBlock(numberofnewresults);
                            
                        } else {
                            if (filteredStbResult.count == 0) {
                                if (failureBlock) {
                                    failureBlock(kStbScrRequestFailureNoNewResults);
                                }
                            } else {
                                if (failureBlock) {
                                    failureBlock(kStbScrRequestFailureCancelled);
                                }
                            }
                        }
                    }];
                }
            }
        }];
        [_stbreqBackgroundOpQueue addOperation: stbreqDecodingXMLOperation];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        
        self.stbreqRequestInProgress = NO;
        
        if (failureBlock) {
            failureBlock(kStbScrRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Stbscr start operation"];
    #endif
    
    if (self.stbscrRequestCancelledFlag) {
        self.stbscrRequestCancelledFlag = NO;
        if (failureBlock) {
            failureBlock(kStbScrRequestFailureCancelled);
        }
    }
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

- (void) resetStationboardResults {
    self.stationboardResult = nil;
    self.stationboardResultFastTrainOnly = nil;
    self.stationboardResultRegioTrainOnly = nil;
    self.stationboardResultTramBusOnly = nil;
}

- (StationboardResults *)getStationboardresultsWithProducttype:(NSUInteger)producttype {
    if (producttype == stbOnlyFastTrain) {
        return self.stationboardResultFastTrainOnly;
    }
    if (producttype == stbOnlyRegioTrain) {
        return self.stationboardResultRegioTrainOnly;
    }
    if (producttype == stbOnlyTramBus) {
        return self.stationboardResultTramBusOnly;
    }
    return nil;
}

- (NSArray *) getStationboardResults {
    if (self.stationboardResult) {
        if ([self.stationboardResult stbJourneys]) {
            if ([[self.stationboardResult stbJourneys] count] > 0) {
                return [[[SBBAPIController sharedSBBAPIController] stationboardResult] stbJourneys];
            }
        }
    }
    return  nil;
}

- (NSUInteger) getNumberOfStationboardResults {
    if (self.stationboardResult) {
        if ([self.stationboardResult stbJourneys]) {
            if ([[self.stationboardResult stbJourneys] count] > 0) {
                return [[self.stationboardResult stbJourneys] count];
            }
        }
    }
    return  0;
}

- (Journey *) getJourneyForStationboardResultWithIndex:(NSUInteger)index {
    if (self.stationboardResult) {
        if ([self.stationboardResult stbJourneys]) {
            int conResultsCount = [[self.stationboardResult stbJourneys] count];
            if (conResultsCount > 0) {
                if (index < conResultsCount) {
                    return [[[[SBBAPIController sharedSBBAPIController] stationboardResult] stbJourneys] objectAtIndex: index];
                }
            }
        }
    }
    return  nil;
}

- (NSUInteger) getStationboardResultsAvailableProductTypes {
    if (self.stationboardResultFastTrainOnly && !self.stationboardResultRegioTrainOnly && !self.stationboardResultTramBusOnly) {
        return stbOnlyFastTrain;
    } else if (!self.stationboardResultFastTrainOnly && self.stationboardResultRegioTrainOnly && !self.stationboardResultTramBusOnly) {
        return stbOnlyRegioTrain;
    } else if (!self.stationboardResultFastTrainOnly && !self.stationboardResultRegioTrainOnly && self.stationboardResultTramBusOnly) {
        return stbOnlyTramBus;
    } else if (self.stationboardResultFastTrainOnly && self.stationboardResultRegioTrainOnly && !self.stationboardResultTramBusOnly) {
        return stbFastAndRegioTrain;
    } else if (self.stationboardResultFastTrainOnly && !self.stationboardResultRegioTrainOnly && self.stationboardResultTramBusOnly) {
        return stbFastTrainAndTramBus;
    } else if (!self.stationboardResultFastTrainOnly && self.stationboardResultRegioTrainOnly && self.stationboardResultTramBusOnly) {
        return stbRegioTrainAndTramBus;
    } else if (self.stationboardResultFastTrainOnly && self.stationboardResultRegioTrainOnly && self.stationboardResultTramBusOnly) {
        return stbAll;
    }
    return stbAll;
}


- (NSArray *) getStationboardResultsWithProductType:(NSUInteger)producttype {
    if (producttype == stbOnlyFastTrain) {
        return  [self.stationboardResultFastTrainOnly stbJourneys];
    } else if (producttype == stbOnlyRegioTrain) {
        return  [self.stationboardResultRegioTrainOnly stbJourneys];
    } else if (producttype == stbOnlyTramBus) {
        return  [self.stationboardResultTramBusOnly stbJourneys];
    }
    return  nil;
}

- (NSUInteger) getNumberOfStationboardResultsWithProductType:(NSUInteger)producttype {
    if (producttype == stbOnlyFastTrain) {
        return  [[self.stationboardResultFastTrainOnly stbJourneys] count];
    } else if (producttype == stbOnlyRegioTrain) {
        return  [[self.stationboardResultRegioTrainOnly stbJourneys] count];
    } else if (producttype == stbOnlyTramBus) {
        return  [[self.stationboardResultTramBusOnly stbJourneys] count];
    }
    return  0;
}

- (Journey *) getJourneyForStationboardResultFWithProductTypeWithIndex:(NSUInteger)producttype index:(NSUInteger)index {
    if (producttype == stbOnlyFastTrain) {
        if ([[self.stationboardResultFastTrainOnly stbJourneys] count] > index) {
            return  [[self.stationboardResultFastTrainOnly stbJourneys] objectAtIndex: index];
        }
        return nil;
    } else if (producttype == stbOnlyRegioTrain) {
        if ([[self.stationboardResultRegioTrainOnly stbJourneys] count] > index) {
            return  [[self.stationboardResultRegioTrainOnly stbJourneys] objectAtIndex: index];
        }
        return nil;
    } else if (producttype == stbOnlyTramBus) {
        if ([[self.stationboardResultTramBusOnly stbJourneys] count] > index) {
            return  [[self.stationboardResultTramBusOnly stbJourneys] objectAtIndex: index];
        }
        return nil;
    }
    return  nil;
}


- (void) splitStationboardResultsIntoProductTypeCategories {
    //NSArray *fastTrainArray = [NSArray arrayWithObjects:  @"IC", @"IR", @"ICE", @"ICN", @"EC", @"RJ", @"TGV", @"EN", @"CNL" , nil];
    //NSArray *regioTrainArray = [NSArray arrayWithObjects:  @"S", @"RE", @"R" , nil];
    //NSArray *otherTransportArray = [NSArray arrayWithObjects:  @"BAT", @"FUN", @"BUS", @"TRO", @"TRAM", @"MET" , nil];
    
    //@"IC", @"IR", @"ICE", @"ICN", @"EC", @"RJ", @"TGV", @"EN", @"CNL" , nil];
    //  1       2      0       1       1       0     0       0      0
    //0-2
    
    //@"S", @"RE", @"R" , nil];
    //  5      3     5
    //3-5
    
    //@"BAT", @"FUN", @"BUS", @"TRO", @"TRAM", @"MET" , nil];
    //           7       6      6          9      9
    //> 5
    
    StationboardResults *fastTrainResult = [[StationboardResults alloc] init];
    StationboardResults *regioTrainResult = [[StationboardResults alloc] init];
    StationboardResults *trambusTrainResult = [[StationboardResults alloc] init];

    NSArray *stbResult = [self getStationboardResults];
    for (Journey *currentJourney in stbResult) {
        NSString *categoryCodeString = [currentJourney journeyCategoryCode];
        NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
        if (([categoryCode integerValue] < 3) || ([categoryCode integerValue] == 8)) {
            [fastTrainResult.stbJourneys addObject: currentJourney];
        } else if (([categoryCode integerValue] >= 3) && ([categoryCode integerValue] <= 5)) {
            [regioTrainResult.stbJourneys addObject: currentJourney];
        } else if (([categoryCode integerValue] > 5) && ([categoryCode integerValue] != 8)) {
            [trambusTrainResult.stbJourneys addObject: currentJourney];
        }
    }
    
    self.stationboardResultFastTrainOnly = fastTrainResult;
    self.stationboardResultRegioTrainOnly = regioTrainResult;
    self.stationboardResultTramBusOnly = trambusTrainResult;
}

- (NSArray *) getStationboardResultsFilteredWithTransportTypeFilter:(NSUInteger)transportTypeFilter {    
    //NSArray *fastTrainArray = [NSArray arrayWithObjects:  @"IC", @"IR", @"ICE", @"ICN", @"EC", @"RJ", @"TGV", @"EN", @"CNL" , nil];
    //NSArray *regioTrainArray = [NSArray arrayWithObjects:  @"S", @"RE", @"R" , nil];
    //NSArray *otherTransportArray = [NSArray arrayWithObjects:  @"BAT", @"FUN", @"BUS", @"TRO", @"TRAM", @"MET" , nil];
    
    //@"IC", @"IR", @"ICE", @"ICN", @"EC", @"RJ", @"TGV", @"EN", @"CNL" , nil];
    //  1       2      0       1       1       0     0       0      0
    //0-2
    
    //@"S", @"RE", @"R" , nil];
    //  5      3     5
    //3-5
    
    //@"BAT", @"FUN", @"BUS", @"TRO", @"TRAM", @"MET" , nil];
    //           7       6      6          9      9
    //> 5
    
    NSMutableArray *filterStbResult = [NSMutableArray arrayWithCapacity:2];
    NSArray *stbResult = [self getStationboardResults];
    for (Journey *currentJourney in stbResult) {
        NSString *categoryCodeString = [currentJourney journeyCategoryCode];
        NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
        if (transportTypeFilter == stbLongdistanceTrains) {
            if (([categoryCode integerValue] < 3) || ([categoryCode integerValue] == 8)) {
                [filterStbResult addObject: currentJourney];
            }
        } else if (transportTypeFilter == stbRegioTrains) {
            if (([categoryCode integerValue] >= 3) && ([categoryCode integerValue] <= 5)) {
                [filterStbResult addObject: currentJourney];
            }
        } else if (transportTypeFilter == stbTramBus) {
            if (([categoryCode integerValue] > 5) && ([categoryCode integerValue] != 8)) {
                [filterStbResult addObject: currentJourney];
            }
        }
    }
    return filterStbResult;
}

- (NSUInteger) getNumberOfStationboardResultsFilteredWithTransportTypeFilter:(NSUInteger)transportTypeFilter {
    NSMutableArray *filterStbResult = [NSMutableArray arrayWithCapacity:2];
    NSArray *stbResult = [self getStationboardResults];
    for (Journey *currentJourney in stbResult) {
        NSString *categoryCodeString = [currentJourney journeyCategoryCode];
        NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
        if (transportTypeFilter == stbLongdistanceTrains) {
            if (([categoryCode integerValue] < 3) || ([categoryCode integerValue] == 8)) {
                [filterStbResult addObject: currentJourney];
            }
        } else if (transportTypeFilter == stbRegioTrains) {
            if (([categoryCode integerValue] >= 3) && ([categoryCode integerValue] <= 5)) {
                [filterStbResult addObject: currentJourney];
            }
        } else if (transportTypeFilter == stbTramBus) {
            if (([categoryCode integerValue] > 5) && ([categoryCode integerValue] != 8)) {
                [filterStbResult addObject: currentJourney];
            }
        }
    }
    return [filterStbResult count];
}

- (Journey *) getJourneyForStationboardResultFilteredWithTransportTypeFilterWithIndex:(NSUInteger)transportTypeFilter index:(NSUInteger)index {
    NSMutableArray *filterStbResult = [NSMutableArray arrayWithCapacity:2];
    NSArray *stbResult = [self getStationboardResults];
    for (Journey *currentJourney in stbResult) {
        NSString *categoryCodeString = [currentJourney journeyCategoryCode];
        NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
        if (transportTypeFilter == stbLongdistanceTrains) {
            if (([categoryCode integerValue] < 3) || ([categoryCode integerValue] == 8)) {
                [filterStbResult addObject: currentJourney];
            }
        } else if (transportTypeFilter == stbRegioTrains) {
            if (([categoryCode integerValue] >= 3) && ([categoryCode integerValue] <= 5)) {
                [filterStbResult addObject: currentJourney];
            }
        } else if (transportTypeFilter == stbTramBus) {
            if (([categoryCode integerValue] > 5) && ([categoryCode integerValue] != 8)) {
                [filterStbResult addObject: currentJourney];
            }
        }
    }
    
    if (index < [filterStbResult count]) {
        return [filterStbResult objectAtIndex: index];
    }
    return nil;
}


- (BasicStop *) getMainBasicStopForStationboardJourney:(Journey *)journey {
    if (journey) {
        return [journey mainstop];
    }
    return nil;
}

- (JourneyHandle *) getJourneyhandleForStationboardJourney:(Journey *)journey {
    if (journey) {
        return [journey journeyHandle];
    }
    return nil;
}

- (NSString *) getDirectionNameForStationboardJourney:(Journey *)journey {
    if (journey) {
        return [journey journeyDirection];
    }
    return nil;
}

-  (NSString *) getDepartureTimeForStationboardJourney:(Journey *)journey {
    if (journey) {
        return [[[journey mainstop] dep] timeString];
    }
    return nil;
}

- (NSString *) getArrivalTimeForStationboardJourney:(Journey *)journey {
    if (journey) {
        return [[[journey mainstop] arr] timeString];
    }
    return nil;
}

- (NSUInteger ) getStationboardJourneyDepartureArrivalForWithStationboardJourney:(Journey *)journey {
    if (journey) {
        if ([[journey mainstop] dep]) {
            return stbDepartureType;
        } else if ([[journey mainstop] arr]) {
            return stbArrivalType;
        }
    }
    return stbDepartureType;
}

- (NSString *) getTransportNameWithStationboardJourney:(Journey *)journey {
    NSString *transportName = [journey journeyName];
        
    NSString *categoryCodeString = [journey journeyCategoryCode];
    NSNumber *categoryCode = [NSNumber numberWithInt: [categoryCodeString integerValue]];
    
    if ([categoryCode integerValue] == 6 || [categoryCode integerValue] == 9) {
        if (transportName && [transportName length] >= 2) {
            NSArray *splitname = [transportName componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            if (splitname && splitname.count > 1) {
                NSString *shortname = [splitname objectAtIndex: 0];
                if ([shortname isEqualToString: @"T"]) {
                    shortname = @"Tram";
                }
                if ([shortname isEqualToString: @"NFT"]) {
                    shortname = @"Tram";
                }
                if ([shortname isEqualToString: @"TRO"]) {
                    shortname = @"Bus";
                }
                if ([shortname isEqualToString: @"NFB"]) {
                    shortname = @"Bus";
                }
                if ([shortname isEqualToString: @"NFO"]) {
                    shortname = @"Bus";
                }
                NSString *transportnamenew = [NSString stringWithFormat:@"%@ %@", shortname, [splitname objectAtIndex: 1]];
                return transportnamenew;
            }
        }
    }
    
    // T, NFT, NFB, NFO, TRO,
    // Tram, Niederflurtram, Niederflurbus, X, Trolley
    
    return transportName;
}

- (NSString *) getSimplifiedTransportNameWithStationboardJourney:(Journey *)journey {
    NSString *transportName = [[self getTransportNameWithStationboardJourney: journey] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    if (transportName && [transportName length] >= 2) {
        NSArray *splitname = [transportName componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        if (splitname && splitname.count > 1) {
            return [splitname objectAtIndex: 0];
        }
        return [transportName substringToIndex: 2];
    }

    return transportName;
}

- (NSString *) getTransportTypeWithStationboardJourney:(Journey *)journey {
    
    NSString *transportImageName = nil;
 
    NSString *transportName = [[[journey journeyCategoryName] uppercaseString] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    NSUInteger transportType = [self getTransportTypeCodeForTransportCategoryType: transportName];
    if (transportType == transportUnknown) {
        return @"Train";
    } else if (transportType == transportFastTrain) {
        return @"Fast train";
    } else if (transportType == transportSlowTrain) {
        return @"Regio train";
    } else if (transportType == transportTram) {
        return @"Tram";
    } else if (transportType == transportBus) {
        return @"Bus";
    } else if (transportType == transportShip) {
        return @"Ship";
    } else if (transportType == transportFuni) {
        return @"Funi";
    }
    return transportImageName;
}

//--------------------------------------------------------------------------------


- (void) sendJourneyReqXMLJourneyRequest:(Station *)station journeyhandle:(JourneyHandle *)journeyhandle jrnDate:(NSDate *)jrndate departureTime:(BOOL)departureTime successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {
        
    if (!station.stationName || ! station.stationId || !jrndate || !journeyhandle) {
        return;
    }
    if (!journeyhandle.tnr || ! journeyhandle.cycle || ! journeyhandle.puic) {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate: jrndate];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeString = [timeFormatter stringFromDate: jrndate];
    
    NSString *xmlString = kJourneyReq_XML_SOURCE;
    
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STATIONID" withString: [station stationId]];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNDATE" withString: dateString];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNTIME" withString: timeString];
    
    if (departureTime) {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNREQTYPE" withString: @"DEP"];
    } else {
        xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNREQTYPE" withString: @"ARR"];
    }
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNTNR" withString: journeyhandle.tnr];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNCYCLE" withString: journeyhandle.cycle];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"JRNPUIC" withString: journeyhandle.puic];
    
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
    
    self.stbreqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.stbreqHttpClient) {
        [self.stbreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.stbreqHttpClient = nil;
    }
    
    self.stbreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.stbreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.stbreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiStbreqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Jrnreq end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Jrnreq cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kJrnReqRequestFailureCancelled);
            }
            return;
        }

        NSBlockOperation *stbreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakStbreqDecodingXMLOperation = stbreqDecodingXMLOperation;
        
        [stbreqDecodingXMLOperation addExecutionBlock: ^(void) {
            
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_jrn_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
                        
            Journey *journey = nil;
            journey = [[Journey alloc] init];
            
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakStbreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Jrnreq cancelled. Jrn queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kJrnReqRequestFailureCancelled);
                        }];
                    }
                    return;
                }

                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *jrnResNode = [xmlResponse nodeForXPath: @"//JourneyRes" error: nil];
                    if (jrnResNode) {
                        for (CXMLElement *currentJourneyResElement in [jrnResNode children]) {
                            
                            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                #ifdef SBBAPILogLevelCancel
                                NSLog(@"Jrnreq cancelled. Jrn queue block. For each 1");
                                #endif
                                
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                        failureBlock(kJrnReqRequestFailureCancelled);
                                    }];
                                }
                                return;
                            }
                            
                            if ([[currentJourneyResElement name] isEqualToString: @"Journey"]) {
                                for (CXMLElement *currentJourneyElement in [currentJourneyResElement children]) {
                                    
                                    if ([weakStbreqDecodingXMLOperation isCancelled]) {
                                        #ifdef SBBAPILogLevelCancel
                                        NSLog(@"Jrnreq cancelled. Jrn queue block. For each 2");
                                        #endif
                                        
                                        if (failureBlock) {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                failureBlock(kJrnReqRequestFailureCancelled);
                                            }];
                                        }
                                        return;
                                    }
                                    
                                    if ([[currentJourneyElement name] isEqualToString: @"JHandle"]) {
                                        NSString *journeytnr = [[currentJourneyElement attributeForName: @"tNr"] stringValue];
                                        NSString *journeypuic = [[currentJourneyElement attributeForName: @"puic"] stringValue];
                                        NSString *journeycycle = [[currentJourneyElement attributeForName: @"cycle"] stringValue];
                                        
                                        #ifdef SBBAPILogLevelFull
                                        NSLog(@"Consection detail element journey handle attribute element type: %@, %@, %@", journeytnr, journeypuic, journeycycle);
                                        #endif
                                        
                                        JourneyHandle *journeyhandle = [[JourneyHandle alloc] init];
                                        journeyhandle.tnr = journeytnr;
                                        journeyhandle.puic = journeypuic;
                                        journeyhandle.cycle = journeycycle;
                                        journey.journeyHandle = journeyhandle;
                                    } else if ([[currentJourneyElement name] isEqualToString: @"JourneyAttributeList"]) {
                                        for (CXMLElement *journeyAttributeElement in [currentJourneyElement children]) {
                                            //NSLog(@"Consection detail element journey attribute element: %@", journeyAttributeElement);
                                            CXMLNode *journeyAttributeElementDetail = [journeyAttributeElement childAtIndex: 0];
                                            //NSLog(@"Array: %@", journeyAttributeElementDetail);
                                            
                                            NSString *attributeType = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"type"] stringValue];
                                            
                                            #ifdef SBBAPILogLevelFull
                                            NSLog(@"Consection detail element journey attribute element type: %@", attributeType);
                                            #endif
                                            
                                            if ([attributeType isEqualToString: @"NAME"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Name attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        NSString *journeyName = [[journeyAttributeVariantElement stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                        journey.journeyName = journeyName;
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Name attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"CATEGORY"]) {
                                                NSString *categoryCode = [[(CXMLElement *)journeyAttributeElementDetail attributeForName: @"code"] stringValue];
                                                journey.journeyCategoryCode = categoryCode;
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Category attribute variant element code: %@", categoryCode);
                                                #endif
                                                
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Category attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        journey.journeyCategoryName = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Category attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"NUMBER"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Number attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        journey.journeyNumber = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Number attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"ADMINISTRATION"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Administration attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        journey.journeyAdministration = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Administration attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"OPERATOR"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        journey.journeyOperator = [journeyAttributeVariantElement stringValue];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Operator attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                                
                                            } else if ([attributeType isEqualToString: @"DIRECTION"]) {
                                                for (CXMLElement *journeyAttributeVariantElement in [journeyAttributeElementDetail children]) {
                                                    NSString *attributeVariantElement = [[(CXMLElement *)journeyAttributeVariantElement attributeForName: @"type"] stringValue];
                                                    //NSLog(@"Operator attribute variant element type: %@", attributeVariantElement);
                                                    if ([attributeVariantElement isEqualToString: @"NORMAL"]) {
                                                        journey.journeyDirection = [self fromISOLatinToUTF8: [journeyAttributeVariantElement stringValue]];
                                                        
                                                        #ifdef SBBAPILogLevelFull
                                                        NSLog(@"Direction attribute variant element text: %@", [journeyAttributeVariantElement stringValue]);
                                                        #endif
                                                    }
                                                }
                                            }
                                        }
                                    } else if ([[currentJourneyElement name] isEqualToString: @"PassList"]) {
                                        for (CXMLElement *journeyPasslistElement in [currentJourneyElement children]) {
                                            //NSLog(@"Consection detail element pass list element: %@", journeyPasslistElement);
                                            
                                            BasicStop *basicStop = [[BasicStop alloc] init];
                                            basicStop.basicStopType = arrivalType;
                                            //CXMLNode *arrivalElements = [currentConSectionDetailElement childAtIndex: 0];
                                            
                                            for (CXMLElement *basicStopElement in [journeyPasslistElement children]) {
                                                
                                                #ifdef SBBAPILogLevelFull
                                                NSLog(@"Consection detail element arrival: %@", [basicStopElement name]);
                                                #endif
                                                
                                                if ([[basicStopElement name] isEqualToString: @"Station"]) {
                                                    Station *station = [[Station alloc] init];
                                                    station.stationName = [self fromISOLatinToUTF8: [[basicStopElement attributeForName: @"name"] stringValue]];
                                                    station.stationId = [self fromISOLatinToUTF8: [[basicStopElement attributeForName: @"externalId"] stringValue]];
                                                    double latitude = [[[basicStopElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                                    double longitude = [[[basicStopElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                                    station.latitude = [NSNumber numberWithFloat: latitude];
                                                    station.longitude = [NSNumber numberWithFloat: longitude];
                                                    basicStop.station = station;
                                                } else if ([[basicStopElement name] isEqualToString: @"Arr"]) {
                                                    Arr *arr = [[Arr alloc] init];
                                                    for (CXMLElement *currentArrElement in [basicStopElement children]) {
                                                        if ([[currentArrElement name] isEqualToString: @"Time"]) {
                                                            arr.timeString = [currentArrElement stringValue];
                                                            basicStop.arr = arr;
                                                        } else if ([[currentArrElement name] isEqualToString: @"Platform"]) {
                                                            CXMLNode *platformElements = [currentArrElement childAtIndex: 0];
                                                            NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                            
                                                            #ifdef SBBAPILogLevelFull
                                                            NSLog(@"STB arr platform: %@", platformString);
                                                            #endif
                                                            
                                                            arr.platform = platformString;
                                                        }
                                                    }
                                                } else if ([[basicStopElement name] isEqualToString: @"Dep"]) {
                                                    Dep *dep = [[Dep alloc] init];
                                                    for (CXMLElement *currentDepElement in [basicStopElement children]) {
                                                        if ([[currentDepElement name] isEqualToString: @"Time"]) {
                                                            dep.timeString = [currentDepElement stringValue];
                                                            basicStop.dep = dep;
                                                        } else if ([[currentDepElement name] isEqualToString: @"Platform"]) {
                                                            CXMLNode *platformElements = [currentDepElement childAtIndex: 0];
                                                            NSString *platformString = [[platformElements stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                                                            
                                                            #ifdef SBBAPILogLevelFull
                                                            NSLog(@"STB dep platform: %@", platformString);
                                                            #endif
                                                            
                                                            dep.platform = platformString;
                                                        }
                                                    }
                                                } else if ([[basicStopElement name] isEqualToString: @"StopPrognosis"]) {
                                                    for (CXMLElement *currentDepElement in [basicStopElement children]) {
                                                        if ([[currentDepElement name] isEqualToString: @"Capacity1st"]) {
                                                            NSString *capstring = [currentDepElement stringValue];
                                                            basicStop.capacity1st = [NSNumber numberWithInt: [capstring integerValue]];
                                                        } else if ([[currentDepElement name] isEqualToString: @"Capacity2nd"]) {
                                                            NSString *capstring = [currentDepElement stringValue];
                                                            basicStop.capacity2nd = [NSNumber numberWithInt: [capstring integerValue]];
                                                        } else if ([[currentDepElement name] isEqualToString: @"Status"]) {
                                                            NSString *statusstring = [currentDepElement stringValue];
                                                            basicStop.scheduled = statusstring;
                                                        }
                                                    }
                                                }
                                            }
                                            [journey.passList addObject: basicStop];
                                        }
                                    } else if ([[currentJourneyElement name] isEqualToString: @"JProg"]) {
                                        // To implement
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }
                        
            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Jrnreq end decoding xml"];
            #endif
            
            self.stbreqRequestInProgress = NO;
            
            #ifdef SBBAPILogLevelXMLReqRes
            NSLog(@"Journey pass list stops before filter: %d", journey.passList.count);
            #endif
            
            NSArray *oldPassList = journey.passList;
            NSMutableArray *newPassList =  [NSMutableArray arrayWithArray:  [self filterBasicStopsForStationboardJourneyRequestBasicstopListWithStation: oldPassList station: station deparr: departureTime]];
            journey.passList = newPassList;
            
            #ifdef SBBAPILogLevelXMLReqRes
            NSLog(@"Journey pass list stops after filter: %d", journey.passList.count);
            #endif
            
            if ([weakStbreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Stbreq cancelled. Stb queue block. End. MainQueue call");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kJrnReqRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (journey) {
                            self.journeyResult = journey;
                            NSUInteger numberofnewresults = 0;
                            if (self.journeyResult) {
                                numberofnewresults = 1;
                            }
                            successBlock(numberofnewresults);
                            
                        } else {
                            if (failureBlock) {
                                failureBlock(kStbScrRequestFailureCancelled);
                            }
                        }
                    }];
                }
            }                        
        }];
        [_stbreqBackgroundOpQueue addOperation: stbreqDecodingXMLOperation];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        self.stbreqRequestInProgress = NO;
        
        if (failureBlock) {
            failureBlock(kJrnReqRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Jrnreq start operation"];
    #endif
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

- (BOOL) setStationboardJourneyResultWithJourney:(Journey *)journey {
    if (journey && journey.passList && journey.passList.count >= 2) {
        self.journeyResult = journey;
        return YES;
    }
    return NO;
}

- (BOOL) stationboardJourneyHasValidPasslist:(Journey *)journey {
    if (journey && journey.passList && journey.passList.count >= 2) {
        return YES;
    }
    return NO;
}

- (Journey *) getJourneyRequestResult {
    if (self.journeyResult) {
        return self.journeyResult;
    }
    return  nil;
}

- (NSArray *) getBasicStopsForStationboardJourneyRequestResult:(Journey *)journey {
    NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:2];
    if (journey) {
        NSArray *passlist = [journey passList];
        for (int i = 0;  i < [passlist count];  i++) {
            BasicStop *currentBasicStop = (BasicStop *)[passlist objectAtIndex: i];
            [stationsArray addObject: currentBasicStop];
        }
        return stationsArray;
    }
    return nil;
}

- (NSArray *) filterBasicStopsForStationboardJourneyRequestBasicstopListWithStation:(NSArray *)basicstoplist station:(Station *)station deparr:(BOOL)deparr {
    NSMutableArray *filteredList = [NSMutableArray arrayWithCapacity: 2];
    if (basicstoplist && station) {
        if ([basicstoplist count]> 0) {
            BOOL stationReached = NO;
            if (deparr) {
                for (BasicStop *currentBasicStop in basicstoplist) {
                    Station *currentStation = [self getStationForBasicStop: currentBasicStop];
                    if (stationReached) {
                        [filteredList addObject: currentBasicStop];
                    } else {
                        if ([currentStation.stationName isEqualToString: station.stationName]) {
                            [filteredList addObject: currentBasicStop];
                            stationReached = YES;
                        }
                    }
                }
            } else {
                for (BasicStop *currentBasicStop in [basicstoplist reverseObjectEnumerator]) {
                    Station *currentStation = [self getStationForBasicStop: currentBasicStop];
                    if (stationReached) {
                        [filteredList insertObject: currentBasicStop atIndex: 0];
                    } else {
                        if ([currentStation.stationName isEqualToString: station.stationName]) {
                            [filteredList insertObject: currentBasicStop atIndex: 0];
                            stationReached = YES;
                        }
                    }
                }
            }
            return filteredList;
        }
    }
    return  nil;
}

//--------------------------------------------------------------------------------

- (void) sendValidationReqXMLValidationRequest:(NSString *)stationname successBlock:(void(^)(NSArray *))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {
    
    if (!stationname) {
        return;
    }
    
    NSString *xmlString = kValidationReq_XML_SOURCE;
    
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"STATIONNAME" withString: stationname];
        
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
    
    self.valreqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.valreqHttpClient) {
        [self.valreqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.valreqHttpClient = nil;
    }
    
    self.valreqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.valreqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.valreqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiValreqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Valreq end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Valreq cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kValReqRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *valreqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakValreqDecodingXMLOperation = valreqDecodingXMLOperation;
        
        NSMutableArray *tempvalidatedstations = [NSMutableArray array];
        
        [valreqDecodingXMLOperation addExecutionBlock: ^(void) {
            
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_val_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
            
            //return;
                        
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakValreqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Valreq cancelled. Val queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kValReqRequestFailureCancelled);
                        }];
                    }
                    return;
                }
                
                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *valResNode = [xmlResponse nodeForXPath: @"//LocValRes" error: nil];
                    if (valResNode) {
                        for (CXMLElement *currentValidationResElement in [valResNode children]) {
                                                        
                            if ([weakValreqDecodingXMLOperation isCancelled]) {
                                #ifdef SBBAPILogLevelCancel
                                NSLog(@"Valreq cancelled. Val queue block. cleanedstring");
                                #endif
                                
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                        failureBlock(kValReqRequestFailureCancelled);
                                    }];
                                }
                                return;
                            }
                            
                            if ([[currentValidationResElement name] isEqualToString: @"Station"]) {
                                Station *station = [[Station alloc] init];
                                station.stationName = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"name"] stringValue]];
                                station.stationId = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"externalId"] stringValue]];
                                double latitude = [[[currentValidationResElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                double longitude = [[[currentValidationResElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                station.latitude = [NSNumber numberWithFloat: latitude];
                                station.longitude = [NSNumber numberWithFloat: longitude];
                                [tempvalidatedstations addObject: station];
                            }
                            
                            if ([[currentValidationResElement name] isEqualToString: @"ReqLoc"]) {                                
                                Station *station = [[Station alloc] init];
                                station.stationName = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"output"] stringValue]];
                                [tempvalidatedstations addObject: station];
                            }
                            
                            if ([[currentValidationResElement name] isEqualToString: @"Poi"]) {
                                Station *station = [[Station alloc] init];
                                station.stationName = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"name"] stringValue]];
                                double latitude = [[[currentValidationResElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                double longitude = [[[currentValidationResElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                station.latitude = [NSNumber numberWithFloat: latitude];
                                station.longitude = [NSNumber numberWithFloat: longitude];
                                [tempvalidatedstations addObject: station];
                            }
                            
                            if ([[currentValidationResElement name] isEqualToString: @"Address"]) {
                                
                                Station *station = [[Station alloc] init];
                                station.stationName = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"name"] stringValue]];
                                double latitude = [[[currentValidationResElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                double longitude = [[[currentValidationResElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                station.latitude = [NSNumber numberWithFloat: latitude];
                                station.longitude = [NSNumber numberWithFloat: longitude];
                                [tempvalidatedstations addObject: station];
                            }

                        }
                    }
                }
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }

            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Valreq end decoding xml"];
            #endif
            
            self.valreqRequestInProgress = NO;
            
            if ([weakValreqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Valreq cancelled. Val queue block. cleanedstring");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kValReqRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (tempvalidatedstations && tempvalidatedstations.count > 0) {
                            NSArray *stationsarray = [NSArray arrayWithArray: tempvalidatedstations];
                            successBlock(stationsarray);
                        } else {
                            if (failureBlock) {
                                failureBlock(kValReqRequestFailureNoNewResults);
                            }
                        }
                    }];
                }
            }            
        }];
        [_valreqBackgroundOpQueue addOperation: valreqDecodingXMLOperation];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        self.valreqRequestInProgress = NO;
        
        if (failureBlock) {
            failureBlock(kValReqRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
    [self logTimeStampWithText:@"Valreq start operation"];
    #endif
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

//--------------------------------------------------------------------------------

- (void) sendClosestStationsReqXMLValidationRequest:(CLLocationCoordinate2D)stationcoordinate successBlock:(void(^)(NSArray *))successBlock failureBlock:(void(^)(NSUInteger))failureBlock {
    
    NSString *xmlString = kClosestStationsReq_XML_SOURCE;
    
    #ifdef SBBAPILogLevelReqEnterExit
    NSLog(@"Put together XML request");
    #endif
    
    NSString *languageLocaleString = @"EN";
    if (self.sbbApiLanguageLocale == reqEnglish) {
        languageLocaleString = @"EN";
    } else if (self.sbbApiLanguageLocale == reqGerman) {
        languageLocaleString = @"DE";
    } else if (self.sbbApiLanguageLocale == reqFrench) {
        languageLocaleString = @"FR";
    } else if (self.sbbApiLanguageLocale == reqItalian) {
        languageLocaleString = @"IT";
    }
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"APILOCALE" withString: languageLocaleString];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"End poi set: %.6f, %.6f", stationcoordinate.latitude , stationcoordinate.longitude);
    #endif
    
    int latitude = (int)(stationcoordinate.latitude * 1000000);
    int longitude = (int)(stationcoordinate.longitude * 1000000);
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"LATITUDE" withString: [NSString stringWithFormat: @"%d", latitude]];
    xmlString = [xmlString stringByReplacingOccurrencesOfString: @"LONGITUDE" withString: [NSString stringWithFormat: @"%d", longitude]];
    
    #ifdef SBBAPILogLevelXMLReqRes
    NSLog(@"XML String: %@", xmlString);
    #endif
    
    self.stareqRequestInProgress = YES;
    
    NSURL *baseURL = [NSURL URLWithString: kSBBXMLAPI_BASE_URL];
    
    if (self.stareqHttpClient) {
        [self.stareqHttpClient cancelAllHTTPOperationsWithMethod: @"POST" path:kSBBXMLAPI_URL_PATH];
        self.stareqHttpClient = nil;
    }
    
    self.stareqHttpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [self.stareqHttpClient defaultValueForHeader:@"Accept"];
    
    NSMutableURLRequest *request = [self.stareqHttpClient requestWithMethod:@"POST" path: kSBBXMLAPI_URL_PATH parameters:nil];
    [request setHTTPBody: [xmlString dataUsingEncoding: NSISOLatin1StringEncoding]];
    
    [request setTimeoutInterval: self.sbbApiStareqTimeout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        #ifdef SBBAPILogLevelTimeStamp
        [self logTimeStampWithText:@"Valreq end operation"];
        #endif
        
        NSString *responseString = [operation responseString];
        
        if ([operation isCancelled]) {
            #ifdef SBBAPILogLevelCancel
            NSLog(@"Valreq cancelled. Op success block start");
            #endif
            
            if (failureBlock) {
                failureBlock(kValReqRequestFailureCancelled);
            }
            return;
        }
        
        NSBlockOperation *stareqDecodingXMLOperation = [[NSBlockOperation alloc] init];
        __weak NSBlockOperation *weakStareqDecodingXMLOperation = stareqDecodingXMLOperation;
        
        NSMutableArray *tempvalidatedstations = [NSMutableArray array];
        
        [stareqDecodingXMLOperation addExecutionBlock: ^(void) {
            
            #ifdef SBBAPILogLevelXMLReqEndRes
            NSLog(@"Result:\n%@",responseString);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSLog(@"Output directory: %@", documentsDirectory);
            NSString *outputFile =  [documentsDirectory stringByAppendingPathComponent: @"xml_val_response.txt"];
            [responseString writeToFile: outputFile atomically: YES encoding: NSUTF8StringEncoding error: NULL];
            #endif
                        
            if (responseString)
            {
                NSString *cleanedString = [responseString stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
                cleanedString = [cleanedString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
                
                if ([weakStareqDecodingXMLOperation isCancelled]) {
                    #ifdef SBBAPILogLevelCancel
                    NSLog(@"Valreq cancelled. Val queue block. cleanedstring");
                    #endif
                    
                    if (failureBlock) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                            failureBlock(kValReqRequestFailureCancelled);
                        }];
                    }
                    return;
                }
                
                CXMLDocument *xmlResponse = [[CXMLDocument alloc] initWithXMLString: cleanedString options:0 error:nil];
                if (xmlResponse)
                {
                    CXMLNode *valResNode = [xmlResponse nodeForXPath: @"//LocValRes" error: nil];
                    if (valResNode) {
                        for (CXMLElement *currentValidationResElement in [valResNode children]) {
                                                        
                            if ([weakStareqDecodingXMLOperation isCancelled]) {
                                #ifdef SBBAPILogLevelCancel
                                NSLog(@"Valreq cancelled. Val queue block. cleanedstring");
                                #endif
                                
                                if (failureBlock) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                        failureBlock(kValReqRequestFailureCancelled);
                                    }];
                                }
                                return;
                            }
                            
                            if ([[currentValidationResElement name] isEqualToString: @"Station"]) {
                                Station *station = [[Station alloc] init];
                                station.stationName = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"name"] stringValue]];
                                station.stationId = [self fromISOLatinToUTF8: [[currentValidationResElement attributeForName: @"externalId"] stringValue]];
                                double latitude = [[[currentValidationResElement attributeForName: @"y"] stringValue] doubleValue] / 1000000;
                                double longitude = [[[currentValidationResElement attributeForName: @"x"] stringValue] doubleValue] / 1000000;
                                station.latitude = [NSNumber numberWithFloat: latitude];
                                station.longitude = [NSNumber numberWithFloat: longitude];
                                [tempvalidatedstations addObject: station];
                            }
                        }
                    }
                }
            } else {
                #ifdef SBBAPILogLevelFull
                NSLog(@"Empty response string!!!");
                #endif
            }

            #ifdef SBBAPILogLevelTimeStamp
            [self logTimeStampWithText:@"Valreq end decoding xml"];
            #endif
            
            self.stareqRequestInProgress = NO;
            
            if ([weakStareqDecodingXMLOperation isCancelled]) {
                #ifdef SBBAPILogLevelCancel
                NSLog(@"Valreq cancelled. Val queue block. cleanedstring");
                #endif
                
                if (failureBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        failureBlock(kValReqRequestFailureCancelled);
                    }];
                }
                return;
            } else {
                if (successBlock) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                        if (tempvalidatedstations && tempvalidatedstations.count > 0) {
                            NSArray *stationsarray = [NSArray arrayWithArray: tempvalidatedstations];
                            successBlock(stationsarray);
                        } else {
                            if (failureBlock) {
                                failureBlock(kValReqRequestFailureNoNewResults);
                            }
                        }
                    }];
                }
            }
        }];
        [_stareqBackgroundOpQueue addOperation: stareqDecodingXMLOperation];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed: %@", error);
        
        NSString *responseString = [operation responseString];
        if (responseString) {
            NSLog(@"Request failed response: %@", responseString);
        }
        self.stareqRequestInProgress = NO;
        
        if (failureBlock) {
            failureBlock(kValReqRequestFailureConnectionFailed);
        }
    }];
    
    #ifdef SBBAPILogLevelTimeStamp
    [self logTimeStampWithText:@"Valreq start operation"];
    #endif
    
    [operation start];
    
    #ifdef SBBAPILogLevelFull
    NSLog(@"XML request send");
    #endif
}

@end

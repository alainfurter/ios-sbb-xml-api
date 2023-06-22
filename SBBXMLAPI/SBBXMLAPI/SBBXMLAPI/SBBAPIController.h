//
//  SBBAPIController.h
//  SBB XML API Controller
//
//  Created by Alain on 29.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>

// SBB API Objects
#import "Connections.h"
#import "Station.h"
#import "ConResult.h"
#import "ConSectionList.h"
#import "ConSection.h"
#import "ConOverview.h"
#import "Walk.h"
#import "Journey.h"
#import "BasicStop.h"
#import "Arr.h"
#import "Dep.h"
#import "DepArr.h"
#import "ConnectionInfo.h"
#import "StationboardResults.h"
#import "JourneyHandle.h"

// Externals
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "TouchXML.h"

// Logging
//#define SBBAPILogLevelFull 1
//#define SBBAPILogLevelReqEnterExit 1
//#define SBBAPILogLevelFunctions 1
//#define SBBAPILogLevelXMLReqRes 1
//#define SBBAPILogLevelXMLReqEndRes 1
//#define SBBAPILogLevelTimeStamp 1
//#define SBBAPILogLevelCancel 1

enum conscrRequestDirectionFlags {
    conscrBackward = 1,
    conscrForward = 2
};

enum stbscrRequestDirectionFlags {
    stbscrBackward = 1,
    stbscrForward = 2
};

enum journeyTransportTypeCodes {
    transportFastTrain = 1,
    transportSlowTrain = 2,
    transportTram = 3,
    transportBus = 4,
    transportShip = 5,
    transportUnknown = 6,
    transportFuni = 7,
    transportCablecar = 8
};

enum stationboardJourneyDepartureArrivalTypeCodes {
    stbDepartureType = 1,
    stbArrivalType = 2
};

enum stationboardJourneyTransportTypeFilterCodes {
    stbLongdistanceTrains = 1,
    stbRegioTrains = 2,
    stbTramBus = 3
};

enum stationboardResultProductCodes {
    stbOnlyFastTrain = 1,
    stbOnlyRegioTrain = 2,
    stbOnlyTramBus = 3,
    stbFastAndRegioTrain = 4,
    stbFastTrainAndTramBus = 5,
    stbRegioTrainAndTramBus = 6,
    stbAll = 7,
    stbNone = 8
};

enum sbbrequestLanguageCodes {
    reqEnglish = 1,
    reqGerman = 2,
    reqFrench = 3,
    reqItalian = 4
};

#define kConRegRequestFailureNoNewResults 8568
#define kConScrRequestFailureNoNewResults 4566
#define kStbRegRequestFailureNoNewResults 7568
#define kStbScrRequestFailureNoNewResults 7566
#define kValReqRequestFailureNoNewResults 7006

#define kConReqRequestFailureConnectionFailed 85
#define kConScrRequestFailureConnectionFailed 45
#define kStbReqRequestFailureConnectionFailed 75
#define kStbScrRequestFailureConnectionFailed 51
#define kJrnReqRequestFailureConnectionFailed 65
#define kValReqRequestFailureConnectionFailed 35

#define kConReqRequestFailureCancelled 8599
#define kConScrRequestFailureCancelled 4599
#define kStbReqRequestFailureCancelled 7599
#define kStbScrRequestFailureCancelled 5599
#define kJrnReqRequestFailureCancelled 6599
#define kValReqRequestFailureCancelled 9005

#define kSbbReqStationsNotDefined 112

#define SBBAPIREQUESTCONREQSTANDARDTIMEOUT 60
#define SBBAPIREQUESTSTBREQSTANDARDTIMEOUT 30
#define SBBAPIREQUESTVALREQSTANDARDTIMEOUT 5

@interface SBBAPIController : NSObject

+ (SBBAPIController *) sharedSBBAPIController;

- (BOOL) isRequestInProgress;

- (void) cancelAllSBBAPIOperations;
- (void) cancelAllSBBAPIConreqOperations;
- (void) cancelAllSBBAPIStbreqOperations;
- (void) cancelAllSBBAPIValOperations;
- (void) cancelAllSBBAPIStaOperations;

//--------------------------------------------------------------------------------

- (void) setSBBAPILanguageLocale:(NSUInteger)languagelocale;
- (void) setSBBConReqNumberOfConnectionsForRequest:(NSUInteger)numberofconnections;
- (void) setSBBConScrNumberOfConnectionsForRequest:(NSUInteger)numberofconnections;
- (void) setSBBStbReqNumberOfConnectionsForRequest:(NSUInteger)numberofconnections;
- (void) setSBBStbScrNumberOfConnectionsForRequest:(NSUInteger)numberofconnections;

- (void) setSBBAPIConreqTimeout:(NSUInteger)timeout;
- (void) setSBBAPIStbreqTimeout:(NSUInteger)timeout;

//--------------------------------------------------------------------------------

- (void) sendConReqXMLConnectionRequest:(Station *)startStation endStation:(Station *)endStation viaStation:(Station *)viaStation conDate:(NSDate *)condate departureTime:(BOOL)departureTime successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

- (void) sendConScrXMLConnectionRequest:(NSUInteger)directionflag successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

- (Connections *)getConnectionsresults;
- (NSArray *) getConnectionResults;
- (NSUInteger) getNumberOfConnectionResults;
- (ConResult *) getConnectionResultWithIndex:(NSUInteger)index;
- (NSDate *) getConnectionDateForConnectionResultWithIndex:(NSUInteger)index;
- (BOOL) getConnectionDateIsDepartureFlagForConnectionResultWithIndex:(NSUInteger)index;
- (ConOverview *) getOverviewForConnectionResultWithIndex:(NSUInteger)index;
- (NSArray *) getConsectionsForConnectionResultWithIndex:(NSUInteger)index;
- (NSUInteger) getNumberOfConsectionsForConnectionResultWithIndex:(NSUInteger)index;
- (NSArray *) getAllBasicStopsForConnectionResultWithIndex:(NSUInteger)index;
- (ConSection *) getConsectionForConnectionResultWithIndexAndConsectionIndex:(NSUInteger)index consectionIndex:(NSUInteger)consectionIndex;
- (ConSection *) getFirstConsectionForConnectionResultWithIndex:(NSUInteger)index;
- (ConSection *) getLastConsectionForConnectionResultWithIndex:(NSUInteger)index;

- (BOOL) ConnectionResultWithIndexHasInfos:(NSUInteger)index;
- (NSUInteger) getNumberOfConnectionInfosForConnectionResultWithIndex:(NSUInteger)index;
- (ConnectionInfo *) getConnectioninfoForConnectionResultWithIndexAndConnectioninfoIndex:(NSUInteger)index infoIndex:(NSUInteger)infoIndex;

- (NSString *) getBetterDepartureStationNameForConnectionResultWithIndex:(NSUInteger)index;
- (NSString *) getBetterArrivalStationNameForConnectionResultWithIndex:(NSUInteger)index;

- (void) resetConnectionsresults;

-  (NSString *) getConnectionDateStringForOverview:(ConOverview *)overview;
-  (NSString *) getArrivalTimeForOverview:(ConOverview *)overview;
-  (NSString *) getDepartureTimeForOverview:(ConOverview *)overview;
-  (NSString *) getArrivalStationNameForOverview:(ConOverview *)overview;
-  (NSString *) getDepartureStationNameForOverview:(ConOverview *)overview;
-  (NSNumber *) getCapacity1stForOverview:(ConOverview *)overview;
-  (NSNumber *) getCapacity2ndForOverview:(ConOverview *)overview;

-  (NSString *) getArrivalTimeForConsection:(ConSection *)conSection;
-  (NSString *) getDepartureTimeForConsection:(ConSection *)conSection;
-  (NSString *) getArrivalStationNameForConsection:(ConSection *)conSection;
-  (NSString *) getDepartureStationNameForConsection:(ConSection *)conSection;
-  (NSString *) getArrivalPlatformForConsection:(ConSection *)conSection;
-  (NSString *) getDeparturePlatformForConsection:(ConSection *)conSection;
-  (NSNumber *) getCapacity1stForConsection:(ConSection *)conSection;
-  (NSNumber *) getCapacity2ndForConsection:(ConSection *)conSection;
-  (NSString *) getExpectedArrivalTimeForConsection:(ConSection *)conSection;
-  (NSString *) getExpectedDepartureTimeForConsection:(ConSection *)conSection;
-  (NSString *) getExpectedArrivalPlatformForConsection:(ConSection *)conSection;
-  (NSString *) getExpectedDeparturePlatformForConsection:(ConSection *)conSection;
-  (BOOL) isJourneyDelayedForConsection:(ConSection *)conSection;
-  (BOOL) isConsectionOfTypeWalk:(ConSection *)conSection;
-  (BOOL) isConsectionOfTypeJourney:(ConSection *)conSection;

- (NSString *) getTransportTypeWithConsection:(ConSection *)conSection;

- (NSString *) getTransportNameWithConsection:(ConSection *)conSection;
- (NSString *) getSimplifiedTransportNameWithConsection:(ConSection *)conSection;

- (NSArray *) getStationsForConsection:(ConSection *)conSection;
- (NSArray *) getBasicStopsForConsection:(ConSection *)conSection;

//--------------------------------------------------------------------------------

- (CLLocationCoordinate2D) getCoordinatesForStation:(Station *)station;
-  (NSString *) getStationameForStation:(Station *)station;
-  (NSNumber *) getLatitudeForStation:(Station *)station;
-  (NSNumber *) getLongitudeForStation:(Station *)station;

//--------------------------------------------------------------------------------

-  (NSString *) getArrivalTimeForBasicStop:(BasicStop *)basicStop;
-  (NSString *) getDepartureTimeForBasicStop:(BasicStop *)basicStop;
-  (NSString *) getStationNameForBasicStop:(BasicStop *)basicStop;
-  (NSString *) getPlatformForBasicStop:(BasicStop *)basicStop;
-  (Station *) getStationForBasicStop:(BasicStop *)basicStop;
-  (NSNumber *) getCapacity1stForBasicStop:(BasicStop *)basicStop;
-  (NSNumber *) getCapacity2ndForBasicStop:(BasicStop *)basicStop;
-  (NSString *) getExpectedArrivalTimeForBasicStop:(BasicStop *)basicStop;
-  (NSString *) getExpectedDepartureTimeForBasicStop:(BasicStop *)basicStop;
-  (NSString *) getExpectedPlatformForBasicStop:(BasicStop *)basicStop;

//--------------------------------------------------------------------------------

- (void) getProductTypesWithQuickCheckStbReqXMLStationboardRequestWithProductCode:(Station *)station destination:(Station *)destination stbDate:(NSDate *)stbdate departureTime:(BOOL)departureTime gotProductTypesBlock:(void(^)(NSUInteger))gotProductTypesBlock failedToGetProductTypesBlock:(void(^)(NSUInteger))failedToGetProductTypesBlock;

- (void) sendStbReqXMLStationboardRequestWithProductType:(Station *)station destination:(Station *)destination stbDate:(NSDate *)stbdate departureTime:(BOOL)departureTime productType:(NSUInteger)productType successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

- (void) sendStbScrXMLStationboardRequestWithProductType:(NSUInteger)directionflag station:(Station *)station destination:(Station *)destination stbDate:(NSDate *)stbdate departureTime:(BOOL)departureTime productType:(NSUInteger)productType successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

- (void) resetStationboardResults;

- (StationboardResults *)getStationboardresultsWithProducttype:(NSUInteger)producttype;
- (NSArray *) getStationboardResults;
- (NSUInteger) getNumberOfStationboardResults;
- (Journey *) getJourneyForStationboardResultWithIndex:(NSUInteger)index;

- (NSUInteger) getStationboardResultsAvailableProductTypes;
- (NSArray *) getStationboardResultsWithProductType:(NSUInteger)producttype;
- (NSUInteger) getNumberOfStationboardResultsWithProductType:(NSUInteger)producttype;
- (Journey *) getJourneyForStationboardResultFWithProductTypeWithIndex:(NSUInteger)producttype index:(NSUInteger)index;

- (BasicStop *) getMainBasicStopForStationboardJourney:(Journey *)journey;

- (JourneyHandle *) getJourneyhandleForStationboardJourney:(Journey *)journey;
- (NSString *) getDirectionNameForStationboardJourney:(Journey *)journey;
- (NSString *) getDepartureTimeForStationboardJourney:(Journey *)journey;
- (NSString *) getArrivalTimeForStationboardJourney:(Journey *)journey;
- (NSUInteger ) getStationboardJourneyDepartureArrivalForWithStationboardJourney:(Journey *)journey;

- (NSString *) getTransportTypeWithStationboardJourney:(Journey *)journey;

- (NSString *) getTransportNameWithStationboardJourney:(Journey *)journey;
- (NSString *) getSimplifiedTransportNameWithStationboardJourney:(Journey *)journey;

//--------------------------------------------------------------------------------

- (void) sendJourneyReqXMLJourneyRequest:(Station *)station journeyhandle:(JourneyHandle *)journeyhandle jrnDate:(NSDate *)jrndate departureTime:(BOOL)departureTime successBlock:(void(^)(NSUInteger))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

- (BOOL) setStationboardJourneyResultWithJourney:(Journey *)journey;
- (BOOL) stationboardJourneyHasValidPasslist:(Journey *)journey;

- (Journey *) getJourneyRequestResult;

- (NSArray *) getBasicStopsForStationboardJourneyRequestResult:(Journey *)journey;
- (NSArray *) filterBasicStopsForStationboardJourneyRequestBasicstopListWithStation:(NSArray *)basicstoplist station:(Station *)station deparr:(BOOL)deparr;

//--------------------------------------------------------------------------------

- (void) sendValidationReqXMLValidationRequest:(NSString *)stationname successBlock:(void(^)(NSArray *))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

//--------------------------------------------------------------------------------

- (void) sendClosestStationsReqXMLValidationRequest:(CLLocationCoordinate2D)stationcoordinate successBlock:(void(^)(NSArray *))successBlock failureBlock:(void(^)(NSUInteger))failureBlock;

@end

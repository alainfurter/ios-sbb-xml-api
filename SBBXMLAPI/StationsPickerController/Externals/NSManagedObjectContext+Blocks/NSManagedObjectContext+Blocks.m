//
//  NSManagedObjectContext+Blocks.m
//  SBB XML API Controller
//
//  Created by Alain on 21.11.12.
//  Copyright (c) 2012 Zone Zero Apps. All rights reserved.
//

#import "NSManagedObjectContext+Blocks.h"

@implementation NSManagedObjectContext (Blocks)


-(void)performFetchInBackground: (NSFetchedResultsController*) fetchedResultsController
                     onComplete:(NSManagedObjectContextFetchCompleteBlock) completeBlock
                                    onError:(NSManagedObjectContextFetchFailBlock) failBlock{
        
	dispatch_queue_t	backgroundQueue	= dispatch_queue_create("ch.fasoft.sbbxmlapi.fetchRequests", NULL);
	dispatch_queue_t	mainQueue		= dispatch_get_main_queue();
    
	dispatch_async(backgroundQueue, ^{
        
		NSManagedObjectContext	*threadContext;
		NSMutableArray			*results = nil;
		NSError					*error = nil;
        
		threadContext = [[NSManagedObjectContext alloc] init];
        
		[threadContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
        
        
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Error %@", [error localizedDescription]);
            dispatch_sync(mainQueue, ^{
				failBlock( error );
			});
        }
    
        dispatch_sync(mainQueue, ^{
            completeBlock(results);
        });
	});
         
}

-(void)executeFetchRequestInBackground:(NSFetchRequest*) aRequest
							onComplete:(NSManagedObjectContextFetchCompleteBlock) completeBlock
							   onError:(NSManagedObjectContextFetchFailBlock) failBlock{
        
	dispatch_queue_t	backgroundQueue	= dispatch_queue_create("ch.fasoft.sbbxmlapi.fetchRequests", NULL);
	dispatch_queue_t	mainQueue		= dispatch_get_main_queue();
    
	[aRequest setResultType:NSManagedObjectIDResultType];
    
	dispatch_async(backgroundQueue, ^{
        
		NSManagedObjectContext	*threadContext;
		NSArray					*threadResults = nil;
		NSMutableArray			*results = nil;
		NSError					*error = nil;
        
		threadContext = [[NSManagedObjectContext alloc] init];
        
		[threadContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
        
		if ((threadResults = [threadContext executeFetchRequest:aRequest error:&error])) {
            
			results = [[NSMutableArray alloc] initWithCapacity:[threadResults count]];
            
			dispatch_sync(mainQueue, ^{
				[threadResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *halt) {
					[results addObject:[self objectWithID:obj]];
				}];
				completeBlock(results);
                
			});
		} else {
			dispatch_sync(mainQueue, ^{
				failBlock( error );				
			});
		}
	});
}
@end

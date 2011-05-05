//
//  BSManagedObjectContextManager.m
//  BSUtilities
//
//  Created by Daniel Thorpe on 01/07/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif


#import "BSManagedObjectContextManager.h"
#import "SynthesizeSingleton.h"

NSString * const BSMOCManagerFailedToMigrateExceptionName = @"BSMOCManagerFailedToMigrateException";
NSString * const BSMOCManagerFailedToCreatePersistentStoreExceptionName = @"BSMOCManagerFailedToCreatePersistentStoreException";
NSString * const BSMOCManagerFailedToInitialisePersistentStoreExceptionName = @"BSMOCManagerFailedToInitialisePersistentStoreException";

NSInteger sortVersionedModelPaths(id str1, id str2, void *context) {
	NSInteger num1 = [str1 integerValue];
	NSInteger num2 = [str2 integerValue];
	
	if(num1 < num2) {
		return NSOrderedAscending;
	} else if (num1 > num2) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

@implementation BSManagedObjectContextManager

// Make this a Singleton class
SYNTHESIZE_SINGLETON_FOR_CLASS(BSManagedObjectContextManager, sharedManager);

@synthesize delegate;
@synthesize applicationSupportDirectory;
@synthesize externalRecordsDirectory;
@synthesize externalRecordsExtension;
@synthesize storeName;
@synthesize storeType;
@dynamic managedObjectModel;
@dynamic persistentStoreCoordinator;
@dynamic managedObjectContext;

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
+ (void)initialize {
	[BSManagedObjectContextManager exposeBinding:@"managedObjectContext"];
}
#endif

- (void)dealloc {
	[managedObjectModel release];
	[managedObjectContext release];
	[persistentStoreCoordinator release];
	self.storeType = nil; [storeType release];
	self.storeName = nil; [storeName release];
	self.applicationSupportDirectory = nil; [applicationSupportDirectory release];
	self.externalRecordsDirectory = nil; [externalRecordsDirectory release];	
	[super dealloc];
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) 
		return managedObjectModel;
	
	// Get all the bundles including ones nested inside the main bundle
	NSMutableSet *allBundles = [NSMutableSet set];
	NSMutableSet *newBundles = [NSMutableSet set];
	NSUInteger numberOfBundles = 0;
	[allBundles addObject:[NSBundle mainBundle]];
	
	while (numberOfBundles < [allBundles count]) {
		// Look for nested bundles
		for(NSBundle *bundle in allBundles) {
			NSArray *morePaths = [NSBundle pathsForResourcesOfType:@".bundle" inDirectory:[bundle bundlePath]];
			if([morePaths count] > 0) {
				for(NSString *bundlePath in morePaths) {
					if(![allBundles containsObject:bundlePath])
						[newBundles addObject:[NSBundle bundleWithPath:bundlePath]];					
				}
			}
		}
		// Add the new bundles
		[allBundles unionSet:newBundles];
		numberOfBundles = [allBundles count];
	}
		
	managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:[allBundles allObjects]] retain];
    if (managedObjectModel) {
		
		// Allow subclasses to modify the model programmatically
		managedObjectModel = [self willUseManagedObjectModel:managedObjectModel];
		return managedObjectModel;	
	} 	
	return nil;	
}

/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
	// Get the managed object model
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom || ([[mom entities] count] == 0) ) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"No model to generate a store from");
        return nil;
    }

	// Make sure that the directories exist for where we're going to save the store
    NSFileManager *fileManager = [NSFileManager defaultManager];	
    NSError *error = nil;    
	NSAssert(self.applicationSupportDirectory != nil, (@"Application support directory hasn't been specified"));
	if ( ![fileManager fileExistsAtPath:self.applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:self.applicationSupportDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", self.applicationSupportDirectory, [error userInfo]]));
			NSLog(@"Error creating application support directory at %@ : %@", self.applicationSupportDirectory, [error userInfo]);
			return nil;
		}
	}		
	
	if(self.externalRecordsDirectory) {
		if ( ![fileManager fileExistsAtPath:self.externalRecordsDirectory isDirectory:NULL] ) {
			if (![fileManager createDirectoryAtPath:self.externalRecordsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
				NSLog(@"Error creating external records directory at %@ : %@", self.externalRecordsDirectory, [error userInfo]);
				NSAssert(NO, ([NSString stringWithFormat:@"Failed to create external records directory %@ : %@", self.externalRecordsDirectory, error]));
				NSLog(@"Error creating external records directory at %@ : %@", self.externalRecordsDirectory, [error userInfo]);
				return nil;
			};
		}
	}
	
	// Persistent store migration Options, enable spotlight and migration
	NSMutableDictionary *storeOptions = [NSMutableDictionary dictionary];
	[storeOptions setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];	
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
	[storeOptions setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];	
#endif	
		
	// Create the url to the store
	NSURL *url = [NSURL fileURLWithPath:[self.applicationSupportDirectory stringByAppendingPathComponent:self.storeName]];
	
	// Create the persistent store coordinator
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

	// Create the persistent store, and add it to the coordinator
	NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:url options:storeOptions error:&error];
	
    if (!persistentStore){
#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
		[[NSApplication sharedApplication] presentError:error];
#endif
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
#if (TARGET_OS_MAC && (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
		[NSException raise:BSMOCManagerFailedToCreatePersistentStoreExceptionName format:@"Unable to create persistent store"];
#endif
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL 
						 ofType:(NSString *)type 
						toModel:(NSManagedObjectModel *)finalModel 						  
						  error:(NSError **)error {
	
	// Get the source store metadata
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type URL:sourceStoreURL error:error];
	if(!sourceMetadata) 
		return NO;
	
	// Check to see if the source is now compatible with our final model
	if([finalModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
		if(*error) *error = nil;
		return YES;
	}
	
	// We need to do some migrating, one migration is done per iteration
	
	// Get the source model
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
	NSAssert(sourceModel != nil, ([NSString stringWithFormat:@"Failed to find the source model for metadata:\n\t%@", sourceMetadata]));
	
	// Find all the mom and momd files in the resource directory
	NSMutableArray *modelPaths = [NSMutableArray array];
	NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" inDirectory:nil];
	
	for(NSString *momdPath in momdArray) {
		NSString *resourceSubpath = [momdPath lastPathComponent];
		NSArray *momArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
		[modelPaths addObjectsFromArray:momArray];
	}

	
	if(!modelPaths || ![modelPaths count]) {
		// Throw and error if there are no models
		if(*error) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setValue:@"No models were found in the main bundle" forKey:NSLocalizedDescriptionKey];
			// Populate the error
			*error = [NSError errorWithDomain:@"BlindingSkies" code:8001 userInfo:dict];			
		}
		return NO;
	}
	
	// We now need to test our models and look for mapping models
	
	NSMappingModel *mappingModel = nil;
	NSManagedObjectModel *targetModel = nil;
	NSString *modelPath = nil;
	
	for(modelPath in modelPaths) {
		NSLog(@"Target model path: %@", modelPath);
		// Instantiate the model
		targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];		
		// Try to create a mapping model
		NSBundle *mainBundle = [NSBundle mainBundle];
		mappingModel = [NSMappingModel mappingModelFromBundles:[NSArray arrayWithObject:mainBundle] forSourceModel:sourceModel destinationModel:targetModel];
		// Check to see if we created a mapping model
		if(mappingModel) 			
			break;
		// Release the target model and keep looking
		[targetModel release]; targetModel = nil;
	}
	
	// Check to see if mapping model is nil, as we come here after we've tested every model
	if(!mappingModel) {
		// Failed
		if(*error) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setValue:@"No models were found in the main bundle" forKey:NSLocalizedDescriptionKey];
			// Populate the error
			*error = [NSError errorWithDomain:@"BlindingSkies" code:8001 userInfo:dict];			
		}
		return NO;		
	}
	
	// We can now perform a migration
	NSMigrationManager *manager = [[[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:targetModel] autorelease];
	[targetModel release];
	NSString *modelName = [[[modelPath lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	NSString *storeExtension = [[sourceStoreURL path] pathExtension];
	NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];
	// Build a path to write the new store to
	storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
	NSURL *destinationURL = [NSURL fileURLWithPath:storePath];
	if(![manager migrateStoreFromURL:sourceStoreURL type:type options:nil withMappingModel:mappingModel toDestinationURL:destinationURL destinationType:type destinationOptions:nil error:error]) {
		return NO;
	}
	
	// Now we need to move the source store out of the way and rename the new store	
	// Create a path to backup the store to
	NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
	uuid = [uuid stringByAppendingPathExtension:modelName];
	uuid = [uuid stringByAppendingPathExtension:storeExtension];
	NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
	NSString *backupPath = [appSupportPath stringByAppendingPathComponent:uuid];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager moveItemAtPath:[sourceStoreURL path] toPath:backupPath error:error]) {
		// Failed to move the file
		return NO;
	}
	
	// Move the new store to the source path
	if(![fileManager moveItemAtPath:storePath toPath:[sourceStoreURL path] error:error]) {
		// Failed to move the file
		// Try to back out of the source move before returning
		[fileManager moveItemAtPath:backupPath toPath:[sourceStoreURL path] error:nil];
		return NO;
	}
	
	// We might not be at the final model yet, so recurse
	return [self progressivelyMigrateURL:sourceStoreURL ofType:type toModel:finalModel error:error];	
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */						

- (NSManagedObjectContext *)managedObjectContext {
	
	// NSManagedObjectContext is not thread-safe, therefore, here we can 
	// determine if this is the main thread, in which return the default
	// context. If not the main thread, then return a new MOC
	
	BOOL isMainThread = [NSThread isMainThread];
	
	// Check if this isn't the main thread
	if(!isMainThread) {
		return [self freshManagedObjectContext];
	}
	
	if(isMainThread && managedObjectContext) {
		return managedObjectContext;
	} 
	
	// Create a mananged object context
	managedObjectContext = [self blankManagedObjectContext];

	// Set the merge policy
	[managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
	
	// return it with retain count of 1 (so we hold onto it)
	return managedObjectContext;
}

- (NSManagedObjectContext *)freshManagedObjectContext {
	
	// Get a blank context
	NSManagedObjectContext *aContext = [self blankManagedObjectContext];
	
	// Set the merge policies
	[aContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	
	// Register for notifications	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

#if __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6 || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_0
	[nc addObserver:self selector:@selector(managedObjectContextWillSave:) name:NSManagedObjectContextWillSaveNotification object:aContext];
#endif	
	
	[nc addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:aContext];
	
	// Add a notification to this new context so that when it gets saved, we
	// merge the changes into the main context
	[nc addObserver:self selector:@selector(mergeChangesFromContextOnOtherThread:) name:NSManagedObjectContextDidSaveNotification object:aContext];			
	
	// return the context we've just created, and autorelease it
	return aContext;
}

// Will create a new managed object context, but without any notifications
// so that the calling library can set up it's own notifications
- (NSManagedObjectContext *)blankManagedObjectContext {
	
	// Get the persistent store coordinator
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
		[NSException raise:BSMOCManagerFailedToInitialisePersistentStoreExceptionName format:@"Failed to initialize the store"];		
        return nil;
    }
	
	// Create a managed object context
	NSManagedObjectContext *aContext = [[NSManagedObjectContext alloc] init];	
	[aContext setPersistentStoreCoordinator:coordinator];
	
	// Call our helper method
	[self didAddStoreCoordinator:coordinator toContext:aContext];
	
	// return the context we've just created, and autorelease it
	return [aContext autorelease];	
}


- (BOOL)saveContext:(NSManagedObjectContext *)aContext {
	NSError *error = nil;
	return [self saveContext:aContext withError:&error];
}

- (BOOL)saveContext:(NSManagedObjectContext *)aContext withError:(NSError **)anError {
	
	// Get the context
	if(!aContext)
		aContext = [self managedObjectContext];
	
	// Nothing to save
	if(![aContext hasChanges]) return YES; 
	
	// Save the context
	if(![aContext save:anError])  {
		if(*anError) {
			NSLog(@"Failed to save to data store: %@", [*anError localizedDescription]);
			NSArray* detailedErrors = [[*anError userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else {
				NSLog(@"  %@", [*anError userInfo]);
			}
		}
		return NO;		
	}
	return YES;
}


#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if (!managedObjectContext) return NSTerminateNow;
	
	if (![managedObjectContext commitEditing]) {
		NSLog(@"Unable to commit editing to terminate");
		return NSTerminateCancel;
	}
	
	if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		BOOL result = [sender presentError:error];
		if (result) return NSTerminateCancel;
		
		NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
		NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
		NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
		NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:question];
		[alert setInformativeText:info];
		[alert addButtonWithTitle:quitButton];
		[alert addButtonWithTitle:cancelButton];
		
		int answer = [alert runModal];
		[alert release], alert = nil;
		if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
	}
	
	return NSTerminateNow;
}
#endif

#pragma mark -
#pragma mark Notifications

- (void)managedObjectContextWillSave:(NSNotification *)aNotificationNote {
	
	// If there is a delegate, which responds to the correct delegate method, then
	// pass this notification on
	if (delegate && [delegate respondsToSelector:@selector(managedObjectContextManager:willSaveManagedObjectContext:)]) {
		[delegate managedObjectContextManager:self willSaveManagedObjectContext:aNotificationNote];
	}
}

- (void)managedObjectContextDidSave:(NSNotification *)aNotificationNote {
	
	// If there is a delegate, which responds to the correct delegate method, then
	// pass this notification on
	if (delegate && [delegate respondsToSelector:@selector(managedObjectContextManager:didSaveManagedObjectContext:)]) {
		[delegate managedObjectContextManager:self didSaveManagedObjectContext:aNotificationNote];
	}					
}

- (void)mergeChangesFromContextOnOtherThread:(NSNotification *)aNotificationNote {
	if ([NSThread isMainThread]) {
		[managedObjectContext mergeChangesFromContextDidSaveNotification:aNotificationNote];
	} else {
		dispatch_sync(dispatch_get_main_queue(), ^{
			[managedObjectContext mergeChangesFromContextDidSaveNotification:aNotificationNote];	
		});
	}
}

#pragma mark -
#pragma mark Methods for subclassing

// Virtual methods which can be over-ridden by the subclass
- (void)didAddStoreCoordinator:(NSPersistentStoreCoordinator *)storeCoordinator toContext:(NSManagedObjectContext *)aContext { }

// Default implementation returns the argument (no-change)
- (NSManagedObjectModel *)willUseManagedObjectModel:(NSManagedObjectModel *)model {
	return model;
}


@end

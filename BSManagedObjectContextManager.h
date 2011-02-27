//
//  BSManagedObjectContextManager.h
//  BSUtilities
//
//  Created by Daniel Thorpe on 01/07/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import <CoreData/CoreData.h>

// Exception names
extern NSString * const BSMOCManagerFailedToMigrateExceptionName;
extern NSString * const BSMOCManagerFailedToCreatePersistentStoreExceptionName;
extern NSString * const BSMOCManagerFailedToInitialisePersistentStoreExceptionName;

NSInteger sortVersionedModelPaths(id str1, id str2, void *context);

@class BSManagedObjectContextManager;

@protocol BSManagedObjectContextManagerDelegate <NSObject>
@optional
- (void)managedObjectContextManager:(BSManagedObjectContextManager *)manager willSaveManagedObjectContext:(NSNotification *)aNotificationNote;
- (void)managedObjectContextManager:(BSManagedObjectContextManager *)manager didSaveManagedObjectContext:(NSNotification *)aNotificationNote;
@end

@interface BSManagedObjectContextManager : NSObject {
	
	// A delegate
	id<BSManagedObjectContextManagerDelegate> delegate;
	
	// Directories, Names & Types
	NSString *applicationSupportDirectory;
	NSString *externalRecordsDirectory;
	NSString *externalRecordsExtension;
	NSString *storeName;
	NSString *storeType;
	
	// Managed Object Model
	NSManagedObjectModel *managedObjectModel;
	
	// Store coordinator - this is thread safe, so we only need one
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	
	// Managed Object Context for the main thread
	// This is the main thread context.
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, readwrite, assign) id<BSManagedObjectContextManagerDelegate> delegate;
@property (nonatomic, readwrite, retain) NSString *applicationSupportDirectory;
@property (nonatomic, readwrite, retain) NSString *externalRecordsDirectory;
@property (nonatomic, readwrite, retain) NSString *externalRecordsExtension;
@property (nonatomic, readwrite, retain) NSString *storeName;
@property (nonatomic, readwrite, retain) NSString *storeType;

@property (nonatomic, readonly, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, retain) NSManagedObjectContext *managedObjectContext;


// Define the singleton method although normally, an application would subclass this to
// specify the file system location of the application's data store.
+ (BSManagedObjectContextManager *)sharedManager;

// This will migrate the datastore to the latest version of the model
- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL ofType:(NSString *)type toModel:(NSManagedObjectModel *)finalModel error:(NSError **)error;

// Methods to save a managed object context.
- (BOOL)saveContext:(NSManagedObjectContext *)aContext;
- (BOOL)saveContext:(NSManagedObjectContext *)aContext withError:(NSError **)anError;

// Will create a new managed object context with appropriate notifications
- (NSManagedObjectContext *)freshManagedObjectContext;

// Notification handlers.
- (void)managedObjectContextWillSave:(NSNotification *)aNotificationNote;
- (void)managedObjectContextDidSave:(NSNotification *)aNotificationNote;
- (void)mergeChangesFromContextOnOtherThread:(NSNotification *)aNotificationNote;

// The application delegate should call this method in its own applicationShouldTerminate: implementation
#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
#endif

@end

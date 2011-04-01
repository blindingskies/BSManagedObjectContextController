//
//  MOCManaged.m
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//

#import "MOCManager.h"
#import "SynthesizeSingleton.h"

@implementation MOCManager

// Make this a Singleton class
SYNTHESIZE_SINGLETON_FOR_CLASS(MOCManager, sharedManager);

- (id)init {
	self = [super init];
	if(self) {
		
#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
		// Mac OS X	
		// Set the application support directory
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
		self.externalRecordsDirectory = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Metadata/CoreData/%@", @"Project Manager"]];
		self.externalRecordsExtension = @"pm"; // for project manager
		self.applicationSupportDirectory = [basePath stringByAppendingPathComponent:@"Project Manager"];
		self.storeName = @"storedata";
		self.storeType = NSSQLiteStoreType;
#else
		// iPhone	
		self.applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
		self.externalRecordsDirectory = nil;
		self.externalRecordsExtension = nil;
		self.storeName = @"Project Manager";
		self.storeType = NSSQLiteStoreType;
#endif	
		
	}
	return self;
}


// Utility class method to return the main moc
+ (NSManagedObjectContext *)sharedContext {
	return [[MOCManager sharedManager] managedObjectContext];
}



@end

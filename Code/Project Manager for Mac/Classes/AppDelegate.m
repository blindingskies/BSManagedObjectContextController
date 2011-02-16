//
//  Project_ManagerAppDelegate.m
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;
@synthesize managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	MOCManager *mocManager = [MOCManager sharedMOCManager];
	return [mocManager applicationShouldTerminate:sender];
}

#pragma mark -
#pragma mark Dynamic methods

- (NSManagedObjectContext *)managedObjectContext {
	if (!managedObjectContext) {
		MOCManager *mocManager = [MOCManager sharedMOCManager];
		managedObjectContext = [mocManager managedObjectContext];
	}
	return managedObjectContext;
}


@end

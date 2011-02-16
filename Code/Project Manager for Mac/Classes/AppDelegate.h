//
//  Project_ManagerAppDelegate.h
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//

@interface AppDelegate : NSObject <NSApplicationDelegate> {
@private	
    NSWindow *window;
	NSManagedObjectContext *managedObjectContext;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, readwrite, assign) NSManagedObjectContext *managedObjectContext;

@end

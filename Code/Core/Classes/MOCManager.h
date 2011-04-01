//
//  MOCManaged.h
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//

#import "BSManagedObjectContextManager.h"

@interface MOCManager : BSManagedObjectContextManager { }

+ (MOCManager *)sharedManager;
+ (NSManagedObjectContext *)sharedContext;

@end

//
//  Project_ManagerAppDelegate.h
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//


@interface AppDelegate : NSObject <UIApplicationDelegate> {
@private    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end


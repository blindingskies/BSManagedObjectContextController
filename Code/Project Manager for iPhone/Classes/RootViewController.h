//
//  RootViewController.h
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//


@interface RootViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
@private
	// NSFetchedResultsController for Core Data driven tables
	// although of course, we'd check out https://github.com/blindingskies/BSFetchedResultsController
	NSFetchedResultsController *fetchedResultsController;
	
}

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

#pragma mark Table configuration
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark Actions
- (IBAction)addProject:(id)sender;

@end

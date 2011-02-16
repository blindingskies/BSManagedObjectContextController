//
//  RootViewController.m
//  Project Manager
//
//  Created by Daniel Thorpe on 16/02/2011.
//  Copyright 2011 Blinding Skies Limited. All rights reserved.
//

#import "RootViewController.h"
#import "MOCManager.h"
#import "Project.h"

@implementation RootViewController


@synthesize fetchedResultsController;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProject:)];
    self.navigationItem.rightBarButtonItem = addButton;
	[addButton release];
	
	self.navigationItem.leftBarButtonItem = [self editButtonItem];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

#pragma mark -
#pragma mark Dynamic methods

- (NSManagedObjectContext *)managedObjectContext {
	// We need a managed object context
	return [[MOCManager sharedMOCManager] managedObjectContext];
}

#pragma mark -
#pragma mark NSFetchedResultsController Delegate Methods

/*
 Assume self has a property 'tableView' -- as is the case for an instance of a UITableViewController
 subclass -- and a method configureCell:atIndexPath: which updates the contents of a given cell
 with information from a managed object at the given index path in the fetched results controller.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex 
	 forChangeType:(NSFetchedResultsChangeType)type {
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] 
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] 
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)_controller 
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath 
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *aTableView = self.tableView;	
	
    switch(type) {
			
		case NSFetchedResultsChangeInsert:
			[aTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] 
							  withRowAnimation:UITableViewRowAnimationFade];
			break;
			
        case NSFetchedResultsChangeDelete:
            [aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
							  withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
			
            [self configureCell:(UITableViewCell *)[aTableView cellForRowAtIndexPath:indexPath] 
					atIndexPath:indexPath];
            break;
			
        case NSFetchedResultsChangeMove:
			
			if (indexPath) {
				[aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
								  withRowAnimation:UITableViewRowAnimationFade];
			}
			if (newIndexPath) {
				
				[aTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] 
								  withRowAnimation:UITableViewRowAnimationFade]; 
			}
            break;
    }
	
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	@try {
		[self.tableView endUpdates];
	}
	@catch (NSException * e) {
		NSLog(@"caught exception: %@: %@", [e name], [e description]);
	}
	@finally { }
}


#pragma mark -
#pragma mark Table view data source

- (NSFetchedResultsController *)fetchedResultsController {
	if (fetchedResultsController) return fetchedResultsController;
	
	// Create and configure a fetch request
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	// Set the entity
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.managedObjectContext];	
	[fetchRequest setEntity:entityDescription];
	
	// Sort Descriptors
	NSSortDescriptor *nameSorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:nameSorter, nil];
	[nameSorter release];	
	[fetchRequest setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
		
	// Create the NSFetchedResultsController
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																   managedObjectContext:self.managedObjectContext 
																	 sectionNameKeyPath:nil 
																			  cacheName:@"Projects"];
	
	// Set the delegate
	fetchedResultsController.delegate = self;
	
	// Release the fetch request
	[fetchRequest release];
	
	// Perform a fetch of the data
	NSError *error;
	BOOL success = [fetchedResultsController performFetch:&error];
	
	return (success == YES) ? fetchedResultsController : nil;
	
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	NSUInteger numberOfObjs = [sectionInfo numberOfObjects];
	return numberOfObjs;	
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
	[self configureCell:cell atIndexPath:indexPath];

    return cell;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	// Get the managed object
	Project *project = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = project.name;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        // Delete the row from the data source.
		Project *project = [self.fetchedResultsController objectAtIndexPath:indexPath];
		NSManagedObjectContext *aContext = self.managedObjectContext;
		[aContext deleteObject:project];
		[[MOCManager sharedMOCManager] saveContext:aContext];
		
//        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}



/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)addProject:(id)sender {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSManagedObjectContext *aContext = self.managedObjectContext;
		// Create a new project	
		Project *newProject = [Project insertInManagedObjectContext:aContext];
		// Save the context
		[[MOCManager sharedMOCManager] saveContext:aContext];		
	});
}

@end


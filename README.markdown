BSManagedObjectContextManager
=============================

This repository is an elaborate example of how to use a single class, BSManagedObjectContextManager, with an explanation of that class's place in a Mac or iPhone application's Core Data stack.

Note, that to actually use the example projects, it is necessary to run mogenerator http://rentzsch.github.com/mogenerator/ to create intermediate machine files which are ignored by the repository. First, install mogenerator, then in Terminal change directory to the clone of this repository and run:

	$ cd Code/Core/Classes/Managed\ Objects/
	$ mogenerator -m ../../Core\ Data\ Models/DataModel.xcdatamodeld/DataModel\ 2.xcdatamodel/
	
What does it do?
----------------

Very simply, BSManagedObjectContextManager is a singleton which provides access to NSManagedObjectContext instances from anywhere in your application. The instances that it creates, and the underlying NSPersistentStoreCoordinator and NSManagedObjectModel instances are all managed automatically. When creating a context, the class will create the persistent store, which will also prompt it to find the managed object model. It does this by exhaustively searching through the applications bundle for model files.

BSManagedObjectContextManager will also deal with merging changes between contexts on different threads, so that if the application requests a context while not on the main thread, a new context will be created, which when saved will merge back into the context on the main thread. See the addProject: method in the RootViewController class in the Project Manager for iPhone project for how this works.

How do I use it?
----------------

* Add the BSManagedObjectContextManager, and SynthesizeSingleton files to your project.

* Subclass BSManagedObjectContext, and copy the design pattern of the MOCManager class in the example Core project to make your subclass a singleton (thanks to Matt Gallagher).  The only requirement in the subclass is that you set the following properties which are application specific (and self explanatory), again look at MOCManager for details on this:

	* applicationSupportDirectory
	* externalRecordsDirectory
	* externalRecordsExtension
	* storeName
	* storeType
	
* In your application, get a context using the method (assuming your subclass is called MOCManager), you could even make this a utility method in your subclass:

		NSManagedObjectContext *aContext = [[MOCManager sharedMOCManager] managedObjectContext];
		
		
How do I separate my model code from my UI code?
-------------------------------------------------------

If you are developing an application for Mac and iOS which have a shared Core Data model layer, then to use the Core Data model in both projects it is necessary to put all the model code, including the .xcdatamodel file(s), model mapping file(s), model class files, BSManagedObjectContextManager and subclass files into a separate Xcode project. In that project, create three targets: a loadable bundle, a Mac OS X framework and an iOS static library. Drag the Core Data model and model mapping files into the bundle target's compile phase. If you have multiple versions of the model, drag the .xcdatamodeld container file; Xcode will work it out. Then add the classes to the other targets and set the appropriate SDKs for those. Then you will need an Xcode project each for the iOS and Mac apps. Into each one, drag from Finder the Xcode project file for the model layer into the Groups & Files area of Xcode. Develop the applications as normal, but make sure that for each one you set the framework/library and the bundle as dependent targets of the application target. Additionally, you'll need to drag the bundle (from the model layer Xcode project icon) into the Copy Bundle Resources build phase of the application targets. On the Mac application, you'll want to add a build phase to Copy Files (select Frameworks) and drag the model layer's Mac OS X framework into it. For the iOS application, you'll need to link against the model layer's static library product.

Also, to make sure everything compiles correctly, you need to set some project build settings. For Mac OS X these will look something like this:

	Runpath Search Paths: @loader_path/../Frameworks
	Framework Search Paths: "$(SRCROOT)/../<Name of your model layer Xcode project>/build/$(BUILD_STYLE)"
	Header Search Paths: "$(SRCROOT)/../<Name of your model layer Xcode project>/" (recusive)
	
For iOS:
	Framework Search Paths: "$(SRCROOT)/../<Name of your model layer Xcode project>/build/$(BUILD_STYLE)-$(PLATFORM_NAME)"
	Header Search Paths: "$(SRCROOT)/../<Name of your model layer Xcode project>/" (recusive)
		

Finally, you can modify the application prefix headers to include the model layer group header file (assuming you wrote one), for Mac OS X this will look something like (where the name of the model layer framework/library is called "Core"):

	#ifdef __OBJC__
	    #import <Cocoa/Cocoa.h>
		#import <Core/Core.h>
	#endif
	
	
For iOS:

	#import <Availability.h>

	#ifndef __IPHONE_3_0
	#warning "This project uses features only available in iPhone SDK 3.0 and later."
	#endif


	#ifdef __OBJC__
	    #import <Foundation/Foundation.h>
	    #import <UIKit/UIKit.h>
		#import "Core.h"
	#endif
	

  
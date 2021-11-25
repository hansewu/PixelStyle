//
//  FilterGallery.h
//  FilterGallery
//
//  Created by Calvin on 3/9/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "PSPlugins.h"
#import "MyWindow.h"

@interface FilterGallery : NSObject{
    
    // The plug-in's manager
    id seaPlugins;
    
    // YES if the application succeeded
    BOOL success;
    
    // Some temporary space we need preallocated for greyscale data
    unsigned char *newdata;
    
    // Determines the boundaries of the layer
    CGRect bounds;
    
    // Signals whether the bounds rectangle is valid
    BOOL boundsValid;
    
    IBOutlet MyWindow* m_window;
}

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		manager
 The PSPlugins instance responsible for managing the plug-ins.
	@result		Returns instance upon success (or NULL otherwise).
 */
- (id)initWithManager:(PSPlugins *)manager;

/*!
	@method		type
	@discussion	Returns the type of plug-in so PixelStyle can correctly interact
 with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
 */
- (int)type;


/*!
	@method		name
	@discussion	Returns the plug-in's name.
	@result		Returns an NSString indicating the plug-in's name.
 */
- (NSString *)name;

/*!
	@method		groupName
	@discussion	Returns the plug-in's group name.
	@result		Returns an NSString indicating the plug-in's group name.
 */
- (NSString *)groupName;

/*!
	@method		instruction
	@discussion	Returns the plug-in's instructions.
	@result		Returns a NSString indicating the plug-in's instructions
 (127 chars max).
 */
- (NSString *)instruction;

/*!
	@method		sanity
	@discussion	Returns a string to indicate this is a PixelStyle plug-in.
	@result		Returns the NSString "PixelStyle Approved (Bobo)".
 */
- (NSString *)sanity;

/*!
	@method		run
	@discussion	Runs the plug-in.
 */
- (void)run;

/*!
	@method		reapply
	@discussion	Applies the plug-in with previous settings.
 */
- (void)reapply;

/*!
	@method		canReapply
	@discussion Returns whether or not the plug-in can be applied again.
	@result		Returns YES if the plug-in can be applied again, NO otherwise.
 */
- (BOOL)canReapply;

/*!
	@method		execute
	@discussion	Executes the effect.
 */

- (BOOL)validateMenuItem:(id)menuItem;

-(NSImage*)getInputImage;
@end


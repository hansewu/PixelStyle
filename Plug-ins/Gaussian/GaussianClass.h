/*!
	@header		BlurClass
	@abstract	Blurs the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2004 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Cocoa/Cocoa.h>
#import "PSPlugins.h"
#import "GaussianFuncs.h"

@interface GaussianClass : NSObject {

	// The plug-in's manager
	id seaPlugins;

	// The label displaying the radius of the blur
	IBOutlet id radiusLabel;
	
	// The slider for the radius of the blur
	IBOutlet id radiusSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The number of applications
	int radius;

	// YES if the blurring must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;

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
	@method		apply:
	@discussion	Applies the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

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
	@method		preview:
	@discussion	Previews the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)preview:(id)sender;

/*!
	@method		cancel:
	@discussion	Cancels the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		update:
	@discussion	Updates the panel's labels.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		gauss
	@discussion	Executes the Gaussian blur.
	@param		method
				Runs the Gaussian blur with the given method.
*/
- (void)gauss:(BlurMethod)method;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

@end

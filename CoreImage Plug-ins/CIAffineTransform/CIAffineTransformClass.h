/*!
	@header		CIAffineTransformClass
	@abstract	Applies a triangle effect to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "PSPlugins.h"

@interface CIAffineTransformClass : NSObject {

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
	@method		points
	@discussion	Returns the number of points that the plug-in requires from the
				effect tool to operate.
	@result		Returns an integer indicating the number of points the plug-in
				requires to operate.
*/
- (int)points;

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
- (void)execute;

/*!
	@method		executeGrey
	@discussion	Executes the effect for greyscale images.
	@param		pluginData
				The PluginData object.
*/
//- (void)executeGrey:(PluginData *)pluginData;

/*!
	@method		executeGrey
	@discussion	Executes the effect for colour images.
	@param		pluginData
				The PluginData object.
*/
//- (void)executeColor:(PluginData *)pluginData;

/*!
	@method		executeChannel:withBitmap:
	@discussion	Executes the effect with any necessary changes depending on channel selection
				(called by either executeGrey or executeColor). 
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
//- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data;

/*!
	@method		determineContentBorders
	@discussion	Determines the content borders, must be called before executing.
	@param		pluginData
				The PluginData object.
*/
- (void)determineContentBorders:(PluginData *)pluginData;

/*!
	@method		transform:
	@discussion	Called by execute once preparation is complete.
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)transform:(PluginData *)pluginData withBitmap:(unsigned char *)data;

/*!
	@method		runAffineTransform:withImage:spp:width:height:
	@discussion	Completes an affine transform of the image returning a freshly allocated bitmap with the result.
				The initial image is left untouched. Useful if PixelStyle wants to run affine transforms using
				CoreImage.
	@param		at
				The affine transform.
	@param		data
				The bitmap data to work with.
	@param		spp
				The samples per pixel of the bitmap.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		opaque
				A boolean that is YES if the image is opaque (speeds up processing).
	@param		newWidth
				The width of the returned bitmap.
	@param		newHeight
				The height of the returned bitmap.
	@result		Returns the resulting bitmap (must be freed by user).
*/
- (unsigned char *)runAffineTransform:(NSAffineTransform *)at withImage:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height opaque:(BOOL)opaque newWidth:(int *)newWidth newHeight:(int *)newHeight;

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

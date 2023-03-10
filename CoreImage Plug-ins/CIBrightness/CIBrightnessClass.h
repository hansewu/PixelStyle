/*!
	@header		CIBrightnessClass
	@abstract	Adjusts brightness and contrast the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "PSPlugins.h"

@interface CIBrightnessClass : NSObject {

	// The plug-in's manager
	id seaPlugins;

	// The label displaying the brightness
	IBOutlet id brightnessLabel;
	
	// The slider for the brightness
	IBOutlet id brightnessSlider;
	
	// The label displaying the contrast
	IBOutlet id contrastLabel;
	
	// The slider for the contrast
	IBOutlet id contrastSlider;
	
	// The label displaying the value
	IBOutlet id saturationLabel;
	
	// The slider for the value
	IBOutlet id saturationSlider;
	
	// The panel for the plug-in
	IBOutlet id panel;

	// The value of the brightness
	float brightness;
	
	// The value of the contrast
	float contrast;
	
	// The value of the saturation
	float saturation;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;

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
	@discussion	Returns the type of plug-in so PixelStyle can correctly interact with the plug-in.
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
	@method		executeColor
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
	@method		adjust:withBitmap:
	@discussion	Called by execute once preparation is complete.
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)adjust:(PluginData *)pluginData withBitmap:(unsigned char *)data;

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

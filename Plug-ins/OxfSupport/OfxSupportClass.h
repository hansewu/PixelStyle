/*!
	@header		CIGaussianBlurClass
	@abstract	Blurs the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "PSPlugins.h"

typedef void * OFX_HOST_HANDLE;
@interface OfxSupportClass : NSObject {
    NSMutableArray *_arrPlugins;
}

-(NSMutableArray *)getPlugins;
@end

@interface OfxSupportClassItem : NSObject {

	// The plug-in's manager
	id seaPlugins;

	// The label displaying the radius
	IBOutlet id radiusLabel;
	
	// The slider for the radius
	IBOutlet id radiusSlider;

	// The panel for the plug-in
	IBOutlet id panel;
    
    IBOutlet NSButton* _btShowOriginal;
    
    NSView *_contentView;

	// The radius of the crystallize
	int radius;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;

    void * _hostHandle;
    NSString *_strPluginId;
    NSString *_strPluginType;
    NSString *_strPluginName;
    OFX_HOST_HANDLE _effectHandle;
    
    volatile int _needCalc;
    //robustVideoMatting *m_rvmProcess;
}

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		manager
				The PSPlugins instance responsible for managing the plug-ins.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithManagerOxf:(PSPlugins *)manager  oxfHostHandle:(void *)hostHandle stringId:(NSString *)strPluginId stringType:(NSString *)strPluginType stringName:(NSString *)strPluginName;

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
- (void)executeGrey:(PluginData *)pluginData;

/*!
	@method		executeColor
	@discussion	Executes the effect for colour images.
	@param		pluginData
				The PluginData object.
*/
- (void)executeColor:(PluginData *)pluginData;

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
- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data;

/*!
	@method		matting:withBitmap:
	@discussion	Called by execute once preparation is complete.
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)matting:(PluginData *)pluginData withBitmap:(unsigned char *)data;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

- (IBAction)reset:(id)sender;
- (IBAction)showOriginal:(id)sender;

@end

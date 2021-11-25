#import "Globals.h"
#import "PSDocument.h"

/*!
	@enum		k...Plugin
	@constant	kBasicPlugin
				Specifies a basic effects plug-in.
	@constant	kPointPlugin
				Specifies a basic effect plug-in that acts on one or
				more given to it by the effects tool.
*/
enum {
    kUnusePlugin = -1,
	kBasicPlugin = 0,
	kPointPlugin = 1,
    kSpecialEffectPlugin = 2,
    kAdjustColorPlugin = 3
};

/*!
	@class		PSPlugins
	@abstract	Manages all of PixelStyle's plug-ins.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain<br>
				<b>Copyright:</b> N/A
*/

@interface PSPlugins : NSObject {

	// The PSController object
	IBOutlet id m_idController;

	// An array of all Seahore's plug-ins
	NSArray *m_arrPlugins;

	// The plug-ins used by the effect tool
	NSArray *m_arrPointPlugins;

	// The names of the plug-ins used by the effect tool
	NSArray *m_arrPointPluginsNames;

	// The submenu to add plug-ins to
	IBOutlet id m_idEffectMenu;
    IBOutlet id m_idImageMenu;
	
	// The last effect applied
	int m_nLastEffect;
	
	// Stores the index of the "CIAffineTransform" plug-in - this plug-in handles PixelStyle CoreImage manipulation
	int m_nCiAffineTransformIndex;
	
    int m_pluginPreTool;
    
    id  m_currentDocument;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Adds plug-ins to the menu.
*/
- (void)awakeFromNib;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		terminate
	@discussion	Saves preferences to disk (this method is called before the
				application exits by the PSController).
*/
- (void)terminate;


/*!
	@method		affinePlugin
	@discussion	Returns the plug-in to be used for Core Image affine transforms.
	@results	Returns an instance of the plug-in to be used  for Core Image
				affine transforms or NULL if no such instance exists.
*/
- (id)affinePlugin;

/*!
	@method		data
	@discussion	Returns the address of a record shared between PixelStyle and the
				plug-in.
	@result		Returns the address of a record shared between PixelStyle and the
				plug-in.
*/
- (id)data;

/*!
	@method		run:
	@discussion	Runs the plug-in specified by the sender.
	@param		sender
				The menu item for the plug-in.
*/
- (IBAction)run:(id)sender;

/*!
	@method		reapplyEffect
	@discussion	Reapplies the last effect without configuration.
	@param		sender
				Ignored.
*/
- (IBAction)reapplyEffect:(id)sender;

/*!
	@method		cancelReapply
	@discussion	Prevents reapplication of the last effect.
*/
- (void)cancelReapply;

/*!
	@method		hasLastEffect
	@discussion	Returns whether there is a last effect.
	@result		Returns YES if there is a last effect, NO otherwise.
*/
- (BOOL)hasLastEffect;

/*!
	@method		pointPluginsNames
	@discussion	Returns the names of the point plugins.
	@result		Returns an NSArray.
*/
- (NSArray *)pointPluginsNames;

/*!
	@method		pointPlugins
	@discussion	Returns the point plugins.
	@result		Returns an NSArray.
*/
- (NSArray *)pointPlugins;


/*!
	@method		activePointEffect
	@discussion	Returns the presently active plug-in according to
				the effect table.
	@result		Returns an instance of the plug-in's class.
*/
- (id)activePointEffect;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

- (void)changeNewToolTo:(int)tool isReset:(BOOL)isReset;

@end

#import "Globals.h"

/*!
	@enum		kPegasusUpdate...
	@constant	kPegasusUpdateAll
				Indicates that all aspects of the Pegasus utility should be updated.
	@constant	kPegasusUpdateLayerView
				Indicates that only the layer view of the Pegasus utility should be updated.
*/
enum {
	kPegasusUpdateAll,
	kPegasusUpdateLayerView
};

/*!
	@defined	kMaxPixelsForLiveUpdate
	@discussion	Defines the maximum number of pixels in a layer before PixelStyle
				will stop updating its opacity in a live manner.
*/
#define kMaxPixelsForLiveUpdate 262144


/*!
	@class		PegasusUtility
	@abstract	Handles layers, channels and paths.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface PegasusUtility : NSObject {
	
	// The LayersView which appears in this utility
	IBOutlet id m_idLayersView;
	
	// The panel responsible for layer settings
	IBOutlet id m_idLayerSettingsPanel;
	
	// The object for handling layer settings
	IBOutlet id m_idLayerSettings;
	
	// The colour select view (this needs to be updated when the channel is changed on an RGBA image)
	IBOutlet id m_idColorSelectView;
	
	// The various layer buttons
	IBOutlet id m_idNewButton;
	IBOutlet id m_idDuplicateButton;
	IBOutlet id m_idUpButton;
	IBOutlet id m_idDownButton;
	IBOutlet id m_idDeleteButton;
	
	// The document which is the focus of this utility
	IBOutlet id m_idDocument;
	
	// Whether or not the utility is enabled
	BOOL m_bEnabled;

	// The Data Source used by the table that serves as the layers view.
	IBOutlet id m_idDataSource;
}

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		activate
	@discussion	Activates this utility with it's document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates this utility.
*/
- (void)deactivate;

/*!
	@method		update:
	@discussion	Updates the utility.
	@param		updateCode
				A Pegasus update code indicating the part of the utility to
				update.
*/
- (void)update:(int)updateCode;

/*!
	@method		layerSettings
	@discussion	Returns the layer settings manager associated with this object.
	@result		Returns an instance of LayerSettings representing the layer
				settings manager associated with this object.
*/
- (id)layerSettings;

/*!
	@method		show:
	@discussion	Shows the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		hide:
	@discussion	Hides the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)hide:(id)sender;

/*!
	@method		setEnabled:
	@discussion	Enables or disables the utility.
	@param		value
				YES if the utility should be enabled, NO otherwise.
*/
- (void)setEnabled:(BOOL)value;

/*!
	@method		toggleLayers:
	@discussion	Toggles the visibility of the of the "Layers" tab of the Pegasus
				utility.
	@param		sender
				Ignored.
*/
- (IBAction)toggleLayers:(id)sender;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled and choses the correct menu item title for it if
				appropriate).
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

/*!
	@method		visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
- (BOOL)visible;

// Proxy Actions
/*!
	@method		addLayer:
	@discussion	Adds a new layer to the document.
	@param		sender
				Ignored
*/
- (IBAction)addLayer:(id)sender;

/*!
	@method		duplicateLayer:
	@discussion	Duplicates the current layer in the document.
	@param		sender
				Ignored
*/
- (IBAction)duplicateLayer:(id)sender;

/*!
	@method		deleteLayer:
	@discussion	Deletes the currently selected layer in the document.
	@param		sender
				Ignored
 */
- (IBAction)deleteLayer:(id)sender;

@end

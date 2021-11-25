#import "Globals.h"

/*!
	@class		LayerSettings
	@abstract	Handles the panel that allows users to change the various
				settings of the various layers of PixelStyle.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
#import "MyCustomComboBox.h"
@class PSLayer;

@interface LayerSettings : NSObject<MyCustomComboBoxDelegate> {

	// The document in focus
	IBOutlet id m_idDocument;
	
	// The PegasusUtility controlling us
	IBOutlet id m_idPegasusUtility;

	// The settings panel
    IBOutlet id m_idPanel;
	
	// The text box for entering the layer's title
    IBOutlet id m_idLayerTitle;
	
	// The various values
    IBOutlet id m_idLeftValue;
    IBOutlet id m_idTopValue;
    IBOutlet id m_idWidthValue;
    IBOutlet id m_idHeightValue;
	
	// The various units
	IBOutlet id m_idLeftUnits;
	IBOutlet id m_idTopUnits;
	IBOutlet id m_idWidthUnits;
	IBOutlet id m_idHeightUnits;

	// The units for the panel
	int m_nUnits;
	
	// The slider that indicates the opacity of the layer
	IBOutlet id m_idOpacitySlider;
	
	// The label that reflects the value of the slider
	IBOutlet id m_idOpacityLabel;
	
	// The pop-up menu that reflects the current mode of the layer
	IBOutlet id m_idModePopup;
		
	// Whether or not this layer is linked
	IBOutlet id m_idLinkedCheckbox;
	
	// Whether or not the alpha layer is enabled
	IBOutlet id m_idAlphaEnabledCheckbox;
	
	// Channel editing
	IBOutlet id m_idChannelEditingMatrix;
	
	// The layer whose settings are currently being changed
	PSLayer* m_pslSettingsLayer;
    
    //add by lcz
    IBOutlet id m_idModePopupOut;
    IBOutlet id m_idLinkedCheckboxOut;
    IBOutlet id m_idAlphaEnabledCheckboxOut;
    
    IBOutlet MyCustomComboBox *m_myComboxOpacity;
    
    IBOutlet NSButton *m_btnEffectFill;
    IBOutlet NSButton *m_btnEffectStroke;
    IBOutlet NSButton *m_btnEffectOuterGlow;
    IBOutlet NSButton *m_btnEffectInnerGlow;
    IBOutlet NSButton *m_btnEffectShadow;
    
    IBOutlet NSView     *m_viewEffect;
    IBOutlet NSView     *m_viewLayer;
}

/*!
	@method		activate
	@discussion	Activates the layer settings manager with the document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates the layer settings manager.
*/
- (void)deactivate;

/*!
	@method		showSettings:from:
	@discussion	Presents the user with a modal dialog to alter the active
				layer's attributes.
	@param		layer
				The layer the settings are for.
	@param		point
				The point that the mouse was clicked to show the information.
				Used to position the window.
*/
- (void)showSettings:(PSLayer *)layer from:(NSPoint)point;

/*!
	@method		apply:
	@discussion	Takes the settings from the panel and applies the necessary
				changes to the document.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Closes the panel without applying the changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		setOffsetsLeft:top:index:
	@discussion	Adjusts the offsets of a given layer (handles updates and
				undos).
	@param		newName
				The name to which the layer should be renamed.
	@param		index
				The index of the layer to rename.
*/
- (void)setOffsetsLeft:(int)left top:(int)top index:(int)index;

/*!
	@method		setName:index:
	@discussion	Renames a given layer (handles updates and undos).
	@param		newName
				The name to which the layer should be renamed.
	@param		index
				The index of the layer to rename.
*/
- (void)setName:(NSString *)newName index:(int)index;

/*!
	@method		changeMode:
	@discussion	Called when the mode of a layer is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeMode:(id)sender;

/*!
	@method		undoOpacity:to:
	@discussion	Undoes a change in the mode of a layer (this method should only
				ever be called by the undo manager following a call to
				changeMode:).
	@param		index
				The index of the layer to undo the mode change for.
	@param		value
				The desired mode value after the undo.
*/
- (void)undoMode:(int)index to:(int)value;

/*!
	@method		changeOpacity:
	@discussion	Called when the opacity of a layer is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeOpacity:(id)sender;

/*!
	@method		undoOpacity:to:
	@discussion	Undoes a change in the opacity of a layer (this method should
				only ever be called by the undo manager following a call to
				changeOpacity:).
	@param		index
				The index of the layer to undo the opacity change for.
	@param		value
				The desired opacity value after the undo.
*/
- (void)undoOpacity:(int)index to:(int)value;

/*!
	@method		changeLinked:
	@discussion	Called when the linked checkbox is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeLinked:(id)sender;

/*!
	@method		changeEnabledAlpha:
	@discussion	Called when the alpha channel is enabled or disabled.
	@param		sender
				Ignored.
*/
- (IBAction)changeEnabledAlpha:(id)sender;

/*!
	@method		changeChannelEditing:
	@discussion	Called when the matrix for channel editing is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeChannelEditing:(id)sender;

//add by lcz
- (IBAction)changeModeFromOut:(id)sender;
- (IBAction)changeLinkedFromOut:(id)sender;
- (IBAction)changeEnabledAlphaFromOut:(id)sender;
- (void)changeLayerSettingsAfterUpdateActiveLayer;

- (IBAction)changeEffect:(id)sender;
-(void)updateEffectUI;

@end

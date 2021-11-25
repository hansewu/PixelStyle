#import "Globals.h"
#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"
/*!
	@class		BrushOptions
	@abstract	Handles the options pane for the paintbrush tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BrushOptions : AbstractPaintOptions<MyCustomComboBoxDelegate> {
	
	// A checkbox indicating whether to fade
	IBOutlet id m_idFadeCheckbox;
	
	// A slider indicating the rate of fading
//	IBOutlet id m_idFadeSlider;
	
	// A checkbox indicating whether to listen to pressure information
	IBOutlet id m_idPressureCheckbox;
	
	// A popup menu indicating pressure style
	IBOutlet id m_idPressurePopup;
	
	// A checkbox indicating whether to scale
	IBOutlet id m_idScaleCheckbox;
	
	// A boolean indicating if the user has been warned about the Mac OS 10.4 bug
	BOOL m_bWarnedUser;

	// Are we erasing stuff?
	BOOL m_bIsErasing;
    
    STRAIGHT_LINE_TYPE m_nStraightLineType;
    
    // Show the feather for the rectangle
//    IBOutlet NSTextField *m_texFieldFade;
    
    IBOutlet id m_idPSComboxFadeOut;
    
    IBOutlet NSTextField *m_labelOpacity;
    IBOutlet NSTextField *m_labelTextures;
    IBOutlet id m_idOpenBrushPanel;
    IBOutlet id m_idOpenTexturePanel;
    IBOutlet id m_idDrawTyle;
    IBOutlet id m_idDrawTyle45;
    
    IBOutlet MyCustomComboBox *m_myCustomComboOpacity;
    IBOutlet id m_idEraseCheckbox;
    BOOL m_bLastEraseState;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				The object responsible for the change.
*/
- (IBAction)update:(id)sender;

/*!
	@method		fade
	@discussion	Returns whether the brush should fade with use.
	@result		Returns YES if the brush should fade with use, NO otherwise.
*/
- (BOOL)fade;

/*!
	@method		fadeValue
	@discussion	Returns the rate of fading.
	@result		Returns an integer representing the rate of fading.
*/
- (int)fadeValue;

/*!
	@method		fade
	@discussion	Returns whether the brush is pressure sensitive.
	@result		Returns YES if the brush is pressure sensitive, NO otherwise.
*/
- (BOOL)pressureSensitive;

/*!
	@method		pressureValue
	@discussion	Returns the pressure value that should be used for the brush.
	@param		event
				The event encapsulating the current pressure.
	@result		Returns an integer from 0 to 255 indicating the pressure value
				that should be used for the brush.
*/
- (int)pressureValue:(NSEvent *)event;

/*!
	@method		scale
	@discussion	Returns whether the brush should be scaled with pressure.
	@result		Returns YES if the brush should scaled, NO otherwise.
*/
- (BOOL)scale;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

/*!
	@method		brushIsErasing
	@discussion	Returns whether or not the brush is erasing.
	@result		Returns YES if the brush is erasing, NO if the brush is using
				its normal operation.
*/
- (BOOL)brushIsErasing;

/*!
	@method		updateModifiers:
	@discussion	Updates the modifier pop-up.
	@param		modifiers
				An unsigned int representing the new modifiers.
*/
- (void)updateModifiers:(unsigned int)modifiers;


-(IBAction)onChangeEraseMode:(id)sender;
-(IBAction)onDrawLinesType:(id)sender;
-(STRAIGHT_LINE_TYPE)getDrawLinesType;

- (float)getOpacityValue;


@end

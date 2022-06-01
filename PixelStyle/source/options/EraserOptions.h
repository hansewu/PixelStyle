#import "Globals.h"
#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

/*!
	@class		EraserOptions
	@abstract	Handles the options pane for the eraser tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EraserOptions : AbstractPaintOptions <MyCustomComboBoxDelegate>{
	
//	// A slider indicating the opacity of the bucket
//	IBOutlet id m_idOpacitySlider;
	
	// A label displaying the opacity of the bucket
	IBOutlet id m_idOpacityLabel;
	
	// A checkbox indicating whether to fade in the same style as the paintbrush
	IBOutlet id m_idMimicBrushCheckbox;
	
    STRAIGHT_LINE_TYPE m_nStraightLineType;
    int m_nFillType;
    
//    IBOutlet NSTextField *m_texFieldOpacity;
    
    IBOutlet id m_idPSComboxOpacity;
    
    
    IBOutlet id m_idOpenBrushPanel;
    IBOutlet id m_idDrawTyle;
    IBOutlet id m_idDrawTyle45;
    
    int m_nEraserType;
    NSPopUpButton *m_popBtnFillType;
}


/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		opacityChanged:
	@discussion	Called when the opacity is changed.
	@param		sender
				Ignored.
*/
- (IBAction)opacityChanged:(id)sender;

/*!
	@method		opacity
	@discussion	Returns the opacity to be used with the eraser tool.
	@result		Returns an integer indicating the opacity (between 0 and 255
				inclusive) to be used with the eraser tool.
*/
- (int)opacity;

/*!
	@method		mimicBrush
	@discussion	Returns whether to mimic the paintbrush settings when fading.
	@result		Returns YES if the eraser should mimic the paintbrush, NO 
				otherwise.
*/
- (BOOL)mimicBrush;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

-(IBAction)onDrawLinesType:(id)sender;
-(STRAIGHT_LINE_TYPE)getDrawLinesType;

-(void)setEraserType:(int)nEraserType;//0 eraser 1 inpaint
-(int)fillType;

@end

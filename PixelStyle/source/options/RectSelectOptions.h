#import "Globals.h"
#import "AbstractSelectOptions.h"
#import "MyCustomComboBox.h"

/*!
	@class		RectSelectOptions
	@abstract	Handles the options pane for the rectangular selection tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface RectSelectOptions : AbstractSelectOptions <MyCustomComboBoxDelegate> {

	
//	// When checked indicates the rectangle should be rounded
//	IBOutlet id m_idRadiusCheckbox;

	// The AspectRatio instance linked to this options panel
	IBOutlet id m_idAspectRatio;
    
//    // The slider to select the feather for the rectangle
//    IBOutlet NSSlider *m_sliderFeather;
    IBOutlet NSTextField *m_labelCornerRadius;
    IBOutlet MyCustomComboBox *m_myCustomComBoxRadius;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		radius
	@discussion	Returns the curve rdius to be used with the rounded rectangle.
	@result		Returns an integer indicating the curve radius to be used with
				the rounded rectangle.
*/
- (int)radius;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;


@end

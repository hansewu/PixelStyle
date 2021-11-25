#import "Globals.h"
#import "AbstractSelectOptions.h"
#import "MyCustomComboBox.h"

/*!
	@class		WandOptions
	@abstract	Handles the options pane for the magic wand tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface WandOptions : AbstractSelectOptions <MyCustomComboBoxDelegate> {
	
	
//    // A slider indicating the tolerance of the wand
//	IBOutlet id m_idToleranceSlider;
//	
//	// A label displaying the tolerance of the wand
//	IBOutlet id m_idToleranceLabel;
//	
//	// A slider for the density of the wand sampling
//	IBOutlet id m_idIntervalsSlider;
//	
//    // A label displaying the Intervals of the wand
//    IBOutlet id m_idIntervalsLabel;
    
    IBOutlet id m_myCustomComboBoxTolerance;
    IBOutlet id m_myCustomComboBoxIntervals;
    
    IBOutlet id m_labelTolerance;
    IBOutlet id m_labelIntervals;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

///*!
//	@method		toleranceSliderChanged:
//	@discussion	Called when the tolerance is changed.
//	@param		sender
//				Ignored.
//*/
//- (IBAction)toleranceSliderChanged:(id)sender;

/*!
	@method		tolerance
	@discussion	Returns the tolerance to be used with the paint bucket tool.
	@result		Returns an integer indicating the tolerance to be used with the
				bucket tool.
*/
- (int)tolerance;

///*!
//	@method		intervalsSliderChanged:
//	@discussion	Called when the intervals is changed.
//	@param		sender
// Ignored.
// */
//- (IBAction)intervalsSliderChanged:(id)sender;
/*!
	@method		numIntervals
	@discussion	Returns the number of intervals for the wand sampling
	@result		Returns an integer.
*/
- (int)numIntervals;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end

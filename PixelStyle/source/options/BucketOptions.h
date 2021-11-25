#import "Globals.h"
#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

/*!
	@class		BucketOptions
	@abstract	Handles the options pane for the paint bucket tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BucketOptions : AbstractPaintOptions<MyCustomComboBoxDelegate> {
	
//	// A slider indicating the tolerance of the bucket
//	IBOutlet id m_idToleranceSlider;
//	
//	// A label displaying the tolerance of the bucket
//	IBOutlet id m_idToleranceLabel;
//
//	// A slider for the density of the wand sampling
//	IBOutlet id m_idIntervalsSlider;
//    
//    // A label displaying the density of the bucket
//    IBOutlet id m_idIntervalsLabel;
    
    IBOutlet id m_myCustomComboBoxTolerance;
    IBOutlet id m_myCustomComboBoxIntervals;
    
    IBOutlet NSButton *m_btnFloodAllSelecion;
    IBOutlet NSButton *m_btnPreviewFlood;
    
    IBOutlet id m_idOpenTexturePanel;
    
    IBOutlet MyCustomComboBox *m_myCustomComboOpacity;
    
    IBOutlet NSTextField *m_labelTolerance;
    IBOutlet NSTextField *m_labelIntervals;
    IBOutlet NSTextField *m_labelOpacity;
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
//	@discussion	Called when the numIntervals is changed.
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
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

-(IBAction)onFloodAllSelection:(id)sender;
-(IBAction)onPreviewFlood:(id)sender;
- (float)getOpacityValue;

@end

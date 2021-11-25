#import "Globals.h"
#import "AbstractOptions.h"

/*!
	@class		EyedropOptions
	@abstract	Handles the options pane for the colour sampling tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EyedropOptions : AbstractOptions {

	// A slider indicating the size of the sample block
	IBOutlet id m_idSizeSlider;
	
	// A checkbox that when checked implies that the tool should consider all pixels not those just in the current layer
	IBOutlet id m_idMergedCheckbox;
    
    IBOutlet id m_idSelectBackColorCheckbox;
    
    IBOutlet NSTextField *m_textFieldSize;
	
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		sampleSize
	@discussion	Returns the size of the sample square.
	@result		Returns an integer indicating the size (in pixels) of the sample
				square.
*/
- (int)sampleSize;

/*!
	@method		mergedSample
	@discussion	Returns whether all layers should be considered in sampling or
				just the active layer.
	@result		Returns YES if all layers should be considered in sampling, NO 
				if only the active layer should be considered.
*/
- (BOOL)mergedSample;

/*!
	@method		dropAsBackgroundColor
	@discussion	Returns whether all layers should be considered in sampling or
 just the active layer.
	@result		Returns YES if all layers should be considered in sampling, NO
 if only the active layer should be considered.
 */
- (BOOL)dropAsBackgroundColor;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end

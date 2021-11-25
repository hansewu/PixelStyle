#import "Globals.h"
#import "AbstractPaintOptions.h"

/*!
	@class		CloneOptions
	@abstract	Handles the options pane for the lasso tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CloneOptions : AbstractPaintOptions {

	// A checkbox that when checked implies that the tool should consider all pixels not those just in the current layer
	IBOutlet id m_idMergedCheckbox;
	
	// A label indicating the source of the clone
	IBOutlet id m_idSourceLabel;
    
    
    IBOutlet id m_idMakeSourceCheckbox;
    IBOutlet id m_idOpenBrushPanel;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		mergedSample
	@discussion	Returns whether all layers should be considered in sampling or
				just the active layer.
	@result		Returns YES if all layers should be considered in sampling, NO 
				if only the active layer should be considered.
*/
- (BOOL)mergedSample;

/*!
	@method		mergedChanged:
	@discussion	Called when the merged sample checkbox is changed to unset
				the source point.
	@param		sender
				Ignored.
*/
- (IBAction)mergedChanged:(id)sender;

/*!
	@method		makeSourceChanged:
	@discussion	Called when the make source checkbox is changed to unset
 the source point.
	@param		sender
 Ignored.
 */
- (IBAction)makeSourceChanged:(id)sender;

/*!
	@method		update
	@discussion	Updates the options panel.
*/
- (void)update;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end

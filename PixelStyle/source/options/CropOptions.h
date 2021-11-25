#import "Globals.h"
#import "AbstractScaleOptions.h"

/*!
	@class		CropOptions
	@abstract	Handles the options pane for the cropping tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CropOptions : AbstractScaleOptions {

	// The AspectRatio instance linked to this options panel
	IBOutlet id m_idAspectRatio;
    
    IBOutlet id m_idCrop;
	
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		crop:
	@discussion	Crops the image to given rectangle.
	@param		sender
				Ignored.
*/
- (IBAction)crop:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

- (void)setCropButtonHidden:(BOOL)hidden;

@end

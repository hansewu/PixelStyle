#import "Globals.h"
#import "AbstractOptions.h"

/*		
	@class		AbstractPaintOptions
	@abstract	Acts as a base class for the options panes of the paint-type tools.
	@discussion	This class is responsible for connection actions of brushes and 
				textures to the options classes.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/


typedef enum
{
    STRAIGHT_NO = -1,
    STRAIGHT_LINE = 0,
    STRAIGHT_LINE_45 = 1,
    STRAIGHT_LINE_COUNT = 2
}STRAIGHT_LINE_TYPE;

@interface AbstractPaintOptions : AbstractOptions {

    IBOutlet NSImageView *m_imageViewTexture;
    IBOutlet NSImageView *m_imageViewBrush;
}

/*!
	@method		toggleTextures:
	@discussion	Toggles the modal textures panel.
	@param		sender
				Ignored.
*/
- (IBAction)toggleTextures:(id)sender;


/*!
	@method		toggleBrushes:
	@discussion	Toggles the modal brushes panel.
	@param		sender
				Ignored.
*/
- (IBAction)toggleBrushes:(id)sender;

@end

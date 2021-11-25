#import "Globals.h"

/*!
	@class		PSShadowView
	@abstract	Provides a view that will draw a shadow for the image to differentiate it from the background.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSShadowView : NSView {
	IBOutlet id scrollView;
	BOOL m_bAreRulersVisible;
    
    IBOutlet id m_idDocument;
}

/*!
	@method		setRulersVisible:
	@discussion	The shadow will have to be offset if there are rulers.
	@param		isVisible
				Whether or not they now are visible.
*/
- (void)setRulersVisible:(BOOL)isVisible;
@end

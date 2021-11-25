#import "Globals.h"

/*!
	@class		LayerControlView
	@abstract	The view for Layer controls
	@discussion	Draws a background and borders for the buttons.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface LayerControlView : NSView {
	// If the user is dragging right now
	BOOL m_bIntermediate;
	
	// The previous width before the drag
	float m_fOldWidth;
	NSPoint m_poiOld;
	
	// The other views in the window
	IBOutlet id m_idLeftPane;
	IBOutlet id m_idRightPane;
	
	// The buttons
	IBOutlet id m_idNewButton;
	IBOutlet id m_idDupButton;
	IBOutlet id m_idDelButton;
	IBOutlet id m_idShButton;
		
	BOOL m_bDrawThumb;
	
	IBOutlet id m_idStatusUtility;
}

- (void)setHasResizeThumb:(BOOL)hasIt;

@end

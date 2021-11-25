#import "Globals.h"

/*!
	@class		LayerDataSource
	@abstract	The view for Layer controls
	@discussion	Draws a background and borders for the buttons.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface LayerDataSource : NSObject {
	// The document this data source is connected to
	IBOutlet id m_idDocument;

	// The nodes that are being dragged (if any)
	// This should be null during no dragging
    NSArray *m_arrDraggedNodes;
	
	// A reference back to the outline view
    IBOutlet id m_idOutlineView;
    
    NSTimeInterval m_lastTimeClickCheck;//only for filtering two times respond
	
}

/*!
	@method		outlineViewAction:
	@discussion	Called when outline view is chicked on.
	@param		sender
				Ignored.
*/
- (IBAction)outlineViewAction:(id)sender;

/*!
	@method		draggedNodes
	@discussion	The nodes being dragged
	@result		An NSArray
*/
- (NSArray*)draggedNodes;

/*!
	@method		selectedNodes
	@discussion	The nodes selected
	@result		An NSArray
*/
- (NSMutableArray *)selectedNodes;

/*!
	@method		update
	@discussion	Called when the data changes.
*/
- (void)update;
@end

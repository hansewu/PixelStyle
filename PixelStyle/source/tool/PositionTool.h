#import "Globals.h"
#import "AbstractTool.h"

/*!
	@class		PositionTool
	@abstract	The position tool allows layers to be repositioned within the
				document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/


@interface PositionTool : AbstractTool {

	// The point from which the drag started
	IntPoint m_sInitialPoint;
       
    // The mode of positioning
	int m_nMode;

	// An outlet to an instance of a class with the same name
	IBOutlet id m_idPSOperations;
    
	
    double m_lastRefreshTime;
    
    IntPoint m_sOldSelectionOrigin;
    
    NSMutableArray *m_linkedLayers;
    NSMutableArray *m_linkedLayersRects;
}


/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;



- (void)undoToOrigin:(IntPoint)origin forLayer:(int)index;




@end

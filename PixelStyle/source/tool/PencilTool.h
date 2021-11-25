#import "Globals.h"
#import "AbstractTool.h"

/*!
	@class		PencilTool
	@abstract	The pencil tool is a precision tool intended for small
				pixel-by-pixel changes.
	@discussion	Shift key - Draws straight lines.<br>Option key - Changes
				the brush to an eraser.<br>Control key - Draws lines at
				45 degree intervals.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PencilTool : AbstractTool {
	
	// The last point a point was made
	IntPoint m_sLastPoint;
	
	// The size of the pencil block (updated from options at initial mouse down)
	int m_nSize;
	
	// The set of pixels upon which to base the pencil block
	unsigned char m_aBasePixel[4];
    
    // Has the first touch been done?
    BOOL m_bFirstTouchDone;
    
    IntRect         m_rectLayerLast;
    unsigned char * m_dataLayerLast;
    BOOL     m_bExpanded;
	
}

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		acceptsLineDraws
	@discussion	Returns whether or not this tool wants to allow line draws.
	@result		Returns YES if the tool does want to allow line draws, NO
				otherwise. The implementation in this class always returns YES.
*/
- (BOOL)acceptsLineDraws;

/*!
	@method		useMouseCoalescing
	@discussion	Returns whether or not this tool should use mouse coalescing.
	@result		Returns YES if this tool should use mouse coalescing, NO
				otherwise.
*/
- (BOOL)useMouseCoalescing;

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
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
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		startStroke:
	@discussion	Starts a stroke at a specified point.
	@param		where
				Where in the document to start the stroke at.
*/
- (void)startStroke:(IntPoint)where;

/*!
	@method		intermediateStroke:
	@discussion	Specifies an intermediate point in the stroke.
	@param		Where in the document to place the intermediate
				stroke.
*/
- (void)intermediateStroke:(IntPoint)where;

/*!
	@method		endStroke:
	@discussion	Ends a stroke at a specified point.
	@param		where
				Where in the document to end the stroke at.
*/
- (void)endStroke:(IntPoint)where;

@end

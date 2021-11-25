#import "Globals.h"
#import "AbstractScaleTool.h"
#import "LassoTool.h"

/*!
	@class		PolygonLassoTool
	@abstract	The polygon lasso tool allows polygonal selections of no specific shape
	@discussion	Option key - floats the selection.
				This is a subclass of the LassoTool, because some of the functionality
				is shared and it reduces duplicate code.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PolygonLassoTool : AbstractSelectTool {
	// The beginning point of the polygonal lasso tool.
	// Represented by the white dot in the view.
	NSPoint m_poiStart;
    
    // The list of points
    IntPoint *m_sPoints;
    
    // The last point
    NSPoint m_poiLast;
    
    // The current position in the list
    int m_nPos;
    
    bool m_bHaveTempPoint;
    IntPoint m_sTempPoint;
}

/*!
	@method		fineMouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		isFineTool
	@discussion	Returns whether the tool needs an NSPoint input as opposed to an IntPoint
 input (i.e. whether fineMouse... or mouse... should be called).
	@result		Returns YES if the tool needs an NSPoint input as opposed to an IntPoint
 input, NO otherwise. The implementation in this class always returns YES.
 */
- (BOOL)isFineTool;

/*!
	@method		currentPoints
	@discussion	Returns the current points used by the tool for other classes to use.
	@result		A LassoPoints struct
 */
- (LassoPoints) currentPoints;

-(BOOL)isHaveTempPoint;

-(IntPoint)tempPoint;

@end

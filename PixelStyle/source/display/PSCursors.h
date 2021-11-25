#import "Globals.h"

/*!
	@class		PSCursors
	@abstract	Handles the cursors for the PSView
	@discussion	This is a second class for organizational simplicity because it 
	contains a separate set of functionality from the view class.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@class PSDocument;
@class	PSView;

@interface PSCursors : NSObject {
	// Other Important Objects
	PSDocument *m_psDocument;
	PSView *m_psView;
	
	// The various cursors used by the toolbox
	NSCursor *m_curCrosspoint, *m_curWand, *m_curZoom, *m_curPencil, *m_curBrush, *m_curBucket, *m_curEyedrop, *m_curMove, *m_curEraser, *m_curSmudge, *m_curEffect, *m_curAdd, *m_curSubtract, *m_curNoop;

	// The view-specific cursors
	NSCursor *m_curHand, *m_curGrab, *m_curUd, *m_curLr, *m_curUrdl, *m_curUldr, *m_curClose, *m_curResize, *m_curRotate , *m_curAnchor;
	
	// The rects for the handles and selection
	NSRect m_recHandleRects[9];
	NSCursor* m_curHandleCursors[9];
	
	// The close rect
	NSRect m_recClose;

	// Scrolling mode variables
	BOOL m_bScrollingMode;
	BOOL m_bScrollingMouseDown;
}

/*!
	@method		initWithDocument:andView:
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
	@param			newDocument
				The PSDocument this cursor manager is in
	@param			newView
				The PSView that uses these cursors
*/
- (id)initWithDocument:(id)newDocument andView:(id)newView;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		resetCursorRects
	@discussion	Sets the current cursor for the view (this is an overridden
				method).
*/
- (void)resetCursorRects;

/*!
	@method		addCursorRect:cursor:
	@discussion	We need this because we need to clip the cursor rect from the
				image to the cursor rect for the superview (so the rects are
				not outside the image).
	@param		rect
				The rect in the coordinates of the PSView
	@param		cursor
				The cursor to add.
*/
- (void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor;

/*!
	@method		handleRectsPointer
	@discussion	Returns a pointer to the rectangles used for the handles.
*/
- (NSRect *)handleRectsPointer;

/*!
	@method		setCloseRect:
	@discussion	For setting the rectangle used for the close cursor for the polygon lasso tool.
	@param		rect
				A NSRect containing the rectangle of the handle.
*/
- (void)setCloseRect:(NSRect)rect;

/*!
	@method		setScrollingMode:mouseDown:
	@discussion	For letting the cursors manager know we are in scrolling mode.
	@param		inMode
				A BOOL if we are in the mode or not.
	@param		mouseDown
				A BOOL if the mouse is down or not.
*/
- (void)setScrollingMode:(BOOL)inMode mouseDown:(BOOL)mouseDown;

@end

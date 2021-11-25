#import "Globals.h"

/*!
	@enum		k...Mode
	@constant	kDefaultMode
				Default selection.
	@constant	kAddMode
				Add to the selection.
	@constant	kSubtractMode
				Subtract from the selection.
	@constant	kMultiplyMode
				Multiply the selections.
	@constant	kSubtractProductMode
				Subtract the product of the selections.
	@constant	kForceNewMode
				For a new selection
*/
enum {
	kDefaultMode,
	kAddMode,
	kSubtractMode,
	kMultiplyMode,
	kSubtractProductMode,
	kForceNewMode
};

/*!
	@class		PSSelection
	@abstract	Manages user selections.
	@discussion	This class is yet to be fully implemented.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSSelection : NSObject {

	// The document associated with this object
	id m_idDocument;

	// The current selection rectangle
    IntRect m_sRect;//, m_sGlobalRect;
	
	// The current selection bitmap and mask
	unsigned char *m_pMask;
	
	// Used to determine if the selection is active
	BOOL m_bActive;
	
	// Help present the user with a visual representation of the mask
	int m_nSelectionColorIndex;
	unsigned char *m_pMaskBitmap;
	NSBitmapImageRep *m_birMaskBitmapRep;
	NSImage *m_imgMask;
	
	// The point of the last copied selection and its size
	IntPoint m_sSelPoint;
	IntSize m_sSelSize;
    
    NSMutableArray *m_selectionEventArray;
    NSMutableArray *m_selectionUndoEventArray;
    int m_lastUndoEventIndex;
	
}


/*
 m_sRect:           整个选区相对画布的位置
 m_sGlobalRect:     整个选区与当前层交叉后相对画布的位置
 trueLocalRect:     整个选区相对当前层的位置
 localRect:         m_sGlobalRect 相对当前层的位置
 */


/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		active
	@discussion	Returns whether the current selection is active or not.
	@result		Returns YES if the selection is active, NO otherwise.
*/
- (BOOL)active;
- (void)setActive:(BOOL)isAvtive;

/*!
	@method		floating
	@discussion	Returns whether the current selection is floating or not.
				Floating implies that the selection's bitmap data is a detached
				from the layer.
	@result		Returns YES if the selection is floating, NO otherwise.
*/
- (BOOL)floating;

/*!
	@method		mask
	@discussion	Returns a mask indicating the opacity of the selection, if NULL
				is returned the selection rectangle should be assumed to be
				entirely opaque.
	@result		Returns a reference to an 8-bit single-channel bitmap or NULL.
*/
- (unsigned char *)mask;

/*!
	@method		maskImage
	@discussion	Returns an image of the mask in the current selection colour.
				This is used so the selection can be represented to users.
*/
- (NSImage *)maskImage;

/*!
	@method		maskOffset
	@discussion	Returns the offset of the mask.
	@result		Returns an IntPoint indicating the point in the mask that
				corresponds to the top-left corner of localRect.
*/
- (IntPoint)maskOffset;

/*!
	@method		maskSize
	@discussion	Returns the size of the mask.
	@result		Returns an IntSize indicating the size of the mask.
*/
- (IntSize)maskSize;

/*!
	@method		trueLocalRect
	@discussion	Returns the selection's true rectangle (this rectangle may
				be larger than the active layer and should rarely be required).
	@result		Returns an IntRect reprensenting the rectangle selection's true
				rectangle in the overlay's co-ordinates.
*/
- (IntRect)trueLocalRect;

/*!
	@method		globalRect
	@discussion	Returns a rectangle enclosing the current selection.
	@result		Returns an IntRect reprensenting the rectangle that encloses the
				current selection in the document's co-ordinates.
*/
- (IntRect)globalRect;

/*!
	@method		localRect
	@discussion	Returns a rectangle enclosing the current selection.
	@result		Returns an IntRect reprensenting the rectangle that encloses the
				current selection in the overlay's co-ordinates.
*/
- (IntRect)localRect;

/*!
	@method		selectRect:
	@discussion Selects the given rectangle in the document (handles updates and
				undos).
	@param		selectionRect
				The rectangle to select in the overlay's co-ordinates.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectRect:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather;

/*!
	@method		selectEllipse:intermediate:
	@discussion Selects the given ellipse in the document.
	@param		selectionRect
				The rectangle containing the ellipse to select in the overlay's
				co-ordinates.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectEllipse:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather;

/*!
	@method		selectRoundedRect:intermediate:
	@discussion Selects the given rounded rectangle in the document.
	@param		selectionRect
				The rectangle containing the rounded rectangle to select in the
				overlay's co-ordinates.
	@param		radius
				An integer indicating the rounded rectangle's curve radius.
	@param		mode
				The mode of the selection (see above).
*/
- (void)selectRoundedRect:(IntRect)selectionRect radius:(int)radius mode:(int)mode feather:(int)nFeather;

/*!
	@method		selectPolyon:points:pointNum:mode:feather
	@discussion Selects the given polyon in the document.
	@param		selectionRect
 The rectangle containing the polyon to select in the
 overlay's co-ordinates.
	@param		points
 The points of the selection (see above).
 @param		pointNum
 The number of the points (see above).
	@param		mode
 The mode of the selection (see above).
 @param		feather
 The feather of the selection (see above).

 */
- (void)selectPolyon:(IntRect)selectionRect points:(IntPoint *)points pointNum:(int)nPointNumber mode:(int)mode feather:(int)nFeather;
/*!
	@method		selectOverlay:inRect:mode:
	@discussion Selects the area given by the overlay's alpha channel.
	@param		destructively
				YES if the overlay is to be destroyed during the selection, NO
				otherwise.
	@param		rect
				The rectangle contianing the section of the overlay to be
				considered for selection.
	@param		mode
				The mode of the selection (see above).
*/

- (void)selectOverlay:(MAKE_OVERLAYER_INFO)info;

/*!
	@method		selectOpaque
	@discussion	Selects the opaque parts of the active layer.
*/
- (void)selectOpaque;

/*!
	@method		moveSelection:
	@discussion	This moves the selection (but not the selection's contents) to the
				new origin.
	@param		newOrigin
				The new origin.
*/
- (void)moveSelection:(IntPoint)newOrigin;

/*!
	@method		readjustSelection
	@discussion	Readjusts the selection so it does not extend beyond the layer's
				boundaries.
*/
- (void)readjustSelection;

/*!
	@method		clearSelection
	@discussion	Makes the current selection void (don't confuse this with
				deleteSelection).
*/
- (void)clearSelection;
- (void)clearSelectionShow;

/*!
	@method		flipSelection:
	@discussion	Flips the current selection's mask in the desired manner (does
				not affect content).
	@param		type
				The type of flip (see PSFlip).
*/
- (void)flipSelection:(int)type;

/*!
	@method		invertSelection
	@discussion	Inverts the current selection (i.e. selects everything in the
				layer that is not selected or nothing if everything is
				selected).
*/
- (void)invertSelection;

/*!
	@method		selectionData
	@discussion	Returns a block of memory containing the layer data encapsulated
				by the rectangle.
	@param		premultiplied
				YES if the returned data should be premultiplied, NO otherwise.
	@result		Returns a pointer to a block of memory containing the layer data
				encapsulated by the rectangle.
*/
- (unsigned char *)selectionData:(BOOL)premultiplied;

/*!
	@method		selectionSizeMatch:
	@discussion	Compares the given size to the size of the last selection.
	@param		inp_size
				The size for comparison.
	@result		Returns YES if the size is equal to the size of the last selection,
				NO otherwise.
*/
- (BOOL)selectionSizeMatch:(IntSize)inp_size;

/*!
	@method		selectionPoint
	@discussion	Returns the point from which the last selection was copied.
	@result		Returns an IntPoint indicating the point from which the last
				selection was copied.
*/
- (IntPoint)selectionPoint;

/*!
	@method		cutSelection
	@discussion	Calls copySelection followed by deleteSelection.
*/
- (void)cutSelection;

/*!
	@method		copySelection
	@discussion	Copies the current selection to the clipboard.
*/
- (void)copySelection;

/*!
	@method		deleteSelection
	@discussion	Deletes the contents of the current selection from the active
				layer (don't confuse this with clearSelection).
*/
- (void)deleteSelection;

/*!
	@method		adjustOffset:
	@discussion	Adjusts the offset of the selection rectangle.
	@param		offset
				An IntPoint representing the adjustment in the offset of the
				selection rectangle.
*/
- (void)adjustOffset:(IntPoint)offset;

/*!
	@method		scaleSelectionHorizontally:vertically:
	@discussion	Scales the current selection.
	@param		xScale
				The scaling to be done horizontally on the selection.
	@param		yScale
				The scaling to be done vertically on the selection.
	@param		interpolation
				The interpolation to be used when scaling (see GIMPCore).
*/
- (void)scaleSelectionHorizontally:(float)xScale vertically:(float)yScale interpolation:(int)interpolation;

/*!
	@method		scaleSelectionTo:from:interpolation:usingMask:
	@discussion	Scales the current selection.
	@param		newRect
				The rectangle of the new selection.
	@param		oldRect
				The rectangle of the old selection.
	@param		interpolation
				The interpolation to be used when scaling (see GIMPCore).
	@param		oldMask
				The mask that should be scaled to the newRect.
*/
- (void)scaleSelectionTo:(IntRect)newRect from:(IntRect)oldRect interpolation:(int)interpolation usingMask:(unsigned char*)oldMask;

/*!
	@method		trimSelection
	@discussion	Trims the selection so it contains no redundant parts, that is,
				so every line in the mask contains some white.
*/
- (void)trimSelection;

@end

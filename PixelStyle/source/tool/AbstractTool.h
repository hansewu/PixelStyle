#import "Globals.h"

/*!
	@class		AbstractTool
	@abstract	Acts as a base class for all tools.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#define BLOCKCOUNT_BRUSHTOOL 100
#define BLOCKSIZE_BRUSHTOOL 256

@class AbstractOptions;

@interface AbstractTool : NSObject {

	// The document associated with this tool
	IBOutlet id m_idDocument;
	
	// The options associated with this tool
	AbstractOptions* m_idOptions;
	
	// Is the selection being made
	BOOL m_bIntermediate;
    
    //add by lcz, overlayOpacity
    int m_brushAlpha;
    int m_overlayBehaviour;
    unsigned char *m_layerRawData;
    unsigned char m_blockInfo[BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL];
    volatile IntRect m_dataChangedRect;
	
    NSCursor *m_cursor, *m_curNoop;
    
    NSString *m_strToolTips;
    
    NSMutableArray *m_arrViewsAbovePSView;
}

/*!
	@method		toolId
	@discussion	For determining the type of a tool based on the object.
				This method must be defined by subclasses.
	@result		Returns an element of the k...Tool enum
*/
- (int)toolId;
-(NSString *)toolTip;
-(NSString *)toolShotKey;
/*!
	@method		setOptions:
	@discussion	Sets the options for this tool.
	@param		newOptions
				The options to set.
*/
- (void)setOptions:(id)newOptions;

/*!
	@method		acceptsLineDraws
	@discussion	Returns whether or not this tool wants to allow line draws.
	@result		Returns YES if the tool does want to allow line draws, NO
				otherwise. The implementation in this class always returns NO.
*/
- (BOOL)acceptsLineDraws;

/*!
	@method		useMouseCoalescing
	@discussion	Returns whether or not this tool should use mouse coalescing.
	@result		Returns YES if this tool should use mouse coalescing, NO
				otherwise. The implementation in this class always returns YES.
*/
- (BOOL)useMouseCoalescing;

/*!
	@method		foregroundIsTexture
	@discussion	Returns whether the foreground colour should is the active
				texture.
	@result		Returns YES if the foreground colour is the active texture, NO
				otherwise. The implementation in this class always returns NO.
*/
- (BOOL)foregroundIsTexture;

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
	 @method		intermediate
	 @discussion	This is used to detect if there is currently a mouse drag
	 @result		Returns a BOOL: YES if there is currently an action being made.
*/
- (BOOL) intermediate;

/*!
	@method		isFineTool
	@discussion	Returns whether the tool needs an NSPoint input as opposed to an IntPoint
				input (i.e. whether fineMouse... or mouse... should be called).
	@result		Returns YES if the tool needs an NSPoint input as opposed to an IntPoint
				input, NO otherwise. The implementation in this class always returns NO.
*/
- (BOOL)isFineTool;

//add by lcz
- (void)copyRawDataToTempInRect:(IntRect)rect;
- (void)combineWillBeProcessDataRect:(IntRect)srcRect;

- (void)drawToolExtra;
- (NSMutableArray *)getToolPreviewEnabledLayer;//default nil
- (void)drawLayerToolPreview:(RENDER_CONTEXT_INFO)contextInfo layerid:(id)layer;

- (void)layerAttributesChanged:(int)nLayerType; //	nLayerType : kActiveLayer = -1, kAllLayers = -2, kLinkedLayers = -3
- (BOOL)isSupportLayerFormat:(int)nLayerFormat;


-(void)checkCurrentLayerIsSupported;

//add by wyl
-(BOOL)enterTool;
-(BOOL)exitTool:(int)newTool;

- (BOOL)validateMenuItem:(id)menuItem;
- (BOOL)canResponseForView:(id)view;
-(BOOL)isAffectedBySelection;
-(BOOL)showSelectionBoundaries;

- (NSMutableArray *)arrViewsAbovePSView;

- (void)resetCursorRects;

- (BOOL)updateCursor:(NSEvent *)event;

- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event;

- (BOOL)stopCurrentOperation;
- (BOOL)deleteKeyPressed;
- (BOOL)enterKeyPressed;
- (BOOL)moveKeyPressedOffset:(NSPoint)offset needUndo:(BOOL)undo;

@end

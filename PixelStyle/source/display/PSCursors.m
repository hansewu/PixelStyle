#import "PSCursors.h"
#import "PSTools.h"
#import "AbstractOptions.h"
#import "AbstractSelectOptions.h"
#import "PSSelection.h"
#import "PSController.h"
#import "PSDocument.h"
#import "PSView.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSLayer.h"
#import "PSContent.h"
#import "OptionsUtility.h"
#import "BrushOptions.h"
#import "PencilOptions.h"
#import "PositionTool.h"
#import "CropTool.h"
#import "PositionOptions.h"

@implementation PSCursors

- (id)initWithDocument:(id)newDocument andView:(id)newView
{
	m_psDocument = newDocument;
	m_psView = newView;
	/* Set-up the cursors */
	// Tool Specific Cursors
	m_curCrosspoint = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curCrosspoint setOnMouseEntered:YES];
	m_curWand = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"wand-cursor"] hotSpot:NSMakePoint(2, 2)];
	[m_curWand setOnMouseEntered:YES];
	m_curZoom = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(5, 6)];
	[m_curZoom setOnMouseEntered:YES];
	m_curPencil = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"pencil-cursor"] hotSpot:NSMakePoint(3, 15)];
	[m_curPencil setOnMouseEntered:YES];
	m_curBrush = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"brush-cursor"] hotSpot:NSMakePoint(1, 14)];
	[m_curBrush setOnMouseEntered:YES];
	m_curBucket = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"bucket-cursor"] hotSpot:NSMakePoint(14, 14)];
	[m_curBucket setOnMouseEntered:YES];
	m_curEyedrop = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eyedrop-cursor"] hotSpot:NSMakePoint(1, 14)];
	[m_curEyedrop setOnMouseEntered:YES];
	m_curMove = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curMove setOnMouseEntered:YES];
	m_curEraser = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eraser-cursor"] hotSpot:NSMakePoint(2, 12)];
    [m_curEraser setOnMouseEntered:YES];
	m_curSmudge = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"smudge-cursor"] hotSpot:NSMakePoint(1, 15)];
	[m_curSmudge setOnMouseEntered:YES];
	m_curEffect = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"effect-cursor"] hotSpot:NSMakePoint(1, 1)];
	[m_curSmudge setOnMouseEntered:YES];
	m_curNoop = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"noop-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curNoop setOnMouseEntered:YES];
    
	// Additional Cursors
	m_curAdd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-add-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curAdd setOnMouseEntered:YES];
	m_curSubtract = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subtract-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curSubtract setOnMouseEntered:YES];
	m_curClose = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-close-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curClose setOnMouseEntered:YES];
	m_curResize = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curResize setOnMouseEntered:YES];
	m_curRotate = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"rotate-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curRotate setOnMouseEntered:YES];
	m_curAnchor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"anchor-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curAnchor setOnMouseEntered:YES];
    
	// View Generic Cursors
	m_curHand = [NSCursor openHandCursor];
	[m_curHand setOnMouseEntered:YES];
	m_curGrab = [NSCursor closedHandCursor];
	[m_curGrab setOnMouseEntered:YES];
	m_curLr = [NSCursor resizeLeftRightCursor];
	[m_curLr setOnMouseEntered:YES];
	m_curUd = [NSCursor resizeUpDownCursor];
	[m_curUd setOnMouseEntered:YES];
	m_curUrdl = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-ne-sw-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curUrdl setOnMouseEntered:YES];
	m_curUldr = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-nw-se-cursor"] hotSpot:NSMakePoint(7, 7)];
	[m_curUldr setOnMouseEntered:YES];
	
	m_curHandleCursors[0]  = m_curUldr;
	m_curHandleCursors[1] = m_curUd;
	m_curHandleCursors[2] = m_curUrdl;
	m_curHandleCursors[3] = m_curLr;
	m_curHandleCursors[4] = m_curUldr;
	m_curHandleCursors[5] = m_curUd;
	m_curHandleCursors[6] = m_curUrdl;
	m_curHandleCursors[7] = m_curLr;
    m_curHandleCursors[8] = [NSCursor arrowCursor];
	
	m_bScrollingMode = NO;
	m_bScrollingMouseDown = NO;
	
	return self;
}

- (void)dealloc
{
	if (m_curCrosspoint) [m_curCrosspoint autorelease];
	if (m_curWand) [m_curWand autorelease];
	if (m_curZoom) [m_curZoom autorelease];
	if (m_curPencil) [m_curPencil autorelease];
	if (m_curBrush) [m_curBrush autorelease];
	if (m_curBucket) [m_curBucket autorelease];
	if (m_curEyedrop) [m_curEyedrop autorelease];
	if (m_curMove) [m_curMove autorelease];
	if (m_curEraser) [m_curEraser autorelease];
	if (m_curSmudge) [m_curSmudge autorelease];
    if (m_curEffect) [m_curEffect autorelease];
	if (m_curNoop) [m_curNoop autorelease];
	if (m_curAdd) [m_curAdd autorelease];
	if (m_curSubtract) [m_curSubtract autorelease];
	if (m_curClose) [m_curClose autorelease];
	if (m_curResize) [m_curResize autorelease];
	if (m_curRotate) [m_curRotate autorelease];
	if (m_curAnchor) [m_curAnchor autorelease];
	if (m_curUrdl) [m_curUrdl autorelease];
	if (m_curUldr) [m_curUldr autorelease];
    
	[super dealloc];
}

- (void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor
{
	NSScrollView *scrollView = (NSScrollView *)[[m_psView superview] superview];
	
	// Convert to the scrollview's origin
	rect.origin = [scrollView convertPoint: rect.origin fromView: m_psView];
	
	// Clip to the centering clipview
	NSRect clippedRect = NSIntersectionRect([[m_psView superview] frame], rect);

	// Convert the point back to the seaview
	clippedRect.origin = [m_psView convertPoint: clippedRect.origin fromView: scrollView];
	[m_psView addCursorRect:clippedRect cursor:cursor];
}

- (void)resetCursorRects
{
	if(m_bScrollingMode){
		if(m_bScrollingMouseDown)
			[self addCursorRect:[m_psView frame] cursor:m_curGrab];
		else
			[self addCursorRect:[m_psView frame] cursor:m_curHand];
		return;
	}
	
	int tool = [[[PSController utilitiesManager] toolboxUtilityFor:m_psDocument] tool];
    AbstractTool* curTool = [[m_psDocument tools] getTool:tool];
    [curTool resetCursorRects];
    return;
    
    
	PSLayer *activeLayer = [[m_psDocument contents] activeLayer];
	float xScale = [[m_psDocument contents] xscale];
	float yScale = [[m_psDocument contents] yscale];
	NSRect operableRect;
	IntRect operableIntRect;
	
	operableIntRect = IntMakeRect([activeLayer xoff] * xScale, [activeLayer yoff] * yScale, [activeLayer width] * xScale, [activeLayer height] *yScale);
	operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([m_psView frame]), operableIntRect));

//	if(tool >= kFirstSelectionTool && tool <= kLastSelectionTool){
//		// Find out what the selection mode is
//		int selectionMode = [(AbstractSelectOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_psDocument] getOptions:tool] selectionMode];
//		
//		if(selectionMode == kAddMode){
//			[self addCursorRect:operableRect cursor:m_curAdd];
//		}else if (selectionMode == kSubtractMode) {
//			[self addCursorRect:operableRect cursor:m_curSubtract];
//		}else if(selectionMode != kDefaultMode){
//			[self addCursorRect:operableRect cursor:m_curCrosspoint];
//		}else{
//
//			// Now we need the handles and the hand
//			if([[m_psDocument selection] active]){
//				NSRect selectionRect = IntRectMakeNSRect([[m_psDocument selection] globalRect]);
//				selectionRect = NSMakeRect(selectionRect.origin.x * xScale, selectionRect.origin.y * yScale, selectionRect.size.width * xScale, selectionRect.size.height * yScale);
//
//				[self addCursorRect:NSConstrainRect(selectionRect,[m_psView frame]) cursor:m_curHand];
//				int i;
//				for(i = 0; i < 8; i++){
//					[self addCursorRect:m_recHandleRects[i] cursor:m_curHandleCursors[i]];
//				}
//				
//			}
//            
//            [self addCursorRect:operableRect cursor:m_curCrosspoint];
//		}
//		
//		if(tool == kPolygonLassoTool && m_recClose.size.width > 0 && m_recClose.size.height > 0){
//			[self addCursorRect:m_recClose cursor: m_curClose];
//		}
//	}else if(tool == kCropTool){
//		NSRect cropRect;
//		IntRect origRect;
//		[self addCursorRect:[m_psView frame] cursor:m_curCrosspoint];
//		
//		origRect = [(CropTool *)[[m_psDocument tools] currentTool] cropRect];
//		cropRect = NSMakeRect(origRect.origin.x * xScale, origRect.origin.y * yScale, origRect.size.width * xScale, origRect.size.height * yScale);
//		
//		if (cropRect.size.width != 0 && cropRect.size.height != 0){
//				
//			[self addCursorRect:NSConstrainRect(cropRect,[m_psView frame]) cursor:m_curHand];
//			int i;
//			for(i = 0; i < 8; i++){
//				[self addCursorRect:m_recHandleRects[i] cursor:m_curHandleCursors[i]];
//			}
//		}
//	}else if (tool == kPositionTool) {
////		NSRect cropRect;
////		IntRect origRect;
////
////		[self addCursorRect:[m_psView frame] cursor:m_curMove];
////		
////		origRect =IntConstrainRect(NSRectMakeIntRect([m_psView frame]), operableIntRect);
////		cropRect = NSMakeRect(origRect.origin.x * xScale, origRect.origin.y * yScale, origRect.size.width * xScale, origRect.size.height * yScale);
////		
////		if (cropRect.size.width != 0 && cropRect.size.height != 0){
////			
////			[self addCursorRect:NSConstrainRect(cropRect,[m_psView frame]) cursor:m_curHand];
////			int i;
////			for(i = 0; i < 8; i++){
////				[self addCursorRect:m_recHandleRects[i] cursor:m_curHandleCursors[i]];
////			}
////		}
//	}else
{

		// If there is currently a selection, then users can operate in there only
		if([[m_psDocument selection] active]){
			operableIntRect = [[m_psDocument selection] globalRect];
			operableIntRect = IntMakeRect(operableIntRect.origin.x * xScale, operableIntRect.origin.y * yScale, operableIntRect.size.width * xScale, operableIntRect.size.height * yScale);
			operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([m_psView frame]), operableIntRect));
		
		}
		
		switch (tool) {
			case kZoomTool:
				[self addCursorRect:[m_psView frame] cursor:m_curZoom];
				break;
			case kPencilTool:
				[self addCursorRect:operableRect cursor:m_curPencil];
				break;
            case kMyBrushTool:
			case kBrushTool:
				[self addCursorRect:operableRect cursor:m_curBrush];
				break;
			case kBucketTool:
				[self addCursorRect:operableRect cursor:m_curBucket];
				break;
			case kTextTool:
				[self addCursorRect:operableRect cursor:[NSCursor IBeamCursor]];
				break;
			case kEyedropTool:
				[self addCursorRect:[m_psView frame] cursor:m_curEyedrop];
				break;
			case kEraserTool:
				[self addCursorRect:operableRect cursor:m_curEraser];
				break;
			case kGradientTool:
				[self addCursorRect:[m_psView frame] cursor:m_curCrosspoint];
				break;
			case kSmudgeTool:
				[self addCursorRect:[m_psView frame] cursor:m_curSmudge];
				break;
			case kCloneTool:
				[self addCursorRect:[m_psView frame] cursor:m_curBrush];
				break;
			case kEffectTool:
				[self addCursorRect:[m_psView frame] cursor:m_curEffect];
				break;
            case kTransformTool:
                //[self addCursorRect:[m_psView frame] cursor:m_curEffect];
                break;
			default:
//				[self addCursorRect:operableRect cursor:NULL];
            {
                AbstractTool* curTool = [[m_psDocument tools] getTool:tool];
                [curTool resetCursorRects];
            }
				break;
		}
		
	}

	if(tool == kBrushTool && [(BrushOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_psDocument] getOptions:tool] brushIsErasing]){
		// Do we need this?
		//[m_psView removeCursorRect:operableRect cursor:m_curBrush];
		[self addCursorRect:operableRect cursor:m_curEraser];
	}else if (tool == kPencilTool && [(PencilOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_psDocument] getOptions:tool] pencilIsErasing]){
		// Do we need this?
		//[m_psView removeCursorRect:operableRect cursor:m_curPencil];
		[self addCursorRect:operableRect cursor:m_curEraser];
	}/*else if (tool == kPositionTool){
		PositionOptions *options = (PositionOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_psDocument] getOptions:tool];
		if([options toolFunction] == kScalingLayer){
			[self addCursorRect:[m_psView frame] cursor:m_curResize];
		}else if([options toolFunction] == kRotatingLayer){
			[self addCursorRect:[m_psView frame] cursor:m_curRotate];
		}else if([options toolFunction] == kMovingLayer){
			[self addCursorRect:[m_psView frame] cursor:m_curMove];
		}
	}*/
	
	
	// Some tools can operate outside of the selection rectangle
//    if(tool != kZoomTool && tool != kEyedropTool && tool != kGradientTool && tool != kSmudgeTool && tool != kCloneTool && tool != kCropTool && tool != kEffectTool && tool != kPositionTool)
	if(tool == kPencilTool || tool == kBrushTool || tool == kBucketTool || tool == kMyBrushTool || tool == kBrushTool){
		// Now we need the noop section		
		if(operableRect.origin.x > 0){
			NSRect leftRect = NSMakeRect(0,0,operableRect.origin.x,[m_psView frame].size.height);
			[self addCursorRect:leftRect cursor:m_curNoop];
		}
		float rightX = operableRect.origin.x + operableRect.size.width; 
		if(rightX < [m_psView frame].size.width){
			NSRect rightRect = NSMakeRect(rightX, 0, [m_psView frame].size.width - rightX, [m_psView frame].size.height);
			[self addCursorRect:rightRect cursor:m_curNoop];
		}
		if(operableRect.origin.y > 0){
			NSRect bottomRect = NSMakeRect(0, 0, [m_psView frame].size.width, operableRect.origin.y);
			[self addCursorRect:bottomRect cursor:m_curNoop];
		}
		float topY = operableRect.origin.y + operableRect.size.height;
		if(topY < [m_psView frame].size.height){
			NSRect topRect = NSMakeRect(0, topY, [m_psView frame].size.width, [m_psView frame].size.height - topY);
			[self addCursorRect:topRect cursor:m_curNoop];
		}
	}
}

- (NSRect *)handleRectsPointer
{
	return m_recHandleRects;
}

- (void)setCloseRect:(NSRect)rect
{
	m_recClose = rect;
}

- (void)setScrollingMode:(BOOL)inMode mouseDown:(BOOL)mouseDown
{
	m_bScrollingMode = inMode;
	m_bScrollingMouseDown = mouseDown;	
}

@end

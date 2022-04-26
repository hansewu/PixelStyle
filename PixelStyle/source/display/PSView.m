#import "PSView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "UtilitiesManager.h"
#ifdef USE_CENTERING_CLIPVIEW
#import "CenteringClipView.h"
#endif
#import "TransparentUtility.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSLayer.h"
#import "PSTextLayer.h"
#import "ToolboxUtility.h"
#import "ColorSelectView.h"
#import "PSWhiteboard.h"
#import "PSTools.h"
#import "PositionTool.h"
#import "PencilTool.h"
#import "BrushTool.h"
#import "PSLayerUndo.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "Units.h"
#import "PSPrintView.h"
#import "PositionTool.h"
#import "InfoUtility.h"
#import "OptionsUtility.h"
#import "BrushOptions.h"
#import "PositionOptions.h"
#import "RectSelectOptions.h"
#import "CloneTool.h"
#import "LassoTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "PolygonLassoTool.h"
#import "CropTool.h"
#import "WandTool.h"
#import "PSWarning.h"
#import "EffectTool.h"
#import "GradientTool.h"
#import "PSFlip.h"
#import "PSOperations.h"
#import "PSCursors.h"
#import "AspectRatio.h"
#import "WarningsUtility.h"
#import "PSScale.h"
#import "NSEvent_Extensions.h"
#import <Carbon/Carbon.h>
#import "GraphicsToBuffer.h"
#import "PSTransformTool.h"
#import "PSSynthesizeImageRender.h"
#import "PSVectorPenTool.h"
#import "MyBrushOptions.h"
#import "PSMenuManager.h"

extern IntPoint gScreenResolution;

static NSString*	SelectNoneToolbarItemIdentifier = @"Select None Toolbar Item Identifier";
static NSString*	SelectAllToolbarItemIdentifier = @"Select All Toolbar Item Identifier";
static NSString*	SelectInverseToolbarItemIdentifier = @"Select Inverse Toolbar Item Identifier";
static NSString*	SelectAlphaToolbarItemIdentifier = @"Select Alpha Toolbar Item Identifier";

@implementation PSView

- (void)addOtherMenu
{
    PSMenuManager *menuManager = [PSMenuManager getMenuManager];
    
    NSMenuItem *menuItem = [[menuManager getMenuSelection] itemWithTitle:NSLocalizedString(@"Selection to Alpha channel", nil)];
    if (menuItem == nil)
    {
        menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Selection to Alpha channel", nil) action:@selector(selectionToAlpha:) keyEquivalent:@""];
        [[menuManager getMenuSelection] addItem:menuItem];
        [menuItem autorelease];
    }
    
    [menuItem setTarget:self];
    
//    [submenu addItem:];
//    [menuItem setTag:i + 10000];
    
}

- (id)initWithDocument:(id)doc 
{
	NSRect frame;
	int xres, yres;
	
    //[self addOtherMenu];
	// Set the last ruler update to take place in the distant past
	m_dateLastRulerUpdate = [NSDate distantPast];
	[m_dateLastRulerUpdate retain];
	
	// Remember the m_idDocument this view is displaying
	m_idDocument = doc;
	
	// Determine the frame at 100% 72-dpi
	frame = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width], [(PSContent *)[m_idDocument contents] height]);

	// Adjust frame for non 72 dpi resolutions
	xres = [[m_idDocument contents] xres];
	yres = [[m_idDocument contents] yres];
//	if (gScreenResolution.x != 0 && xres != gScreenResolution.x){
//		frame.size.width /= ((float)xres / gScreenResolution.x);
//	}
//	
//	if (gScreenResolution.y != 0 && yres != gScreenResolution.y) {
//		frame.size.height /= ((float)yres / gScreenResolution.y);
//	}
    
    float maxDif = 0.000001f;
    if (ABS(gScreenResolution.x - 0) > maxDif && ABS(xres - 0) > maxDif && ABS(xres - gScreenResolution.x) > maxDif){
        frame.size.width /= ((float)xres / gScreenResolution.x);
    }
    
    if (ABS(gScreenResolution.y - 0) > maxDif && ABS(yres - 0) > maxDif && ABS(yres - gScreenResolution.y) > maxDif) {
        frame.size.height /= ((float)yres / gScreenResolution.y);
    }

	// Initialize superclass
	if ([super initWithFrame:frame] == NULL){
		return NULL;
	}
	
	// Set data members appropriately
	m_bLineDraw = NO;
	m_bKeyWasUp = YES;
	m_bScrollingMode = NO;
	m_timScrollTimer = NULL;
	m_timMagnifyTimer = NULL;
	m_fMagnifyFactor = 1.0;
	m_nTabletEraser = 0;
	m_nEyedropToolMemory = kEyedropTool;
	m_fScrollZoom = m_fLastTrigger = 0.0;
	
	// Set the delta
	m_sDelta = IntMakePoint(0,0);
	
	// Set the zoom appropriately
	m_nZoomIndex = 6;
    m_fZoom = m_fPrevZoom = 1.0;
	
	// Create the cursors manager
	m_idCursorsManager = [[PSCursors alloc] initWithDocument: doc andView: self];
	
	// Register for drag operations
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NSFilenamesPboardType, nil]];
	
	// Set up the rulers
	[[m_idDocument scrollView] setHasHorizontalRuler:YES];
	[[m_idDocument scrollView] setHasVerticalRuler:YES];
	m_rvHorizontalRuler = [[m_idDocument scrollView] horizontalRulerView];
	m_rvVerticalRuler = [[m_idDocument scrollView] verticalRulerView];
	[self updateRulers];
	
	// Change the ruler client views
	[m_rvVerticalRuler setClientView:[m_idDocument scrollView]];
	[m_rvHorizontalRuler setClientView:[m_idDocument scrollView]];
	[[m_idDocument scrollView] retain];
	
	// Add the markers
	m_rmVMarker = [[NSRulerMarker alloc]initWithRulerView:m_rvVerticalRuler markerLocation:0 image:[NSImage imageNamed:@"vMarker"] imageOrigin:NSMakePoint(4.0,4.0)];
	[m_rvVerticalRuler addMarker:m_rmVMarker];
	[m_rmVMarker autorelease];
	m_rmHMarker = [[NSRulerMarker alloc]initWithRulerView:m_rvHorizontalRuler markerLocation:0 image:[NSImage imageNamed:@"hMarker"] imageOrigin:NSMakePoint(4.0,0.0)];
	[m_rvHorizontalRuler addMarker:m_rmHMarker];
	[m_rmHMarker autorelease];
	m_rmVStatMarker = [[NSRulerMarker alloc]initWithRulerView:m_rvVerticalRuler markerLocation:-256e6 image:[NSImage imageNamed:@"vStatMarker"] imageOrigin:NSMakePoint(4.0,4.0)];
	[m_rvVerticalRuler addMarker:m_rmVStatMarker];
	[m_rmVStatMarker autorelease];
	m_rmHStatMarker = [[NSRulerMarker alloc]initWithRulerView:m_rvHorizontalRuler markerLocation:-256e6 image:[NSImage imageNamed:@"hStatMarker"] imageOrigin:NSMakePoint(4.0,0.0)];
	[m_rvHorizontalRuler addMarker:m_rmHStatMarker];
	[m_rmHStatMarker autorelease];
	
	// Make the rulers visible/invsible
	[self updateRulersVisiblity];
	
	// Warn if bad resolution
	if (xres != yres || (xres < 72)) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"strange res message", @"This image has an unusual resolution. As such, it may look different to what is expected at 100% zoom. To fix this use \"Image > Resolution...\" and set to 72 x 72 dpi.") forDocument: m_idDocument level:kLowImportance];
	}
	else if (xres > 300) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"high res message", @"This image has a high resolution. PixelStyle's performance may therefore be reduced. You can reduce the resolution using \"Image > Resolution...\" (with \"Preserve size\" checked). This will result in a lower-quality image.") forDocument: m_idDocument level:kLowImportance];
	}
    
//    m_sSelectBoundPoints.points = malloc(kMaxPoints * sizeof(IntPoint));
//    m_sSelectBoundPoints.nPointNumber = 0;
    m_maSelectBoundPoints = [[NSMutableArray alloc] initWithCapacity:5];
    m_bUpdateBoundPoints = true;
    m_bRefreshWhiteboardImage = true;

    m_timerLoopDrawSelectBoundaries = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(LoopDrawSelectBoundaries) userInfo:nil repeats:YES];

    NSLog(@"m_synthesizeImageRender = nil to test");
    m_synthesizeImageRender = nil;//[[PSSynthesizeImageRender alloc] initWithDocument:m_idDocument];
    m_needResetCombine = YES;
    m_cgLayerCache = nil;
    
    [self performSelector:@selector(delayAddObserver) withObject:nil afterDelay:0.5];
    
    return self;
}



- (void)delayAddObserver
{
    [self zoomToFit];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawOuterSelection:) name:@"DRAWOUTERSELECTION" object:nil];
}

- (void)dealloc
{
    if(m_maSelectBoundPoints)
        [m_maSelectBoundPoints release];
    if(m_cgLayerCache)
        CGLayerRelease(m_cgLayerCache);
    CGLayerRelease(m_cgLayerWhiteboardImage);
    
    if(m_synthesizeImageRender){
        [m_synthesizeImageRender release];
        m_synthesizeImageRender = nil;
    }
    
    
    [m_idCursorsManager release];
    
	[super dealloc];
}

-(void)stopDrawSelectionBoundariesTimer
{
    [m_timerLoopDrawSelectBoundaries setFireDate:[NSDate distantFuture]];
}

-(void)restoreDrawSelectionBoundariesTimer
{
    [m_timerLoopDrawSelectBoundaries setFireDate:[NSDate distantPast]];
}

- (IBAction)changeSpecialFont:(id)sender
{
	[[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kTextTool] changeFont:sender];
}

- (void)needsCursorsReset
{
	// Tell the parent that the cursors need to be invalidated
	[[self window] invalidateCursorRectsForView:self];
}
	
- (void)resetCursorRects
{
	// Inform the cursor manager that we will need the new cursor rects
	[m_idCursorsManager resetCursorRects];
}

static float s_Zoom[] = {0.05, 0.10, 0.15, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0,7.0, 8.0, 10.0, 12.0, 16.0, 25.0, 32.0};
- (BOOL)canZoomIn
{
    return (m_fZoom < 32.0);//(m_nZoomIndex <= sizeof(s_Zoom)/sizeof(float)-1);//(zoom <= 32.0);
}

- (BOOL)canZoomOut
{
	return (m_fZoom > 0.05);//(m_nZoomIndex >= 1);//(zoom >= 1.0 / 32.0);
}

- (void)zoomToFit
{
    CGFloat fImageShowWidth, fImageShowHeight;
    
    fImageShowWidth  = (float)[(PSContent *)[m_idDocument contents] width];
    fImageShowHeight = (float)[(PSContent *)[m_idDocument contents] height];
    
    if (gScreenResolution.x != 0 && [[m_idDocument contents] xres] != gScreenResolution.x) fImageShowWidth /= ((CGFloat)[[m_idDocument contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[m_idDocument contents] yres] != gScreenResolution.y) fImageShowHeight /= ((CGFloat)[[m_idDocument contents] yres] / gScreenResolution.y);
    
    NSRect clipRect = [(NSClipView *)[self superview] bounds];
    
    CGFloat fRatio = MIN(clipRect.size.width/fImageShowWidth, clipRect.size.height/fImageShowHeight);
    
#ifdef USE_CENTERING_CLIPVIEW
    NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
#else
    NSPoint point = NSMakePoint(0, 0);
#endif
    
    for (int nIndex = sizeof(s_Zoom)/sizeof(float) - 1; nIndex >= 0; nIndex--)
    {
        if(s_Zoom[nIndex] < fRatio)
        {
            m_fZoom = s_Zoom[nIndex];
            break;
        }
    }
    
    [self dealZoom:point];
    
}

- (void)zoomToActualSize
{
    NSRect frame;
    
    m_nZoomIndex = 6;//zoom = 1.0;
    m_fZoom = 1.0;
    [self updateRulers];
    frame = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width], [(PSContent *)[m_idDocument contents] height]);
    if (gScreenResolution.x != 0 && [[m_idDocument contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[m_idDocument contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[m_idDocument contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[m_idDocument contents] yres] / gScreenResolution.y);
    [(NSClipView *)[self superview] scrollToPoint:NSMakePoint(0, 0)];
    [self setFrame:frame];
#ifdef USE_CENTERING_CLIPVIEW
    [(CenteringClipView *)[self superview] setCenterPoint:NSMakePoint(frame.size.width / 2.0, frame.size.height / 2.0)];
#else
    [(NSClipView *)[self superview] scrollToPoint:point];
#endif
    [self setNeedsDisplay:YES];
    [[m_idDocument helpers] zoomChanged];

}
- (IBAction)zoomNormal:(id)sender
{
    [self zoomToFit];
    
    return;
    
}

- (IBAction)zoomIn:(id)sender
{	
	#ifdef USE_CENTERING_CLIPVIEW
	NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
	#else
	NSPoint point = NSMakePoint(0, 0);
	#endif
    
	[self zoomInToPoint:point];
}


- (void)zoomTo:(float)power
{
    if(power > 32.0 || (power < 0.05)) return;
    
	NSPoint point = NSZeroPoint;
	#ifdef USE_CENTERING_CLIPVIEW
	point = [(CenteringClipView *)[self superview] centerPoint];
	#else
	point = NSMakePoint(0, 0);
	#endif
	
    m_fPrevZoom = m_fZoom;
    m_fZoom = power;
    [self dealZoom:point];
    
}

- (void)zoomInToPoint:(NSPoint)point
{
    m_fPrevZoom = m_fZoom;
    
    if(m_fZoom >= 32.0)
        return;
    
    for (int nIndex = 0; nIndex <= sizeof(s_Zoom)/sizeof(float) - 1; nIndex++)
    {
        if(s_Zoom[nIndex] > m_fZoom)
        {
            m_fZoom = s_Zoom[nIndex];
            break;
        }
    }

    [self dealZoom:point];
}

- (IBAction)zoomOut:(id)sender
{
	#ifdef USE_CENTERING_CLIPVIEW
	NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
	#else
	NSPoint point = NSMakePoint(0, 0);
	#endif
	
	[self zoomOutFromPoint:point];
}

- (void)zoomOutFromPoint:(NSPoint)point
{
    m_fPrevZoom = m_fZoom;
    
    if(m_fZoom <= 0.05)
        return;
    
    for (int nIndex = sizeof(s_Zoom)/sizeof(float) - 1; nIndex >= 0; nIndex--)
    {
        if(s_Zoom[nIndex] < m_fZoom)
        {
            m_fZoom = s_Zoom[nIndex];
            break;
        }
    }
    
    [self dealZoom:point];
}

-(void)dealZoom:(NSPoint)point
{
    NSRect frame;
    
    NSPoint centerPoint = [(CenteringClipView *)[self superview] centerPoint];
    
    NSPoint pointOffset = NSMakePoint(point.x - centerPoint.x, point.y - centerPoint.y);
 //   pointOffset.x = pointOffset.x * m_fZoom/m_fPrevZoom;
 //   pointOffset.y = pointOffset.y * m_fZoom/m_fPrevZoom;
    
    point.x = point.x * m_fZoom/m_fPrevZoom;
    point.y = point.y * m_fZoom/m_fPrevZoom;
    
    //zoom /= 2.0; point.x = roundf(point.x / 2.0); point.y = roundf(point.y / 2.0);
    [self updateRulers];
    frame = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width], [(PSContent *)[m_idDocument contents] height]);
    
    if (gScreenResolution.x != 0 && [[m_idDocument contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[m_idDocument contents] xres] / gScreenResolution.x);
    if (gScreenResolution.y != 0 && [[m_idDocument contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[m_idDocument contents] yres] / gScreenResolution.y);
    
    frame.size.height *= m_fZoom;
    frame.size.width *= m_fZoom;
    [self setFrame:frame];
    
    point.x = point.x - pointOffset.x;
    point.y = point.y - pointOffset.y;
#ifdef USE_CENTERING_CLIPVIEW
    [(CenteringClipView *)[self superview] setCenterPoint:point];
#else
    [(NSClipView *)[self superview] scrollToPoint:point];
#endif
    
    //    [self setRefreshWhiteboardImage:NO];
    [self setNeedsDisplay:YES];
    [[m_idDocument helpers] zoomChanged];
}



- (float)zoom
{
    return m_fZoom;//s_Zoom[m_nZoomIndex];//zoom;
}

-(int)zoomIndex
{
    return m_nZoomIndex;
}

//- (void)drawRect:(NSRect)rect
//{
//    NSLog(@"PSView drawRect %@",NSStringFromRect(rect));
//    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//    assert(context);
//    
//    //画背景
//    [self drawBackground:rect];
//
////    画图片
////    整个刷时，才保存到层，刷新某个rect时，不保存到层，因为即使保存，也不能用，只是某个区域，还是需要整个区域。另外每次保存到层也是有损耗的，所以刷某个rect时，反正也不能用，就直接刷上，不采用保存到层的机制
//    if( (!m_bRefreshWhiteboardImage) && (!m_cgLayerWhiteboardImage))
//    {
//        if(m_cgLayerWhiteboardImage)  {
//            CGLayerRelease(m_cgLayerWhiteboardImage);
//            m_cgLayerWhiteboardImage = nil;
//        }
//        
//        m_cgLayerWhiteboardImage = CGLayerCreateWithContext(context, self.bounds.size, nil);
//        assert(m_cgLayerWhiteboardImage);
//        CGContextRef imageLayerRef = CGLayerGetContext(m_cgLayerWhiteboardImage);
//        assert(imageLayerRef);
//        
//        CGContextSaveGState(context);
//        [self drawImageLayer:rect toContext:imageLayerRef isBitmap:YES];
//        CGContextRestoreGState(context);
//        
//        
//        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:context flipped:NO]];
//        
//        NSLog(@"drawRect2");
//    }
//
//    if(NSEqualRects(rect, [self visibleRect]) && m_cgLayerWhiteboardImage && (!m_bRefreshWhiteboardImage))
//    {
//        printf("cglayer\n");
//        CGContextDrawLayerAtPoint(context, self.bounds.origin, m_cgLayerWhiteboardImage);
//    }
//    else
//    {
//        [self drawImageLayer:rect toContext:[[NSGraphicsContext currentContext] graphicsPort] isBitmap:NO];
//
//        if(m_cgLayerWhiteboardImage) { CGLayerRelease(m_cgLayerWhiteboardImage); m_cgLayerWhiteboardImage = nil; }
//    }
//    
//    
//    if(!NSEqualRects(rect, [self visibleRect]))
//        if(m_cgLayerWhiteboardImage) { CGLayerRelease(m_cgLayerWhiteboardImage); m_cgLayerWhiteboardImage = nil; }
//    
//    //画辅助线
//    // Clear out the old cursor rects
//    [self needsCursorsReset];
//    // If we aren't using the view for printing draw the boundaries and the marching ants
//    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
//    if (
//        ([[PSController m_idPSPrefs] layerBounds] && ![[m_idDocument whiteboard] whiteboardIsLayerSpecific]) ||
//        [[m_idDocument selection] active] ||
//        (curToolIndex == kCropTool) ||
//        (curToolIndex == kRectSelectTool && [(RectSelectTool *)[[m_idDocument tools] getTool: kRectSelectTool] intermediate]) ||
//        (curToolIndex == kEllipseSelectTool && [(EllipseSelectTool *)[[m_idDocument tools] getTool: kEllipseSelectTool] intermediate]) ||
//        (curToolIndex == kLassoTool && [(LassoTool *)[[m_idDocument tools] getTool:kLassoTool] intermediate]) ||
//        (curToolIndex == kPolygonLassoTool && [(PolygonLassoTool *)[[m_idDocument tools] getTool:kPolygonLassoTool] intermediate])
//        ) {
//        [self drawBoundaries];
//    }
//    [self drawExtras];   
//
//    
//    m_bRefreshWhiteboardImage = true;
//    
//    return;
//}
-(void)resetSynthesizedImageRender
{
    if(m_synthesizeImageRender)
        [m_synthesizeImageRender resetSynthesizedImageCGlayer];
    m_needResetCombine = YES;
}

- (id)getCurrentDocumnet
{
//    PSDocument *document = gCurrentDocument;
//    if (!document) {
//        document = [[[self window] windowController] document];
//    }
//    return document;
    
    return m_idDocument;
    
}

- (BOOL)getNeedResetCombineData
{
    if (m_needResetCombine) {
        m_needResetCombine = NO;
        return YES;
    }
    return NO;
}

-(BOOL) isPreviewing
{
     NSMutableArray *previewLayers = [(AbstractTool*)[[m_idDocument tools] currentTool] getToolPreviewEnabledLayer];
    
    if([previewLayers count]) return YES;
    
    return NO;
}

//- (CGLayerRef)getCombinedLayerData
//{
//    if (m_synthesizeImageRender) {
//        bool bWantUnlock;
//        CGLayerRef cgLayerWhiteboardImage = [m_synthesizeImageRender getSynthesizedImageCGlayer: &bWantUnlock];
//        return cgLayerWhiteboardImage;
//    }
//    return nil;
//}

- (void)drawRect:(NSRect)rect
{
//    NSLog(@"PSView drawRect %@",NSStringFromRect(rect));
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    assert(context);
    
    float fScaleX = [(PSContent *)[m_idDocument contents] xscale];
    float fScaleY = [(PSContent *)[m_idDocument contents] yscale];
    if (fScaleX > 5.9 || fScaleY > 5.9) {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    }else{
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);//kCGInterpolationDefault);
    }
    
    
    
    //画背景
    [self drawBackground:rect];
    
    BOOL bWantUnlock = NO;
    CGLayerRef cgLayerWhiteboardImage =  nil;//[m_synthesizeImageRender getSynthesizedImageCGlayer: &bWantUnlock];
 //   NSLog(@"cgLayerWhiteboardImage =  nil to test");

    NSRect intRect1 = CGRectIntegral([self visibleRect]);
    NSRect intRect2 = CGRectIntegral(rect);
    CGSize cglayerSize = CGLayerGetSize(cgLayerWhiteboardImage);
    int nWidth = [(PSContent *)[m_idDocument contents] width];
    //int nHeight = [(PSContent *)[m_idDocument contents] height];
    int nBoundWidth = ceilf(self.bounds.size.width);
    int nCGlayerWidth = cglayerSize.width;
    
    BOOL canUse = YES;
    if (nCGlayerWidth < nBoundWidth && nCGlayerWidth != nWidth) {
        //canUse = NO;
    }
    

    
    if(NSEqualRects(intRect1, intRect2) && cgLayerWhiteboardImage && canUse && [self isPreviewing] == NO)
    {
        CGSize desSize;
        float fScaleX = [(PSContent *)[m_idDocument contents] xscale];
        float fScaleY = [(PSContent *)[m_idDocument contents] yscale];
        if (fScaleX < 1.0) {
            desSize.width = self.bounds.size.width; //ceilf(self.bounds.size.width);
        }else{
            desSize.width = self.bounds.size.width;
        }
        if (fScaleY < 1.0) {
            desSize.height = self.bounds.size.height;//ceilf(self.bounds.size.height);
        }else{
            desSize.height = self.bounds.size.height;
        }
//        NSSize sizee = CGLayerGetSize(cgLayerWhiteboardImage);
//        NSSize sizee1 = self.bounds.size;
        //NSLog(@"%@ %@", NSStringFromSize(cglayerSize), NSStringFromSize(desSize));
        CGContextDrawLayerInRect(context, CGRectMake(0, 0, desSize.width, desSize.height), cgLayerWhiteboardImage);
        
        //CGContextDrawLayerInRect(context, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height), cgLayerWhiteboardImage);
        
        [m_synthesizeImageRender unlockSynthesizedImageCGlayer];
        
        //NSLog(@"gdsfdsfds");
    }
    else
    {
        if(bWantUnlock)  [m_synthesizeImageRender unlockSynthesizedImageCGlayer];
//        printf("\ndrawImageLayer\n");
        [self drawImageLayer:rect toContext:[[NSGraphicsContext currentContext] graphicsPort] isBitmap:NO];
        
        //NSLog(@"gdsfdsfds111 %@",NSStringFromRect(rect));
    }
    
    
    
    //画辅助线
    // Clear out the old cursor rects
    [self needsCursorsReset];
    // If we aren't using the view for printing draw the boundaries and the marching ants
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (
        ([[PSController m_idPSPrefs] layerBounds] && ![[m_idDocument whiteboard] whiteboardIsLayerSpecific]) ||
        [[m_idDocument selection] active] ||
        (curToolIndex == kCropTool) ||
        (curToolIndex == kRectSelectTool && [(RectSelectTool *)[[m_idDocument tools] getTool: kRectSelectTool] intermediate]) ||
        (curToolIndex == kEllipseSelectTool && [(EllipseSelectTool *)[[m_idDocument tools] getTool: kEllipseSelectTool] intermediate]) ||
        (curToolIndex == kLassoTool && [(LassoTool *)[[m_idDocument tools] getTool:kLassoTool] intermediate]) ||
        (curToolIndex == kPolygonLassoTool && [(PolygonLassoTool *)[[m_idDocument tools] getTool:kPolygonLassoTool] intermediate])
        ) {
        [self drawBoundaries];
    }
    [self drawExtras];
    
    
    m_bRefreshWhiteboardImage = true;
    
    return;
}

-(void)drawBackground:(NSRect)rect
{
    // Set the background color
    if ([[m_idDocument whiteboard] whiteboardIsLayerSpecific]) {
        [[NSColor colorWithCalibratedWhite:0.6667 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect:rect] fill];
    }
    else {
        if([(PSPrefs *)[PSController m_idPSPrefs] useCheckerboard]){
            [[NSColor colorWithPatternImage: [NSImage imageNamed:@"checkerboard"] ] set];
        }else{
            [[[[PSController utilitiesManager] transparentUtility] color] set];
        }
        [[NSBezierPath bezierPathWithRect:rect] fill];
    }
}

-(CGLayerRef)getCGLayerCache:(CGSize)size spp:(int)nspp
{
    if(m_cgLayerCache)
    {
        CGSize lastSize = CGLayerGetSize(m_cgLayerCache);
        if(fabs(lastSize.width - size.width) < 0.0001 && fabs(lastSize.height - size.height) < 0.00001)
        {
            return m_cgLayerCache;
        }
        else CGLayerRelease(m_cgLayerCache);
    }
    
    CGColorSpaceRef defaultColorSpace = ((nspp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, nspp * size.width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    m_cgLayerCache = CGLayerCreateWithContext(bitmapContext, size, nil);
    assert(m_cgLayerCache);

   // CGContextRelease(bitmapContext);
    //CGColorSpaceRelease(defaultColorSpace);

    return m_cgLayerCache;
}

-(void)drawImageLayer:(NSRect)rect toContext:(CGContextRef)contextRef isBitmap:(BOOL)isBitmap
{
    int nSpp = [(PSContent *)[m_idDocument contents] spp];
    int nWidth = [(PSContent *)[m_idDocument contents] width]; //self.bounds.size.width;
    int nHeight = [(PSContent *)[m_idDocument contents] height]; //self.bounds.size.height;
    
    float fScaleX = [[m_idDocument contents] xscale];
    float fScaleY = [[m_idDocument contents] yscale];
    
    fScaleX = (fScaleX < 0.9999) ? fScaleX : 1.0;
    fScaleY = (fScaleY < 0.9999) ? fScaleY : 1.0;
    //里面preview存的缩放的数据，如果是缩小的数据，绘制到1：1上会比较慢，所以congtext也缩小就快了

    
    NSSize cglayerSize = CGSizeMake(nWidth, nHeight);
    cglayerSize.width = ceilf((float)nWidth*fScaleX);
    cglayerSize.height = ceilf((float)nHeight*fScaleY);
    
    //    NSRect visibleRect = [self getVisibleRectForConetextScale:CGSizeMake(fScaleX, fScaleY)];
    //    nWidth = visibleRect.size.width;
    //    nHeight = visibleRect.size.height;
    
    //    cglayerSize.width = ceilf(self.bounds.size.width);
    //    cglayerSize.height = ceilf(self.bounds.size.height);
    
  //  CGLayerRef cgLayerWhiteboardImage = [self getCGLayerCache:cglayerSize  spp:nSpp];
    CGColorSpaceRef defaultColorSpace = ((nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, cglayerSize.width, cglayerSize.height, 8, nSpp * cglayerSize.width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    CGLayerRef cgLayerWhiteboardImage = CGLayerCreateWithContext(bitmapContext, cglayerSize, nil);
    assert(cgLayerWhiteboardImage);
    
    CGContextRef imageLayerRef = CGLayerGetContext(cgLayerWhiteboardImage);
    assert(imageLayerRef);
    
 //   CGContextSaveGState(imageLayerRef);
    
    
    float fContextScaleX = cglayerSize.width / nWidth;
    float fContextScaleY = cglayerSize.height / nHeight;
    
    RENDER_CONTEXT_INFO info;
    
    memset(&info, 0, sizeof(info));
    
    info.context = imageLayerRef;
    info.offset = CGPointMake(0, 0);
    //info.offset = CGPointMake(visibleRect.origin.x / fScaleX, visibleRect.origin.y / fScaleY);
    info.scale = CGSizeMake(fContextScaleX, fContextScaleY);
    info.refreshMode = 1;
    info.state = NULL;
   
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    if([[m_idDocument contents] xscale] > 1.0){
        NSRect clipedRect= CGRectMake(rect.origin.x / [[m_idDocument contents] xscale] - 1.0, rect.origin.y / [[m_idDocument contents] yscale] - 1.0, rect.size.width / [[m_idDocument contents] xscale] + 2.0, rect.size.height / [[m_idDocument contents] yscale] + 2.0);
        CGContextClipToRect(imageLayerRef, clipedRect);
    }
    else{
        NSRect clipedRect= CGRectMake(rect.origin.x - 1.0, rect.origin.y - 1.0, rect.size.width + 2.0, rect.size.height + 2.0);
        CGContextClipToRect(imageLayerRef, NSRectToCGRect(clipedRect));
    }
    [[[m_idDocument whiteboard] compositor] compositeLayersToContext:info];
    
    
    //NSLog(@"time1 %f",[NSDate timeIntervalSinceReferenceDate] - begin);
    //begin = [NSDate timeIntervalSinceReferenceDate];
    
    //[[[m_idDocument whiteboard] compositor] compositeLayersToContext:imageLayerRef inRect:NSRectToCGRect(rect) isBitmap:YES];
    //NSLog(@"time3 %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    
    CGContextClipToRect(contextRef, NSRectToCGRect(rect));
    //cglayerSize = CGLayerGetSize(cgLayerWhiteboardImage);
    //CGContextDrawLayerAtPoint(contextRef, CGPointMake(0.0, 0.0), cgLayerWhiteboardImage);
    
    
    float fViewScaleX = [[m_idDocument contents] xscale];
    float fViewScaleY = [[m_idDocument contents] yscale];
    
    
    CGSize desSize;
    if (fScaleX < 1.0) {
        desSize.width = cglayerSize.width * fViewScaleX / fContextScaleX; //cglayerSize.width; //self.bounds.size.width; //self.bounds.size.width; //
    }else{
        desSize.width = self.bounds.size.width; //cglayerSize.width; //
    }
    if (fScaleY < 1.0) {
        desSize.height = cglayerSize.height * fViewScaleY / fContextScaleY; //cglayerSize.height;//self.bounds.size.height; //self.bounds.size.height;//
    }else{
        desSize.height = self.bounds.size.height; //cglayerSize.height; //
    }
    CGContextDrawLayerInRect(contextRef, CGRectMake(0, 0, desSize.width, desSize.height), cgLayerWhiteboardImage);
    
    //NSLog(@"time2 %f",[NSDate timeIntervalSinceReferenceDate] - begin);
    
    
    //    NSRect desRect = [self visibleRect];
    //    float xScale = [[m_idDocument contents] xscale];
    //    float yScale = [[m_idDocument contents] yscale];
    //    desRect.size.width = nWidth * xScale / fScaleX;
    //    desRect.size.height = nHeight * yScale / fScaleY;
    //    CGContextDrawLayerInRect(contextRef, desRect, cgLayerWhiteboardImage);
    
 //   CGContextRestoreGState(imageLayerRef);
    CGLayerRelease(cgLayerWhiteboardImage);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(defaultColorSpace);
    
}

-(void)drawImageLayer_version1:(NSRect)rect toContext:(CGContextRef)contextRef isBitmap:(BOOL)isBitmap
{
    int nSpp = [(PSContent *)[m_idDocument contents] spp];
    int nWidth = [(PSContent *)[m_idDocument contents] width]; //self.bounds.size.width;
    int nHeight = [(PSContent *)[m_idDocument contents] height]; //self.bounds.size.height;
    
    float fScaleX = [[m_idDocument contents] xscale];
    float fScaleY = [[m_idDocument contents] yscale];
    
    fScaleX = (fScaleX < 0.9999) ? fScaleX : 1.0;
    fScaleY = (fScaleY < 0.9999) ? fScaleY : 1.0;
    //里面preview存的缩放的数据，如果是缩小的数据，绘制到1：1上会比较慢，所以congtext也缩小就快了
//    fScaleX = 1.0;
//    fScaleY = 1.0;
    
    NSSize cglayerSize = CGSizeMake(nWidth, nHeight);
    cglayerSize.width = ceilf((float)nWidth*fScaleX);
    cglayerSize.height = ceilf((float)nHeight*fScaleY);
    
//    NSRect visibleRect = [self getVisibleRectForConetextScale:CGSizeMake(fScaleX, fScaleY)];
//    nWidth = visibleRect.size.width;
//    nHeight = visibleRect.size.height;

//    cglayerSize.width = ceilf(self.bounds.size.width);
//    cglayerSize.height = ceilf(self.bounds.size.height);
    
    CGColorSpaceRef defaultColorSpace = ((nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, nWidth, nHeight, 8, nSpp * nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    CGLayerRef cgLayerWhiteboardImage = CGLayerCreateWithContext(bitmapContext, cglayerSize, nil);
    assert(cgLayerWhiteboardImage);
    
    CGContextRef imageLayerRef = CGLayerGetContext(cgLayerWhiteboardImage);
    assert(imageLayerRef);

    float fContextScaleX = cglayerSize.width / nWidth;
    float fContextScaleY = cglayerSize.height / nHeight;
    
    RENDER_CONTEXT_INFO info;
    
    memset(&info, 0, sizeof(info));
    
    info.context = imageLayerRef;
    info.offset = CGPointMake(0, 0);
    //info.offset = CGPointMake(visibleRect.origin.x / fScaleX, visibleRect.origin.y / fScaleY);
    info.scale = CGSizeMake(fContextScaleX, fContextScaleY);
    info.refreshMode = 0;//1;
    info.state = NULL;
    NSLog(@"info.refreshMode = 0");
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    [[[m_idDocument whiteboard] compositor] compositeLayersToContext:info];
    
    //NSLog(@"time1 %f",[NSDate timeIntervalSinceReferenceDate] - begin);
    //begin = [NSDate timeIntervalSinceReferenceDate];
    
    //[[[m_idDocument whiteboard] compositor] compositeLayersToContext:imageLayerRef inRect:NSRectToCGRect(rect) isBitmap:YES];
    //NSLog(@"time3 %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    
    CGContextClipToRect(contextRef, NSRectToCGRect(rect));
    //cglayerSize = CGLayerGetSize(cgLayerWhiteboardImage);
    //CGContextDrawLayerAtPoint(contextRef, CGPointMake(0.0, 0.0), cgLayerWhiteboardImage);
    
    
    float fViewScaleX = [[m_idDocument contents] xscale];
    float fViewScaleY = [[m_idDocument contents] yscale];

    
    CGSize desSize;
    if (fScaleX < 1.0) {
        desSize.width = cglayerSize.width * fViewScaleX / fContextScaleX; //cglayerSize.width; //self.bounds.size.width; //self.bounds.size.width; //
    }else{
        desSize.width = self.bounds.size.width; //cglayerSize.width; //
    }
    if (fScaleY < 1.0) {
        desSize.height = cglayerSize.height * fViewScaleY / fContextScaleY; //cglayerSize.height;//self.bounds.size.height; //self.bounds.size.height;//
    }else{
        desSize.height = self.bounds.size.height; //cglayerSize.height; //
    }
    CGContextDrawLayerInRect(contextRef, CGRectMake(0, 0, desSize.width, desSize.height), cgLayerWhiteboardImage);
    
    //NSLog(@"time2 %f",[NSDate timeIntervalSinceReferenceDate] - begin);
    
    
//    NSRect desRect = [self visibleRect];
//    float xScale = [[m_idDocument contents] xscale];
//    float yScale = [[m_idDocument contents] yscale];
//    desRect.size.width = nWidth * xScale / fScaleX;
//    desRect.size.height = nHeight * yScale / fScaleY;
//    CGContextDrawLayerInRect(contextRef, desRect, cgLayerWhiteboardImage);
    
    CGLayerRelease(cgLayerWhiteboardImage);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(defaultColorSpace);
    
}

- (NSRect)getVisibleRectForConetextScale:(CGSize)scale
{
    NSRect visibleRect = [self visibleRect];
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    visibleRect.origin.x /= xScale;
    visibleRect.origin.y /= yScale;
    visibleRect.size.width /= xScale;
    visibleRect.size.height /= yScale;
    
    visibleRect.origin.x *= scale.width;
    visibleRect.origin.y *= scale.height;
    visibleRect.size.width *= scale.width;
    visibleRect.size.height *= scale.height;
    visibleRect.size.width = ceilf(visibleRect.size.width);
    visibleRect.size.height = ceilf(visibleRect.size.height);
    
    return visibleRect;
}

- (void)drawBoundaries
{
	int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    	
	if (curToolIndex == kCropTool) {
		[self drawCropBoundaries];
	}
	else
    {
        BOOL bShowSelectioinBoundaries = [(AbstractTool*)[[m_idDocument tools] currentTool] showSelectionBoundaries];
        if(bShowSelectioinBoundaries){
            [self drawSelectBoundaries:[[NSGraphicsContext currentContext] graphicsPort]];
        }
	}
}

- (void)drawCropBoundaries
{
	NSRect tempRect;
	IntRect cropRect;
	NSBezierPath *tempPath;
	float xScale, yScale;
	int width, height;
	
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
    cropRect = [(CropTool*)[[m_idDocument tools] getTool:kCropTool] cropRect];
	if (cropRect.size.width == 0 || cropRect.size.height == 0)
		return;
	tempRect.origin.x = floor(cropRect.origin.x * xScale);
	tempRect.origin.y =  floor(cropRect.origin.y * yScale);
	tempRect.size.width = ceil(cropRect.size.width * xScale);
	tempRect.size.height = ceil(cropRect.size.height * yScale);
	[[[PSController m_idPSPrefs] selectionColor:0.4] set];
	tempPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, width * xScale + 1.0, height * yScale + 1.0)];
	[tempPath appendBezierPathWithRect:tempRect];
	[tempPath setWindingRule:NSEvenOddWindingRule];
	[tempPath fill];
	
	[self drawDragHandles: tempRect type: kCropHandleType];
}

int matrix_invert(int N, double *matrix) {
    
    int error=0;
    int *pivot = malloc(N * N * sizeof(long));
    double *workspace = malloc(N * sizeof(double));
    
    dgetrf_(&N, &N, matrix, &N, pivot, &error);
    
    if (error != 0) {
        // NSLog(@"Error 1");
        return error;
    }
    
    dgetri_(&N, matrix, &N, pivot, workspace, &N, &error);
    
    if (error != 0) {
        // NSLog(@"Error 2");
        return error;
    }
    
    free(pivot);
    free(workspace);
    return error;
}

- (CGAffineTransform)getTransformFromP1:(CGPoint)p1 P2:(CGPoint)p2 P3:(CGPoint)p3 Q1:(CGPoint)q1 Q2:(CGPoint)q2 Q3:(CGPoint)q3
{
    //CGPoint p1, p2, p3, q1, q2, q3;
    
    // TODO: initialize points
    
    double A[36];
    
    A[ 0] = p1.x; A[ 1] = p1.y; A[ 2] = 0; A[ 3] = 0; A[ 4] = 1; A[ 5] = 0;
    A[ 6] = 0; A[ 7] = 0; A[ 8] = p1.x; A[ 9] = p1.y; A[10] = 0; A[11] = 1;
    A[12] = p2.x; A[13] = p2.y; A[14] = 0; A[15] = 0; A[16] = 1; A[17] = 0;
    A[18] = 0; A[19] = 0; A[20] = p2.x; A[21] = p2.y; A[22] = 0; A[23] = 1;
    A[24] = p3.x; A[25] = p3.y; A[26] = 0; A[27] = 0; A[28] = 1; A[29] = 0;
    A[30] = 0; A[31] = 0; A[32] = p3.x; A[33] = p3.y; A[34] = 0; A[35] = 1;
    
    int err = matrix_invert(6, A);
    assert(err == 0);
    
    double B[6];
    
    B[0] = q1.x; B[1] = q1.y; B[2] = q2.x; B[3] = q2.y; B[4] = q3.x; B[5] = q3.y;
    
    double M[6];
    
    M[0] = A[ 0] * B[0] + A[ 1] * B[1] + A[ 2] * B[2] + A[ 3] * B[3] + A[ 4] * B[4] + A[ 5] * B[5];
    M[1] = A[ 6] * B[0] + A[ 7] * B[1] + A[ 8] * B[2] + A[ 9] * B[3] + A[10] * B[4] + A[11] * B[5];
    M[2] = A[12] * B[0] + A[13] * B[1] + A[14] * B[2] + A[15] * B[3] + A[16] * B[4] + A[17] * B[5];
    M[3] = A[18] * B[0] + A[19] * B[1] + A[20] * B[2] + A[21] * B[3] + A[22] * B[4] + A[23] * B[5];
    M[4] = A[24] * B[0] + A[25] * B[1] + A[26] * B[2] + A[27] * B[3] + A[28] * B[4] + A[29] * B[5];
    M[5] = A[30] * B[0] + A[31] * B[1] + A[32] * B[2] + A[33] * B[3] + A[34] * B[4] + A[35] * B[5];
    
    //NSLog(@"%f, %f, %f, %f, %f, %f", M[0], M[1], M[2], M[3], M[4], M[5]);
    
    CGAffineTransform transform = CGAffineTransformMake(M[0], M[2], M[1], M[3], M[4], M[5]); // Order is correct...
    
    return transform;
}


- (void)drawOuterSelection:(NSNotification*) notification
{
    if (![[[m_idDocument tools] currentTool] intermediate] && (![(PSSelection*)[m_idDocument selection] active] || [(PSSelection*)[m_idDocument selection] mask] == NULL))
    {
        return;
    }
    if (notification.object != [m_idDocument shadowView]) {
        return;
    }
    NSView *shadowView = notification.object;
    NSPoint viewPoint0 = NSMakePoint(0, 0);
    NSPoint superPoint0 = [shadowView convertPoint: viewPoint0 fromView: self];
    NSPoint viewPoint1 = NSMakePoint(1, 0);
    NSPoint superPoint1 = [shadowView convertPoint: viewPoint1 fromView: self];
    NSPoint viewPoint2 = NSMakePoint(1, 1);
    NSPoint superPoint2 = [shadowView convertPoint: viewPoint2 fromView: self];
    
    CGAffineTransform transform = [self getTransformFromP1:viewPoint0 P2:viewPoint1 P3:viewPoint2 Q1:superPoint0 Q2:superPoint1 Q3:superPoint2];
    
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextConcatCTM(context, transform);
    [self drawSelectBoundaries:context];
    CGContextRestoreGState(context);
}

- (void)drawSelectBoundaries:(CGContextRef)ctx
{
	float xScale, yScale;
	NSRect tempRect, srcRect;
	IntRect selectRect, tempSelectRect;
	int xoff, yoff, width, height, lwidth, lheight;
	BOOL useSelection, special, intermediate;
	int curToolIndex = (int)[(ToolboxUtility *)[(UtilitiesManager *)[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	NSBezierPath *tempPath;
	NSImage *maskImage;
	int radius = 0;
	float revCurveRadius, f;

	selectRect = [[m_idDocument selection] globalRect];
	useSelection = [[m_idDocument selection] active];
	xoff = [[[m_idDocument contents] activeLayer] xoff];
	yoff = [[[m_idDocument contents] activeLayer] yoff];
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
	lwidth = [(PSLayer *)[[m_idDocument contents] activeLayer] width];
	lheight = [(PSLayer *)[[m_idDocument contents] activeLayer] height];
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];

	// The selection rectangle
    [self drawUseSelectionBoundaries:ctx];
	// Get the data for drawing rounded rectangular selections
	special = NO;
//	if (curToolIndex == kRectSelectTool) {
//		radius = [(RectSelectOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] currentOptions] radius];
//		tempSelectRect = [(RectSelectTool *)[[m_idDocument tools] currentTool] selectionRect];
//		special = tempSelectRect.size.width < 2 * radius && tempSelectRect.size.height < 2 * radius;
//	}
	
	// Check to see if the user is currently dragging a selection
	intermediate = NO;
	if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool){
		intermediate =  [(AbstractScaleTool *)[[m_idDocument tools] getTool: curToolIndex] intermediate] && ! [(AbstractScaleTool *)[[m_idDocument tools] getTool: curToolIndex] isMovingOrScaling];
	}
//	intermediate =  YES;
	[m_idCursorsManager setCloseRect:NSMakeRect(0, 0, 0, 0)];
	if ((intermediate && curToolIndex == kEllipseSelectTool) || special) {
		// The ellipse tool is currently being dragged, so draw its marching ants
		tempSelectRect = [(EllipseSelectTool *)[[m_idDocument tools] currentTool] selectionRect];
		tempRect = IntRectMakeNSRect(tempSelectRect);
		tempRect.origin.x += xoff; tempRect.origin.y += yoff;
		tempRect.origin.x *= xScale; tempRect.origin.y *= yScale; tempRect.size.width *= xScale; tempRect.size.height *= yScale;
        
        //NSLog(@"tempSelectRect %@",NSStringFromRect(tempRect));
        
		tempPath = [NSBezierPath bezierPathWithOvalInRect:tempRect];
		CGFloat black[4] = {0,.5,2,3.5};
		[[NSColor blackColor] set];
		[tempPath setLineDash: black count: 4 phase: 0.0];
		[tempPath stroke];
		CGFloat white[4] = {0,3.5,2,.5};
		[[NSColor whiteColor] set];
		[tempPath setLineDash: white count: 4 phase: 0.0];
		[tempPath stroke];
	}
	else if (curToolIndex == kRectSelectTool && intermediate) {
		// The rectangle tool is being dragged, so draw its marching ants
		tempSelectRect = [(RectSelectTool *)[[m_idDocument tools] currentTool] selectionRect];
		tempRect = IntRectMakeNSRect(tempSelectRect);
		tempRect.origin.x += xoff; tempRect.origin.y += yoff;		
		tempRect.origin.x *= xScale; tempRect.origin.y *= yScale; tempRect.size.width *= xScale; tempRect.size.height *= yScale;
        
        //NSLog(@"tempSelectRect %@",NSStringFromRect(tempRect));
		
        radius = [(RectSelectOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] currentOptions] radius];
        // The corners have a rounding
		if (radius) {
			f = (4.0 / 3.0) * (sqrt(2) - 1);
			
            float revCurveRadiusX, revCurveRadiusY;
            revCurveRadiusX = radius * xScale;
            revCurveRadiusY = radius * yScale;
			if (tempRect.size.width < 2 * revCurveRadiusX) revCurveRadiusX = tempRect.size.width / 2.0;
			if (tempRect.size.height < 2 * revCurveRadiusY) revCurveRadiusY = tempRect.size.height / 2.0;
			
            tempPath = [NSBezierPath bezierPathWithRoundedRect:tempRect xRadius:revCurveRadiusX yRadius:revCurveRadiusY];
//			tempPath = [NSBezierPath bezierPath];
//			[tempPath moveToPoint:NSMakePoint(tempRect.origin.x, tempRect.origin.y + revCurveRadius * yScale)];
//			[tempPath curveToPoint:NSMakePoint(tempRect.origin.x + revCurveRadius * xScale, tempRect.origin.y) controlPoint1:NSMakePoint(tempRect.origin.x, tempRect.origin.y + (1.0 - f) * revCurveRadius * yScale) controlPoint2:NSMakePoint(tempRect.origin.x + (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y)];
//			[tempPath lineToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width - revCurveRadius * xScale, tempRect.origin.y)];
//			[tempPath curveToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + revCurveRadius * yScale) controlPoint1:NSMakePoint(tempRect.origin.x + tempRect.size.width - (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y) controlPoint2:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + (1.0 - f) * revCurveRadius * yScale)];
//			[tempPath lineToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + tempRect.size.height - revCurveRadius * yScale)];
//			[tempPath curveToPoint:NSMakePoint(tempRect.origin.x + tempRect.size.width - revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height) controlPoint1:NSMakePoint(tempRect.origin.x + tempRect.size.width, tempRect.origin.y + tempRect.size.height - (1.0 - f) * revCurveRadius * yScale) controlPoint2:NSMakePoint(tempRect.origin.x + tempRect.size.width - (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height)];
//			[tempPath lineToPoint:NSMakePoint(tempRect.origin.x + revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height)];
//			[tempPath curveToPoint:NSMakePoint(tempRect.origin.x, tempRect.origin.y + tempRect.size.height - revCurveRadius * yScale) controlPoint1:NSMakePoint(tempRect.origin.x + (1.0 - f) * revCurveRadius * xScale, tempRect.origin.y + tempRect.size.height) controlPoint2:NSMakePoint(tempRect.origin.x, tempRect.origin.y + tempRect.size.height - (1.0 - f) * revCurveRadius * yScale)];
//			[tempPath lineToPoint:NSMakePoint(tempRect.origin.x, tempRect.origin.y + revCurveRadius * yScale)];
		}
		else {
			// There are no rounded corners
			tempRect.origin.x += .5;
			tempRect.origin.y += .5;
			tempRect.size.width -= 1;
			tempRect.size.height -= 1;
			
			tempPath = [NSBezierPath bezierPathWithRect:tempRect];		
		}
		
		// The marching ants themselves
		CGFloat black[4] = {0,.5,2,3.5};
		[[NSColor blackColor] set];
		[tempPath setLineDash: black count: 4 phase: 0.0];
		[tempPath stroke];
		CGFloat white[4] = {0,3.5,2,.5};
		[[NSColor whiteColor] set];
		[tempPath setLineDash: white count: 4 phase: 0.0];
		[tempPath stroke];
	}else if((curToolIndex == kLassoTool || curToolIndex == kPolygonLassoTool) && intermediate){
		// Finally, draw the marching ants for the lasso or polygon lasso tools
		tempPath = [NSBezierPath bezierPath];
		
		LassoPoints lassoPoints;
		NSPoint start;
        if ([[[m_idDocument tools] currentTool] isKindOfClass: [LassoTool class]] || [[[m_idDocument tools] currentTool] isKindOfClass: [PolygonLassoTool class]]) {
            lassoPoints = [[[m_idDocument tools] currentTool] currentPoints]; //(LassoTool *)
            if(lassoPoints.points == NULL || lassoPoints.pos < 0) return;
            start = NSMakePoint((lassoPoints.points[0].x + xoff) *xScale , (lassoPoints.points[0].y + yoff) * yScale );
            
            // Create a special start point for the polygonal lasso tool
            // This allows the user to close the polygon by just clicking
            // near the first point in the polygon.
            if(curToolIndex == kPolygonLassoTool){
                [self drawHandle: start type:kPolygonalLassoType index: -1];
            }
            
            // It is now the job of the PSView instead of the tool itself to draw the edges because
            // this way, the polygon can be persistent across view changes such as scrolling or resizing
            [tempPath moveToPoint:start];
            int i;
            for(i = 1; i <= lassoPoints.pos; i++){
                IntPoint thisPoint = lassoPoints.points[i];
                [tempPath lineToPoint:NSMakePoint((thisPoint.x + xoff) * xScale , (thisPoint.y + yoff) * yScale )];
            }
            
            if(curToolIndex == kPolygonLassoTool)
            {
                BOOL bHaveTempPoint = [[[m_idDocument tools] currentTool] isHaveTempPoint];
                if(bHaveTempPoint)
                {
                    IntPoint tempPoint = [[[m_idDocument tools] currentTool] tempPoint];
                    [tempPath lineToPoint:NSMakePoint((tempPoint.x + xoff) * xScale , (tempPoint.y + yoff) * yScale )];
                }
            }
            
            CGFloat black[4] = {0,.5,2,3.5};
            [[NSColor blackColor] set];
            [tempPath setLineDash: black count: 4 phase: 0.0];
            [tempPath stroke];
            CGFloat white[4] = {0,3.5,2,.5};
            [[NSColor whiteColor] set];
            [tempPath setLineDash: white count: 4 phase: 0.0];
            [tempPath stroke];
            
        }
	}
}

-(void)drawUseSelectionBoundaries:(CGContextRef)ctx
{
    float xScale, yScale;
    NSRect tempRect;
    IntRect selectRect;
    BOOL useSelection;
    int curToolIndex = (int)[(ToolboxUtility *)[(UtilitiesManager *)[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    
    selectRect = [[m_idDocument selection] globalRect];
    useSelection = [[m_idDocument selection] active];
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
 
    // The selection rectangle
    if (useSelection){
        [self drawMarchingAnts:ctx];
        tempRect = NSMakeRect(selectRect.origin.x, selectRect.origin.y, selectRect.size.width, selectRect.size.height);
        
        // Ensure we're drawing whole pixels, again
        tempRect.origin.x = floor(tempRect.origin.x * xScale);
        tempRect.origin.y =  floor(tempRect.origin.y * yScale);
        tempRect.size.width = ceil(tempRect.size.width * xScale);
        tempRect.size.height = ceil(tempRect.size.height * yScale);
   
        
        // If the currently selected tool is a selection tool, draw the handles
        if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool){
            [self drawDragHandles: tempRect type: kSelectionHandleType];
        }
    }

}

- (void)drawDragAffineHandlesPoint1:(NSPoint)point1  point2:(NSPoint)point2  point3:(NSPoint)point3  point4:(NSPoint)point4
{
    NSPoint tempPoint;
    tempPoint.x = point1.x - 1;
    tempPoint.y = point1.y - 1;
    [self drawHandle: tempPoint type: kPositionType index: 0];
    tempPoint.x = (point1.x + point2.x) / 2;
    tempPoint.y = (point1.y + point2.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 1];
    tempPoint.x = point2.x - 1;
    tempPoint.y = point2.y - 1;
    [self drawHandle: tempPoint type: kPositionType index: 2];
    tempPoint.x = (point2.x + point3.x) / 2;
    tempPoint.y = (point2.y + point3.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 3];
    tempPoint.x = point3.x - 1;
    tempPoint.y = point3.y - 1;
    [self drawHandle: tempPoint type: kPositionType index: 4];
    tempPoint.x = (point3.x + point4.x) / 2;
    tempPoint.y = (point3.y + point4.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 5];
    tempPoint.x = point4.x - 1;
    tempPoint.y = point4.y - 1;
    [self drawHandle: tempPoint type: kPositionType index: 6];
    tempPoint.x = (point1.x + point4.x) / 2;
    tempPoint.y = (point1.y + point4.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 7];
}


- (void)drawDragHandles:(NSRect) rect type: (int)type
{
	rect.origin.x -= 1;
	rect.origin.y -= 1;
	[self drawHandle: rect.origin type: type index: 0];
	rect.origin.x += rect.size.width / 2 + 1;
	[self drawHandle: rect.origin type: type index: 1];
	rect.origin.x += rect.size.width / 2 + 1;
	[self drawHandle: rect.origin type: type index: 2];
	rect.origin.y += rect.size.height / 2 + 1;
	[self drawHandle: rect.origin type: type index: 3];
	rect.origin.y += rect.size.height / 2 + 1;
	[self drawHandle: rect.origin type: type index: 4];
	rect.origin.x -= rect.size.width / 2 + 1;
	[self drawHandle: rect.origin type: type index: 5];
	rect.origin.x -= rect.size.width / 2 + 1;
	[self drawHandle: rect.origin type: type index: 6];
	rect.origin.y -= rect.size.height / 2 + 1;
	[self drawHandle: rect.origin type: type index: 7];
}

- (void)drawHandle:(NSPoint) origin  type: (int)type index:(int) index
{
	NSRect outside  = NSMakeRect(origin.x - 4,origin.y - 4,8,8);
	// This function is also used to set the appropriate cursor rects
	// The rectangles must be persistent because in the event loop, each view
	// has its cursor rects reset AFTER the view is drawn, so setting the rects
	// here would just have them immediately invalidated.
	NSRect *handleRects = [(PSCursors *) m_idCursorsManager handleRectsPointer];
	if(index >= 0)
		handleRects[index] = outside;
	
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: outside];
	switch (type) {
		case kSelectionHandleType:
			[[NSColor whiteColor] set];
			break;
		case kLayerHandleType:
			[[NSColor whiteColor] set];
			break;
		case kCropHandleType:
			[[NSColor redColor] set];
			break;
		case kGradientStartType:
			[[NSColor whiteColor] set];
			break;
		case kGradientEndType:
			[[NSColor whiteColor] set];
			break;
		case kPolygonalLassoType:
			[[NSColor blackColor] set];
			[m_idCursorsManager setCloseRect:outside];
			break;
		case kPositionType:
			[[(PSPrefs *)[PSController m_idPSPrefs] guideColor: 1.0] set];
			outside = NSMakeRect(origin.x - 3, origin.y - 3, 6, 6);
			path = [NSBezierPath bezierPathWithRect:outside];
			break;
		default:
			NSLog(@"Handle type not understood.");
			break;
	}

	// The handle should have a subtle shadow so that it can be visible on background
	// where the color is the same as the inside and outside of the handle
	[NSGraphicsContext saveGraphicsState];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset: NSMakeSize(0, 0)];
	[shadow setShadowBlurRadius: 1];
	
	if(type == kPolygonalLassoType){
		// This handle has inverted colors to make it obvious
		[shadow setShadowColor:[NSColor whiteColor]];
	}else{
		[shadow setShadowColor:[NSColor blackColor]];
	}
	[shadow set];
	[path fill];

	[NSGraphicsContext restoreGraphicsState];

	NSRect inside  = NSMakeRect(origin.x - 3,origin.y - 3,6,6);
	path = [NSBezierPath bezierPathWithOvalInRect: inside];

	switch (type) {
		case kSelectionHandleType:
			[[(PSPrefs *)[PSController m_idPSPrefs] selectionColor:1] set];
			break;
		case kCropHandleType:
			[[(PSPrefs *)[PSController m_idPSPrefs] selectionColor:0.6] set];
			inside  = NSMakeRect(origin.x - 2.5,origin.y - 3,5.5,6);
			path = [NSBezierPath bezierPathWithOvalInRect: inside];
			break;
		case kLayerHandleType:
			[[NSColor cyanColor] set];
			break;
		case kGradientStartType:
			[[[m_idDocument contents] foreground] set];
			break;
		case kGradientEndType:
			[[[m_idDocument contents] background] set];
			break;
		case kPolygonalLassoType:
			[[NSColor whiteColor] set];
			break;
		case kPositionType:
			inside = NSMakeRect(origin.x - 2, origin.y - 2, 4, 4);
			path = [NSBezierPath bezierPathWithRect: inside];
            [[NSColor whiteColor] set];
            switch (index) {
                case 0:
                    [[NSColor redColor] set];
                    break;
                case 2:
                    [[NSColor greenColor] set];
                    break;
                case 4:
                    [[NSColor blueColor] set];
                    break;
                case 6:
                    [[NSColor yellowColor] set];
                    break;
                    
                default:
                    break;
            }
			
			break;
		default:
			NSLog(@"Handle type not understood.");
			break;
	}
	[path fill];
	[[(PSPrefs *)[PSController m_idPSPrefs] guideColor: 1.0] set];
}

- (void)drawExtras
{	
	int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	id cloneTool = [[m_idDocument tools] getTool:kCloneTool];
	id effectTool = [[m_idDocument tools] getTool:kEffectTool];
	NSPoint outPoint, hilightPoint;
	float xScale, yScale;
	int xoff, yoff, lwidth, lheight, i;
	NSBezierPath *tempPath;
	IntPoint sourcePoint;
	NSImage *crossImage;
	
	
	// Fill out various variables
	xoff = [[[m_idDocument contents] activeLayer] xoff];
	yoff = [[[m_idDocument contents] activeLayer] yoff];
	lwidth = [(PSLayer *)[[m_idDocument contents] activeLayer] width];
	lheight = [(PSLayer *)[[m_idDocument contents] activeLayer] height];
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];

	tempPath = [NSBezierPath bezierPath];
	[tempPath setLineWidth:1.0];
	
	
	if([(PSPrefs *)[PSController m_idPSPrefs] guides] && xScale > 2 && yScale > 2){
		[[NSColor colorWithCalibratedWhite:0.9 alpha:0.25] set];
		int i, j;
		
		for(i = 0; i < [self frame].size.width / xScale; i++){
			[tempPath moveToPoint:NSMakePoint(xScale * i - 0.5, 0)];
			[tempPath lineToPoint:NSMakePoint(xScale * i - 0.5, [self frame].size.height)];
		}
		
		for(j = 0; j < [self frame].size.height / yScale; j++){
			[tempPath moveToPoint:NSMakePoint(0, yScale * j - 0.5)];
			[tempPath lineToPoint:NSMakePoint([self frame].size.width, yScale *j - 0.5)];
		}		
		[tempPath stroke];
		[[NSColor colorWithCalibratedWhite:0.5 alpha:0.25] set];

		for(i = 0; i < [self frame].size.width / xScale; i++){
			[tempPath moveToPoint:NSMakePoint(xScale * i + 0.5, 0)];
			[tempPath lineToPoint:NSMakePoint(xScale * i + 0.5, [self frame].size.height)];
		}
		
		for(j = 0; j < [self frame].size.height / yScale; j++){
			[tempPath moveToPoint:NSMakePoint(0, yScale * j + 0.5)];
			[tempPath lineToPoint:NSMakePoint([self frame].size.width, yScale *j + 0.5)];
		}		
		[tempPath stroke];
		
	
	}
	
	if(curToolIndex == kPositionTool && [(PSPrefs *)[PSController m_idPSPrefs] guides]){
		float radians = 0.0;
		id positionTool = [[m_idDocument tools] getTool:kPositionTool];

		// The position tool now has guides (which the user can turn on or off)
		// This makes it easy to see the dimensions and the boundaries of the moved layer
		// or selection, even when there is currently an active selection.
		xoff *= xScale;
		lwidth *= xScale;
		yoff *= yScale;
		lheight *= yScale;
		
		[[(PSPrefs *)[PSController m_idPSPrefs] guideColor: 1.0] set];
		
		if([positionTool intermediate]){
			IntRect postScaledRect = [positionTool postScaledRect];
			xoff = postScaledRect.origin.x;
			yoff = postScaledRect.origin.y;
			lwidth = postScaledRect.size.width;
			lheight = postScaledRect.size.height;
		}
        
        
      //  return;
   
	/*	NSPoint centerPoint = NSMakePoint(xoff + lwidth / 2, yoff + lheight / 2);
		// Additionally, the new guides are directly proportional to the amount of rotation or 
		// of scaling done by the layer if these modifiers are used.
		if ([(PositionTool *)positionTool scale] != -1) {
			float scale = [(PositionTool *)positionTool scale];
			lwidth *= scale;
			lheight *= scale;
			xoff = centerPoint.x - lwidth / 2;
			yoff = centerPoint.y - lheight / 2;
		}else if([(PositionTool *)positionTool rotationDefined]){
			radians = [(PositionTool *)positionTool rotation];
		}
		
		// All of the silliness with the 0.5's is because when drawing with Bezier paths
		// the coordinates are at vertices between the pixels, not centered on them.
		[tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + 0.5, yoff +0.5), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + lwidth - 0.5, yoff +0.5), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff+lwidth -0.5, yoff+ lheight -0.5), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff +0.5, yoff+ lheight -0.5), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff+0.5, yoff +0.5), centerPoint, radians)];
		
		// In addition to the 4 sides, there are guides that divide the rectangle into thirds.
		// This is better than halves because that way scaling is visible
		[tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(floor(xoff + lwidth / 3) + 0.5, yoff), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(floor(xoff + lwidth / 3) + 0.5, yoff + lheight), centerPoint, radians)];
		[tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(ceil(xoff + 2 * lwidth / 3) - 0.5, yoff + lheight), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(ceil(xoff + 2 * lwidth / 3) - 0.5, yoff), centerPoint, radians)];
		
		[tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(xoff, floor(yoff + lheight / 3) + 0.5), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + lwidth, floor(yoff + lheight / 3) + 0.5), centerPoint, radians)];
		[tempPath moveToPoint:NSPointRotateNSPoint(NSMakePoint(xoff, ceil(yoff + 2* lheight / 3) -0.5), centerPoint, radians)];
		[tempPath lineToPoint:NSPointRotateNSPoint(NSMakePoint(xoff + lwidth, ceil(yoff + 2* lheight / 3) - 0.5), centerPoint, radians)];

		[tempPath stroke]; */

	}
//    else if(curToolIndex == kCloneTool){
//		// Draw source point
//		if ([cloneTool sourceSetting]) {
//			sourcePoint = [cloneTool sourcePoint:NO];
//			crossImage = [NSImage imageNamed:@"cross"];
//			outPoint = IntPointMakeNSPoint(sourcePoint);
//			outPoint.x *= xScale;
//			outPoint.y *= yScale;
//			outPoint.x -= 12;
//			outPoint.y -= 12;
//			//outPoint.y += 26;
//			//[crossImage compositeToPoint:outPoint operation:NSCompositeSourceOver fraction:(float)[cloneTool sourceSetting] / 100.0];
//            [crossImage drawAtPoint:outPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(float)[cloneTool sourceSetting] / 100.0];
//		}
//	}
    else if (curToolIndex == kEffectTool){
		// Draw effect tool dots
		for (i = 0; i < [effectTool clickCount]; i++) {
			[[[PSController m_idPSPrefs] selectionColor:0.6] set];
			hilightPoint = IntPointMakeNSPoint([effectTool point:i]);
			tempPath = [NSBezierPath bezierPath];
			[tempPath moveToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale - 4, (hilightPoint.y + yoff) * yScale + 4)];
			[tempPath lineToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale + 4, (hilightPoint.y + yoff) * yScale - 4)];
			[tempPath moveToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale + 4, (hilightPoint.y + yoff) * yScale + 4)];
			[tempPath lineToPoint:NSMakePoint((hilightPoint.x + xoff) * xScale - 4, (hilightPoint.y + yoff) * yScale - 4)];
			[tempPath setLineWidth:2.0];
			[tempPath stroke];
		}
	}else if (curToolIndex == kGradientTool) {
		GradientTool *tool = [[m_idDocument tools] getTool:kGradientTool];
		
		if([tool intermediate]){
			// Draw the connecting line
			[[(PSPrefs *)[PSController m_idPSPrefs] guideColor: 1.0] set];

			tempPath = [NSBezierPath bezierPath];
			[tempPath setLineWidth:1.0];
			[tempPath moveToPoint:[tool start]];
			[tempPath lineToPoint:[tool current]];
			[tempPath stroke];
			
			// The handles are the appropriate color of the gradient.
			[self drawHandle:[tool start] type:kGradientStartType index: -1];
			[self drawHandle:[tool current] type:kGradientEndType index: -1];
		}
	}else if (curToolIndex == kWandTool || curToolIndex == kBucketTool){
		WandTool *tool = [[m_idDocument tools] getTool: curToolIndex];
		if([tool intermediate] && (curToolIndex == kBucketTool || ![tool isMovingOrScaling])){
			// Draw the connecting line
			[[(PSPrefs *)[PSController m_idPSPrefs] guideColor: 1.0] set];

			tempPath = [NSBezierPath bezierPath];
			[tempPath setLineWidth:1.0];
			[tempPath moveToPoint:[tool start]];
			[tempPath lineToPoint:[tool current]];
			[tempPath stroke];
			
			[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect([tool start].x - 3, [tool start].y-3, 6,6)] fill];
			[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect([tool current].x - 3, [tool current].y-3, 6,6)] fill];
			 
		}
	}else if (curToolIndex == kTransformTool){
        
        //id transformTool = [[m_idDocument tools] getTool:kTransformTool];
        //[transformTool drawToolExtra];
    }
    
    [[[m_idDocument tools] currentTool] drawToolExtra];
}


#pragma mark - draw Marching Ants

#define ALPHA 128
#define kMaxPoints 2000000
-(void)setRefreshWhiteboardImage:(bool)bRefreshWhiteboardImage
{
    m_bRefreshWhiteboardImage = bRefreshWhiteboardImage;
}

-(void)setNeedsUpdateSelectBoundPoints
{
    m_bUpdateBoundPoints = true;
}

- (void)LoopDrawSelectBoundaries
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex == kCropTool)  return;
    
    BOOL bUseSelection = [(PSSelection*)[m_idDocument selection] active];
    if(!bUseSelection) return;
    unsigned char *pSelectionMask = [(PSSelection*)[m_idDocument selection] mask];
    if(!pSelectionMask) return;
    
    m_bRefreshWhiteboardImage = false;
    [self setNeedsDisplay:YES];
}

- (void)drawMarchingAnts:(CGContextRef)context
{
    BOOL bUseSelection = [(PSSelection*)[m_idDocument selection] active];
    if(!bUseSelection) return;
    unsigned char *pSelectionMask = [(PSSelection*)[m_idDocument selection] mask];
    if(!pSelectionMask) return;
 
    if(m_bUpdateBoundPoints)
    {
        [self updateMarchingAntsBoundPoints];
        m_bUpdateBoundPoints = false;
    }
    
//    [self drawMarchingAntsWithBoundPoints:context selectBoundPoints:m_sSelectBoundPoints];
    [self drawMarchingAntsWithBoundPoints:context selectBoundPoints:m_maSelectBoundPoints];
}

/*
-(void)updateMarchingAntsBoundPoints
{
    NSImage *maskImage = [(PSSelection*)[m_idDocument selection] maskImage];
    if(!maskImage) return;
    
    IntSize selectMaskSize = [[m_idDocument selection] maskSize];
    float fScaleX = [[m_idDocument contents] xscale];
    float fScaleY = [[m_idDocument contents] yscale];
    int nScaleWidth = selectMaskSize.width * fScaleX;
    int nScaleHeight = selectMaskSize.height * fScaleY;
    
    //获取Image buffer
    unsigned char *pMaskImageBuffer = malloc(nScaleWidth * nScaleHeight * 4);
    memset(pMaskImageBuffer, 0, nScaleWidth * nScaleHeight * 4);
    GetNSImageBuffer(maskImage, nScaleWidth, nScaleHeight, pMaskImageBuffer, 1);
  
    if (m_sSelectBoundPoints.points != NULL)
        free(m_sSelectBoundPoints.points);
    
    m_sSelectBoundPoints.points = malloc(kMaxPoints * sizeof(IntPoint));
    m_sSelectBoundPoints.nPointNumber = 0;
    
//    IntRect selectRect = [[m_idDocument selection] globalRect];
//    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
//    for (int j = maskOffset.y; j < maskOffset.y + selectRect.size.height; j++)
//    {
//        for (int i = maskOffset.x; i < maskOffset.x + selectRect.size.width; i++)
    for (int j = 0; j < nScaleHeight; j++)
    {
        for (int i = 0; i < nScaleWidth; i++)
        {
            if(pMaskImageBuffer[j * nScaleWidth * 4 + i * 4 + 3] > ALPHA)
            {
                int nLeft = i - 1;
                int nRight = i + 1;
                int nTop = j - 1;
                int nBottom = j + 1;
                
                if(i - 1 < 0)
                    nLeft = 0;
                if(i + 1 > nScaleWidth -1)
                    nRight = nScaleWidth -1;
                if(j - 1 < 0)
                    nTop = 0;
                if(j + 1 > nScaleHeight -1)
                    nBottom = nScaleHeight -1;
                
                if(pMaskImageBuffer[j * nScaleWidth * 4 + nLeft * 4 + 3] <= ALPHA ||
                   pMaskImageBuffer[j * nScaleWidth * 4 + nRight * 4 + 3] <= ALPHA ||
                   pMaskImageBuffer[nTop * nScaleWidth * 4 + i * 4 + 3] <= ALPHA ||
                   pMaskImageBuffer[nBottom * nScaleWidth * 4 + i * 4 + 3] <= ALPHA)
                {
                    m_sSelectBoundPoints.points[m_sSelectBoundPoints.nPointNumber].x = i;
                    m_sSelectBoundPoints.points[m_sSelectBoundPoints.nPointNumber].y = j;
                    m_sSelectBoundPoints.nPointNumber++;
                    
                }
            }
            else if(i == 0 || (i == (nScaleWidth - 1)) || (j == 0) || (j == (nScaleHeight - 1))) //选区边界点
            {
                m_sSelectBoundPoints.points[m_sSelectBoundPoints.nPointNumber].x = i;
                m_sSelectBoundPoints.points[m_sSelectBoundPoints.nPointNumber].y = j;
                m_sSelectBoundPoints.nPointNumber++;
            }
        }
    }
    
    free(pMaskImageBuffer);
}

-(void)drawMarchingAntsWithBoundPoints:(CGContextRef)context selectBoundPoints:(POINTSET)selectBoundPoints
{
    float fScaleX = [[m_idDocument contents] xscale];
    float fScaleY = [[m_idDocument contents] yscale];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntRect selectRect = [[m_idDocument selection] globalRect];
   
//    double d1 = [[NSDate date] timeIntervalSince1970];
    
    CGRect blackRects[kMaxPoints/2];
    CGRect whiteRects[kMaxPoints/2];
    int nBlackRectCount, nWhiterRectCount;
    nBlackRectCount = nWhiterRectCount = 0;

   
    float fPhase = fmodl([[NSDate date] timeIntervalSince1970]*10, 8);
//    static float fPhase = 0;
//    if(fPhase >= 10) fPhase = 0;
//    fPhase += 1;
    
    for(int nIndex = 0; nIndex < selectBoundPoints.nPointNumber; nIndex++)
    {
        int nPointX = selectBoundPoints.points[nIndex].x;
        int nPointY = selectBoundPoints.points[nIndex].y;
        
        if(fmodf(nPointX + nPointY + fPhase, 8) > 3.0)
        {
            blackRects[nBlackRectCount] = CGRectMake((int)(nPointX + (selectRect.origin.x-maskOffset.x)*fScaleX), (int)(nPointY + (selectRect.origin.y-maskOffset.y) * fScaleY), 1.0, 1.0);
            nBlackRectCount ++;
            
        }
        else
        {
            whiteRects[nWhiterRectCount] = CGRectMake((int)(nPointX + (selectRect.origin.x-maskOffset.x)*fScaleX), (int)(nPointY + (selectRect.origin.y-maskOffset.y) * fScaleY), 1.0, 1.0);
            nWhiterRectCount ++;
        }
    }
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRects(context, blackRects, nBlackRectCount);
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillRects(context, whiteRects, nWhiterRectCount);
    
//    double d2 = [[NSDate date] timeIntervalSince1970] - d1;
//   
//    printf("time %f\n",d2);
}*/

-(void)updateMarchingAntsBoundPoints
{
    NSImage *maskImage = [(PSSelection*)[m_idDocument selection] maskImage];
    if(!maskImage) return;
    
    IntSize selectMaskSize = [[m_idDocument selection] maskSize];
    float fScaleX = [[m_idDocument contents] xscale];
    float fScaleY = [[m_idDocument contents] yscale];
    int nScaleWidth = selectMaskSize.width * fScaleX;
    int nScaleHeight = selectMaskSize.height * fScaleY;
    
    if(nScaleHeight == 0 || (nScaleWidth == 0))
    {
        if (m_maSelectBoundPoints)
            [m_maSelectBoundPoints removeAllObjects];
        return;
    }
    //获取Image buffer
    unsigned char *pMaskImageBuffer = malloc(nScaleWidth * nScaleHeight * 4);
    memset(pMaskImageBuffer, 0, nScaleWidth * nScaleHeight * 4);
    GetNSImageBuffer(maskImage, nScaleWidth, nScaleHeight, pMaskImageBuffer, 1);
    
    if (m_maSelectBoundPoints)
        [m_maSelectBoundPoints removeAllObjects];
    
    for (int j = 0; j < nScaleHeight; j++)
    {
        for (int i = 0; i < nScaleWidth; i++)
        {
            if(pMaskImageBuffer[j * nScaleWidth * 4 + i * 4 + 3] > ALPHA)
            {
                int nLeft = i - 1;
                int nRight = i + 1;
                int nTop = j - 1;
                int nBottom = j + 1;
                
                if(i - 1 < 0)
                    nLeft = 0;
                if(i + 1 > nScaleWidth -1)
                    nRight = nScaleWidth -1;
                if(j - 1 < 0)
                    nTop = 0;
                if(j + 1 > nScaleHeight -1)
                    nBottom = nScaleHeight -1;
                
                if(pMaskImageBuffer[j * nScaleWidth * 4 + nLeft * 4 + 3] <= ALPHA ||
                   pMaskImageBuffer[j * nScaleWidth * 4 + nRight * 4 + 3] <= ALPHA ||
                   pMaskImageBuffer[nTop * nScaleWidth * 4 + i * 4 + 3] <= ALPHA ||
                   pMaskImageBuffer[nBottom * nScaleWidth * 4 + i * 4 + 3] <= ALPHA)
                {
                    [m_maSelectBoundPoints addObject:[NSValue valueWithPoint:NSMakePoint(i, j)]];
                }
            }
            else if(i == 0 || (i == (nScaleWidth - 1)) || (j == 0) || (j == (nScaleHeight - 1))) //选区边界点
            {
                [m_maSelectBoundPoints addObject:[NSValue valueWithPoint:NSMakePoint(i, j)]];
            }
        }
    }
    
    free(pMaskImageBuffer);
}

-(void)drawMarchingAntsWithBoundPoints:(CGContextRef)context selectBoundPoints:(NSMutableArray *)maSelectBoundPoints
{
    float fScaleX = [[m_idDocument contents] xscale];
    float fScaleY = [[m_idDocument contents] yscale];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntRect selectRect = [[m_idDocument selection] globalRect];
    
    static CGRect blackRects[kMaxPoints/2];
    static CGRect whiteRects[kMaxPoints/2];
    int nBlackRectCount, nWhiterRectCount;
    nBlackRectCount = nWhiterRectCount = 0;
    
    
    float fPhase = fmodl([[NSDate date] timeIntervalSince1970]*10, 8);
    
    for(int nIndex = 0; nIndex < [maSelectBoundPoints count]; nIndex++)
    {
        NSPoint point = [[maSelectBoundPoints objectAtIndex:nIndex] pointValue];
        int nPointX = point.x;
        int nPointY = point.y;
        
        if(fmodf(nPointX + nPointY + fPhase, 8) > 3.0)
        {
            blackRects[nBlackRectCount] = CGRectMake((int)(nPointX + (selectRect.origin.x-maskOffset.x)*fScaleX), (int)(nPointY + (selectRect.origin.y-maskOffset.y) * fScaleY), 1.0, 1.0);
            nBlackRectCount ++;
        }
        else
        {
            whiteRects[nWhiterRectCount] = CGRectMake((int)(nPointX + (selectRect.origin.x-maskOffset.x)*fScaleX), (int)(nPointY + (selectRect.origin.y-maskOffset.y) * fScaleY), 1.0, 1.0);
            nWhiterRectCount ++;
        }
    }
    
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRects(context, blackRects, nBlackRectCount);
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillRects(context, whiteRects, nWhiterRectCount);
}


- (void)checkMouseTracking
{
	if ([[self window] isMainWindow]) {
		if ([[m_idDocument scrollView] rulersVisible] || [[[PSController utilitiesManager] infoUtilityFor:m_idDocument] visible])
			[[self window] setAcceptsMouseMovedEvents:YES];
		else
			[[self window] setAcceptsMouseMovedEvents:NO];
	}
}

- (void)updateRulerMarkings:(NSPoint)mouseLocation andStationary:(NSPoint)statLocation
{
	NSPoint markersLocation, statMarkersLocation;
	
	// Only make a change if it has been more than 0.03 seconds
	if ([[NSDate date] timeIntervalSinceDate:m_dateLastRulerUpdate] > 0.03) {
	
		// Record this as the new time of the last update
		[m_dateLastRulerUpdate autorelease];
		m_dateLastRulerUpdate = [NSDate date];
		[m_dateLastRulerUpdate retain];
	
		// Get mouse location and convert it
		markersLocation.x = [[m_rvHorizontalRuler clientView] convertPoint:mouseLocation fromView:nil].x;
		markersLocation.y = [[m_rvVerticalRuler clientView] convertPoint:mouseLocation fromView:nil].y;
		statMarkersLocation.x = [[m_rvHorizontalRuler clientView] convertPoint:statLocation fromView:nil].x;
		statMarkersLocation.y = [[m_rvVerticalRuler clientView] convertPoint:statLocation fromView:nil].y;
		
		// Move the horizontal marker
		[m_rmHMarker setMarkerLocation:markersLocation.x];
		[m_rmHStatMarker setMarkerLocation:statMarkersLocation.x];
		[m_rvHorizontalRuler setNeedsDisplay:YES];
		
		// Move the vertical marker
		[m_rmVMarker setMarkerLocation:markersLocation.y];
		[m_rmVStatMarker setMarkerLocation:statMarkersLocation.y];
		[m_rvVerticalRuler setNeedsDisplay:YES];
	
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	if ([[[PSController utilitiesManager] infoUtilityFor:m_idDocument] visible]) [[[PSController utilitiesManager] infoUtilityFor:m_idDocument] update];
	if ([[m_idDocument scrollView] rulersVisible]) [self updateRulerMarkings:[theEvent locationInWindow] andStationary:NSMakePoint(-256e6, -256e6)];
    //NSLog(@"ddddd");
//    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
//    if (curToolIndex == kTransformTool) {
//        PSTransformTool* curTool = [[m_idDocument tools] currentTool];
//       NSPoint globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
//        [curTool mouseMoveTo:globalPoint withEvent:theEvent];
//    }
    
    AbstractTool* curTool = [[m_idDocument tools] currentTool];
    NSPoint globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    [curTool mouseMoveTo:globalPoint withEvent:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	unsigned int mods;
	NSPoint globalPoint;
	
	// Check for zoom-in or zoom-out
	mods = [theEvent modifierFlags];
	if ((mods & NSAlternateKeyMask) >> 19)
    {
		globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
		
		m_fScrollZoom += ([theEvent deltaY] > 0.0) ? 1.0 : -1.0;
         if (m_fScrollZoom - m_fLastTrigger > 1.0)//10.0)
         {
             m_fLastTrigger = m_fScrollZoom;
             [self zoomInToPoint:globalPoint];
         }
         else if (m_fScrollZoom - m_fLastTrigger < -1.0)//-10.0)
         {
             m_fLastTrigger = m_fScrollZoom;
             [self zoomOutFromPoint:globalPoint];
         }
	}
	else {
        
        [self setRefreshWhiteboardImage:NO];
		[super scrollWheel:theEvent];
	}
 
}

- (void)readjust:(BOOL)scaling
{
	#ifdef USE_CENTERING_CLIPVIEW
	NSPoint point = [(CenteringClipView *)[self superview] centerPoint];
	#else
	NSPoint point = NSMakePoint(0, 0);
	#endif
	NSRect frame;
	
    float zoom = [self zoom];
	// Readjust the frame
	frame = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width], [(PSContent *)[m_idDocument contents] height]);
	if (gScreenResolution.x != 0 && [[m_idDocument contents] xres] != gScreenResolution.x) frame.size.width /= ((float)[[m_idDocument contents] xres] / gScreenResolution.x);
	if (gScreenResolution.y != 0 && [[m_idDocument contents] yres] != gScreenResolution.y) frame.size.height /= ((float)[[m_idDocument contents] yres] / gScreenResolution.y);
	frame.size.height *= zoom; frame.size.width *= zoom;
	if (scaling) {
		point.x *= frame.size.width / [self frame].size.width;
		point.y *= frame.size.height / [self frame].size.height;
	}
	[self setFrame:frame];
	#ifdef USE_CENTERING_CLIPVIEW
	[(CenteringClipView *)[self superview] setCenterPoint:point];
	#endif
	[self setNeedsDisplay:YES];
}

#ifdef MACOS_10_4_COMPILE
- (void)tabletProximity:(NSEvent *)theEvent
{
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
		m_nTabletEraser = 0;
		if ([theEvent isEnteringProximity] && [theEvent pointingDeviceType] == NSEraserPointingDevice) {
			m_nTabletEraser = 2;
		}
	}
}
#endif

- (void)tabletPoint:(NSEvent *)theEvent
{
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self mouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [self stopDrawSelectionBoundariesTimer];
    
	float xScale, yScale;
	id curTool;
	IntPoint localActiveLayerPoint;
	NSPoint localPoint, globalPoint;
	//int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	AbstractOptions* options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] currentOptions];
   
    [self expandAndTrimLayer:YES];
	
	// Get xScale, yScale	
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];
	
	// Check if we are in scrolling mode
	if (m_bScrollingMode)
    {
		[m_idCursorsManager setScrollingMode: YES mouseDown:YES];
		[self needsCursorsReset];
		m_poiLastScrollPoint = [theEvent locationInWindow];
		return;
	}
	

	/* else if(curToolIndex == kCropTool || curToolIndex == kPositionTool) {
		IntRect localRect;
		if(curToolIndex == kCropTool){
			CropTool *tool = [[m_idDocument tools] getTool:kCropTool];
			localRect = [tool cropRect];
		}else {
			localRect = [[[m_idDocument contents] activeLayer] localRect];
		}

		m_nScalingDir = [self point: [self convertPoint:[theEvent locationInWindow] fromView:NULL] isInHandleFor: localRect];
		if(m_nScalingDir >= 0){
			if(curToolIndex == kCropTool){
				m_nScalingMode = kCropScalingMode;
			}else {
				m_nScalingMode = kPositionScalingMode;
			}

			preScaledRect = localRect;
			preScaledMask = NULL;
			return;
		}
	}	 */
    // Get the current tool
    curTool = [[m_idDocument tools] currentTool];
    [curTool checkCurrentLayerIsSupported];
    
	// Check if it is a line draw
//	if (m_bLineDraw) {
//		[self mouseDragged:theEvent];
//		return;
//	}
    
    m_bLineDraw = NO;
    if ([curTool acceptsLineDraws] && ([options modifier] == kShiftModifier || [options modifier] == kShiftControlModifier)) {
        m_bLineDraw = YES;
        [self mouseDragged:theEvent];
        return;
    }
	
	// Calculate the localPoint and localActiveLayerPoint
	m_poiMouseDownLoc = [theEvent locationInWindow];
	globalPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	localPoint.x = globalPoint.x / xScale;
	localPoint.y = globalPoint.y / yScale;
	localActiveLayerPoint.x = localPoint.x - [[[m_idDocument contents] activeLayer] xoff];
	localActiveLayerPoint.y = localPoint.y - [[[m_idDocument contents] activeLayer] yoff];
	
	// Turn mouse coalescing on or off
	if ([curTool useMouseCoalescing] || [(PSPrefs *)[PSController m_idPSPrefs] mouseCoalescing] || m_bScrollingMode){
        [NSEvent setMouseCoalescingEnabled:true];
//		SetMouseCoalescingEnabled(true, NULL);
	}else{
        [NSEvent setMouseCoalescingEnabled:false];
//		SetMouseCoalescingEnabled(false, NULL);
	}
	
	// Check for tablet events
	#ifdef MACOS_10_4_COMPILE
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
		if (m_nTabletEraser < 2) {
			m_nTabletEraser = 0;
			if ([theEvent subtype] == NSTabletProximityEventSubtype) {
				if ([theEvent pointingDeviceType] == NSEraserPointingDevice) {
					m_nTabletEraser = 1;
				}
			}
		}
	}
	#endif
	
	// Reset the deltas
	m_sDelta = IntMakePoint(0,0);
	m_sInitialPoint = NSPointMakeIntPoint(localPoint);
	
	// Determine special value
	if (([theEvent buttonNumber] == 1) || m_nTabletEraser) {
		[options forceAlt];
        
        [curTool updateCursor:theEvent];
	}
    
    //judge layer is hidden
    if (![self judgeIsSupportLayerHiddenForTool])
    {
        [[PSController seaWarning] showAlertInfo:NSLocalizedString(@"Could not use the tool because the target layer is hidden.", nil) infoText:@""];
        return;
    }
    if (![self judgeIsSupportChannelForTool])
    {
        [[PSController seaWarning] showAlertInfo:NSLocalizedString(@"Could not use the tool because the tool only supports editing full channel, please use another tool or switch to full channel.", nil) infoText:@""];
        return;
    }
	
	// Run the event
	[m_idDocument lock];
//	if (curToolIndex == kZoomTool) {
//		if ([options modifier] == kAltModifier) {
//			if ([self canZoomOut])
//				[self zoomOutFromPoint:globalPoint];
//			else
//				NSBeep();
//		}
//		else {
//			if ([self canZoomIn])
//				[self zoomInToPoint:globalPoint];
//			else
//				NSBeep();
//		}
//	}
//	else
    if ([curTool isFineTool]) {
		[curTool fineMouseDownAt:localPoint withEvent:theEvent];
	}
	else {
        [curTool mouseDownAt:localActiveLayerPoint withEvent:theEvent];
	}
	m_sLastActiveLayerPoint = localActiveLayerPoint;
    
}

- (BOOL)judgeIsSupportLayerHiddenForTool
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex == kTransformTool || curToolIndex == kPencilTool || curToolIndex == kBrushTool || curToolIndex == kEraserTool || curToolIndex == kBucketTool || curToolIndex == kGradientTool || curToolIndex == kCloneTool || curToolIndex == kSmudgeTool || curToolIndex == kRedEyeRemoveTool || curToolIndex == kMyBrushTool || curToolIndex == kBurnTool || curToolIndex == kDodgeTool || curToolIndex == kSpongeTool || curToolIndex == kShapeTool)
    {
        if (![[[m_idDocument contents] activeLayer] visible]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)judgeIsSupportChannelForTool
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex == kCloneTool || curToolIndex == kSmudgeTool|| curToolIndex == kRedEyeRemoveTool|| curToolIndex == kMyBrushTool|| curToolIndex == kBurnTool|| curToolIndex == kDodgeTool|| curToolIndex == kSpongeTool) //curToolIndex == kBucketTool || curToolIndex == kGradientTool || 
    {
        PS_EDIT_CHANNEL_TYPE editType = [[[m_idDocument contents] activeLayer] editedChannelOfLayer];
        if (editType != kEditAllChannels) {
            return NO;
        }
    }
    return YES;
}

//- (BOOL)judgeIsValidPositionForTool:(NSEvent *)theEvent
//{
//    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
//    if (!NSPointInRect(point, self.bounds)) {
//        int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
//        if (curToolIndex == kTextTool)
//        {
//            return NO;
//        }
//    }
//    
//    return YES;
//}


- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	float xScale, yScale;
	id curTool;
	IntPoint localActiveLayerPoint;
	NSPoint localPoint;
	int curToolIndex, deltaX, deltaY;
	double angle;
	NSPoint origin, newScrollPoint;
	NSClipView *view;
	AbstractOptions* options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] currentOptions];
	
	NSRect visRect = [(NSClipView *)[self superview] documentVisibleRect];
	localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	/* When the user drags the mouse out of the currently visible view rect, they expect it to 
	scroll, probably proportionally to the distance they are outside of the view. Thus we need to
	calculate if we're outside of the view, and the scroll the view by that much.*/
	
	// Cancel any previous scroll options
	if(m_timScrollTimer){
		[m_timScrollTimer invalidate];
		m_timScrollTimer = NULL;
	}
	
	float horzScroll = 0;
	float rightVis = visRect.origin.x + visRect.size.width;
	float rightAct = [(PSContent *)[m_idDocument contents] width] * [[m_idDocument contents] xscale];
	if(localPoint.x < visRect.origin.x){
		horzScroll = localPoint.x - visRect.origin.x;
		// This is so users don't scroll past the beginning
		if(-1 * horzScroll > visRect.origin.x){
			horzScroll = visRect.origin.x < 0 ? 0 : -1 * visRect.origin.x;
		}
	}else if(localPoint.x > rightVis){
		horzScroll = localPoint.x - rightVis;
		// And this is so users don't scroll past the end
		if(horzScroll > rightAct - rightVis){
			horzScroll = rightVis > rightAct ? 0 : rightAct - rightVis;
		}
	}
	
	
	float vertScroll = 0;
	float botVis = visRect.origin.y + visRect.size.height;
	float botAct = [(PSContent *)[m_idDocument contents] height] * [[m_idDocument contents] yscale];
	if(localPoint.y < visRect.origin.y){
		vertScroll = localPoint.y - visRect.origin.y;
		// This is so users don't scroll past the beginning
		if(-1 *vertScroll > visRect.origin.y){
			vertScroll = visRect.origin.y < 0 ? 0 : -1 * visRect.origin.y;
		}
	}else if(localPoint.y > botVis){
		vertScroll = localPoint.y - botVis;
		// And this is so users don't scroll past the end
		if(vertScroll > botAct - botVis){
			vertScroll = botVis > botAct ? 0 : botAct - botVis;
		}
	}
	
	// We will want the document to continue to scroll even if the user isn't sending mouse events
	// This means there needs to be some sort of timer to call the method automatically
	if(horzScroll != 0 || vertScroll != 0){
		//NSDictionary *uInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:horzScroll], @"x", [NSNumber numberWithFloat:vertScroll], @"y", nil];
		NSClipView *view = (NSClipView *)[self superview];
		NSPoint origin =  [view documentVisibleRect].origin;
		origin.x += horzScroll;
		origin.y += vertScroll;
		[view scrollToPoint:[view constrainScrollPoint:origin]];
		[(NSScrollView *)[view superview] reflectScrolledClipView:view];
		
		//m_timScrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target: self selector:@selector(autoScroll:) userInfo: theEvent repeats: YES];
	}
	
	// Check if we are in manual scrolling mode
	if (m_bScrollingMode) {
		newScrollPoint = [theEvent locationInWindow];
		view = (NSClipView *)[self superview];
		origin = visRect.origin;
		origin.x -= (newScrollPoint.x - m_poiLastScrollPoint.x) * 2;
		origin.y += (newScrollPoint.y - m_poiLastScrollPoint.y) * 2;
		[view scrollToPoint:[view constrainScrollPoint:origin]];
		[(NSScrollView *)[view superview] reflectScrolledClipView:view];
		m_poiLastScrollPoint = newScrollPoint;
		return;
	}
	
	// Set up tools
	curTool = [[m_idDocument tools] currentTool];
	curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	
	// Calculate the localPoint and localActiveLayerPoint
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];
	localPoint.x /= xScale;
	localPoint.y /= yScale;	
	localActiveLayerPoint.x = localPoint.x - [[[m_idDocument contents] activeLayer] xoff];
	localActiveLayerPoint.y = localPoint.y - [[[m_idDocument contents] activeLayer] yoff];
	
	// Snap to 45 degree intervals if requested
	deltaX = localActiveLayerPoint.x - m_sLastActiveLayerPoint.x;
	deltaY = localActiveLayerPoint.y - m_sLastActiveLayerPoint.y;
    
    if (m_bLineDraw) {
        if ([theEvent type] != NSLeftMouseDown) {
            return;
        }
    }
	if (m_bLineDraw && ([options modifier] == kShiftControlModifier) && deltaX != 0) {
		angle = atan((double)deltaY / (double)abs(deltaX));
		if (angle > -0.3927 && angle < 0.3927)
			localActiveLayerPoint.y = m_sLastActiveLayerPoint.y;
		else if (angle > 1.1781 || angle < -1.1781)
			localActiveLayerPoint.x = m_sLastActiveLayerPoint.x;
		else if (angle > 0.0)
			localActiveLayerPoint.y = m_sLastActiveLayerPoint.y + abs(deltaX);
		else 
			localActiveLayerPoint.y = m_sLastActiveLayerPoint.y - abs(deltaX);
        
	}
    
	
	// Determine the delta
	m_sDelta.x = localPoint.x - m_sInitialPoint.x;
	m_sDelta.y = localPoint.y - m_sInitialPoint.y;
    
    //judge layer is hidden
    if (![self judgeIsSupportLayerHiddenForTool])
    {
        return;
    }
    if (![self judgeIsSupportChannelForTool])
    {
        return;
    }

	// Behave differently depending on current tool
	if ([curTool isFineTool]) {
		[(AbstractTool *)curTool fineMouseDraggedTo:localPoint withEvent:theEvent];
	}
	else {
		[(AbstractTool *)curTool mouseDraggedTo:localActiveLayerPoint withEvent:theEvent];
	}
    m_sLastActiveLayerPoint = localActiveLayerPoint;
	//m_bLineDraw = NO;
	
	// Update the info utility
	if ([[[PSController utilitiesManager] infoUtilityFor:m_idDocument] visible]) [[[PSController utilitiesManager] infoUtilityFor:m_idDocument] update];
	if ([[m_idDocument scrollView] rulersVisible]) [self updateRulerMarkings:[theEvent locationInWindow] andStationary:m_poiMouseDownLoc];
}


- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [self performSelector:@selector(restoreDrawSelectionBoundariesTimer) withObject:nil afterDelay:1.0];
    
	float xScale, yScale;
	id curTool = [[m_idDocument tools] currentTool];
	NSPoint localPoint;
	IntPoint localActiveLayerPoint;
	AbstractOptions* options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] currentOptions];
	
	// Get xScale, yScale
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];
	
	// Return to normal coalescing
//	SetMouseCoalescingEnabled(true, NULL);
    [NSEvent setMouseCoalescingEnabled:true];
	
	// Check if we are in scrolling mode
	if (m_bScrollingMode) {
		[m_idCursorsManager setScrollingMode: YES mouseDown: NO];
		[self needsCursorsReset];
		return;
	}
	
	// Check if it is a line draw
//    m_bLineDraw = NO;
//	if ([curTool acceptsLineDraws] && ([options modifier] == kShiftModifier || [options modifier] == kShiftControlModifier)) {
//		m_bLineDraw = YES;
//		return;
//	}
    
    if (m_bLineDraw) {
        //[self mouseDragged:theEvent];
        return;
    }

	// Calculate the localPoint and localActiveLayerPoint
	m_poiMouseDownLoc = NSMakePoint(-256e6, -256e6);
	localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	localPoint.x /= xScale;
	localPoint.y /= yScale;
	localActiveLayerPoint.x = localPoint.x - [[[m_idDocument contents] activeLayer] xoff];
	localActiveLayerPoint.y = localPoint.y - [[[m_idDocument contents] activeLayer] yoff];
	
	// First treat this as an ordinary drag
	[self mouseDragged:theEvent];
	
	// Reset the delta
	m_sDelta = IntMakePoint(0,0);
    
    //judge layer is hidden
    if (![self judgeIsSupportLayerHiddenForTool])
    {
        return;
    }
    if (![self judgeIsSupportChannelForTool])
    {
        return;
    }

	// Run the event
	[m_idDocument unlock];
	if ([curTool isFineTool]) {
		[curTool fineMouseUpAt:localPoint withEvent:theEvent];
	}
	else {
		[curTool mouseUpAt:localActiveLayerPoint withEvent:theEvent];
	}
	
	// Unforce alt
	[options unforceAlt];
    
    [curTool updateCursor:theEvent];
    
    [self expandAndTrimLayer:NO];
    
}


- (void)expandAndTrimLayer:(BOOL)isExpand
{
    return;  //wzq should move to tool
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex == kBrushTool || curToolIndex == kMyBrushTool || curToolIndex == kPencilTool || curToolIndex == kGradientTool)
    {
        if (isExpand)
        {
            [[[m_idDocument contents] activeLayer] expandLayerTemply:nil];
        }
        else
        {
            [[[m_idDocument contents] activeLayer] trimLayer];
        }
        [[m_idDocument whiteboard] readjustLayer:NO];
    }
}

- (IntPoint)delta
{
	return m_sDelta;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	[(AbstractOptions *)[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] currentOptions] updateModifiers:[theEvent modifierFlags]];
	[[m_idDocument helpers] endLineDrawing];
    
    AbstractTool* curTool = [[m_idDocument tools] currentTool];

    [curTool updateCursor:theEvent];
}

- (void)undoMoveSelection:(IntPoint)origin
{
    IntPoint oldOrigin = [[m_idDocument selection] globalRect].origin;
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMoveSelection:oldOrigin];
    [[m_idDocument selection] moveSelection:origin];
}

- (void)keyDown:(NSEvent *)theEvent
{
	int whichKey, whichLayer, xoff, yoff;
	id curLayer, activeLayer;
	IntPoint oldOffsets;
	unichar key;
	unsigned int mods;
	int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	BOOL floating = [[m_idDocument selection] floating];
	
	// End the line drawing
	[[m_idDocument helpers] endLineDrawing];
    
	
	// Check for zoom-in or zoom-out
	mods = [theEvent modifierFlags];
	if ((mods & NSCommandKeyMask) >> 20) {
		for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
			key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
			if (key == NSUpArrowFunctionKey)
				[self zoomIn:NULL];
			else if (key == NSDownArrowFunctionKey)
				[self zoomOut:NULL];
		}
	}
	
	// Don't do anything if a modifier is down
	// Actually, we may want to do something with the option key
	if (((mods & NSControlKeyMask) >> 18) || ((mods & NSCommandKeyMask) >> 20))
		return;
	
	// Go through all keys
	for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
	
		// Find the key
		key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
		
		// For arrow nudging
		if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey || key == NSLeftArrowFunctionKey || key == NSRightArrowFunctionKey) {
			int nudge = ((mods & NSAlternateKeyMask) >> 19) ? 10 : 1;
            
            NSPoint offset = CGPointMake(0, 0);
            switch (key) {
                case NSUpArrowFunctionKey:
                    offset.y = -nudge;
                    break;
                    
                case NSDownArrowFunctionKey:
                    offset.y = nudge;
                    break;
                    
                case NSLeftArrowFunctionKey:
                    offset.x = -nudge;
                    break;
                    
                case NSRightArrowFunctionKey:
                    offset.x = nudge;
                    break;
                    
                default:
                    break;
            }
            if ([[[m_idDocument tools] currentTool] moveKeyPressedOffset:offset needUndo:NO]) {
                continue;
            }
            
			// Get the active layer
			activeLayer = [[m_idDocument contents] activeLayer];
		
			// Undo to the old position
			if (m_bKeyWasUp) {
                //NSLog(@"m_bKeyWasUp");
                if (curToolIndex == kCropTool) {
                    
                }
                else if ([[m_idDocument selection] active] && ![[m_idDocument selection] floating]) {
                    IntPoint oldOffsets = [[m_idDocument selection] globalRect].origin;
                    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMoveSelection:oldOffsets];
                }
                else{
                    // If the active layer is linked we have to move all associated layers
                    if ([activeLayer linked]) {
                        // Go through all linked layers allowing a satisfactory undo
                        for (whichLayer = 0; whichLayer < [[m_idDocument contents] layerCount]; whichLayer++) {
                            curLayer = [[m_idDocument contents] layer:whichLayer];
                            if ([curLayer linked]) {
                                oldOffsets.x = [curLayer xoff]; oldOffsets.y = [curLayer yoff];
                                [[[m_idDocument undoManager] prepareWithInvocationTarget:[[m_idDocument tools] getTool:kPositionTool]] undoToOrigin:oldOffsets forLayer:whichLayer];
                            }
                        }
                        
                    }
                    else {
                        //正常情况下不会走
                        oldOffsets.x = [activeLayer xoff]; oldOffsets.y = [activeLayer yoff];
                        [[[m_idDocument undoManager] prepareWithInvocationTarget:[[m_idDocument tools] getTool:kPositionTool]] undoToOrigin:oldOffsets forLayer:[[m_idDocument contents] activeLayerIndex]];
                    }
                
                }
                
				
				m_bKeyWasUp = NO;
				
			}
			
			// If there is a selection active move the selection otherwise move the layer
			if (curToolIndex == kCropTool) {
			
				// Make the adjustment
				switch (key) {
					case NSUpArrowFunctionKey:
						[[[m_idDocument tools] currentTool] adjustCrop:IntMakePoint(0, -1 * nudge)];
					break;
					case NSDownArrowFunctionKey:
						[[[m_idDocument tools] currentTool] adjustCrop:IntMakePoint(0, nudge)];
					break;
					case NSLeftArrowFunctionKey:
						[[[m_idDocument tools] currentTool] adjustCrop:IntMakePoint(-1 * nudge, 0)];
					break;
					case NSRightArrowFunctionKey:
						[[[m_idDocument tools] currentTool] adjustCrop:IntMakePoint(nudge, 0)];
					break;
				}
				
			
			}
			else if ([[m_idDocument selection] active] && ![[m_idDocument selection] floating]) {
			
				// Make the adjustment
				switch (key) {
					case NSUpArrowFunctionKey:
						[[m_idDocument selection] adjustOffset:IntMakePoint(0, -1 * nudge)];
					break;
					case NSDownArrowFunctionKey:
						[[m_idDocument selection] adjustOffset:IntMakePoint(0, nudge)];
					break;
					case NSLeftArrowFunctionKey:
						[[m_idDocument selection] adjustOffset:IntMakePoint(-1 * nudge, 0)];
					break;
					case NSRightArrowFunctionKey:
						[[m_idDocument selection] adjustOffset:IntMakePoint(nudge, 0)];
					break;
				}
				
				// Advise the change has taken place
				[[m_idDocument helpers] selectionChanged];
			
			}
			else {
			
				// If the active layer is linked we have to move all associated layers
				if ([activeLayer linked]) {
				
					// Move all of the linked layers
					for (whichLayer = 0; whichLayer < [[m_idDocument contents] layerCount]; whichLayer++) {
						curLayer = [[m_idDocument contents] layer:whichLayer];
						if ([curLayer linked]) {
						
							// Get the old position
							xoff = [curLayer xoff]; yoff = [curLayer yoff];
							
							// Make the adjustment
							switch (key) {
								case NSUpArrowFunctionKey:
									[curLayer setOffsets:IntMakePoint(xoff, yoff - nudge)];
								break;
								case NSDownArrowFunctionKey:
									[curLayer setOffsets:IntMakePoint(xoff, yoff + nudge)];
								break;
								case NSLeftArrowFunctionKey:
									[curLayer setOffsets:IntMakePoint(xoff - nudge, yoff)];
								break;
								case NSRightArrowFunctionKey:
									[curLayer setOffsets:IntMakePoint(xoff + nudge, yoff)];
								break;
							}
							
						}
					}
					oldOffsets.x = [activeLayer xoff]; oldOffsets.y = [activeLayer yoff];
					[[m_idDocument helpers] layerOffsetsChanged:kLinkedLayers from:oldOffsets];
					
				}
				else {
				
					// Get the old position
					xoff = [activeLayer xoff]; yoff = [activeLayer yoff];
				
					// Make the adjustment
					switch (key) {
						case NSUpArrowFunctionKey:
							[activeLayer setOffsets:IntMakePoint(xoff, yoff - nudge)];
						break;
						case NSDownArrowFunctionKey:
							[activeLayer setOffsets:IntMakePoint(xoff, yoff + nudge)];
						break;
						case NSLeftArrowFunctionKey:
							[activeLayer setOffsets:IntMakePoint(xoff - nudge, yoff)];
						break;
						case NSRightArrowFunctionKey:
							[activeLayer setOffsets:IntMakePoint(xoff + nudge, yoff)];
						break;
					}
					
					// Advise the change has taken place
					oldOffsets = IntMakePoint(xoff, yoff);
					[[m_idDocument helpers] layerOffsetsChanged:kActiveLayer from:oldOffsets];
					
				}
			
			}
			
		}
		
		// No repeat keys
		if (![theEvent isARepeat]) {
			// For window configurations and keyboard shortcuts
            
            if (key == 'm' || key == 'l' || key == 'b' || key == 'g' || key == 't' || key == 'e' || key == 'o') {
                if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] lastCombinedToolType] != key) {
                    int lastTool = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] lastCombinedTool:key];
                    if (lastTool > 0) {
                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:lastTool];
                        return;
                    }
                }
            }
            
            BOOL bChanged = [self changeToolOnKey:key];
            if(bChanged) return;
            
			switch (key) {
				case kEscapeCharCode:
                {
                    [[[m_idDocument tools] currentTool] stopCurrentOperation];
                    [self setNeedsDisplay:YES];
                }
				break;
                    
                case kDeleteCharCode:
                case NSDeleteFunctionKey:
                {
                    if (![[[m_idDocument tools] currentTool] deleteKeyPressed]) {
                        if ([[m_idDocument selection] active]) {
                            [[m_idDocument selection] deleteSelection];
                        }else{
                            [(PSContent *)[m_idDocument contents] deleteLayer:kActiveLayer];
                        }
                    }
                    
                }
                    break;
                    
                case '\r':
                case kEnterCharCode:{
                    [[m_idDocument warnings] keyTriggered];
                    [[[m_idDocument tools] currentTool] enterKeyPressed];
                }
                    break;

                    
//				case 'm':
//					if (!floating) {
//                        if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] lastCombinedToolType] != key) {
//                            int lastTool = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] lastCombinedTool:key];
//                            if (lastTool > 0) {
//                                [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:lastTool];
//                                break;
//                            }
//                        }
//						if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kRectSelectTool)
//							[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kEllipseSelectTool];
//						else
//							[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kRectSelectTool];
//					}
//				break;
//				case 'l':
//					if (!floating) {
//						if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kLassoTool)
//							[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kPolygonLassoTool];
//						else
//							[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kLassoTool];
//					}
//				break;
//				case 'w':
//					if (!floating) {
//						[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kWandTool];
//					}
//				break;
//				case 'b':
//                    if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kMyBrushTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kPencilTool];
//                    else if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kPencilTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kBrushTool];
//                    else
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kMyBrushTool];
//				break;
//				case 'g':
//					if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kBucketTool)
//						[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kGradientTool];
//					else
//						[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kBucketTool];
//				break;
//				case 't':
////					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kTextTool];
//                    if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kTextTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kTransformTool];
//                    else
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kTextTool];
//				break;
//				case 'e':
////					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kEraserTool];
//                    if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kEraserTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kVectorEraserTool];
//                    else
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kEraserTool];
//				break;
//				case 'i':
//					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kEyedropTool];
//				break;
//				case 'o':
//                    if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kSmudgeTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kBurnTool];
//                    else if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kBurnTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kDodgeTool];
//                    else if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kDodgeTool)
//                        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kSpongeTool];
//					else
//						[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kSmudgeTool];
//				break;
//				case 's':
//					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kCloneTool];
//				break;
//				case 'c':
//					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kCropTool];
//				break;
//				case 'z':
//					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kZoomTool];
//				break;
//				case 'v':
//					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kPositionTool];
//				break;
//                case 'u':
//                    [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kShapeTool];
//                    break;
//                case 'a':
//                    [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kVectorMoveTool];
//                    break;
//                case 'p':
//                    [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kVectorPenTool];
//                    break;
//                case 'r':
//                    [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kRedEyeRemoveTool];
//                    break;
				case 'x':
					[[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] colorView] swapColors: self];
				break;
				case 'd':
					[[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] colorView] defaultColors: self];
				break;
				case '\t':
					m_nEyedropToolMemory = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
					[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kEyedropTool];
				break;
                    
                case '[':{
                    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
                    if(curToolIndex == kMyBrushTool){
                        [[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool] addRadius:NO];
                        AbstractTool* curTool = [[m_idDocument tools] currentTool];
                        [curTool updateCursor:theEvent];

                    }
                }
                    break;
                    
                case ']':{
                    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
                    if(curToolIndex == kMyBrushTool){
                        [[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool] addRadius:YES];
                        AbstractTool* curTool = [[m_idDocument tools] currentTool];
                        [curTool updateCursor:theEvent];

                    }
                }
                    break;
				
			}

			// Activate scrolling mode
			if (key == ' ' && ![m_idDocument locked]) {
				m_bScrollingMode = YES;
				[m_idCursorsManager setScrollingMode: YES mouseDown: NO];
				[self needsCursorsReset];
			}
		}
	}
}

- (void)keyUp:(NSEvent *)theEvent
{
	int whichKey;
	unichar key;
	
	// Go through all keys
	for (whichKey = 0; whichKey < [[theEvent characters] length]; whichKey++) {
	
		// Find the key
		key = [[theEvent charactersIgnoringModifiers] characterAtIndex:whichKey];
			
		// Deactivate scrolling mode
		switch (key) {
			case ' ':
				m_bScrollingMode = NO;
				[m_idCursorsManager setScrollingMode: NO mouseDown: NO];
				[self needsCursorsReset];
			break;
			case '\t':
				[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:m_nEyedropToolMemory];
			break;
		}
	
	}
	
	m_bKeyWasUp = YES;
}

-(BOOL)changeToolOnKey:(unichar)key
{
    BOOL bChangeTool = NO;
    //工具快捷键
    NSArray *array = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] allShowTools];
    if(!array) return bChangeTool;
    
    NSMutableArray *arrShotKey = [[NSMutableArray alloc] init];
    for (int nIndex = 0; nIndex < [array count]; nIndex++)
    {
        int nToolIndex = [[array objectAtIndex:nIndex] intValue];
        unichar cShotKey = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] getToolShotKey:nToolIndex];
        if(cShotKey == key)
            [arrShotKey addObject:[array objectAtIndex:nIndex]];
    }
    
    
    if([arrShotKey count] == 1)
    {
        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:[[arrShotKey objectAtIndex:0] intValue]];
        
        bChangeTool = YES;
    }
    else if([arrShotKey count] > 1)
    {
        int nCurrentToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
        unichar cCurrentToolShotKey = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] getToolShotKey:nCurrentToolIndex];
        
        if(cCurrentToolShotKey == key) //这组按钮进行切换
        {
            int nCurrentToolInGroupIndex;
            for(int nIndex = 0; nIndex < [arrShotKey count]; nIndex++)
            {
                int nToolIndex = [[arrShotKey objectAtIndex:nIndex] intValue];
                if(nToolIndex == nCurrentToolIndex)
                {
                    nCurrentToolInGroupIndex = nIndex;
                }
            }
            
            nCurrentToolInGroupIndex++;
            if(nCurrentToolInGroupIndex == [arrShotKey count]) nCurrentToolInGroupIndex = 0;
            
            [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:[[arrShotKey objectAtIndex:nCurrentToolInGroupIndex] intValue]];
        }
        else  //切换到这组当前显示的tool
        {
            [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:[[arrShotKey objectAtIndex:0] intValue]];
        }
        
        bChangeTool = YES;
    }
    
    [arrShotKey release];
    
    return bChangeTool;
}


- (void)autoScroll:(NSTimer *)theTimer
{
	// The point of autoscrolling is that we simulate another mouse event
	// outside of the bounds, but that we're moving the viewport to keep
	// that even inside what the user sees.
	[self mouseDragged:[theTimer userInfo]];
}

- (void)clearScrollingMode
{
	m_bScrollingMode = NO;
	[m_idCursorsManager setScrollingMode: NO mouseDown: NO];
	[self needsCursorsReset];
}

- (void)magnifyWithEvent:(NSEvent *)event
{
	if(m_timMagnifyTimer){
		[m_timMagnifyTimer invalidate];
		m_timMagnifyTimer = NULL;
	}
	
	float factor = ((float)[event magnification] + 1.0);
	m_fMagnifyFactor = factor * m_fMagnifyFactor;
	m_timMagnifyTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
												   target: self
												 selector:@selector(clearMagnifySum:)
												 userInfo: event
												  repeats: NO];
}

- (void)swipeWithEvent:(NSEvent *)event {
    float x = [event deltaX];
    float y = [event deltaY];
    if (x > 0) {
		[[m_idDocument contents] layerBelow];
	}else if (x < 0) {
		[[m_idDocument contents] layerAbove];
	}else if (y < 0) {
		[[m_idDocument contents] anchorSelection];
	}else if (y > 0) {
		unsigned int mods = [event modifierFlags];
		[[m_idDocument contents] makeSelectionFloat:(mods & NSAlternateKeyMask) >> 19];
    }
}

- (void)clearMagnifySum:(NSTimer *)theTimer
{
	if(m_timMagnifyTimer){
		[m_timMagnifyTimer invalidate];
		m_timMagnifyTimer = NULL;
	}
	
	if(m_fMagnifyFactor >= 2){
		[self zoomIn:self];
	}else if (m_fMagnifyFactor <= 0.5) {
		[self zoomOut:self];
	}
	
	m_fMagnifyFactor = 1.0;
}

- (IBAction)cut:(id)sender
{
    if (![[m_idDocument selection] active])
        [self selectAll:nil];
	[[m_idDocument selection] cutSelection];
    
}

- (IBAction)copy:(id)sender
{
    if (![[m_idDocument selection] active])
        [self selectAll:nil];
	[[m_idDocument selection] copySelection];
}

- (IBAction)paste:(id)sender
{
    /// wzq
    if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kTextTool)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
        if([layer layerFormat] == PS_TEXT_LAYER)
        {

            NSString *str = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
            if(str != nil)
            {
                [[[m_idDocument tools] getTool:kTextTool] insertText:(id)str];
                return;
            }
        }
    }
    
	if ([[m_idDocument selection] active])
		[[m_idDocument selection] clearSelection];
    
	//[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:kRectSelectTool];
    [[m_idDocument contents] makePasteboardFloat:nil center:NSMakePoint(0, 0)];
}

- (IBAction)delete:(id)sender
{
	if ([[m_idDocument selection] floating]) {
		[[m_idDocument contents] deleteLayer:kActiveLayer];
		[[m_idDocument selection] clearSelection];
	}
	else {
		[[m_idDocument selection] deleteSelection];
	}
}

- (IBAction)selectionToAlpha:(id)sender
{
    
}

- (IBAction)selectAll:(id)sender
{
	//[[m_idDocument selection] selectRect:IntMakeRect(0, 0, [(PSLayer *)[[m_idDocument contents] activeLayer] width], [(PSLayer *)[[m_idDocument contents] activeLayer] height]) mode:kDefaultMode feather:0];
    [[m_idDocument selection] selectRect:IntMakeRect(0, 0, [(PSContent*)[m_idDocument contents] width], [(PSContent*)[m_idDocument contents] height]) mode:kDefaultMode feather:0];
}

- (IBAction)selectNone:(id)sender
{
	int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	
    if(curToolIndex >= kFirstSelectionTool && curToolIndex <= kLastSelectionTool && [[[m_idDocument tools] currentTool] intermediate]){
		//[[[m_idDocument tools] currentTool] cancelSelection];
    }
    else{
		[[m_idDocument selection] clearSelection];
    }
}

- (IBAction)selectInverse:(id)sender
{
	[[m_idDocument selection] invertSelection];
}

- (IBAction)selectOpaque:(id)sender
{
	[[m_idDocument selection] selectOpaque];
}

- (void)endLineDrawing
{
	m_bLineDraw = NO;
}

- (BOOL)isLineDrawing
{
    return m_bLineDraw;
}

- (IntPoint)getMousePosition:(BOOL)compensation
{
	NSPoint tempPoint;
	IntPoint localPoint;
	float xScale, yScale;
	id contents = [m_idDocument contents];
	
	xScale = [[m_idDocument contents] xscale];
	yScale = [[m_idDocument contents] yscale];
	localPoint.x = localPoint.y = -1;
	tempPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:NULL];
	// tempPoint.y = [self bounds].size.height - tempPoint.y;
	if (!NSMouseInRect(tempPoint, [self visibleRect], YES) || ![[self window] isVisible])
		return localPoint;
	localPoint.x = tempPoint.x / xScale;
	localPoint.y = tempPoint.y / yScale;
	if ([[m_idDocument whiteboard] whiteboardIsLayerSpecific] && compensation) {
		localPoint.x -= [[contents activeLayer] xoff];
		localPoint.y -= [[contents activeLayer] yoff];
		if (localPoint.x < 0 || localPoint.x >= [(PSLayer *)[contents activeLayer] width] || localPoint.y < 0 || localPoint.y >= [(PSLayer *)[contents activeLayer] height])
			localPoint.x = localPoint.y = -1;		
	}
	else {
		if (localPoint.x < 0 || localPoint.x >= [(PSContent *)[m_idDocument contents] width] || localPoint.y < 0 || localPoint.y >= [(PSContent *)[m_idDocument contents] height])
			localPoint.x = localPoint.y = -1;
	}
	
	return localPoint;
}

- (NSColor*)getScreenColor:(int)spp
{
    NSPoint where;
    NSColor *pixelColor;
    
    where = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:NULL];
    //where = [NSEvent mouseLocation];
    // NSReadPixel pulls data out of the current focused graphics context,
    // so you must first call lockFocus.
    [self lockFocus];
    pixelColor = NSReadPixel(where);
    [self unlockFocus];
    
    return pixelColor;
}

- (NSDragOperation)draggingEntered:(id)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	NSArray *files;
	id layer;
	int i;
	BOOL success;
	
	// Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
		layer = [[sender draggingSource] source];
	else
		layer = NULL;
	
	// Accept copy operations if possible
    if (sourceDragMask & NSDragOperationCopy) {
		if ([[pboard types] containsObject:NSTIFFPboardType] || [[pboard types] containsObject:NSPICTPboardType]) {
        	if (layer != [[m_idDocument contents] activeLayer] && ![m_idDocument locked] && ![[m_idDocument selection] floating] ) {
				return NSDragOperationCopy;
			}
        }
		if ([[pboard types] containsObject:NSFilenamesPboardType]) {
			if (layer != [[m_idDocument contents] activeLayer] && ![m_idDocument locked] && ![[m_idDocument selection] floating]) {
				files = [pboard propertyListForType:NSFilenamesPboardType];
				success = YES;
				for (i = 0; i < [files count]; i++)
					success = success && [[m_idDocument contents] canImportLayerFromFile:[files objectAtIndex:i]];
				if (success) {
					return NSDragOperationCopy;
				}
			}
		}
	}
	
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	NSArray *files;
	BOOL success;
	id layer;
	int i;
	
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSPoint point = [sender draggingLocation];
    point = [self convertPoint:point fromView:NULL];
    
    point.x = point.x / xScale;
    point.y = point.y / yScale;

	// Determine the pasteboard and acceptable dragging operations
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	if ([sender draggingSource] && [[sender draggingSource] respondsToSelector:@selector(source)])
		layer = [[sender draggingSource] source];
	else
		layer = NULL;

	if (sourceDragMask & NSDragOperationCopy) {
	
		// Accept TIFFs as new layers
		if ([[pboard types] containsObject:NSTIFFPboardType])
        {
			if (layer != NULL)
            {
				[[m_idDocument contents] copyLayer:layer];
				return YES;
			}
			else
            {
                [[m_idDocument contents] makePasteboardFloat:pboard center:point];  //wzq
                return YES;
            //    [[m_idDocument contents] addLayerFromPasteboard:pboard centerPointInCanvas:point];
			}
		}
		
		// Accept PICTs as new layers
		if ([[pboard types] containsObject:NSPICTPboardType]) {
            [[m_idDocument contents] addLayerFromPasteboard:pboard centerPointInCanvas:point];
            return YES;
		}
		
		// Accept files as new layers
		if ([[pboard types] containsObject:NSFilenamesPboardType])
        {
			files = [pboard propertyListForType:NSFilenamesPboardType];
			success = YES;
            
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert addButtonWithTitle:NSLocalizedString(@"New Document", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"New Layer", nil)];
            [alert setMessageText:NSLocalizedString(@"", nil) ];
            [alert setInformativeText:NSLocalizedString(@"Open File as ...", nil)];
            [alert setAlertStyle:NSWarningAlertStyle];
            
            NSModalResponse reCode = [alert runModal];
            if(reCode == NSAlertFirstButtonReturn) //Update Now
            {
                for (i = 0; i < [files count]; i++)
                {
                    
                    NSString *file = [files objectAtIndex:i];
                    NSURL *fileType = (NSString *)UTTypeCreatePreferredIdentifierForTag( kUTTagClassFilenameExtension,
                        (CFStringRef)[file pathExtension],
                        (CFStringRef)@"public.data");
                    
                    PSDocument *newDocument = [[PSDocument alloc] initWithContentsOfFile:file ofType:fileType];
                    [[NSDocumentController sharedDocumentController] addDocument:newDocument];
                    [newDocument makeWindowControllers];
                    [newDocument showWindows];
                    [newDocument autorelease];
                }
            }
            else                  //No
            {
                for (i = 0; i < [files count]; i++)
                    success = success && [[m_idDocument contents] importLayerFromFile:[files objectAtIndex:i]];
            }
	
			return success;
		}
        if ([[pboard types] containsObject:NSHTMLPboardType])
        {
            layer = NULL;
        
        }
        if ([[pboard types] containsObject:NSURLPboardType])
        {
            layer = NULL;
        }

	}

    return NO;
}

- (void)updateRulersVisiblity
{
	NSView *superview = [[m_idDocument scrollView] superview];
	int i;
	// This assumes that all of the subviews will actually respond to setRulersVisible
	for(i = 0; i < [[superview subviews] count]; i++){
		[[[superview subviews] objectAtIndex: i] setRulersVisible:[[PSController m_idPSPrefs] rulers]];
	}
	
	[self checkMouseTracking];
}

- (void)updateRulers
{
    float zoom = [self zoom];
	// Set up the rulers for the new settings
	switch ([m_idDocument measureStyle]) {
		case kPixelUnits:
            //add by lcz
            if (ABS([[m_idDocument contents] xres])<0.1) {
                NSLog(@"should not be here, updateRulers failed");
            }
			[NSRulerView registerUnitWithName:@"Custom Horizontal Pixels" abbreviation:@"px" unitToPointsConversionFactor:((float)[[m_idDocument contents] xres] / 72.0) * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:10.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
			[m_rvHorizontalRuler setMeasurementUnits:@"Custom Horizontal Pixels"];
			[NSRulerView registerUnitWithName:@"Custom Vertical Pixels" abbreviation:@"px" unitToPointsConversionFactor:((float)[[m_idDocument contents] yres] / 72.0) * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:10.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
			[m_rvVerticalRuler setMeasurementUnits:@"Custom Vertical Pixels"];
		break;
		case kInchUnits:
			[NSRulerView registerUnitWithName:@"Custom Inches" abbreviation:@"in" unitToPointsConversionFactor:72.0 * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:2.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
			[m_rvHorizontalRuler setMeasurementUnits:@"Custom Inches"];
			[m_rvVerticalRuler setMeasurementUnits:@"Custom Inches"];
		break;
		case kMillimeterUnits:
			[NSRulerView registerUnitWithName:@"Custom Millimetres" abbreviation:@"mm" unitToPointsConversionFactor:2.83464 * zoom stepUpCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:5.0]] stepDownCycle:[NSArray arrayWithObject:[NSNumber numberWithFloat:0.5]]];
			[m_rvHorizontalRuler setMeasurementUnits:@"Custom Millimetres"];
			[m_rvVerticalRuler setMeasurementUnits:@"Custom Millimetres"];
		break;
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{	
	[[self window] makeFirstResponder:self];
	
	return YES;
}

- (BOOL)resignFirstResponder 
{
	return YES;
	// WHY NOT?
	//return NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    BOOL bValidate = YES;
	id availableType;
	
	[[m_idDocument helpers] endLineDrawing];
	switch ([menuItem tag]) {
//		case 261: /* Copy */
//			if (![[m_idDocument selection] active])
//				return NO;
//		break;
//		case 260: /* Cut */
//			if (![[m_idDocument selection] active] || [[m_idDocument selection] floating])// || [[m_idDocument contents] selectedChannel] != kAllChannels)
//				return NO;
//		break;
		case 263: /* Delete */
			if (![[m_idDocument selection] active])// || [[m_idDocument contents] selectedChannel] != kAllChannels)
				return NO;
		break;
		case 270: /* Select All */
		case 273: /* Select Alpha */
			if ([[m_idDocument selection] floating])
				return NO;
		break;
		case 271: /* Select None */
			if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kPolygonLassoTool && [[[m_idDocument tools] currentTool] intermediate])
				bValidate = YES;
			if (![[m_idDocument selection] active] || [[m_idDocument selection] floating])
				return NO;
		break;
		case 272: /* Select Inverse */
			if (![[m_idDocument selection] active] || [[m_idDocument selection] floating])
				return NO;
		break;
		case 262: /* Paste */
			if ([[m_idDocument selection] floating])
				return NO;
            
            availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]];
            if (availableType)
                bValidate = YES;
            else
                bValidate = NO;
            
            if(!bValidate)
            {
                ///// wzq /////
                if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kTextTool)
                {
                    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
                    if([layer layerFormat] == PS_TEXT_LAYER)
                    {
                        NSString *str = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
                        if(str != nil)  bValidate = YES;
                    }
                }
            }
		break;
	}
    
    if(bValidate)
    {
        //根据当前工具确定
        bValidate = [[[gCurrentDocument tools] currentTool] validateMenuItem:menuItem];
    }
    if(bValidate)
    {
        //根据选中层确定菜单是否可用
        bValidate = [[gCurrentDocument contents] validateMenuItem:menuItem];
    }
	
	return bValidate;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if([[theItem itemIdentifier] isEqual: SelectNoneToolbarItemIdentifier]){
		if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kPolygonLassoTool && [[[m_idDocument tools] currentTool] intermediate])
			return YES;
		if (![[m_idDocument selection] active] || [[m_idDocument selection] floating])
			return NO;
	} else 	if([[theItem itemIdentifier] isEqual: SelectAllToolbarItemIdentifier] || [[theItem itemIdentifier] isEqual: SelectAlphaToolbarItemIdentifier] ){
		if ([[m_idDocument selection] floating])
			return NO;
	} else if([[theItem itemIdentifier] isEqual: SelectInverseToolbarItemIdentifier]){
		if (![[m_idDocument selection] active] || [[m_idDocument selection] floating])
			return NO;
	}
	
	return YES;
}

-(void)shutdown
{
    if(m_timerLoopDrawSelectBoundaries)
    {
        [self stopDrawSelectionBoundariesTimer];
        [m_timerLoopDrawSelectBoundaries invalidate];
        m_timerLoopDrawSelectBoundaries = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DRAWOUTERSELECTION" object:nil];
    
    [m_synthesizeImageRender shutdown];
}

@end

//
//  PSAbstractVectorDrawTool.m
//  PixelStyle
//
//  Created by wyl on 16/4/1.
//
//

#import "PSAbstractVectorDrawTool.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSVecLayer.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSTools.h"
#import "PSView.h"

#import "WDDrawingController.h"
#import "WDPath.h"
#import "WDCompoundPath.h"
#import "WDBezierNode.h"
#import "WDLayer.h"

#import "PSHoverButton.h"
#import "PSShowInfoPanel.h"

@implementation PSAbstractVectorDrawTool

-(id)init
{
    self = [super init];
    
    m_enumTransfomType = Transform_NO;
    m_bottomToolView = nil;
    
    return self;
}

- (int)toolId
{
    return -1;
}

-(void)awakeFromNib
{
    m_vectorTransformManager = [[PSVectorTransformManager alloc] initWithDocument:m_idDocument];
}

-(void)dealloc
{
    if(m_bottomToolView) {[m_bottomToolView release]; m_bottomToolView = nil;}
    if(m_vectorTransformManager) {[m_vectorTransformManager release]; m_vectorTransformManager = nil;}

    [super dealloc];
}

- (BOOL)isFineTool
{
    return YES;
}

//-(void)drawSelectedObjectExtra
//{
//    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
//    if( curToolIndex != [self toolId]) return;
//    
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    id activeLayer = [contents activeLayer];
//    if([activeLayer layerFormat] != PS_VECTOR_LAYER) return;
//    
//    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
//    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
//    if(ctx == nil)  return;
//    
//    CGContextSaveGState(ctx);
//    //  assert(ctx);
//    float xScale, yScale;
//    xScale = [[m_idDocument contents] xscale];
//    yScale = [[m_idDocument contents] yscale];
//    
//    CGContextScaleCTM(ctx, xScale, yScale);
//    
//    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
//    
//    
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    for (WDElement *element in wdDrawingController.selectedObjects)
//    {
//        PSVecLayer *pVecLayer = [element layer].layerDelegate;
//        if (![self judgeVectorElementNeedDraw:element]) {
//            continue;
//        }        
//        CGContextSaveGState(ctx);
//        CGContextConcatCTM(ctx,[pVecLayer transform]);
//        
//        [element drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
//        //[element drawHandlesWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
//        
//        CGContextRestoreGState(ctx);
//    }
//    
//    WDElement           *singleSelection = [wdDrawingController singleSelection];
//    BOOL isCombine = NO;
//    if (!singleSelection) {
//        isCombine = YES;
//    }
//    if (singleSelection && [singleSelection isKindOfClass:[WDCompoundPath class]]) {
//        isCombine = YES;
//    }
//    // if we're not transforming, draw filled anchors on all paths
//    if (isCombine) {
//        for (WDElement *element in wdDrawingController.selectedObjects) {
//            PSVecLayer *pVecLayer = [element layer].layerDelegate;
//            if (![self judgeVectorElementNeedDraw:element]) {
//                continue;
//            }
//            CGContextSaveGState(ctx);
//            CGContextConcatCTM(ctx,[pVecLayer transform]);
//            [element drawAnchorsWithViewTransform:ctx :CGAffineTransformIdentity scale:scale];
//            CGContextRestoreGState(ctx);
//        }
//    }else{
//        PSVecLayer *pVecLayer = [singleSelection layer].layerDelegate;
//        if([self judgeVectorElementNeedDraw:singleSelection])         {
//            CGContextSaveGState(ctx);
//            CGContextConcatCTM(ctx,[pVecLayer transform]);
//            [singleSelection drawHandlesWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
//            CGContextRestoreGState(ctx);
//        }
//    }
//    
//    
//    CGContextRestoreGState(ctx);
//}

-(void)drawAuxiliaryLine
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if( curToolIndex != [self toolId]) return;
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    //  assert(ctx);
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);
    
    float scale = [[m_idDocument docView] zoom];
//    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
    [m_pathTemp drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
    
    CGContextRestoreGState(ctx);
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER)
        return YES;
    
    return NO;
}

-(BOOL)showSelectionBoundaries
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    id activeLayer = [contents activeLayer];
    if([activeLayer layerFormat] == PS_VECTOR_LAYER)
        return NO;
    
    return YES;
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

//- (BOOL)judgeVectorElementNeedDraw:(WDElement*)element
//{
//    PSVecLayer *pVecLayer = [element layer].layerDelegate;
//    if(![pVecLayer visible]){
//        return NO;
//    }
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    int index = [contents layerIndex:pVecLayer];
//    if (index == -1) {
//        return NO;
//    }
//    
//    if (![self judgeVectorLayerContainsElement:element]) {
//        return NO;
//    }
//    
//    return YES;
//}
//
//
//- (BOOL)judgeVectorLayerContainsElement:(WDElement*)element
//{
//    BOOL contain = NO;
//        
//    if ([[element layer].elements containsObject:element]){
//        contain = YES;
//    }else{
//        WDPath *path = nil;
//        if ([element isKindOfClass:[WDPath class]]) {
//            path = (WDPath *) element;
//        }
//        
//        if (path && path.superpath && [[element layer].elements containsObject:path.superpath]) {
//            contain = YES;
//        }
//    }
//    return contain;
//}

#pragma mark - drawToolExtra
-(void)drawToolExtra
{
    [super drawToolExtra];
    
    [m_vectorTransformManager drawToolExtra];
    
}

#pragma mark - Mouse Events
-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(m_enumTransfomType == Transform_NO)
    {
        [self resetCursorRects];
        
        
        if([event window] != [m_idDocument window])
        {
            [[NSCursor arrowCursor] set];
            return;
        }
        
        NSRect colorPanelRect = [[NSColorPanel sharedColorPanel] frame];
        if( (NSPointInRect([NSEvent mouseLocation], colorPanelRect) && [gColorPanel isVisible]))
        {
            [[NSCursor arrowCursor] set];
            return;
        }
        
        NSArray *arrChildWindows = [[m_idDocument window] childWindows];
        for(NSWindow *window in arrChildWindows)
        {
            if((NSPointInRect([NSEvent mouseLocation], [window frame]) && [window isVisible]))
            {
                [[NSCursor arrowCursor] set];
                return;
            }
        }
        
        for (NSView *view in m_arrViewsAbovePSView)
        {
            NSPoint tempPoint = [(NSWindow *)[[m_idDocument docView] window] convertScreenToBase:[NSEvent mouseLocation]];
            tempPoint = [view convertPoint:tempPoint fromView:[(NSWindow *)[[m_idDocument docView] window] contentView]];
            if((NSPointInRect(tempPoint, view.bounds) && ![view isHidden]))
            {
                [[NSCursor arrowCursor] set];
                return;
            }
        }

        
        NSRect operableRect = [[m_idDocument docView] frame];
    
        if([self setCursor:where rect:operableRect cursor:m_cursor])    return;
        
        [[NSCursor arrowCursor] set];
    }
    else
    {
        [self resetCursorRects];
        if((NSPointInRect([NSEvent mouseLocation], [gColorPanel frame]) && [gColorPanel isVisible]))
        {
            if(m_cursor) {[m_cursor release]; m_cursor = nil;}
            m_cursor = [[NSCursor arrowCursor] retain];
            [m_cursor set];
            return;
        }
        
        NSArray *arrChildWindows = [[m_idDocument window] childWindows];
        for(NSWindow *window in arrChildWindows)
        {
            if((NSPointInRect([NSEvent mouseLocation], [window frame]) && [window isVisible]))
            {
                if(m_cursor) {[m_cursor release]; m_cursor = nil;}
                m_cursor = [[NSCursor arrowCursor] retain];
                [m_cursor set];
                
                return;
            }
        }
        
        [m_vectorTransformManager setNormalCursor:m_cursor];
        [m_vectorTransformManager mouseMoveTo:where withEvent:event];
    }
    
    if([self toolId] != kVectorPenTool)
        [super mouseMoveTo:where withEvent:event];
}


- (BOOL)setCursor:(NSPoint)point rect:(NSRect)rect cursor:(NSCursor *)cursor //point：相对于[m_idDocument docView]， rect 相对于[[m_idDocument docView] superview]
{
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    
    // Convert to the scrollview's origin
    rect.origin = [scrollView convertPoint: rect.origin fromView: [m_idDocument docView]];
    
    // Clip to the centering clipview
    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], rect);
    
    // Convert the point back to the seaview
    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    if(NSPointInRect(point, clippedRect))
    {
        [cursor set];
        return YES;
    }
    
    return NO;
}

#pragma mark - resetCursorRects
- (void)resetCursorRects
{
    if(m_enumTransfomType == Transform_NO)
        [super resetCursorRects];
    else
        [m_vectorTransformManager resetCursorRects];
}

-(void)selectAllObjects
{
    [m_vectorTransformManager setTransformStatus:Transform_NO];
    [super selectAllObjects];
    [m_vectorTransformManager setTransformStatus:Transform_Scale];
}

#pragma mark -
-(BOOL)enterTool
{
    [self showBottomPanel];
    [m_arrViewsAbovePSView addObject:m_bottomToolView];
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    if(nSelection)  [self setTransformType:Transform_Scale];
    
    return [super enterTool];
}

-(BOOL)exitTool:(int)newTool
{
    [self setTransformType:Transform_NO];
    
    [self hiddenBottomPanel];
    
    for(NSView *view in m_arrViewsAbovePSView)
        if(m_bottomToolView == view)
        {
            [m_arrViewsAbovePSView removeObject:view];
            break;
        }
    
    return [super exitTool:newTool];
}

-(void)showBottomPanel
{
    NSView *view = [[m_idDocument scrollView] superview];
    
    if(m_bottomToolView)
    {
        [m_bottomToolView setHidden:NO];
        
        return;
    }
    
    int nBottomViewHeight = 38;
    int nBottomViewWidth = 130;
    int nButtonWidth = 32;
    int nButtonHeight = 32;
    
    
    NSRect rect = NSMakeRect(view.frame.size.width/2.0 - nBottomViewWidth/2.0, 40, nBottomViewWidth, nBottomViewHeight);

    m_bottomToolView = [[NSView alloc] initWithFrame:rect];
    [m_bottomToolView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMaxYMargin];
    [m_bottomToolView.layer setBackgroundColor:[[NSColor clearColor] CGColor]];
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:m_bottomToolView.bounds];
    [imageView.cell setBordered:NO];
    [imageView setImageScaling:NSImageScaleAxesIndependently];
    [imageView setImage:[NSImage imageNamed:@"info-win-backer-2"]];
    [m_bottomToolView addSubview:imageView positioned:NSWindowBelow relativeTo:nil];
    [imageView release];
    
    
    for (int i = 0; i < 3; i++)
    {
        NSRect rect = NSMakeRect(10 + nButtonWidth*i + 8 *i, nBottomViewHeight/2.0 - nButtonHeight/2.0, nButtonWidth, nButtonHeight);
        PSHoverButton *btn = [[PSHoverButton alloc] initWithFrame:rect];
        [btn.cell setBezelStyle:NSSmallSquareBezelStyle];
        [btn.cell setBordered:NO];
        [btn setButtonType:NSSwitchButton];
        [btn setImagePosition:NSImageOnly];
        [(NSButtonCell *)btn.cell setImageScaling:NSImageScaleAxesIndependently];
        if(i==0)
        {
            [btn setImage:[NSImage imageNamed:@"transform-scale"]];
            [btn setAlternateImage:[NSImage imageNamed:@"transform-scale-a"]];
            [btn setToolTip:NSLocalizedString(@"Scale", nil)];
        }
//        else if (i==1)
//        {
//            [btn setImage:[NSImage imageNamed:@"transform-rotate"]];
//            [btn setAlternateImage:[NSImage imageNamed:@"transform-rotate-a"]];
//            [btn setToolTip:NSLocalizedString(@"Rotate", nil)];
//        }
        else if (i==1)
        {
            [btn setImage:[NSImage imageNamed:@"transform-miter"]];
            [btn setAlternateImage:[NSImage imageNamed:@"transform-miter-a"]];
            [btn setToolTip:NSLocalizedString(@"Skew", nil)];
        }
        else if (i==2)
        {
            [btn setImage:[NSImage imageNamed:@"transform-perspective"]];
            [btn setAlternateImage:[NSImage imageNamed:@"transform-perspective-a"]];
            [btn setToolTip:NSLocalizedString(@"Perspective", nil)];
        }
        
        [btn setTag:200+1+i];
        [btn setTarget:self];
        [btn setState:NSOffState];
        [btn setAction:@selector(changeTransform:)];
        [btn setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMaxYMargin];
        [m_bottomToolView addSubview:btn];
        [btn release];
    }
    [view addSubview:m_bottomToolView];
}

-(void)hiddenBottomPanel
{
    if(m_bottomToolView)
        [m_bottomToolView setHidden:YES];
}

#pragma mark - Transform
-(void)setTransformType:(TransformType)TransformType
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if(wdDrawingController.selectedObjects.count == 0)
    {
        TransformType = Transform_NO;
//        return;
    }
    
    m_enumTransfomType = TransformType;
    
    [m_vectorTransformManager setTransformStatus:TransformType];
    
    
    [self resumeTransformTypeButtonImage];
    if(m_enumTransfomType != Transform_NO)
        [[m_bottomToolView viewWithTag:200 + m_enumTransfomType] setState:NSOnState];
}

-(void)changeTransform:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    if (!btn.state)
        btn.state = !btn.state;
    
    BOOL bCanDoTransform = [self canDoTransform];
    if(!bCanDoTransform)
    {
        btn.state = !btn.state;
        [self showAlertView];
    }
    
    if (!btn.state)
        m_enumTransfomType = Transform_NO;
    else
        m_enumTransfomType = btn.tag - 200;
    
    [self resumeTransformTypeButtonImage];
    if(m_enumTransfomType != Transform_NO)
        [btn setState:NSOnState];
    
    [m_vectorTransformManager setTransformStatus:m_enumTransfomType];
}

-(void)resumeTransformTypeButtonImage
{
    NSButton *btn;
    
    for(int i = 1; i < 4; i++)
    {
        btn = [m_bottomToolView viewWithTag:200 + i];
        [btn setState:NO];
    }
}

-(BOOL)canDoTransform
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    
    return (nSelection > 0);
}

#pragma mark - showPanel
-(void)showAlertView
{
    PSShowInfoPanel *showInfoPanel = [[[PSShowInfoPanel alloc] init] autorelease];
    [showInfoPanel addMessageText:NSLocalizedString(@"No shape is selected", nil)];
    [showInfoPanel setAutoHiddenDelay:1.5];
    [showInfoPanel showPanel:NSZeroRect];
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    if(m_enumTransfomType != Transform_NO)
        return [m_vectorTransformManager validateMenuItem:menuItem];
    
    return [super validateMenuItem:menuItem];
}

//- (BOOL)moveKeyPressed:(int)direction step:(int)step
//{
//    BOOL doAction = NO;
//    
//    [m_vectorTransformManager moveKeyPressed:direction step:step];
//    
//    PSContent *contents = [m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    NSMutableArray *objects = [wdDrawingController orderedSelectedObjects];
//    if ([objects count] > 0) {
//        
//        [[m_idDocument docView] setNeedsDisplay:YES];
//        return YES;
//    }
//    
//    
//    return doAction;
//}

@end
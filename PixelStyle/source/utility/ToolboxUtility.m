#import "ToolboxUtility.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "PSView.h"
#import "OptionsUtility.h"
#import "ColorSelectView.h"
#import "PSController.h"
#import "PSHelp.h"
#import "UtilitiesManager.h"
#import "PSTools.h"
#import "PSHelpers.h"
#import "PSPrefs.h"
#import "PSProxy.h"
#import "InfoUtility.h"
#import "AbstractOptions.h"
#import "PSToolbarItem.h"
#import "PSImageToolbarItem.h"
#import "StatusUtility.h"
#import "PSWindowContent.h"
#import "WarningsUtility.h"
#import "MyToolBarView.h"
#import "PSContent.h"
#import "AbstractTool.h"
#import "MyCustomPanel.h"
#import "PSHoverButton.h"

#define ToolButtonHeight            29
#define ToolButtonWidth             39

#define SpaceHeight                 2
#define SpaceWidth                  39

#define ToolGroupPopButtonHeight    29
#define ToolGroupPopButtonWidth     17 //17

#define ToolColorSelectViewHeight   50
#define ToolColorSelectViewWidth    35

#define SpaceInButtons              2
#define SpaceBegin                  6

static NSString*	DocToolbarIdentifier 	= @"Document Toolbar Instance Identifier";

//static NSString*	SelectionIdentifier 	= @"Selection  Item Identifier";
//static NSString*	DrawIdentifier 	= @"Draw Item Identifier";
//static NSString*    EffectIdentifier = @"Effect Item Identifier";
//static NSString*    TransformIdentifier = @"Transform Item Identifier";
//static NSString*	ColorsIdentifier = @"Colors Item Identifier";
//
//// Additional (Non-default) toolbar items
//static NSString*	ZoomInToolbarItemIdentifier = @"Zoom In Toolbar Item Identifier";
//static NSString*	ZoomOutToolbarItemIdentifier = @"Zoom Out Toolbar Item Identifier";
//static NSString*	ActualSizeToolbarItemIdentifier = @"Actual Size Toolbar Item Identifier";
//static NSString*	NewLayerToolbarItemIdentifier = @"New Layer Toolbar Item Identifier";
//static NSString*	DuplicateLayerToolbarItemIdentifier = @"Duplicate Layer Toolbar Item Identifier";
//static NSString*	ForwardToolbarItemIdentifier = @"Move Layer Forward  Toolbar Item Identifier";
//static NSString*	BackwardToolbarItemIdentifier = @"Move Layer Backward Toolbar Item Identifier";
//static NSString*	DeleteLayerToolbarItemIdentifier = @"Delete Layer Toolbar Item Identifier";
//static NSString*	ToggleLayersToolbarItemIdentifier = @"Show/Hide Layers Item Identifier";
//static NSString*	InspectorToolbarItemIdentifier = @"Show/Hide Inspector Toolbar Item Identifier";
//static NSString*	FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
//static NSString*	DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";
//static NSString*	SelectNoneToolbarItemIdentifier = @"Select None Toolbar Item Identifier";
//static NSString*	SelectAllToolbarItemIdentifier = @"Select All Toolbar Item Identifier";
//static NSString*	SelectInverseToolbarItemIdentifier = @"Select Inverse Toolbar Item Identifier";
//static NSString*	SelectAlphaToolbarItemIdentifier = @"Select Alpha Toolbar Item Identifier";

@implementation ToolboxUtility

- (id)init
{
	m_idForeground = [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0] retain];
	m_idBackground = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0] retain];
	m_idDelayTimer = NULL;
    m_nTool = kPositionTool; //set initial tool, modify by lcz
	m_nOldTool = kPositionTool;
    
    m_arrToolBtnTip = [[NSArray arrayWithObjects:NSLocalizedString(@"Rectangular Marquee Tool", nil), NSLocalizedString(@"Elliptical Marquee Tool", nil),NSLocalizedString(@"Lasso Tool", nil), NSLocalizedString(@"Polygonal Lasso Tool", nil),NSLocalizedString(@"Magic Wand Tool", nil), NSLocalizedString(@"Pencil Tool", nil),NSLocalizedString(@"Brush Tool", nil), NSLocalizedString(@"Eyedropper Tool", nil),NSLocalizedString(@"Text Tool", nil), NSLocalizedString(@"Eraser Tool", nil),NSLocalizedString(@"Paint Bucket Tool", nil), NSLocalizedString(@"Gradient Tool", nil),NSLocalizedString(@"Crop Tool", nil), NSLocalizedString(@"Clone Stamp Tool", nil),NSLocalizedString(@"Smudge Tool", nil), NSLocalizedString(@"Effect Tool", nil),NSLocalizedString(@"Zoom Tool", nil), NSLocalizedString(@"Move and Align Tool", nil),NSLocalizedString(@"Vector Tool", nil), NSLocalizedString(@"Art Brush Tool", nil),NSLocalizedString(@"Transform Tool", nil), NSLocalizedString(@"Shape Tool", nil),NSLocalizedString(@"Path Selection Tool", nil), NSLocalizedString(@"Pen Tool", nil),NSLocalizedString(@"Path Eraser Tool", nil),NSLocalizedString(@"Red Eye Remove Tool", nil),NSLocalizedString(@"Burn Tool", nil),NSLocalizedString(@"Dodge Tool", nil),NSLocalizedString(@"Sponge Tool", nil),NSLocalizedString(@"Node Editor Tool", nil), nil] retain];
    
    m_arrToolBtnShotKey = [[NSArray arrayWithObjects:@"M", @"M",@"L", @"L",@"W", @"B",@"B", @"I",@"T", @"E",@"G", @"G",@"C", @"S",@"O", @" ",@"Z", @"V",@" ", @"B",@"T", @"U",@"A", @"P",@"E", @"R",@"O",@"O",@"O",@"N",  nil] retain];
    
    m_colorCanChange = YES;
    
    for (int i = 0; i < 10; i++) {
        m_arrayLastTools[i] = -1;
    }
    
    return self;
}

- (void)awakeFromNib
{
    
    // Create the toolbar instance, and attach it to our document window
    m_idToolbar = [[[NSToolbar alloc] initWithIdentifier: DocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [m_idToolbar setAllowsUserCustomization: YES];
    [m_idToolbar setAutosavesConfiguration: YES];
    [m_idToolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    //[m_idToolbar setDelegate: self];
    
    // Attach the toolbar to the document window
    //    [[m_idDocument window] setToolbar: m_idToolbar];
    
    [[PSController utilitiesManager] setToolboxUtility: self for:m_idDocument];
    [self initToolBarView];
    [self performSelector:@selector(delayChangeInitToolUI) withObject:nil afterDelay:0.5];
}

#pragma mark - addToolbarView
-(void)initToolBarView
{
    NSMutableArray *array = nil;
#ifdef PROPAINT_VERSION
//    kPositionTool,kTransformTool,-1,(kRectSelectTool,kEllipseSelectTool,kLassoTool,kPolygonLassoTool),kWandTool,kCropTool,-1,kMyBrushTool,kBrushTool,kPencilTool,kEraserTool,kEyedropTool,kBucketTool,kGradientTool,kSmudgeTool,-1,kShapeTool,kTextTool,-1,kZoomTool
    array = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:kPositionTool],
                             [NSNumber numberWithInt:kTransformTool],
                             [NSNumber numberWithInt:-1],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kRectSelectTool],[NSNumber numberWithInt:kEllipseSelectTool],[NSNumber numberWithInt:kLassoTool],[NSNumber numberWithInt:kPolygonLassoTool], nil],
                             [NSNumber numberWithInt:kWandTool],
                             [NSNumber numberWithInt:kCropTool],
                             [NSNumber numberWithInt:-1],
                             [NSNumber numberWithInt:kMyBrushTool],
                             [NSNumber numberWithInt:kBrushTool],
                             [NSNumber numberWithInt:kPencilTool],
                             [NSNumber numberWithInt:kEraserTool],
                             [NSNumber numberWithInt:kEyedropTool],
//                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kBucketTool],[NSNumber numberWithInt:kGradientTool],nil],
                             [NSNumber numberWithInt:kBucketTool],
                             [NSNumber numberWithInt:kGradientTool],
                             [NSNumber numberWithInt:kSmudgeTool],
                             [NSNumber numberWithInt:-1],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kVectorMoveTool],
                              [NSNumber numberWithInt:kVectorNodeEditorTool],[NSNumber numberWithInt:kVectorEraserTool],nil],
                             [NSNumber numberWithInt:kVectorPenTool],
                             [NSNumber numberWithInt:kShapeTool],
                             [NSNumber numberWithInt:kTextTool],
                             [NSNumber numberWithInt:-1],
                             [NSNumber numberWithInt:kZoomTool],
                             nil];
#else
    //    kPositionTool,kTransformTool,-1,(kRectSelectTool,kEllipseSelectTool,kLassoTool,kPolygonLassoTool),kWandTool,kCropTool,-1,kMyBrushTool,kBrushTool,kPencilTool,kEraserTool,kEyedropTool,kBucketTool,kGradientTool,kSmudgeTool,-1,kShapeTool,kTextTool,-1,kZoomTool
    array = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:kPositionTool],
                             [NSNumber numberWithInt:kTransformTool],
                             [NSNumber numberWithInt:-1],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kRectSelectTool],[NSNumber numberWithInt:kEllipseSelectTool],[NSNumber numberWithInt:kLassoTool],[NSNumber numberWithInt:kPolygonLassoTool], nil],
                             [NSNumber numberWithInt:kWandTool],
                             [NSNumber numberWithInt:kCropTool],
                             [NSNumber numberWithInt:-1],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kMyBrushTool],[NSNumber numberWithInt:kBrushTool],[NSNumber numberWithInt:kPencilTool],nil],
                             [NSNumber numberWithInt:kEraserTool],
                             [NSNumber numberWithInt:kEyedropTool],
                             [NSNumber numberWithInt:kCloneTool],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kBucketTool],[NSNumber numberWithInt:kGradientTool],nil],
                             [NSNumber numberWithInt:kRedEyeRemoveTool],
                             [NSNumber numberWithInt:kSmudgeTool],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kBurnTool],[NSNumber numberWithInt:kDodgeTool],[NSNumber numberWithInt:kSpongeTool],nil],
                             [NSNumber numberWithInt:-1],
//                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kVectorMoveTool],
//                                [NSNumber numberWithInt:kVectorNodeEditorTool],[NSNumber numberWithInt:kVectorEraserTool],nil],
                            [NSNumber numberWithInt:kTextTool],
                             [NSNumber numberWithInt:kShapeTool],
                            [NSNumber numberWithInt:kVectorPenTool],
                             [NSArray arrayWithObjects:[NSNumber numberWithInt:kVectorMoveTool],                              [NSNumber numberWithInt:kVectorEraserTool],nil],  //modify by lcz
                             
                             [NSNumber numberWithInt:-1],
                             [NSNumber numberWithInt:kZoomTool],
                             nil];
#endif
    
#ifdef FREE_VERSION
    array = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:kPositionTool],
             [NSNumber numberWithInt:kTransformTool],
             [NSNumber numberWithInt:-1],
             [NSArray arrayWithObjects:[NSNumber numberWithInt:kRectSelectTool],[NSNumber numberWithInt:kEllipseSelectTool],[NSNumber numberWithInt:kLassoTool],[NSNumber numberWithInt:kPolygonLassoTool], nil],
             [NSNumber numberWithInt:kWandTool],
             [NSNumber numberWithInt:kCropTool],
             [NSNumber numberWithInt:-1],
//             [NSArray arrayWithObjects:[NSNumber numberWithInt:kBrushTool],[NSNumber numberWithInt:kPencilTool],nil],
             [NSNumber numberWithInt:kMyBrushTool],
             [NSNumber numberWithInt:kBrushTool],
             [NSNumber numberWithInt:kPencilTool],
             [NSNumber numberWithInt:kEraserTool],
             [NSNumber numberWithInt:kEyedropTool],
             [NSNumber numberWithInt:kCloneTool],
             [NSArray arrayWithObjects:[NSNumber numberWithInt:kBucketTool],[NSNumber numberWithInt:kGradientTool],nil],
             [NSNumber numberWithInt:kRedEyeRemoveTool],
             [NSNumber numberWithInt:kSmudgeTool],
             [NSArray arrayWithObjects:[NSNumber numberWithInt:kBurnTool],[NSNumber numberWithInt:kDodgeTool],[NSNumber numberWithInt:kSpongeTool],nil],
             [NSNumber numberWithInt:-1],
             [NSNumber numberWithInt:kTextTool],
             [NSNumber numberWithInt:-1],
             [NSNumber numberWithInt:kZoomTool],
             nil];
#endif
    
    [self setAllTools:array];
    
    for (int nIndex = [m_tbvMyToolBar.subviews count] - 1; nIndex >= 0; nIndex--)
    {
        NSView *view = [m_tbvMyToolBar.subviews objectAtIndex:nIndex];
        if(![view isKindOfClass:[ColorSelectView class]])
            [view removeFromSuperview];
    }
    
    [self addToolBarViewBg];
    
    int nSpaceIndex = 0;
    int nToolIndex = -1;
    for (int nIndex = 0; nIndex < [array count]; nIndex++)
    {
        NSObject *object = [array objectAtIndex:nIndex];
        if([object isKindOfClass:[NSArray class]])
            nToolIndex = [[(NSArray *)object objectAtIndex:0] intValue];
        else
            nToolIndex = [(NSNumber *)object intValue];
        
        [self addViewToToolBarView:nIndex spaceIndex:nSpaceIndex toolIndex:nToolIndex];
        
        if(nToolIndex == -1)    nSpaceIndex++;
        
        
        if([object isKindOfClass:[NSArray class]])
            [self addGroupPopButtonToToolBarView:nIndex spaceIndex:nSpaceIndex toolIndex:nToolIndex];
    }
    
    [self setSelectColorViewFrame:[array count] spaceCount:nSpaceIndex];
    
    [array release];
}

-(void)addViewToToolBarView:(int)nObjectViewIndex spaceIndex:(int)nSpaceIndex toolIndex:(int)nToolIndex
{
    if(nToolIndex!=-1)
    {
        NSRect rect = NSMakeRect((m_tbvMyToolBar.frame.size.width - ToolButtonWidth)/2.0, m_tbvMyToolBar.frame.size.height-SpaceBegin - (nObjectViewIndex - nSpaceIndex + 1) * (ToolButtonHeight + SpaceInButtons) - nSpaceIndex * (SpaceHeight + SpaceInButtons), ToolButtonWidth, ToolButtonHeight);
        PSHoverButton *btn = [[PSHoverButton alloc] initWithFrame:rect];
        [btn.cell setBezelStyle:NSSmallSquareBezelStyle];
        [btn.cell setBordered:NO];
        [btn setButtonType:NSSwitchButton];
        [btn setImagePosition:NSImageOnly];
        [(NSButtonCell *)btn.cell setImageScaling:NSImageScaleAxesIndependently];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"tools-%d",nToolIndex]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"tools-%d-a",nToolIndex]]];
        
        NSString *sToolTip = [[m_arrToolBtnTip objectAtIndex:nToolIndex] stringByAppendingFormat:@"(%@)", [m_arrToolBtnShotKey objectAtIndex:nToolIndex]];
        [btn setToolTip:sToolTip];
        [btn setTag:800+nToolIndex];
        [btn setTarget:self];
        [btn setState:NSOffState];
        [btn setAction:@selector(selectToolUsingTag:)];
        [m_tbvMyToolBar addSubview:btn];
        [btn release];
    }
    else
    {
        NSRect rect = NSMakeRect((m_tbvMyToolBar.frame.size.width - SpaceWidth)/2.0, m_tbvMyToolBar.frame.size.height-SpaceBegin - (nObjectViewIndex - nSpaceIndex) * (ToolButtonHeight + SpaceInButtons) - (nSpaceIndex+1) * (SpaceHeight + SpaceInButtons), SpaceWidth, SpaceHeight);
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:rect];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [imageView setImage:[NSImage imageNamed:@"tools-jiangexian"]];
        [m_tbvMyToolBar addSubview:imageView];
        [imageView release];
    }
}



-(void)addGroupPopButtonToToolBarView:(int)nObjectViewIndex spaceIndex:(int)nSpaceIndex toolIndex:(int)nToolIndex
{
    NSRect rect = NSMakeRect(m_tbvMyToolBar.frame.size.width/2.0 + ToolButtonWidth/2.0 - ToolGroupPopButtonWidth, m_tbvMyToolBar.frame.size.height-SpaceBegin - (nObjectViewIndex - nSpaceIndex + 1) * (ToolButtonHeight + SpaceInButtons) - nSpaceIndex * (SpaceHeight + SpaceInButtons), ToolGroupPopButtonWidth, ToolGroupPopButtonHeight);
    NSButton *btn = [[NSButton alloc] initWithFrame:rect];
    [btn.cell setBezelStyle:NSSmallSquareBezelStyle];
    [btn.cell setBordered:NO];
    [btn setButtonType:NSSwitchButton];
    [btn setImagePosition:NSImageOnly];
    [(NSButtonCell *)btn.cell setImageScaling:NSImageScaleAxesIndependently];
    [btn setImage:[NSImage imageNamed:@"xiaosanjiao"]];
    [btn setAlternateImage:[NSImage imageNamed:@"xiaosanjiao"]];
    
    int nGroupIndex = [self toolsGroupId:nToolIndex];
    [btn setTag:900+nGroupIndex];
    [btn setTarget:self];
    [btn setAction:@selector(showGroupToolsView:)];
    [m_tbvMyToolBar addSubview:btn];
    [btn release];
}

-(void)addToolBarViewBg
{
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:m_tbvMyToolBar.bounds];
    [imageView.cell setBordered:NO];
    [imageView setImageScaling:NSImageScaleAxesIndependently];
    [imageView setImage:[NSImage imageNamed:@"info-win-backer"]];
    [m_tbvMyToolBar addSubview:imageView positioned:NSWindowBelow relativeTo:nil];
    [imageView release];
}

-(void)setSelectColorViewFrame:(int)nObjectViewCount spaceCount:(int)nSpaceCount
{
    for(NSView *view in m_tbvMyToolBar.subviews)
    {
        if([view isKindOfClass:[ColorSelectView class]])
        {
            NSPoint originPoint = NSMakePoint(view.frame.origin.x, m_tbvMyToolBar.frame.size.height-SpaceBegin - (nObjectViewCount - nSpaceCount) * (ToolButtonHeight + SpaceInButtons) - nSpaceCount * (SpaceHeight + SpaceInButtons) - view.frame.size.height - 10);
            [view setFrameOrigin:originPoint];
            [view setHidden:NO];
        }
    }
}

-(void)addSelectColorViewToToolBarView:(int)nObjectViewCount spaceCount:(int)nSpaceCount
{
    NSRect rect = NSMakeRect(m_tbvMyToolBar.frame.size.width/2.0 + ToolButtonWidth/2.0 - ToolGroupPopButtonWidth, m_tbvMyToolBar.frame.size.height-SpaceBegin - (nObjectViewCount - nSpaceCount) * (ToolButtonHeight + SpaceInButtons) - nSpaceCount * (SpaceHeight + SpaceInButtons), ToolGroupPopButtonWidth, ToolGroupPopButtonHeight);
    
    ColorSelectView *colorSelectView = [[ColorSelectView alloc] initWithFrame:rect];
    [m_tbvMyToolBar addSubview:colorSelectView];
    [colorSelectView release];
}

#pragma mark - Tools
-(void)setAllTools:(NSMutableArray *)array
{
    if(m_arrTools)  {[m_arrTools release]; m_arrTools = nil;}
    m_arrTools = [[NSMutableArray alloc] init];
    
    if(m_arrGroupsTools)  {[m_arrGroupsTools release]; m_arrGroupsTools = nil;}
    m_arrGroupsTools = [[NSMutableArray alloc] init];
    
    int nToolIndex;
    for (int nIndex = 0; nIndex < [array count]; nIndex++)
    {
        NSObject *object = [array objectAtIndex:nIndex];
        if([object isKindOfClass:[NSArray class]])
        {
            for (NSNumber *value in (NSArray *)object)
            {
                nToolIndex = [value intValue];
                [m_arrTools addObject:[NSNumber numberWithInt:nToolIndex]];
            }
            
            [m_arrGroupsTools addObject:object];
        }
        else
        {
            nToolIndex = [(NSNumber *)object intValue];
            if(nToolIndex != -1)
                [m_arrTools addObject:object];
        }
    }
}


-(NSArray *)allShowTools
{
    return m_arrTools;
}

-(void)delayChangeInitToolUI
{
    [self changeToolTo:kMyBrushTool];
}

- (void)dealloc
{
    [m_idForeground autorelease];
    [m_idBackground autorelease];
    [m_idDelayTimer invalidate];
    [m_idDelayTimer autorelease];
    if(m_arrToolBtnTip) {[m_arrToolBtnTip release]; m_arrToolBtnTip = nil;}
    if(m_arrToolBtnShotKey) {[m_arrToolBtnShotKey release]; m_arrToolBtnShotKey = nil;}
    
    if(m_arrTools)  {[m_arrTools release]; m_arrTools = nil;}
    if(m_arrGroupsTools)  {[m_arrGroupsTools release]; m_arrGroupsTools = nil;}
    
	[super dealloc];
}

- (NSColor *)foreground
{
	return m_idForeground;
}

- (NSColor *)background
{
	return m_idBackground;
}

- (void)setForeground:(NSColor *)color
{
	[m_idForeground autorelease];
	m_idForeground = [color retain];
	if (m_idDelayTimer) {
		[m_idDelayTimer invalidate];
		[m_idDelayTimer autorelease];
	}
	m_idDelayTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[[m_idDocument tools] getTool:kTextTool]  selector:@selector(preview:) userInfo:NULL repeats:NO];
	[m_idDelayTimer retain];	
}

- (void)setBackground:(NSColor *)color
{
	[m_idBackground autorelease];
	m_idBackground = [color retain];
}

- (id)colorView
{
	return m_idColorSelectView;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void)activate
{
	if(m_nTool == -1)
		[self changeToolTo:kRectSelectTool];
	// Set the document appropriately
	[m_idColorSelectView setDocument:m_idDocument];
		
	// Then pretend a tool change
	[self update:YES];
}

- (void)deactivate
{
	int i;
	
	[m_idColorSelectView setDocument:m_idDocument];
	for (i = kFirstSelectionTool; i <= kLastSelectionTool; i++) {
		[[m_idToolbox cellWithTag:i] setEnabled:YES];
	}
}

- (void)update:(BOOL)full
{
	int i;
	
	if (full) {
//		/* Disable or enable the tool */
//		if ([[m_idDocument selection] floating]) {
//			for (i = kFirstSelectionTool; i <= kLastSelectionTool; i++) {
//				[[m_idSelectionTBView cellAtRow:0 column:i] setEnabled:NO ];				
//			}
//			[m_idSelectionMenu setEnabled:NO];
//		}
//		else {
//			for (i = kFirstSelectionTool; i <= kLastSelectionTool; i++) {
//				[[m_idSelectionTBView cellAtRow:0 column: i] setEnabled:YES];
//			}
//			[m_idSelectionMenu setEnabled:YES];
//		}
		// Implement the change
		[[m_idDocument docView] setNeedsDisplay:YES];
		[m_idOptionsUtility update];
		[[PSController seaHelp] updateInstantHelp:m_nTool];

	}
	[m_idColorSelectView update];
}

- (int)tool
{
	return m_nTool;
}

#pragma mark - ShotKey
-(unichar)getToolShotKey:(int)nToolIndex
{
    if(nToolIndex < 0) return "";
    
    NSString *sShortKey = m_arrToolBtnShotKey[nToolIndex];
    sShortKey = [sShortKey lowercaseString];
    return [sShortKey characterAtIndex:0];
}

#pragma mark - group
-(IBAction)showGroupToolsView:(id)sender
{
    int nGroupId = [sender tag] % 100;
    
    if(!m_arrGroupsTools) return;
    NSArray *groupArray = [m_arrGroupsTools objectAtIndex:nGroupId];
    
    if(!groupArray) return;
    
    NSRect rect = [(NSButton *)sender frame];
    
    int nCount = groupArray.count;
    
    
    NSPoint point;
    point.x = NSMaxX([(NSButton *)sender frame]) + 2;
    point.y = NSMaxY([(NSButton *)sender frame]);
    
    NSWindow *w = [m_idDocument window];
    point = [m_tbvMyToolBar convertPoint:point toView:[w contentView]];
    point.x += w.frame.origin.x;
    point.y += w.frame.origin.y;
    NSRect frame = NSMakeRect(point.x, point.y - (nCount * rect.size.height + 2 *(3*nCount+1) + 6) , 50, nCount * rect.size.height + 2 *(3*nCount+1) + 6);
    MyCustomPanel *customPanel = [[[MyCustomPanel alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:NULL] autorelease];
    [customPanel setBackgroundColor:[NSColor clearColor]];
    [customPanel setOpaque:NO];
    
//    NSRect rectImageView = NSInsetRect(customPanel.contentView.bounds, 1.5, 1.5);
    NSImageView *imageViewBg = [[[NSImageView alloc] initWithFrame:customPanel.contentView.bounds] autorelease];
    [imageViewBg setImage:[NSImage imageNamed:@"tools-pop_bg"]];
    [imageViewBg setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [imageViewBg setImageScaling:NSImageScaleAxesIndependently];
    [customPanel.contentView addSubview:imageViewBg];
    
    for (int nIndex = 0; nIndex < nCount; nIndex++)
    {
        int nToolIndex = [[groupArray objectAtIndex:nIndex] intValue];
        NSRect btnRect = NSMakeRect(6,  2*(3* (nCount - nIndex -1 ) + 1) + (nCount - nIndex -1 ) * rect.size.height + 6, 39, rect.size.height);
        PSHoverButton *btn = [[[PSHoverButton alloc] initWithFrame:btnRect] autorelease];
        [btn setTag:800 + nToolIndex];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"tools-%d",nToolIndex]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"tools-%d-a",nToolIndex]]];
        NSString *sToolTip = [[m_arrToolBtnTip objectAtIndex:nToolIndex] stringByAppendingFormat:@"(%@)", [m_arrToolBtnShotKey objectAtIndex:nToolIndex]];
        [btn setToolTip:sToolTip];
        [btn setImagePosition:NSImageOnly];
        [btn setTitle:@""];
        [btn.cell setImageScaling:NSImageScaleAxesIndependently];
        [btn setBordered:NO];
        [btn setBezelStyle:NSThickSquareBezelStyle];
        [btn setButtonType:NSSwitchButton];
        [btn setTarget:self];
        [btn setAction:@selector(selectToolFromGroupSender:)];
        
        [customPanel.contentView addSubview:btn];
        
        
        if(nIndex == nCount - 1) break;
        NSRect rectImageView = NSMakeRect(btnRect.origin.x + 2, NSMinY(btnRect) - 4, btnRect.size.width - 7, 2);
        NSImageView *imageViewSeparate = [[[NSImageView alloc] initWithFrame:rectImageView] autorelease];
        [imageViewSeparate setImage:[NSImage imageNamed:@"tools-jiangexian"]];
        [imageViewSeparate setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [imageViewSeparate setImageScaling:NSImageScaleAxesIndependently];
        [customPanel.contentView addSubview:imageViewSeparate];
    }
    
    [customPanel showPanel:frame];
}


- (void)selectToolFromGroupSender:(id)sender
{
    int nNewToolIndex = [sender tag] % 100;    
    [self updateToolsGroupButton:nNewToolIndex];

    [self changeToolTo:nNewToolIndex];
    
    [[sender window] hidePanel];
}

-(int)toolsGroupId:(int)nToolIndex
{
    if(!m_arrGroupsTools) return -1;
    
    for (int nIndex = 0; nIndex < [m_arrGroupsTools count]; nIndex++)
    {
        NSArray *arrTools = [m_arrGroupsTools objectAtIndex:nIndex];
        for (NSNumber *toolIndex in arrTools)
        {
            if(nToolIndex == toolIndex.intValue)
                return nIndex;
        }
    }
    
    return -1;
}

-(int)currentShowToolIndex:(int)nGroupId
{
    if(nGroupId == -1) return -1;
    
    for (NSView *subView in m_tbvMyToolBar.subviews)
    {
        int nToolIndex = subView.tag - 800;
    
        int nsubViewGroupId = [self toolsGroupId:nToolIndex];
        
        if(nsubViewGroupId == nGroupId) return nToolIndex;
    }
    
    return -1;
}

- (IBAction)selectToolUsingTag:(id)sender
{
    [m_tbvMyToolBar enableButton:sender];
	[self changeToolTo:[sender tag] % 100];
}

- (IBAction)selectToolFromSender:(id)sender
{
	[self changeToolTo:[[sender selectedCell] tag] % 100];
}

- (void)switchToolWithToolIndex:(NSInteger)nCurrentShowToolIndex
{
    PSHoverButton *btn = [m_tbvMyToolBar viewWithTag:800 + nCurrentShowToolIndex];
    
    if(!btn) return;
    
    [self selectToolUsingTag:btn];
}

- (void)setColorCanChange:(BOOL)canChange
{
    m_colorCanChange = canChange;
}

- (void)updateToolsGroupButton:(int)nNewToolIndex
{
    int groupId = [self toolsGroupId:nNewToolIndex];
    if (groupId == -1) {
        return;
    }
    int nCurrentShowToolIndex = [self currentShowToolIndex:groupId];
    PSHoverButton *btn = [m_tbvMyToolBar viewWithTag:800 + nCurrentShowToolIndex];
    [btn setTag:800 + nNewToolIndex];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"tools-%d",nNewToolIndex]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"tools-%d-a",nNewToolIndex]]];
    NSString *sToolTip = [[m_arrToolBtnTip objectAtIndex:nNewToolIndex] stringByAppendingFormat:@"(%@)", [m_arrToolBtnShotKey objectAtIndex:nNewToolIndex]];
    [btn setToolTip:sToolTip];
}

- (int)lastCombinedTool:(unichar)type
{
    switch (type) {
        case 'm':
            return m_arrayLastTools[0];
            break;
        case 'l':
            return m_arrayLastTools[1];
            break;
        case 'b':
            return m_arrayLastTools[2];
            break;
        case 'g':
            return m_arrayLastTools[3];
            break;
        case 't':
            return m_arrayLastTools[4];
            break;
        case 'e':
            return m_arrayLastTools[5];
            break;
        case 'o':
            return m_arrayLastTools[6];
            break;
            
        default:
            break;
    }
    return m_arrayLastTools[0];
}

- (unichar)lastCombinedToolType
{
    return m_nLastToolType;
}



- (void)resetLastToolInfo:(int)newTool
{
    switch (newTool) {
            
        case kRectSelectTool:
        case kEllipseSelectTool:
            m_arrayLastTools[0] = newTool;
            m_nLastToolType = 'm';
            break;
            
        case kLassoTool:
        case kPolygonLassoTool:
            m_arrayLastTools[1] = newTool;
            m_nLastToolType = 'l';
            break;
            
        case kMyBrushTool:
        case kPencilTool:
        case kBrushTool:
            m_arrayLastTools[2] = newTool;
            m_nLastToolType = 'b';
            break;
            
        case kBucketTool:
        case kGradientTool:
            m_arrayLastTools[3] = newTool;
            m_nLastToolType = 'g';
            break;
            
        case kTransformTool:
        case kTextTool:
            m_arrayLastTools[4] = newTool;
            m_nLastToolType = 't';
            break;
            
        case kEraserTool:
        case kVectorEraserTool:
            m_arrayLastTools[5] = newTool;
            m_nLastToolType = 'e';
            break;
            
        case kSmudgeTool:
        case kBurnTool:
        case kDodgeTool:
        case kSpongeTool:
            m_arrayLastTools[6] = newTool;
            m_nLastToolType = 'o';
            break;
            
        default:
            m_nLastToolType = 0;
            break;
    }

}

- (void)changeToolTo:(int)newTool
{
    if(newTool == m_nTool) return;
    
    [self resetLastToolInfo:newTool];

    BOOL bExitTool = [[[m_idDocument tools] getTool:m_nTool] exitTool:newTool];
    if(!bExitTool)  //can not exit
    {
        [m_tbvMyToolBar enableButton:[m_tbvMyToolBar viewWithTag:800 + m_nTool]];
        return;
    }
    
    if (!m_colorCanChange)
    {
        [m_tbvMyToolBar enableButton:[m_tbvMyToolBar viewWithTag:800 + m_nTool]];
        return;
    }
    
    [self updateToolsGroupButton:newTool];
    
    m_nTool = newTool;
    [[[m_idDocument tools] getTool:newTool] enterTool];
    [m_tbvMyToolBar enableButton:[m_tbvMyToolBar viewWithTag:800 + m_nTool]];
    
    [self update:YES];
    
    
////    add by lcz
////    if (newTool == kPositionTool) {
////        newTool = kTransformTool;
////    }
//    if (newTool == kTransformTool) {
//        [(PSTransformTool*)[[m_idDocument tools] getTool:kTransformTool] initialInfoForTransformTool];
//    }
//    else
//    {
//        if (m_nOldTool == kPositionTool) {
//            PSTransformTool* transformTool = (PSTransformTool*)[[m_idDocument tools] getTool:kTransformTool];
//            [transformTool changeToolFromTransformTool:newTool];
//            if ([transformTool getIfHasBeginTransform]) {
//                return;
//            }
//        }
//    }
//    
//    if (!m_colorCanChange) {
//        return;
//    }
}

-(void)floatTool
{
	// Show the banner
	[[m_idDocument warnings] showFloatBanner];
	
	m_nOldTool = m_nTool;
//	[self changeToolTo: kPositionTool];   //modify by wyl
}

-(void)anchorTool
{
	// Hide the banner
	[[m_idDocument warnings] hideFloatBanner];
	if (m_nOldTool != -1) [self changeToolTo: m_nOldTool];
}

- (void)setEffectEnabled:(BOOL)enable
{
//	[[m_idEffectTBView cellAtRow: 0 column: kEffectTool] setEnabled: enable];
}

- (BOOL)validateMenuItem:(id)menuItem
{	
	if ([menuItem tag] >= 600 && [menuItem tag] < 700) {
		[menuItem setState:([menuItem tag] == m_nTool + 600)];
	}
	
	return YES;
}


@end

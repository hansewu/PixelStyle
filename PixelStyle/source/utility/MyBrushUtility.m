//
//  MyBrushUtility.m
//  PixelStyle
//
//  Created by wyl on 15/9/8.
//
//

#import "MyBrushUtility.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "UtilitiesManager.h"
#import "PSController.h"
#import "OptionsUtility.h"
#import "PSTools.h"

#import "ipaintapi.h"
#import "MyBrushOptions.h"
#import "MyBrushDrawView.h"

#define BTN_SIZE_WIDTH                32
#define BTN_NUM_PER_LINE              7

#define BTN_FAVOIRITE_SPACE 3
#define BTN_FAVOIRTITE_SIZE_WIDTH          38
#define BTN_FAVORITE_COUNT                 7


@implementation MyBrushUtility

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idBrushType setToolTip:NSLocalizedString(@"Choose the brush category", nil)];
    [m_idPenType setToolTip:NSLocalizedString(@"Choose the pen category", nil)];
    [m_idPencilType setToolTip:NSLocalizedString(@"Choose the pencil category", nil)];
    [m_idAirbrushType setToolTip:NSLocalizedString(@"Choose the airbrush category", nil)];
    [m_idScrawlType setToolTip:NSLocalizedString(@"Choose the scrawl category", nil)];
    [m_idSpecialType setToolTip:NSLocalizedString(@"Choose the special category", nil)];
    
    [[PSController utilitiesManager] setMyBrushUtility:self for:m_idDocument];
    
    
    [m_idView setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"info-win-backer"]]];
    [m_idFavoriteBrushesView setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"info-win-backer"]]];
  
    m_nActiveBrushGroup = 2;
    m_arrGroupNames = [[NSMutableArray alloc] init];
    m_arrFavoriteBrushNames = [[NSMutableArray alloc] init];
    m_dictFavoriteBrushHistoryPara = [[NSDictionary alloc] init];
    
    [self loadBrushes];
    [self loadFavoriteBrush];
    
    m_idMyBrushesDrawView = [[MyBrushDrawView alloc] initWithMaster:self];
    [m_idMyBrushesDrawView setFrame:NSMakeRect(11, 15, 292, 152)];
    [m_idView.superview addSubview:m_idMyBrushesDrawView positioned:NSWindowBelow relativeTo:m_idView];
    
    
    [self performSelector:@selector(initData) withObject:nil afterDelay:.5];
}

-(void)initData
{
    char *cPackageFile = (char*)[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/brush.dat"] cStringUsingEncoding: NSUTF8StringEncoding];
    IP_Init(cPackageFile);
    
    m_strCurrBrushName = [[NSString alloc] initWithString:[self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:0]]];
    m_hBrush = [self activeMyBrush];    
}

-(void)readBrushNameFromFileconst:(NSString *)sFilePath brushNameArray:(NSArray<NSString *>**)brushNameArray
{
    NSString *string = [NSString stringWithContentsOfFile:sFilePath encoding:NSUTF8StringEncoding error:nil];
   
    if([string rangeOfString:@"\r\n"].length != 0)
        *brushNameArray = [string componentsSeparatedByString:@"\r\n"];
    else
        *brushNameArray = [string componentsSeparatedByCharactersInSet:  [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
    //*brushNameArray = [string componentsSeparatedByCharactersInSet:  [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
}

-(void)writeToFile:(NSString *)sFilePath string:(NSString *)string
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:sFilePath])
    {
        [fileManager removeItemAtPath:sFilePath error:nil];
    }
    
    [string writeToFile:sFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)dealloc
{
    [m_arrGroupNames release];
    [m_arrFavoriteBrushNames release];
    [m_dictFavoriteBrushHistoryPara release];
    [m_strCurrBrushName release];
    [m_idMyBrushesDrawView release];
    
    [super dealloc];
}

- (void *)activeMyBrush
{
    if(!m_hBrush)
        [self changeCurrentBrush:m_strCurrBrushName];
    
    return m_hBrush;
}


- (NSString *)activeMyBrushName
{
    return m_strCurrBrushName;
}

#pragma mark - Favorite Brushes -
-(void)loadFavoriteBrush
{
//    NSString *sPath = [[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/favouritebrushconfig.txt"];
    NSString *sPath = [self configFavouriteBrushFile];
    NSArray *array;
    [self readBrushNameFromFileconst:sPath brushNameArray:&array];
    
    [m_arrFavoriteBrushNames removeAllObjects];
    [m_arrFavoriteBrushNames addObjectsFromArray:array];
    
    [self updateFavouriteBrushesUI];
}

//favorite brush tag 2000+
-(void)updateFavouriteBrushesUI
{
    NSArray *subViews = [m_idFavoriteBrushesView.documentView subviews];
    
    for(int nIndex = [subViews count] - 1; nIndex >= 0; nIndex--)
        [[subViews objectAtIndex:nIndex] removeFromSuperview];
    
    if([m_arrFavoriteBrushNames count] > BTN_FAVORITE_COUNT)
    {
        NSArray *array = [[(NSMutableArray *)[m_arrFavoriteBrushNames subarrayWithRange:NSMakeRange(0, 7)] retain] autorelease];
        [m_arrFavoriteBrushNames removeAllObjects];
        [m_arrFavoriteBrushNames addObjectsFromArray:array];
    }
    
    NSRect frame = [m_idFavoriteBrushesView.documentView frame];
    frame.size.width = [m_arrFavoriteBrushNames count] * (BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH);
    [m_idFavoriteBrushesView.documentView setFrame:frame];
    
    for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex++)
    {
        int nOriginX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRITE_SPACE;
        int nOriginY = (m_idFavoriteBrushesView.frame.size.height - BTN_FAVOIRTITE_SIZE_WIDTH)/2.0;
        
        
        
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(nOriginX, nOriginY, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH)];
        NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:nIndex]];
        NSString *sPath = [[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:sOriginalBrushName] stringByAppendingString:@"_prev.png"];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:sPath] autorelease];
        [imageView setTag:3000+nIndex];
        [imageView setImage:image];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [m_idFavoriteBrushesView.documentView addSubview:imageView];
        [imageView release];
        

        
        PSGestureButton *btn = [[PSGestureButton alloc] initWithFrame:NSMakeRect(nOriginX  , nOriginY, BTN_FAVOIRTITE_SIZE_WIDTH , BTN_FAVOIRTITE_SIZE_WIDTH )];
        
        [btn setBezelStyle:NSThickSquareBezelStyle];
        [btn setBordered:NO];
        [btn setButtonType:NSSwitchButton];
        [btn setTag:2000+nIndex];
        [btn setState:NSOffState];
        [btn setTarget:self];
        [btn setAction:@selector(onFravoriteBrushBtn:)];
        btn.toolTip = [m_arrFavoriteBrushNames objectAtIndex:nIndex];
        [btn setImagePosition:NSImageOnly];
        NSButtonCell *btnCell = btn.cell;
        [btnCell setBezeled:YES];
        [btnCell setImageScaling:NSImageScaleAxesIndependently];
        
        [btn setImage:nil];
        [btn setAlternateImage:[NSImage imageNamed:@"button-bg-a"]];
        
        [m_idFavoriteBrushesView.documentView addSubview:btn];
        [btn release];
        
        id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
        int nFavoriteBrushIndex = [(MyBrushOptions *)options getFavoriteBrushIndex];
        if(nIndex == nFavoriteBrushIndex)
            [btn setState:YES];
        
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9)
        {
            [btn addPSGestureRecognizer:self];
        }
        else
        {
            NSPanGestureRecognizer *panGesture = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFavoritePan:)];
            [btn addGestureRecognizer:panGesture];
            [panGesture release];
        }
        
    }
}

-(NSString *)getFavoriteBrushOriginalName:(NSString *)sName
{
    NSArray *array = [[[NSArray alloc] init] autorelease];
    array = [sName componentsSeparatedByString:@"_"];
    array = [array subarrayWithRange:NSMakeRange(0, 2)];
    
    NSString *sOriginalBrushName = [[[NSString alloc] initWithString:[array componentsJoinedByString:@"_"]]autorelease];
    
    return sOriginalBrushName;
}

-(void)onFravoriteBrushBtn:(id)sender
{
    [self resumeFavoriteBrushBtnState];
    [self resumeBrushStyleButtonImage];
    
    NSButton *btn = (NSButton *)sender;
    [btn setState:YES];
    int nIndex = btn.tag - 2000;
    
    id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    [(MyBrushOptions *)options setFavoriteBrushIndex:nIndex];
    
    
//    NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:nIndex]];
//    
//    [self changeCurrentBrush:sOriginalBrushName];
    [m_idMyBrushesDrawView update];
   
}

-(void)resumeFavoriteBrushBtnState
{
    id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    [(MyBrushOptions *)options setFavoriteBrushIndex:-1];
    
    int nCount = [m_arrFavoriteBrushNames count];
    for(int nIndex = 0; nIndex < nCount; nIndex++)
    {
        NSButton *btn = (NSButton *)[m_idFavoriteBrushesView.documentView viewWithTag:2000 + nIndex];
        
        [btn setState:NO];
    }
}


#pragma mark - brush group UI -
-(IBAction)changeBrushStyle:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    int nTag = btn.tag;
    
    if(m_nActiveBrushGroup == (nTag - 100))  return;
    
    m_nActiveBrushGroup = nTag - 100;
    
    [self updateGroupUI];
    [self resumeFavoriteBrushBtnState];
    
    if(m_strCurrBrushName) [m_strCurrBrushName release];
    m_strCurrBrushName = [[NSString alloc] initWithString:[[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] objectAtIndex:0]];
    [self changeCurrentBrush:m_strCurrBrushName];
    [m_idMyBrushesDrawView update];
    
    [self update];
}

//Group btn tag 100+
-(void)updateGroupUI
{
    for (int i = 0; i < [[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] count]; i++)
    {
        NSButton *btn = [m_idView.superview viewWithTag:100 + i];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"mybrushes-group-%d",i]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"mybrushes-group-%d",i]]];
    }
    
    NSButton *btn = [m_idView.superview viewWithTag:100 + m_nActiveBrushGroup];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"mybrushes-group-%d-a",m_nActiveBrushGroup]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"mybrushes-group-%d-a",m_nActiveBrushGroup]]];
    
}

- (BOOL)isString:(NSString*)fullString contains:(NSString*)other
{
    NSRange range = [fullString rangeOfString:other];
    return range.length != 0;
}

-(void)loadBrushes
{
    NSString *sPath;
    NSArray *array;
   
    NSArray *files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes"]];
    for(int i = 0; i < [files count]; i++)
    {
        sPath = [files objectAtIndex:i];
        if([[sPath pathExtension] isEqualToString:@"txt"] && ![self isString:sPath contains:@"brushconfig.txt"])
        {
            [self readBrushNameFromFileconst:[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString: sPath] brushNameArray:&array];
//            [m_arrGroupNames arrayByAddingObject:array];
            [m_arrGroupNames addObject:array];
        }
    }
    
    [self update];
}

#pragma mark - brush UI -

//brush tag 1000+
-(void)update
{
    NSArray *subViews = [m_idView.documentView subviews];
    
    for(int nIndex = [subViews count] - 1; nIndex >= 0; nIndex--)
    {
        [[subViews objectAtIndex:nIndex] removeFromSuperview];
    }
    
    NSArray *array = [m_arrGroupNames objectAtIndex:m_nActiveBrushGroup];
    
    int nWidth = ((NSView *)m_idView).bounds.size.width;
    int nSpace = (nWidth - BTN_NUM_PER_LINE * BTN_SIZE_WIDTH)/(BTN_NUM_PER_LINE + 1);
    
    int nRow,nCol;
    for (int i = 0; i < array.count; i++)
    {
        nRow = i/BTN_NUM_PER_LINE;
        nCol = i - nRow * BTN_NUM_PER_LINE;
        
        int nHeight = [m_idView frame].size.height;
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(nCol * (BTN_SIZE_WIDTH + nSpace) + nSpace/2.0, nHeight - (nRow+1) * (BTN_SIZE_WIDTH + nSpace), BTN_SIZE_WIDTH, BTN_SIZE_WIDTH)];
        NSString *string = [[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:[array objectAtIndex:i]];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:[string stringByAppendingString:@"_prev.png"]] autorelease];
        [imageView setImage:image];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [m_idView.documentView addSubview:imageView];
        [imageView release];
        
        NSRect rect = NSMakeRect(imageView.frame.origin.x, imageView.frame.origin.y, BTN_SIZE_WIDTH, BTN_SIZE_WIDTH);
        PSGestureButton *btn2 = [[PSGestureButton alloc] initWithFrame:rect];
        [btn2 setTitle:@""];
        NSButtonCell *btnCell = btn2.cell;
        [btnCell setBezeled:YES];
        [btnCell setBordered:NO];
        [btnCell setBezelStyle:NSThickSquareBezelStyle];
        [btnCell setButtonType:NSSwitchButton];
        [btnCell setImageScaling:NSImageScaleAxesIndependently];
        [btn2 setImage:nil];
        [btn2 setAlternateImage:[NSImage imageNamed:@"button-bg-a"]];
        [btn2 setState:NO];
        [btn2 setTag:1000+i];
        [btn2 setTarget:self];
        [btn2 setAction:@selector(changeBrush:)];
        [m_idView.documentView addSubview:btn2];
        [btn2 release];
        btn2.toolTip = [array objectAtIndex:i];
        
        if([[array objectAtIndex:i] isEqualToString:m_strCurrBrushName])
        {
            [btn2 setState:YES];
        }
        
        
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9)
        {
            [btn2 addPSGestureRecognizer:self];
        }
        else
        {
            NSPanGestureRecognizer *panGesture = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [btn2 addGestureRecognizer:panGesture];
            [panGesture release];
        }
    }

}

-(void)resumeBrushStyleButtonImage
{
    int nCount = [[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] count];
    for(int nIndex = 0; nIndex < nCount; nIndex ++)
    {
        NSButton *btn = (NSButton *)[m_idView.documentView viewWithTag:1000 + nIndex];
        
        [btn setState:NO];
    }
}

-(void)changeBrush:(id)sender
{
    [self resumeFavoriteBrushBtnState];
    [self resumeBrushStyleButtonImage];
    
    NSButton *btn = (NSButton *)sender;
    [btn setState:YES];
    
    int nIndex = btn.tag - 1000;
    NSString *sBrushName = [[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] objectAtIndex:nIndex];
    
    [self changeCurrentBrush:sBrushName];
    
    [m_idMyBrushesDrawView update];
}

-(void)changeCurrentBrush:(NSString *)sBrushName
{
    NSString *string = [[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:sBrushName];
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:[string stringByAppendingString:@"_prev.png"]] autorelease];
    id boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    [(MyBrushOptions *)boptions updateBrushImage:image];
    
    NSString *sTemp = m_strCurrBrushName;
    
    m_strCurrBrushName = [[NSString alloc] initWithString:sBrushName];
    if(sTemp) [sTemp release];
    //HANDLE_PAINT_CANVAS hCanvas = [[m_idDocument whiteboard] getCanvas];
    id brushTool = [[m_idDocument tools] getTool:kMyBrushTool];
    HANDLE_PAINT_CANVAS hCanvas = [brushTool getCanvas];
    assert(hCanvas);
    if(m_hBrush)
        IP_DestroyBursh(hCanvas, m_hBrush);
    
    m_hBrush = IP_CreateBrushFromPackage(hCanvas, (char *)[[sBrushName stringByAppendingString:@".bru"] UTF8String]);
    
    [self updateParaUI];
}



#pragma mark - para -

#define BRUSH_OPAQUE 0
#define BRUSH_OPAQUE_MULTIPLY 1
#define BRUSH_OPAQUE_LINEARIZE 2
#define BRUSH_RADIUS_LOGARITHMIC 3
#define BRUSH_HARDNESS 4
#define BRUSH_SLOW_TRACKING 16


-(void)recodeFavoriteBrushHistoryPara:(int)nIndex
{
    NSString *sBrushName = [m_arrFavoriteBrushNames objectAtIndex:nIndex];
    
    float fOpacity = [self getBrushPara:BRUSH_OPAQUE];
    float fRadius = [self getBrushPara:BRUSH_RADIUS_LOGARITHMIC];
    float fHardness = [self getBrushPara:BRUSH_HARDNESS];
    float fSmooth = [self getBrushPara:BRUSH_SLOW_TRACKING];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:fRadius], [NSNumber numberWithFloat:fOpacity],[NSNumber numberWithFloat:fHardness], [NSNumber numberWithFloat:fSmooth], nil] forKeys:[NSArray arrayWithObjects:@"radius",@"opacity",@"hardness",@"smooth", nil]];
    
    [m_dictFavoriteBrushHistoryPara setValue:dictionary forKey:sBrushName];
}



-(void)changeBrushPara:(int)nItem value:(float)fValue
{
    //HANDLE_PAINT_CANVAS hCanvas = [[m_idDocument whiteboard] getCanvas];
    id brushTool = [[m_idDocument tools] getTool:kMyBrushTool];
    HANDLE_PAINT_CANVAS hCanvas = [brushTool getCanvas];
    assert(hCanvas);
    
    if(m_hBrush)
        IP_SetBrushParam(hCanvas, m_hBrush, nItem, fValue);
    
    [self updateParaUI];
}

-(float)getBrushPara:(int)nItem
{
    //HANDLE_PAINT_CANVAS hCanvas = [[m_idDocument whiteboard] getCanvas];
    id brushTool = [[m_idDocument tools] getTool:kMyBrushTool];
    HANDLE_PAINT_CANVAS hCanvas = [brushTool getCanvas];
    assert(hCanvas);
    
    if(m_hBrush)
        return IP_GetBrushParam(hCanvas, m_hBrush, nItem);
    
    return 0;
}

-(void)updateParaUI
{
    float fOpacity = [self getBrushPara:BRUSH_OPAQUE];
    float fRadius = [self getBrushPara:BRUSH_RADIUS_LOGARITHMIC];
    float fHardness = [self getBrushPara:BRUSH_HARDNESS];
    float fSmooth = [self getBrushPara:BRUSH_SLOW_TRACKING];
    
    id boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    [(MyBrushOptions *)boptions setOpacity:fOpacity];
    [(MyBrushOptions *)boptions setRadius:fRadius];
    [(MyBrushOptions *)boptions setHardness:fHardness];
    [(MyBrushOptions *)boptions setSmooth:fSmooth];
}

-(void)showPanelFrom:(NSPoint)p onWindow:(NSWindow *)parent
{
    [super showPanelFrom:p onWindow:parent];
    
    id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    int nFravoriteIndex = [(MyBrushOptions *)options getFavoriteBrushIndex];
    if(nFravoriteIndex == -1)
    {
        
        [self resumeFavoriteBrushBtnState];
    }
    else
    {
        [self onFravoriteBrushBtn:[m_idFavoriteBrushesView.documentView viewWithTag:2000+nFravoriteIndex]];
    }

    [m_idMyBrushesDrawView update];
    
    [self hideHelpInfo];
}

-(void)hideHelpInfo
{
    [m_imageViewShowHelp setHidden:NO];
    [m_imageViewShowHelp setAlphaValue:1.0];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:3.0];
    [[m_imageViewShowHelp animator] setAlphaValue:0.0];
    [[m_imageViewShowHelp animator] setHidden:YES];
    [NSAnimationContext endGrouping];
}

-(void)closePanel:(id)sender
{
    //刷新
    id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    int nFravoriteIndex = [(MyBrushOptions *)options getFavoriteBrushIndex];
    if(nFravoriteIndex == -1)
    {
        
        [self resumeFavoriteBrushBtnState];
    }
    else
    {
        [self onFravoriteBrushBtn:[m_idFavoriteBrushesView.documentView viewWithTag:2000+nFravoriteIndex]];
    }
    
    [self updateParaUI];
    
    //暂停 试画界面
    [m_idMyBrushesDrawView stopUpdate];
    
    [super closePanel:sender];
}

- (void)shutdown
{
    if (m_hBrush)
    {
        //HANDLE_PAINT_CANVAS hCanvas = [[m_idDocument whiteboard] getCanvas];
        id brushTool = [[m_idDocument tools] getTool:kMyBrushTool];
        HANDLE_PAINT_CANVAS hCanvas = [brushTool getCanvas];
        assert(hCanvas);
        IP_DestroyBursh(hCanvas, m_hBrush);
        m_hBrush = NULL;
    }
}

#pragma mark - Gesture
-(void)handleFavoritePan:(NSPanGestureRecognizer *)recognizer
{
    NSWindow *window = (NSWindow *)m_winWindow;
    
    CGPoint translation = [recognizer translationInView:window.contentView];
    
    int nTag = recognizer.view.tag;
    
    NSRect frameRect = NSMakeRect(recognizer.view.frame.origin.x , recognizer.view.frame.origin.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    frameRect = [m_idFavoriteBrushesView.documentView convertRect:frameRect toView:window.contentView];
    NSRect imageViewFrameRect = NSMakeRect(frameRect.origin.x + translation.x, frameRect.origin.y + translation.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    
    
    if(recognizer.state == NSGestureRecognizerStateBegan)
    {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageViewFrameRect];
        NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:nTag - 2000]];
        NSString *sPath = [[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:sOriginalBrushName] stringByAppendingString:@"_prev.png"];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:sPath] autorelease];
        [imageView setImage:image];
        [imageView setTag:10000];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [window.contentView addSubview:imageView];
        [imageView release];
        
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag] setAlphaValue:0.0];
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag - 2000 + 3000] setAlphaValue:0.0];
    }
    else if((recognizer.state == NSGestureRecognizerStateChanged))
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view setFrame:imageViewFrameRect];
        
        
        BOOL bIntersect = NSIntersectsRect(imageViewFrameRect, m_idFavoriteBrushesView.frame);
        if(bIntersect)
        {
            imageViewFrameRect = [window.contentView convertRect:imageViewFrameRect toView:m_idFavoriteBrushesView.documentView];
            int nCenterX = imageViewFrameRect.origin.x + imageViewFrameRect.size.width/2.0;
    
            for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
            {
                int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
                if(nCenterX < nFavoriteBtnCenterX)
                {
                    [self willSwapFavoriteBrushesAnimation:nTag - 2000 toIndex:nIndex];
                    
                    break;
                }
                
                if(nCenterX > (BTN_FAVORITE_COUNT - 1)*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2)
                    [self willSwapFavoriteBrushesAnimation:nTag - 2000 toIndex:BTN_FAVORITE_COUNT];
            }
            
        }
        else
            [self willSwapFavoriteBrushesAnimation:nTag - 2000 toIndex:BTN_FAVORITE_COUNT];
    }
    else if(recognizer.state == NSGestureRecognizerStateEnded)
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view removeFromSuperview];
        
        int nIndexNew;
        BOOL bIntersect = NSIntersectsRect(imageViewFrameRect, m_idFavoriteBrushesView.frame);
        if(bIntersect)
        {
            imageViewFrameRect = [window.contentView convertRect:imageViewFrameRect toView:m_idFavoriteBrushesView.documentView];
            int nCenterX = imageViewFrameRect.origin.x + imageViewFrameRect.size.width/2.0;
            
            for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
            {
                int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
                if(nCenterX < nFavoriteBtnCenterX)
                {
                    nIndexNew = nIndex;
                    
                    break;
                }
                
                if(nCenterX > (BTN_FAVORITE_COUNT - 1)*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2)
                    nIndexNew = BTN_FAVORITE_COUNT - 1;
            }
            
        }
        else
            nIndexNew = BTN_FAVORITE_COUNT - 1;
        
        int nOriginX = nIndexNew*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRITE_SPACE;
        int nOriginY = [m_idFavoriteBrushesView.documentView viewWithTag:nTag].frame.origin.y;
        NSRect newFrameRect = NSMakeRect(nOriginX, nOriginY, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag] setFrame:newFrameRect];
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag - 2000 + 3000] setFrame:newFrameRect];
        
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag] setAlphaValue:1.0];
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag - 2000 + 3000] setAlphaValue:1.0];
        
        [self moveFavoriteBrushFrom:nTag - 2000 toIndex:nIndexNew];
    }
}


-(void)moveFavoriteBrushFrom:(int)nIndex toIndex:(int)nToIndex
{
    //当前选中的最喜爱笔的名字
    id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    int nCurFavoriteBrushIndex = [(MyBrushOptions *)options getFavoriteBrushIndex];
    NSString *sSelectFavoriteBrushName = nil;
    if(nCurFavoriteBrushIndex != -1)
        sSelectFavoriteBrushName = [NSString stringWithString:[m_arrFavoriteBrushNames objectAtIndex:nCurFavoriteBrushIndex]];
    
    
    NSString *sFavoriteBrushName = [NSString stringWithString:[m_arrFavoriteBrushNames objectAtIndex:nIndex]] ;
//    NSLog(@"sFavoriteBrushName = %@",sFavoriteBrushName);
    [m_arrFavoriteBrushNames removeObjectAtIndex:nIndex];


    NSArray *frontArray = [m_arrFavoriteBrushNames subarrayWithRange:NSMakeRange(0, nToIndex)];
    NSArray *endArray = [m_arrFavoriteBrushNames subarrayWithRange:NSMakeRange(nToIndex, BTN_FAVORITE_COUNT - 1 - nToIndex)];
    
    NSArray *favoriteArray = [[frontArray arrayByAddingObject:sFavoriteBrushName] arrayByAddingObjectsFromArray:endArray];
    
    //更新文件
    NSString *sFavorite = [favoriteArray componentsJoinedByString:@"\r\n"];
 //   NSString *sFavorite = [favoriteArray componentsJoinedByString:@"\n"];
//    NSString *sPath = [[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/favouritebrushconfig.txt"];
    NSString *sPath = [self configFavouriteBrushFile];
    [self writeToFile:sPath string:sFavorite];
    
    
    //更新选项栏常用画笔以及当前选中最喜爱笔activeIndex
    [(MyBrushOptions *)options loadFavoriteBrush];
    

    if(sSelectFavoriteBrushName)
    {
        for (int i = 0; i < [favoriteArray count]; i++)
        {
            NSString *string = [NSString stringWithString:[favoriteArray objectAtIndex:i]];;
//            NSLog(@"stirng = %@,sSelectFavoriteBrushName = %@",string,sSelectFavoriteBrushName);

            if([string isEqualToString:sSelectFavoriteBrushName])
            {
                [options setFavoriteBrushIndex:i];
                break;
            }
        }
    }
    
    //更新当前界面常用画笔
    [self loadFavoriteBrush];
}

-(void)willSwapFavoriteBrushesAnimation:(int)nFromIndex toIndex:(int)nToIndex
{
    for (int i = 0; i < [m_arrFavoriteBrushNames count]; i ++)
    {
        if(i == nFromIndex) continue;
        int nOriginX = i*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRITE_SPACE;
        if(nToIndex >= nFromIndex)
        {
            if(i >= nFromIndex && i <= nToIndex)
            {
                nOriginX = nOriginX - (BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH);
            }
        }
        else
        {
            if(i >= nToIndex && i <= nFromIndex)
            {
                nOriginX = nOriginX + (BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH);
            }
        }
        
        NSView *view = [m_idFavoriteBrushesView.documentView viewWithTag:3000+i];
        NSView *view2 = [m_idFavoriteBrushesView.documentView viewWithTag:2000+i];
        NSRect endFrame = NSMakeRect(nOriginX, view.frame.origin.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
        
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1];
        [[view animator] setFrameOrigin:endFrame.origin];
        [[view2 animator] setFrameOrigin:endFrame.origin];
        [NSAnimationContext endGrouping];
    }
}

-(void)handlePan:(NSPanGestureRecognizer *)recognizer
{
    NSWindow *window = (NSWindow *)m_winWindow;
    
    CGPoint translation = [recognizer translationInView:window.contentView];
    
    int nTag = recognizer.view.tag;
    
    NSRect frameRect = NSMakeRect(recognizer.view.frame.origin.x , recognizer.view.frame.origin.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    frameRect = [m_idView.documentView convertRect:frameRect toView:window.contentView];
    NSRect imageViewFrameRect = NSMakeRect(frameRect.origin.x + translation.x, frameRect.origin.y + translation.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    
    if(recognizer.state == NSGestureRecognizerStateBegan)
    {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageViewFrameRect];
        NSString *string = [[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:[[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] objectAtIndex:nTag - 1000]];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:[string stringByAppendingString:@"_prev.png"]] autorelease];
        [imageView setImage:image];
        [imageView setTag:10000];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [window.contentView addSubview:imageView];
        [imageView release];
    }
    else if((recognizer.state == NSGestureRecognizerStateChanged))
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view setFrame:imageViewFrameRect];
        
        [self brushBtnGestureStateChanged:imageViewFrameRect];
    }
    else if(recognizer.state == NSGestureRecognizerStateEnded)
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view removeFromSuperview];
        
        
        BOOL bIntersect = NSIntersectsRect(imageViewFrameRect, m_idFavoriteBrushesView.frame);
        if(bIntersect)
        {
            imageViewFrameRect = [window.contentView convertRect:imageViewFrameRect toView:m_idFavoriteBrushesView.documentView];
            int nCenterX = imageViewFrameRect.origin.x + imageViewFrameRect.size.width/2.0;
            
            
            for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
            {
                int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
                if(nCenterX < nFavoriteBtnCenterX)
                {
                    NSString *sBrushName = [[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] objectAtIndex:nTag-1000];
                    [self insertBrushToFavorite:sBrushName index:nIndex];
                    
                    break;
                }
            }
        }
    }
}

-(void)brushBtnGestureStateChanged:(NSRect)frameRect
{
    NSWindow *window = (NSWindow *)m_winWindow;
    BOOL bIntersect = NSIntersectsRect(frameRect, m_idFavoriteBrushesView.frame);
    if(bIntersect)
    {
        frameRect = [window.contentView convertRect:frameRect toView:m_idFavoriteBrushesView.documentView];
        int nCenterX = frameRect.origin.x + frameRect.size.width/2.0;
        
        for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
        {
            int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
            if(nCenterX < nFavoriteBtnCenterX)
            {
                [self willAddOneFavoriteBrushesAnimation:nIndex];
                break;
            }
        }
        
        if(nCenterX > (BTN_FAVORITE_COUNT - 1)*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2)
            [self willAddOneFavoriteBrushesAnimation:[m_arrFavoriteBrushNames count]];
    }
    else
        [self willAddOneFavoriteBrushesAnimation:[m_arrFavoriteBrushNames count]];
}

-(void)willAddOneFavoriteBrushesAnimation:(int)nIndex
{
    for (int i = 0; i < [m_arrFavoriteBrushNames count]; i ++)
    {
        NSView *view = [m_idFavoriteBrushesView.documentView viewWithTag:3000+i];
        NSView *view2 = [m_idFavoriteBrushesView.documentView viewWithTag:2000+i];
        
        int nOriginX = i*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRITE_SPACE;
        if(i >= nIndex)
            nOriginX = nOriginX+(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH);
        NSRect endFrame = NSMakeRect(nOriginX, view.frame.origin.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);

        
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1];
        [[view animator] setFrameOrigin:endFrame.origin];
        [[view2 animator] setFrameOrigin:endFrame.origin];
        [NSAnimationContext endGrouping];
    }
}

-(void)insertBrushToFavorite:(NSString *)sBrushName index:(int)nIndex
{
    NSString *sFavoriteBrushName = [self getFavoriteBrushName:sBrushName];
    NSArray *frontArray = [m_arrFavoriteBrushNames subarrayWithRange:NSMakeRange(0, nIndex)];
    NSArray *endArray = [m_arrFavoriteBrushNames subarrayWithRange:NSMakeRange(nIndex, BTN_FAVORITE_COUNT - nIndex - 1)];
    
    NSArray *favoriteArray = [[frontArray arrayByAddingObject:sFavoriteBrushName] arrayByAddingObjectsFromArray:endArray];
    
    //更新文件
    NSString *sFavorite = [favoriteArray componentsJoinedByString:@"\r\n"];
//    NSString *sFavorite = [favoriteArray componentsJoinedByString:@"\n"];
//    NSString *sPath = [[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/favouritebrushconfig.txt"];
    NSString *sPath = [self configFavouriteBrushFile];
    [self writeToFile:sPath string:sFavorite];
    
    //更新选项栏常用画笔以及当前选中最喜爱笔activeIndex
    id options = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kMyBrushTool];
    [(MyBrushOptions *)options loadFavoriteBrush];
    
    int nFavoriteBrushIndex = [(MyBrushOptions *)options getFavoriteBrushIndex];
    if (nFavoriteBrushIndex >= nIndex)
    {
        nFavoriteBrushIndex++;
        if(nFavoriteBrushIndex >= BTN_FAVORITE_COUNT) nFavoriteBrushIndex = -1;
        [options setFavoriteBrushIndex:nFavoriteBrushIndex];
    }
    
    //更新当前界面常用画笔
    [self loadFavoriteBrush];
}

-(NSString *)getFavoriteBrushName:(NSString *)sBrushName
{
    NSString *sCurFavoriteBrushName = sBrushName;
    
    BOOL bHaveFlag = true;
    while (bHaveFlag)
    {
        bHaveFlag = false;
        for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
        {
            NSString *sBrushFavoriteName = [m_arrFavoriteBrushNames objectAtIndex:nIndex];
            if ([sBrushFavoriteName isEqualToString:sCurFavoriteBrushName])
            {
                bHaveFlag = true;
                break;
            }
        }
        
        if(bHaveFlag)
        {
            NSArray *array = [sCurFavoriteBrushName componentsSeparatedByString:@"_"];
            if([array count] > 2)
            {
                int nValue = [[array lastObject] intValue] + 1;
                array = [array subarrayWithRange:NSMakeRange(0, 2)];
                NSString *string = [array componentsJoinedByString:@"_"];
                sCurFavoriteBrushName = [string stringByAppendingString:[NSString stringWithFormat:@"_%d",nValue]];
            }
            else
            {
                sCurFavoriteBrushName = [sCurFavoriteBrushName stringByAppendingString:@"_1"];
            }
        }
    }
    
    
    return sCurFavoriteBrushName;
}


#pragma mark - <=10.9 Gesture
-(void)handlePSPan:(PSPanGestureRecognizer *)recongnizer
{
    if (recongnizer.view.tag >= 2000)
    {
        [self handlePSFavoritePan:recongnizer];
    }
    else if(recongnizer.view.tag >= 1000)
    {
        [self handlePSBrushPan:recongnizer];
    }
}

-(void)handlePSFavoritePan:(PSPanGestureRecognizer *)recognizer
{
    NSWindow *window = (NSWindow *)m_winWindow;
    
    CGPoint translation = NSPointToCGPoint(recognizer.offsetPoint);
    
    int nTag = recognizer.view.tag;
    
    NSRect frameRect = NSMakeRect(recognizer.view.frame.origin.x , recognizer.view.frame.origin.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    frameRect = [m_idFavoriteBrushesView.documentView convertRect:frameRect toView:window.contentView];
    NSRect imageViewFrameRect = NSMakeRect(frameRect.origin.x + translation.x, frameRect.origin.y + translation.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    
    
    if(recognizer.state == NSGestureRecognizerStateBegan)
    {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageViewFrameRect];
        NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:nTag - 2000]];
        NSString *sPath = [[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:sOriginalBrushName] stringByAppendingString:@"_prev.png"];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:sPath] autorelease];
        [imageView setImage:image];
        [imageView setTag:10000];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [window.contentView addSubview:imageView];
        [imageView release];
        
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag] setAlphaValue:0.0];
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag - 2000 + 3000] setAlphaValue:0.0];
    }
    else if((recognizer.state == NSGestureRecognizerStateChanged))
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view setFrame:imageViewFrameRect];
        
        
        BOOL bIntersect = NSIntersectsRect(imageViewFrameRect, m_idFavoriteBrushesView.frame);
        if(bIntersect)
        {
            imageViewFrameRect = [window.contentView convertRect:imageViewFrameRect toView:m_idFavoriteBrushesView.documentView];
            int nCenterX = imageViewFrameRect.origin.x + imageViewFrameRect.size.width/2.0;
            
            for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
            {
                int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
                if(nCenterX < nFavoriteBtnCenterX)
                {
                    [self willSwapFavoriteBrushesAnimation:nTag - 2000 toIndex:nIndex];
                    
                    break;
                }
                
                if(nCenterX > (BTN_FAVORITE_COUNT - 1)*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2)
                    [self willSwapFavoriteBrushesAnimation:nTag - 2000 toIndex:BTN_FAVORITE_COUNT];
            }
            
        }
        else
            [self willSwapFavoriteBrushesAnimation:nTag - 2000 toIndex:BTN_FAVORITE_COUNT];
    }
    else if(recognizer.state == NSGestureRecognizerStateEnded)
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view removeFromSuperview];
        
        int nIndexNew;
        BOOL bIntersect = NSIntersectsRect(imageViewFrameRect, m_idFavoriteBrushesView.frame);
        if(bIntersect)
        {
            imageViewFrameRect = [window.contentView convertRect:imageViewFrameRect toView:m_idFavoriteBrushesView.documentView];
            int nCenterX = imageViewFrameRect.origin.x + imageViewFrameRect.size.width/2.0;
            
            for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
            {
                int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
                if(nCenterX < nFavoriteBtnCenterX)
                {
                    nIndexNew = nIndex;
                    
                    break;
                }
                
                if(nCenterX > (BTN_FAVORITE_COUNT - 1)*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2)
                    nIndexNew = BTN_FAVORITE_COUNT - 1;
            }
            
        }
        else
            nIndexNew = BTN_FAVORITE_COUNT - 1;
        
        int nOriginX = nIndexNew*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRITE_SPACE;
        int nOriginY = [m_idFavoriteBrushesView.documentView viewWithTag:nTag].frame.origin.y;
        NSRect newFrameRect = NSMakeRect(nOriginX, nOriginY, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag] setFrame:newFrameRect];
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag - 2000 + 3000] setFrame:newFrameRect];
        
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag] setAlphaValue:1.0];
        [[m_idFavoriteBrushesView.documentView viewWithTag:nTag - 2000 + 3000] setAlphaValue:1.0];
        
        [self moveFavoriteBrushFrom:nTag - 2000 toIndex:nIndexNew];
    }
}

-(void)handlePSBrushPan:(PSPanGestureRecognizer *)recognizer
{
    NSWindow *window = (NSWindow *)m_winWindow;
    
    CGPoint translation = NSPointToCGPoint(recognizer.offsetPoint);//[recognizer translationInView:window.contentView];
    
    int nTag = recognizer.view.tag;
    
    NSRect frameRect = NSMakeRect(recognizer.view.frame.origin.x , recognizer.view.frame.origin.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    frameRect = [m_idView.documentView convertRect:frameRect toView:window.contentView];
    NSRect imageViewFrameRect = NSMakeRect(frameRect.origin.x + translation.x, frameRect.origin.y + translation.y, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH);
    
    if(recognizer.state == NSGestureRecognizerStateBegan)
    {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageViewFrameRect];
        NSString *string = [[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:[[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] objectAtIndex:nTag - 1000]];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:[string stringByAppendingString:@"_prev.png"]] autorelease];
        [imageView setImage:image];
        [imageView setTag:10000];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [window.contentView addSubview:imageView];
        [imageView release];
    }
    else if((recognizer.state == NSGestureRecognizerStateChanged))
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view setFrame:imageViewFrameRect];
        
        [self brushBtnGestureStateChanged:imageViewFrameRect];
    }
    else if(recognizer.state == NSGestureRecognizerStateEnded)
    {
        NSView *view = [window.contentView viewWithTag:10000];
        if(view)
            [view removeFromSuperview];
        
        
        BOOL bIntersect = NSIntersectsRect(imageViewFrameRect, m_idFavoriteBrushesView.frame);
        if(bIntersect)
        {
            imageViewFrameRect = [window.contentView convertRect:imageViewFrameRect toView:m_idFavoriteBrushesView.documentView];
            int nCenterX = imageViewFrameRect.origin.x + imageViewFrameRect.size.width/2.0;
            
            
            for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex ++)
            {
                int nFavoriteBtnCenterX = nIndex*(BTN_FAVOIRITE_SPACE + BTN_FAVOIRTITE_SIZE_WIDTH) + BTN_FAVOIRTITE_SIZE_WIDTH/2;
                if(nCenterX < nFavoriteBtnCenterX)
                {
                    NSString *sBrushName = [[m_arrGroupNames objectAtIndex:m_nActiveBrushGroup] objectAtIndex:nTag-1000];
                    [self insertBrushToFavorite:sBrushName index:nIndex];
                    
                    break;
                }
            }
        }
    }
}

-(NSString *)configFavouriteBrushFile
{
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);//NSCachesDirectory, NSUserDomainMask, YES);// 
    NSString *docDir = [paths objectAtIndex:0];
    NSString *pPath = [docDir stringByAppendingString:@"/favouritebrushconfig.txt"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pPath])
        [[NSFileManager defaultManager] removeItemAtPath:pPath error:nil];
        
    if (![[NSFileManager defaultManager] fileExistsAtPath:pPath])
    {
        NSString *src = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/myBrushes/favouritebrushconfig.txt"];
//        NSString *src = [[NSBundle mainBundle] pathForResource:@"favouritebrushconfig" ofType:@"txt"];
        
        [[NSFileManager defaultManager] copyItemAtPath:src toPath:pPath error:nil];
    }
   
    return pPath;
}

@end

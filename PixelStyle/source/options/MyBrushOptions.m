//
//  MyBrushOptions.m
//  PixelStyle
//
//  Created by wyl on 15/9/9.
//
//

#import "MyBrushOptions.h"
#import "PSDocument.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "MyBrushUtility.h"

#define BRUSH_OPAQUE 0
#define BRUSH_OPAQUE_MULTIPLY 1
#define BRUSH_OPAQUE_LINEARIZE 2
#define BRUSH_RADIUS_LOGARITHMIC 3
#define BRUSH_HARDNESS 4
#define BRUSH_SLOW_TRACKING 16

#define BTN_FAVOIRTITE_SIZE_WIDTH          28
#define BTN_FAVORITE_COUNT                 7

@implementation MyBrushOptions

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idFavoriteBrushesView setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"info-win-backer"]]];

    m_mdFavoriteBrushHistoryPara = [[NSMutableDictionary alloc] init];
    m_nFavoriteBrushIndex = 0;
    
    //[self performSelector:@selector(initView) withObject:nil afterDelay:0.1];
    [self initView];
}

-(void)initView
{
    [m_myCustomComboSmooth setDelegate:self];
    [m_myCustomComboSmooth setSliderMaxValue:10];
    [m_myCustomComboSmooth setSliderMinValue:0];
    [m_myCustomComboSmooth setStringValue:@"1"];
    
    [m_myCustomComboRadius setDelegate:self];
    [m_myCustomComboRadius setSliderMaxValue:5];
    [m_myCustomComboRadius setSliderMinValue:-2];
    [m_myCustomComboRadius setStringValue:@"2.5"];
    
    [m_myCustomComboOpacity setDelegate:self];
    [m_myCustomComboOpacity setSliderMaxValue:2];
    [m_myCustomComboOpacity setSliderMinValue:0];
    [m_myCustomComboOpacity setStringValue:@"1"];
    
    [m_myCustomComboHardness setDelegate:self];
    [m_myCustomComboHardness setSliderMaxValue:1];
    [m_myCustomComboHardness setSliderMinValue:0];
    [m_myCustomComboHardness setStringValue:@"0.5"];
    
    [m_myCustomComboPressure setDelegate:self];
    [m_myCustomComboPressure setSliderMaxValue:1];
    [m_myCustomComboPressure setSliderMinValue:0];
    [m_myCustomComboPressure setStringValue:@"0.5"];
    
    
    [m_imageViewMyBrush setToolTip:NSLocalizedString(@"Display the current brush", nil)];
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Art Brush” Selector", nil)];
    [m_myCustomComboRadius setToolTip:NSLocalizedString(@"Adjust brush size", nil)];
    [m_myCustomComboOpacity setToolTip:NSLocalizedString(@"Adjust brush transparency", nil)];
    [m_myCustomComboSmooth setToolTip:NSLocalizedString(@"Adjust brush smoothness", nil)];
    [m_myCustomComboHardness setToolTip:NSLocalizedString(@"Adjust brush hardness", nil)];
    [m_myCustomComboPressure setToolTip:NSLocalizedString(@"Adjust/Show brush pressure", nil)];
    
    [m_labelRadius setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Radius", nil)]];
    [m_labelOpacity setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [m_labelHardness setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Hardness", nil)]];
    [m_labelSmooth setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Smooth", nil)]];
    [m_labelPressure setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Pressure", nil)]];
    
    
    [self loadFavoriteBrush];
    
    
    NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:m_nFavoriteBrushIndex]];
    NSString *sPath = [[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:sOriginalBrushName] stringByAppendingString:@"_prev.png"];
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:sPath] autorelease];
    
    [m_imageViewMyBrush setImage:image];
}

#pragma mark - Favorite Brushes -

-(void)loadFavoriteBrush
{
    NSString *sPath = [self configFavouriteBrushFile];//[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/favouritebrushconfig.txt"];
    
    NSArray *array;
    [self readBrushNameFromFileconst:sPath brushNameArray:&array];
    m_arrFavoriteBrushNames = [(NSMutableArray *)array retain];
    
    
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
        [m_arrFavoriteBrushNames release];
        m_arrFavoriteBrushNames = [(NSMutableArray *)[m_arrFavoriteBrushNames subarrayWithRange:NSMakeRange(0, 7)] retain];
    }

    
    for (int nIndex = 0; nIndex < [m_arrFavoriteBrushNames count]; nIndex++)
    {
        int nOriginX = nIndex*(8 + BTN_FAVOIRTITE_SIZE_WIDTH) + 3;
        int nOriginY = (m_idFavoriteBrushesView.frame.size.height - BTN_FAVOIRTITE_SIZE_WIDTH)/2.0;
        
        
        
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(nOriginX, nOriginY, BTN_FAVOIRTITE_SIZE_WIDTH, BTN_FAVOIRTITE_SIZE_WIDTH)];
        NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:nIndex]];
        NSString *sPath = [[[[gMainBundle resourcePath] stringByAppendingString:@"/myBrushes/"] stringByAppendingString:sOriginalBrushName] stringByAppendingString:@"_prev.png"];
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:sPath] autorelease];
        [imageView setImage:image];
        [imageView.cell setBezeled:YES];
        [imageView.cell setBordered:NO];
        [imageView setImageScaling:NSImageScaleAxesIndependently];
        [m_idFavoriteBrushesView.documentView addSubview:imageView];
        [imageView release];
        
        
        
        NSButton *btn = [[NSButton alloc] initWithFrame:NSMakeRect(nOriginX  , nOriginY, BTN_FAVOIRTITE_SIZE_WIDTH , BTN_FAVOIRTITE_SIZE_WIDTH )];
        
        [btn setBezelStyle:NSThickSquareBezelStyle];
        [btn setBordered:NO];
        [btn setButtonType:NSSwitchButton];
        [btn setTag:2000+nIndex];
        [btn setState:NSOffState];
        [btn setTarget:self];
        [btn setAction:@selector(onFravoriteBrushBtn:)];
        [btn setImagePosition:NSImageOnly];
        NSButtonCell *btnCell = btn.cell;
        [btnCell setBezeled:YES];
        [btnCell setImageScaling:NSImageScaleAxesIndependently];
        [btn setImage:nil];
        [btn setAlternateImage:[NSImage imageNamed:@"button-bg-a"]];
        btn.toolTip = [m_arrFavoriteBrushNames objectAtIndex:nIndex];
        
        [m_idFavoriteBrushesView.documentView addSubview:btn];
        [btn release];
        
        if(nIndex == m_nFavoriteBrushIndex)
        {
            [btn setState:YES];
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

-(void)readBrushNameFromFileconst:(NSString *)sFilePath brushNameArray:(NSArray<NSString *>**)brushNameArray
{
    NSString *string = [NSString stringWithContentsOfFile:sFilePath encoding:NSUTF8StringEncoding error:nil];
    if([string rangeOfString:@"\r\n"].length != 0)
        *brushNameArray = [string componentsSeparatedByString:@"\r\n"];
    else
        *brushNameArray = [string componentsSeparatedByCharactersInSet:  [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
}

-(void)onFravoriteBrushBtn:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    m_nFavoriteBrushIndex = btn.tag - 2000;
    
    [self resumeFavoriteBrushBtnState];
    
    
    
    NSString *sOriginalBrushName = [self getFavoriteBrushOriginalName:[m_arrFavoriteBrushNames objectAtIndex:m_nFavoriteBrushIndex]];
    
    [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeCurrentBrush:sOriginalBrushName];
    
    
    //更新参数
    NSString *sBrushName = [m_arrFavoriteBrushNames objectAtIndex:m_nFavoriteBrushIndex];
    NSDictionary *dic = [m_mdFavoriteBrushHistoryPara objectForKey:sBrushName];
    if(dic)
    {
        float fOpacity = [[dic objectForKey:@"opacity"] floatValue];
        float fRadius = [[dic objectForKey:@"radius"] floatValue];
        float fHardness = [[dic objectForKey:@"hardness"] floatValue];
        float fSmooth = [[dic objectForKey:@"smooth"] floatValue];
        
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_SLOW_TRACKING value:fSmooth];
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_RADIUS_LOGARITHMIC value:fRadius];
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_OPAQUE value:fOpacity];
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_HARDNESS value:fHardness];
    }
    
    
}

-(void)resumeFavoriteBrushBtnState
{
    int nCount = [m_arrFavoriteBrushNames count];
    for(int nIndex = 0; nIndex < nCount; nIndex++)
    {
        NSButton *btn = (NSButton *)[m_idFavoriteBrushesView.documentView viewWithTag:2000 + nIndex];
        
        [btn setState:NO];
        
        if(nIndex == m_nFavoriteBrushIndex)
            [btn setState:YES];
    }
}

-(void)setFavoriteBrushIndex:(int)nIndex
{
    m_nFavoriteBrushIndex = nIndex;
    if(m_nFavoriteBrushIndex != -1)
        [self onFravoriteBrushBtn:[m_idFavoriteBrushesView.documentView viewWithTag:2000+m_nFavoriteBrushIndex]];
    else
        [self resumeFavoriteBrushBtnState];
}

-(int)getFavoriteBrushIndex
{
    return m_nFavoriteBrushIndex;
}

-(void)dealloc
{
    [m_mdFavoriteBrushHistoryPara release];
    
    [super dealloc];
}

#pragma mark - Brush Para
-(void)setSmooth:(float)fSmooth
{
    [m_myCustomComboSmooth setStringValue:[NSString stringWithFormat:@"%.1f",fSmooth]];
}

- (float)radius
{
    return [[m_myCustomComboRadius getStringValue] floatValue];
}

-(void)setRadius:(float)fRadius
{
    [m_myCustomComboRadius setStringValue:[NSString stringWithFormat:@"%.1f",fRadius]];
}

- (void)addRadius:(BOOL)isAdd
{
    float radius = [self radius];
    if (isAdd) {
        radius += 0.1;
        radius = MIN(radius, [m_myCustomComboRadius getSliderMaxValue]);
    }else{
        radius -= 0.1;
        radius = MAX(radius, [m_myCustomComboRadius getSliderMinValue]);
    }
    [m_myCustomComboRadius setStringValue:[NSString stringWithFormat:@"%.1f",radius]];
    [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_RADIUS_LOGARITHMIC value:radius];
    [self recodeFavoriteBrushHistoryPara];
    
}

-(void)setHardness:(float)fHardness
{
    [m_myCustomComboHardness setStringValue:[NSString stringWithFormat:@"%.1f",fHardness]];
}

-(void)setOpacity:(float)fOpacity
{
    [m_myCustomComboOpacity setStringValue:[NSString stringWithFormat:@"%.1f",fOpacity]];
}

- (void)setPressure:(float)fPressure
{
    [m_myCustomComboPressure setStringValue:[NSString stringWithFormat:@"%.1f",fPressure]];
}

- (float)pressure
{
    return [[m_myCustomComboPressure getStringValue] floatValue];
}

- (IBAction)toggleMyBrushes:(id)sender
{
    NSWindow *w = [gCurrentDocument window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

-(void)updateBrushImage:(NSImage *)image
{
    [m_imageViewMyBrush setImage:image];
}

-(void)recodeFavoriteBrushHistoryPara
{
    if(m_nFavoriteBrushIndex == -1) return;
    
    NSString *sBrushName = [m_arrFavoriteBrushNames objectAtIndex:m_nFavoriteBrushIndex];
    
    float fOpacity = [[m_myCustomComboOpacity getStringValue] floatValue];
    float fRadius = [[m_myCustomComboRadius getStringValue] floatValue];
    float fHardness = [[m_myCustomComboHardness getStringValue] floatValue];
    float fSmooth = [[m_myCustomComboSmooth getStringValue] floatValue];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:fRadius], [NSNumber numberWithFloat:fOpacity],[NSNumber numberWithFloat:fHardness], [NSNumber numberWithFloat:fSmooth], nil] forKeys:[NSArray arrayWithObjects:@"radius",@"opacity",@"hardness",@"smooth", nil]];
    
    [m_mdFavoriteBrushHistoryPara setObject:dictionary forKey:sBrushName];
//    [m_mdFavoriteBrushHistoryPara setValue:dictionary forKey:sBrushName];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComboSmooth)
    {
        [m_myCustomComboSmooth setStringValue:[NSString stringWithFormat:@"%.1f",sValue.floatValue]];
        
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_SLOW_TRACKING value:sValue.floatValue];
        [self recodeFavoriteBrushHistoryPara];
    }
    else if (customComboBox == m_myCustomComboRadius)
    {
        [m_myCustomComboRadius setStringValue:[NSString stringWithFormat:@"%.1f",sValue.floatValue]];
        
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_RADIUS_LOGARITHMIC value:sValue.floatValue];
        [self recodeFavoriteBrushHistoryPara];
    }
    else if (customComboBox == m_myCustomComboOpacity)
    {
        [m_myCustomComboOpacity setStringValue:[NSString stringWithFormat:@"%.1f",sValue.floatValue]];
        
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_OPAQUE value:sValue.floatValue];
        [self recodeFavoriteBrushHistoryPara];
    }
    else if (customComboBox == m_myCustomComboHardness)
    {
        [m_myCustomComboHardness setStringValue:[NSString stringWithFormat:@"%.1f",sValue.floatValue]];
        
        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_HARDNESS value:sValue.floatValue];
        
        [self recodeFavoriteBrushHistoryPara];
    }
    else if(customComboBox == m_myCustomComboPressure)
    {
        [m_myCustomComboPressure setStringValue:[NSString stringWithFormat:@"%.1f",sValue.floatValue]];
    }
}

-(NSString *)configFavouriteBrushFile
{
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *pPath = [docDir stringByAppendingString:@"/favouritebrushconfig.txt"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pPath])
        [[NSFileManager defaultManager] removeItemAtPath:pPath error:nil];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:pPath])
    {
        NSString *src = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/myBrushes/favouritebrushconfig.txt"];
        
        [[NSFileManager defaultManager] copyItemAtPath:src toPath:pPath error:nil];
    }
    
    return pPath;
}

@end

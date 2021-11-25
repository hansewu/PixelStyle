//
//  CurvesClass.m
//  Curves
//
//  Created by lchzh on 22/9/15.
//  Copyright (c) 2015 lchzh. All rights reserved.
//

#import "CurvesClass.h"
#import "PSCurveView.h"
//#import "CurveColorAdjustFilter.h"
#import "PSColorSelectView.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CurvesClass


- (id)initWithManager:(PSPlugins *)manager
{
    seaPlugins = manager;
    m_pointValueArray = [[NSMutableArray alloc] init];
    m_pointValueArrayForRed = [[NSMutableArray alloc] init];
    m_pointValueArrayForGreen = [[NSMutableArray alloc] init];
    m_pointValueArrayForBlue = [[NSMutableArray alloc] init];
    memset(m_grayHistogramInfo, 0, 256);
//    m_curveAdjustFilter = [[CurveColorAdjustFilter alloc] init];
//    [m_curveAdjustFilter useNextFrameForImageCapture];
    
    [NSBundle loadNibNamed:@"Curves" owner:self];
    [m_curveView setCustumDelegate:self];
    
    [m_blackFieldToColorView setCustumDelegate:self];
    [m_blackFieldToColorView setViewTag:0];
    [m_grayFieldToColorView setCustumDelegate:self];
    [m_grayFieldToColorView setViewTag:1];
    [m_whiteFieldToColorView setCustumDelegate:self];
    [m_whiteFieldToColorView setViewTag:2];
    
    for (int i = 0; i < 3; i++) {
        m_blackFieldFrom[i] = 0;
        m_blackFieldTo[i] = 0;
        m_grayFieldFrom[i] = 128;
        m_grayFieldTo[i] = 128;
        m_whiteFieldFrom[i] = 255;
        m_whiteFieldTo[i] = 255;
    }
    m_selectedFieldIndex = -1;
    
    std::vector<float> xPoints;
    std::vector<float> yPoints;
    m_curveInterpolationObject = new Lagrange(xPoints, yPoints);
    
    m_redEnable = NO;
    m_curveInterpolationObjectForRed = new Lagrange(xPoints, yPoints);
    m_greenEnable = NO;
    m_curveInterpolationObjectForGreen = new Lagrange(xPoints, yPoints);
    m_blueEnable = NO;
    m_curveInterpolationObjectForBlue = new Lagrange(xPoints, yPoints);
    
    return self;
}

- (int)type
{
    return 3;
}

- (NSString *)name
{
    return [gOurBundle localizedStringForKey:@"name" value:@"Curves" table:NULL];
}

- (NSString *)groupName
{
    return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

//- (NSString *)sanity
//{
//    return @"EffectMatrix";
//}

- (NSString *)sanity
{
    return @"PixelStyle Approved (Bobo)";
}

- (NSMutableArray *)getDragPointValueArrayForColorIndex:(int)index
{
    switch (index) {
        case 0:
            return m_pointValueArray;
            break;
        case 1:
            return m_pointValueArrayForRed;
            break;
        case 2:
            return m_pointValueArrayForGreen;
            break;
        case 3:
            return m_pointValueArrayForBlue;
            break;
            
        default:
            break;
    }
    return m_pointValueArray;
}

- (BOOL)getCurveEnableForColorIndex:(int)index
{
    switch (index) {
        case 0:
            return YES;
            break;
        case 1:
            return m_redEnable;
            break;
        case 2:
            return m_greenEnable;
            break;
        case 3:
            return m_blueEnable;
            break;
            
        default:
            break;
    }
    return NO;
}

- (void)insertPoint:(NSPoint)point atIndex:(int)index
{
    NSValue *pointValue = [NSValue valueWithPoint:point];
    NSInteger colorIndex = [m_colorChannelSegment selectedSegment];
    switch (colorIndex) {
        case 0:
            [m_pointValueArray insertObject:pointValue atIndex:index];
            break;
        case 1:
            [m_pointValueArrayForRed insertObject:pointValue atIndex:index];
            break;
        case 2:
            [m_pointValueArrayForGreen insertObject:pointValue atIndex:index];
            break;
        case 3:
            [m_pointValueArrayForBlue insertObject:pointValue atIndex:index];
            break;
            
        default:
            break;
    }
    
    [self updateInterpolationObjectInfo];
    [self updateCurveView];
    [self updateOverlayInSelector];
}

- (void)replacePoint:(NSPoint)point atIndex:(int)index
{
    NSValue *pointValue = [NSValue valueWithPoint:point];
    NSInteger colorIndex = [m_colorChannelSegment selectedSegment];
    switch (colorIndex) {
        case 0:
            [m_pointValueArray replaceObjectAtIndex:index withObject:pointValue];
            break;
        case 1:
            [m_pointValueArrayForRed replaceObjectAtIndex:index withObject:pointValue];
            break;
        case 2:
            [m_pointValueArrayForGreen replaceObjectAtIndex:index withObject:pointValue];
            break;
        case 3:
            [m_pointValueArrayForBlue replaceObjectAtIndex:index withObject:pointValue];
            break;
            
        default:
            break;
    }
    
    [self updateInterpolationObjectInfo];
    [self updateCurveView];
    [self updateOverlayInSelector];
}

- (void)removePointAtIndex:(int)index
{
    NSInteger colorIndex = [m_colorChannelSegment selectedSegment];
    switch (colorIndex) {
        case 0:
            if ([m_pointValueArray count] > 2) {
                [m_pointValueArray removeObjectAtIndex:index];
            }else{
                return;
            }
            break;
            
        case 1:
            if ([m_pointValueArrayForRed count] > 2) {
                [m_pointValueArrayForRed removeObjectAtIndex:index];
            }else{
                return;
            }
            break;
            
        case 2:
            if ([m_pointValueArrayForGreen count] > 2) {
                [m_pointValueArrayForGreen removeObjectAtIndex:index];
            }else{
                return;
            }
            break;
            
        case 3:
            if ([m_pointValueArrayForBlue count] > 2) {
                [m_pointValueArrayForBlue removeObjectAtIndex:index];
            }else{
                return;
            }
            break;
            
        default:
            break;
    }
    
    [self updateInterpolationObjectInfo];
    [self updateCurveView];
    [self updateOverlayInSelector];
}

- (void)updateInterpolationObjectInfoForIndex:(int)index
{
    std::vector<float> xPoints;
    std::vector<float> yPoints;
    switch (index) {
        case 0:
            for (int i = 0; i < [m_pointValueArray count]; i++) {
                NSValue *pointValue = [m_pointValueArray objectAtIndex:i];
                NSPoint point = [pointValue pointValue];
                xPoints.push_back(point.x);
                yPoints.push_back(point.y);
            }
            m_curveInterpolationObject->insertSamples(xPoints, yPoints);
            break;
        case 1:
            for (int i = 0; i < [m_pointValueArrayForRed count]; i++) {
                NSValue *pointValue = [m_pointValueArrayForRed objectAtIndex:i];
                NSPoint point = [pointValue pointValue];
                xPoints.push_back(point.x);
                yPoints.push_back(point.y);
            }
            m_curveInterpolationObjectForRed->insertSamples(xPoints, yPoints);
            break;
        case 2:
            for (int i = 0; i < [m_pointValueArrayForGreen count]; i++) {
                NSValue *pointValue = [m_pointValueArrayForGreen objectAtIndex:i];
                NSPoint point = [pointValue pointValue];
                xPoints.push_back(point.x);
                yPoints.push_back(point.y);
            }
            m_curveInterpolationObjectForGreen->insertSamples(xPoints, yPoints);
            break;
        case 3:
            for (int i = 0; i < [m_pointValueArrayForBlue count]; i++) {
                NSValue *pointValue = [m_pointValueArrayForBlue objectAtIndex:i];
                NSPoint point = [pointValue pointValue];
                xPoints.push_back(point.x);
                yPoints.push_back(point.y);
            }
            m_curveInterpolationObjectForBlue->insertSamples(xPoints, yPoints);
            break;
            
        default:
            break;
    }

}

- (void)updateInterpolationObjectInfo
{
    int colorIndex = (int)[m_colorChannelSegment selectedSegment];
    switch (colorIndex) {
        case 0:
            break;
        case 1:
            m_redEnable = YES;
            break;
        case 2:
            m_greenEnable = YES;
            break;
        case 3:
            m_blueEnable = YES;
            break;
            
        default:
            break;
    }
    [self updateInterpolationObjectInfoForIndex:colorIndex];
}

- (void)updateCurveViewInfoForIndex:(int)index
{
    NSMutableArray *array = [NSMutableArray array];
    int pointsCount = 300;
    switch (index) {
        case 0:{
            float beginx = [[m_pointValueArray firstObject] pointValue].x;
            float endx = [[m_pointValueArray lastObject] pointValue].x;
            for (int i = 0; i < pointsCount; i++) {
                float srcValue = beginx + (float)i / pointsCount * (endx - beginx);
                float desValue = m_curveInterpolationObject->interpolate(srcValue);
                if (i == pointsCount -1) {
                    desValue = [[m_pointValueArray lastObject] pointValue].y;
                }
                desValue = MIN(254, MAX(1, desValue));
                NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(srcValue, desValue)];
                [array addObject:pointValue];
            }
            break;
        }
        case 1:{
            float beginx = [[m_pointValueArrayForRed firstObject] pointValue].x;
            float endx = [[m_pointValueArrayForRed lastObject] pointValue].x;
            for (int i = 0; i < pointsCount; i++) {
                float srcValue = beginx + (float)i / pointsCount * (endx - beginx);
                float desValue = m_curveInterpolationObjectForRed->interpolate(srcValue);
                if (i == pointsCount -1) {
                    desValue = [[m_pointValueArrayForRed lastObject] pointValue].y;
                }
                desValue = MIN(254, MAX(1, desValue));
                NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(srcValue, desValue)];
                [array addObject:pointValue];
            }
            break;
        }
        case 2:{
            float beginx = [[m_pointValueArrayForGreen firstObject] pointValue].x;
            float endx = [[m_pointValueArrayForGreen lastObject] pointValue].x;
            for (int i = 0; i < pointsCount; i++) {
                float srcValue = beginx + (float)i / pointsCount * (endx - beginx);
                float desValue = m_curveInterpolationObjectForGreen->interpolate(srcValue);
                if (i == pointsCount -1) {
                    desValue = [[m_pointValueArrayForGreen lastObject] pointValue].y;
                }
                desValue = MIN(254, MAX(1, desValue));
                NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(srcValue, desValue)];
                [array addObject:pointValue];
            }
            break;
        }
        case 3:{
            float beginx = [[m_pointValueArrayForBlue firstObject] pointValue].x;
            float endx = [[m_pointValueArrayForBlue lastObject] pointValue].x;
            for (int i = 0; i < pointsCount; i++) {
                float srcValue = beginx + (float)i / pointsCount * (endx - beginx);
                float desValue = m_curveInterpolationObjectForBlue->interpolate(srcValue);
                if (i == pointsCount -1) {
                    desValue = [[m_pointValueArrayForBlue lastObject] pointValue].y;
                }
                desValue = MIN(254, MAX(1, desValue));
                NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(srcValue, desValue)];
                [array addObject:pointValue];
            }
            break;
        }
            
        default:
            break;
    }
    [m_curveView updateDrawPointArray:array ForColorIndex:index];
   
}

- (void)updateCurveView
{
    int colorIndex = (int)[m_colorChannelSegment selectedSegment];
    [self updateCurveViewInfoForIndex:colorIndex];
    
    [m_curveView setNeedsDisplay:YES];
   
}


- (unsigned char)getTransformedValue:(unsigned char)srcValue ColorIndex:(int)colorIndex
{
    unsigned char desValue = srcValue;
    float desValuef = 0.0;
    float srcValuef = (float)srcValue;
    switch (colorIndex) {
        case 0:{
            if (srcValuef <= [[m_pointValueArray firstObject] pointValue].x) {
                desValuef = [[m_pointValueArray firstObject] pointValue].y;
            }else if (srcValuef >= [[m_pointValueArray lastObject] pointValue].x) {
                desValuef = [[m_pointValueArray lastObject] pointValue].y;
            }else{
                desValuef = m_curveInterpolationObject->interpolate(srcValuef);
            }
            break;
        }
        case 1:{
            if (srcValuef <= [[m_pointValueArrayForRed firstObject] pointValue].x) {
                desValuef = [[m_pointValueArrayForRed firstObject] pointValue].y;
            }else if (srcValuef >= [[m_pointValueArrayForRed lastObject] pointValue].x) {
                desValuef = [[m_pointValueArrayForRed lastObject] pointValue].y;
            }else{
                desValuef = m_curveInterpolationObjectForRed->interpolate(srcValuef);
            }
            break;
        }
        case 2:
            if (srcValuef <= [[m_pointValueArrayForGreen firstObject] pointValue].x) {
                desValuef = [[m_pointValueArrayForGreen firstObject] pointValue].y;
            }else if (srcValuef >= [[m_pointValueArrayForGreen lastObject] pointValue].x) {
                desValuef = [[m_pointValueArrayForGreen lastObject] pointValue].y;
            }else{
                desValuef = m_curveInterpolationObjectForGreen->interpolate(srcValuef);
            }
            break;
        case 3:
            if (srcValuef <= [[m_pointValueArrayForBlue firstObject] pointValue].x) {
                desValuef = [[m_pointValueArrayForBlue firstObject] pointValue].y;
            }else if (srcValuef >= [[m_pointValueArrayForBlue lastObject] pointValue].x) {
                desValuef = [[m_pointValueArrayForBlue lastObject] pointValue].y;
            }else{
                desValuef = m_curveInterpolationObjectForBlue->interpolate(srcValuef);
            }
            break;
            
        default:
            break;
    }
    desValuef = MIN(255, MAX(0, desValuef));
    desValue = (unsigned char)desValuef;
    return desValue;
}

- (void)updateHistogramInfo
{
    NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    NSInteger index = [m_colorChannelSegment selectedSegment];
    PluginData *pluginData;
    IntRect selection;
    unsigned char *data;
    int pos, i, j, width, spp;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    selection = [pluginData selection];
    spp = [pluginData spp];
    width = [pluginData width];
    data = [pluginData data];
    
    float histogramInfo[256];
    memset(histogramInfo, 0, 256 * sizeof(float));
    switch (index) {
        case 0:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
                    pos = j * width + i;
                    float grayf = (float)data[pos * spp] * 0.299 + (float)data[pos * spp + 1] * 0.587 + (float)data[pos * spp + 2] * 0.114;
                    grayf = MIN(255.0, grayf);
                    unsigned char grayn = (unsigned char)grayf;
                    histogramInfo[grayn] += 1.0f;
                }
            }
            break;
        }
        case 1:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        histogramInfo[data[pos * spp]] += 1.0f;
                    }
                }
            }
            break;
        }
        case 2:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        histogramInfo[data[pos * spp + 1]] += 1.0f;
                    }
                }
            }
            break;
        }
        case 3:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        histogramInfo[data[pos * spp + 2]] += 1.0f;
                    }
                }
            }
            break;
        }
        default:
            break;
    }
    
    float max = histogramInfo[0];
    for (int i = 1; i < 256; i++) {
        if (histogramInfo[i] > max) {
            max = histogramInfo[i];
        }
    }
    max = MAX(max, 1.0);
    for (int i = 0; i < 256; i++) {
        m_grayHistogramInfo[i] = (unsigned char)(histogramInfo[i] / max * 255.0);
    }
    //NSLog(@"updateHistogramInfo %f",[NSDate timeIntervalSinceReferenceDate]- begin);
}

- (int)getSelectedColorIndex
{
    return (int)[m_colorChannelSegment selectedSegment];
}

- (unsigned char*)getGrayHistogramInfo
{
    return m_grayHistogramInfo;
}



- (void)run
{
    [(PSPlugins *)seaPlugins changeNewToolTo:7 isReset:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedColorChanged:) name:@"EYEDROPCOLORCHANGED" object:nil];
    [m_colorChannelSegment setSelectedSegment:0];
    
    for (int i = 0; i < 3; i++) {
        m_blackFieldFrom[i] = 0;
        m_blackFieldTo[i] = 0;
        m_grayFieldFrom[i] = 128;
        m_grayFieldTo[i] = 128;
        m_whiteFieldFrom[i] = 255;
        m_whiteFieldTo[i] = 255;
    }
    m_selectedFieldIndex = -1;
    [self updateFieldButtonImage];

    m_redEnable = NO;
    m_greenEnable = NO;
    m_blueEnable = NO;
    [self updateHistogramInfo];
    [m_pointValueArray removeAllObjects];
    [m_pointValueArrayForRed removeAllObjects];
    [m_pointValueArrayForGreen removeAllObjects];
    [m_pointValueArrayForBlue removeAllObjects];
    NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(0, 0)];
    [m_pointValueArray addObject:pointValue];
    [m_pointValueArrayForRed addObject:pointValue];
    [m_pointValueArrayForGreen addObject:pointValue];
    [m_pointValueArrayForBlue addObject:pointValue];
    pointValue = [NSValue valueWithPoint:NSMakePoint(255.0, 255.0)];
    [m_pointValueArray addObject:pointValue];
    [m_pointValueArrayForRed addObject:pointValue];
    [m_pointValueArrayForGreen addObject:pointValue];
    [m_pointValueArrayForBlue addObject:pointValue];
    
    [self updateInterpolationObjectInfoForIndex:0];
    [self updateInterpolationObjectInfoForIndex:1];
    [self updateInterpolationObjectInfoForIndex:2];
    [self updateInterpolationObjectInfoForIndex:3];
    
    
    PluginData *pluginData;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    //[self preview:self];
    if ([pluginData window]){
        //[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        //[panel makeKeyAndOrderFront:nil];
        [[pluginData window] addChildWindow:panel ordered:NSWindowAbove];
        [panel makeKeyAndOrderFront:nil];
        //[NSApp runModalForWindow:panel];
    }
    else{
        [NSApp runModalForWindow:panel];
    }
    
    [self updateCurveView];
    
}


- (void)selectedColorChanged:(NSNotification*) notification
{
    if (m_selectedFieldIndex == -1) {
        return;
    }
    
    NSColor *color = [notification object];
    unsigned char red = (unsigned char)([color redComponent] * 255.0);
    unsigned char green = (unsigned char)([color greenComponent] * 255.0);
    unsigned char blue = (unsigned char)([color blueComponent] * 255.0);
    
    switch (m_selectedFieldIndex) {
        case 0:{
            [self setBlackFieldFromRed:red green:green blue:blue];
            break;
        }
        case 1:{
            [self setGrayFieldFromRed:red green:green blue:blue];
            break;
        }
        case 2:{
            [self setWhiteFieldFromRed:red green:green blue:blue];
            break;
        }
            
        default:
            break;
    }
    for (int i = 0; i < 4; i++) {
        [self updateInterpolationObjectInfoForIndex:i];
        [self updateCurveViewInfoForIndex:i];
    }
    [m_curveView setNeedsDisplay:YES];
    [self updateOverlayInSelector];
}

- (IBAction)apply:(id)sender
{
    PluginData *pluginData;
    pluginData = [(PSPlugins *)seaPlugins data];
    [pluginData apply];
    
    [NSApp stopModal];
    if ([pluginData window]) [NSApp endSheet:panel];
    [panel orderOut:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"EYEDROPCOLORCHANGED" object:nil];
    [(PSPlugins *)seaPlugins changeNewToolTo:0 isReset:YES];
}


- (void)reapply
{
    PluginData *pluginData;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    [pluginData apply];
}


- (BOOL)canReapply
{
    return success;
}

- (void)updateOverlayAfterChanged
{
    NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    PluginData *pluginData;
    IntRect selection;
    unsigned char *data, *overlay, *replace;
    int pos, i, j, width, spp;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    selection = [pluginData selection];
    spp = [pluginData spp];
    width = [pluginData width];
    data = [pluginData data];
    overlay = [pluginData overlay];
    replace = [pluginData replace];
    
    NSInteger checked = [m_previewButton state];
    if (!checked) {
        [pluginData setOverlayOpacity:0];
        [pluginData performSelectorOnMainThread:@selector(preview) withObject:nil waitUntilDone:YES]; //会卡顿
        return;
    }
    

    
    unsigned char curveTransformForRed[256];
    if (m_redEnable) {
        for (int i = 0; i < 256; i++) {
            curveTransformForRed[i] = [self getTransformedValue:i ColorIndex:1];
            curveTransformForRed[i] = [self getTransformedValue:curveTransformForRed[i] ColorIndex:0];
        }
    }else{
        for (int i = 0; i < 256; i++) {
            curveTransformForRed[i] = [self getTransformedValue:i ColorIndex:0];
        }
    }
    unsigned char curveTransformForGreen[256];
    if (m_greenEnable) {
        for (int i = 0; i < 256; i++) {
            curveTransformForGreen[i] = [self getTransformedValue:i ColorIndex:2];
            curveTransformForGreen[i] = [self getTransformedValue:curveTransformForGreen[i] ColorIndex:0];
        }
    }else{
        for (int i = 0; i < 256; i++) {
            curveTransformForGreen[i] = [self getTransformedValue:i ColorIndex:0];
        }
    }
    unsigned char curveTransformForBlue[256];
    if (m_blueEnable) {
        for (int i = 0; i < 256; i++) {
            curveTransformForBlue[i] = [self getTransformedValue:i ColorIndex:3];
            curveTransformForBlue[i] = [self getTransformedValue:curveTransformForBlue[i] ColorIndex:0];
        }
    }else{
        for (int i = 0; i < 256; i++) {
            curveTransformForBlue[i] = [self getTransformedValue:i ColorIndex:0];
        }
    }
    
    //NSLog(@"updateOverlayAfterChanged1 %f",[NSDate timeIntervalSinceReferenceDate]- begin);
    for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
        for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
            pos = j * width + i;
            overlay[pos * spp] = curveTransformForRed[data[pos * spp]];
            overlay[pos * spp + 1] = curveTransformForGreen[data[pos * spp + 1]];
            overlay[pos * spp + 2] = curveTransformForBlue[data[pos * spp + 2]];
            overlay[pos * spp + 3] = data[pos * spp + 3];
            replace[pos] = 255;
        }
    }
    
    //NSLog(@"updateOverlayAfterChanged2 %f",[NSDate timeIntervalSinceReferenceDate]- begin);
    //[pluginData preview];  //费时，如何中断
    [pluginData performSelectorOnMainThread:@selector(preview) withObject:nil waitUntilDone:YES]; //会卡顿
    
    NSLog(@"updateOverlayAfterChanged3 %f",[NSDate timeIntervalSinceReferenceDate]- begin);
}



- (IBAction)segmentSelectionChanged:(id)sender
{
    [self updateHistogramInfo];
    [self updateCurveView];
    [self updateOverlayInSelector];
}

- (IBAction)resetLine:(id)sender
{
    int colorIndex = (int)[m_colorChannelSegment selectedSegment];
    switch (colorIndex) {
        case 0:{
            for (int i = 0; i < 3; i++) {
                m_blackFieldFrom[i] = 0;
                m_blackFieldTo[i] = 0;
                m_grayFieldFrom[i] = 128;
                m_grayFieldFrom[i] = 128;
                m_whiteFieldFrom[i] = 255;
                m_whiteFieldTo[i] = 255;
            }
            m_selectedFieldIndex = -1;
            [self updateFieldButtonImage];
            
            [m_pointValueArray removeAllObjects];
            [m_pointValueArrayForRed removeAllObjects];
            [m_pointValueArrayForGreen removeAllObjects];
            [m_pointValueArrayForBlue removeAllObjects];
            NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(0, 0)];
            [m_pointValueArray addObject:pointValue];
            [m_pointValueArrayForRed addObject:pointValue];
            [m_pointValueArrayForGreen addObject:pointValue];
            [m_pointValueArrayForBlue addObject:pointValue];
            pointValue = [NSValue valueWithPoint:NSMakePoint(255.0, 255.0)];
            [m_pointValueArray addObject:pointValue];
            [m_pointValueArrayForRed addObject:pointValue];
            [m_pointValueArrayForGreen addObject:pointValue];
            [m_pointValueArrayForBlue addObject:pointValue];
            m_redEnable = NO;
            m_greenEnable = NO;
            m_blueEnable = NO;
            for (int i = 0; i < 4; i++) {
                [self updateInterpolationObjectInfoForIndex:i];
                [self updateCurveViewInfoForIndex:i];
            }
            break;
        }
        case 1:{
            [m_pointValueArrayForRed removeAllObjects];
            NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(0, 0)];
            [m_pointValueArrayForRed addObject:pointValue];
            pointValue = [NSValue valueWithPoint:NSMakePoint(255.0, 255.0)];
            [m_pointValueArrayForRed addObject:pointValue];
            m_redEnable = NO;
            [self updateInterpolationObjectInfoForIndex:colorIndex];
            [self updateCurveViewInfoForIndex:colorIndex];
            break;
        }
        case 2:{
            [m_pointValueArrayForGreen removeAllObjects];
            NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(0, 0)];
            [m_pointValueArrayForGreen addObject:pointValue];
            pointValue = [NSValue valueWithPoint:NSMakePoint(255.0, 255.0)];
            [m_pointValueArrayForGreen addObject:pointValue];
            m_greenEnable = NO;
            [self updateInterpolationObjectInfoForIndex:colorIndex];
            [self updateCurveViewInfoForIndex:colorIndex];
            break;
        }
        case 3:{
            [m_pointValueArrayForBlue removeAllObjects];
            NSValue *pointValue = [NSValue valueWithPoint:NSMakePoint(0, 0)];
            [m_pointValueArrayForBlue addObject:pointValue];
            pointValue = [NSValue valueWithPoint:NSMakePoint(255.0, 255.0)];
            [m_pointValueArrayForBlue addObject:pointValue];
            m_blueEnable = NO;
            [self updateInterpolationObjectInfoForIndex:colorIndex];
            [self updateCurveViewInfoForIndex:colorIndex];
            break;
        }
            
        default:
            break;
    }
    
    [m_curveView setNeedsDisplay:YES];
    [self updateOverlayInSelector];
}

- (void)updateOverlayInSelector
{
    SEL sel = @selector(updateOverlayAfterChangedInThread);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
    [self performSelector: sel withObject: nil afterDelay: 0.1];
    
}

- (void)updateOverlayAfterChangedInThread
{
    SEL sel = @selector(updateOverlayAfterChanged);
    [NSThread detachNewThreadSelector:sel toTarget:self withObject:nil];
}

- (IBAction)cancel:(id)sender
{
    PluginData *pluginData;    
    pluginData = [(PSPlugins *)seaPlugins data];
    [pluginData cancel];
    
    [panel setAlphaValue:1.0];
    
    [NSApp stopModal];
    [NSApp endSheet:panel];
    [panel orderOut:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"EYEDROPCOLORCHANGED" object:nil];
    [(PSPlugins *)seaPlugins changeNewToolTo:0 isReset:YES];
}




- (BOOL)validateMenuItem:(id)menuItem
{
    PluginData *pluginData;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    
    if (pluginData != NULL) {
        
        if ([pluginData channel] == kAlphaChannel)
            return NO;
        
        if ([pluginData spp] == 2)
            return NO;
        
    }
    
    return YES;
}

- (IBAction)previewButtonClicked:(id)sender
{
    //NSInteger checked = [m_previewButton state];
    [self updateOverlayInSelector];
}

- (IBAction)autoButtonClicked:(id)sender
{
    
}

- (NSImage*)getImageForName:(NSString*)name
{
    NSString *path = nil;
    NSString *bundlePath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:@"Curves.bundle"];
    path = [[NSBundle bundleWithPath:bundlePath] pathForImageResource:name];
    if (path) {
        return [[NSImage alloc] initWithContentsOfFile:path];
    }
    return  nil;
}

- (void)updateFieldButtonImage
{
    switch (m_selectedFieldIndex) {
        case -1:
            [m_blackFieldButton setImage:[self getImageForName:@"blackFiledImage0"]];
            [m_grayFieldButton setImage:[self getImageForName:@"grayFiledImage0"]];
            [m_whiteFieldButton setImage:[self getImageForName:@"whiteFiledImage0"]];
            break;
        case 0:
            [m_blackFieldButton setImage:[self getImageForName:@"blackFiledImage1"]];
            [m_grayFieldButton setImage:[self getImageForName:@"grayFiledImage0"]];
            [m_whiteFieldButton setImage:[self getImageForName:@"whiteFiledImage0"]];
            break;
        case 1:
            [m_blackFieldButton setImage:[self getImageForName:@"blackFiledImage0"]];
            [m_grayFieldButton setImage:[self getImageForName:@"grayFiledImage1"]];
            [m_whiteFieldButton setImage:[self getImageForName:@"whiteFiledImage0"]];
            break;
        case 2:
            [m_blackFieldButton setImage:[self getImageForName:@"blackFiledImage0"]];
            [m_grayFieldButton setImage:[self getImageForName:@"grayFiledImage0"]];
            [m_whiteFieldButton setImage:[self getImageForName:@"whiteFiledImage1"]];
            break;
            
        default:
            break;
    }
    
}

- (IBAction)blackFieldButtonClicked:(id)sender
{
    
    if (m_selectedFieldIndex == 0) {
        m_selectedFieldIndex = -1;
    }else{
        m_selectedFieldIndex = 0;
    }
    [self updateFieldButtonImage];
}

- (IBAction)grayFieldButtonClicked:(id)sender
{
    if (m_selectedFieldIndex == 1) {
        m_selectedFieldIndex = -1;
    }else{
        m_selectedFieldIndex = 1;
    }
    [self updateFieldButtonImage];
}

- (IBAction)whiteFieldButtonClicked:(id)sender
{
    if (m_selectedFieldIndex == 2) {
        m_selectedFieldIndex = -1;
    }else{
        m_selectedFieldIndex = 2;
    }
    [self updateFieldButtonImage];
}

//set white gray black field

- (void)setWhiteFieldFromRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    m_whiteFieldFrom[0] = red;
    m_whiteFieldFrom[1] = green;
    m_whiteFieldFrom[2] = blue;
    if (red <= m_blackFieldFrom[0]) {
        m_blackFieldFrom[0] = MAX(red - 2, 0);
    }
    if (green <= m_blackFieldFrom[1]) {
        m_blackFieldFrom[1] = MAX(green - 2, 0);
    }
    if (blue <= m_blackFieldFrom[2]) {
        m_blackFieldFrom[2] = MAX(blue - 2, 0);
    }
    [self updatePointInfoAfterSetField:NO];
}


- (void)setWhiteFieldToRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    m_whiteFieldTo[0] = red;
    m_whiteFieldTo[1] = green;
    m_whiteFieldTo[2] = blue;
    [self updatePointInfoAfterSetField:NO];
}


- (void)setGrayFieldFromRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    if (red <= m_grayFieldFrom[0]) {
        m_blackFieldFrom[0] = MAX(red - 2, 0);
    }
    if (green <= m_grayFieldFrom[1]) {
        m_blackFieldFrom[1] = MAX(green - 2, 0);
    }
    if (blue <= m_grayFieldFrom[2]) {
        m_blackFieldFrom[2] = MAX(blue - 2, 0);
    }
    float midValue = ((float)red + (float)green + (float)blue) / 3.0;
    unsigned char originalData[3];
    originalData[0] = red;
    originalData[1] = green;
    originalData[2] = blue;
    for (int i = 0; i < 2; i++) {
        float grayValue = ((float)m_blackFieldFrom[i] + (float)m_whiteFieldFrom[i]) / 2.0 + ((float)originalData[i] - midValue);
        grayValue = MIN(MAX((float)m_blackFieldFrom[i], grayValue), (float)m_whiteFieldFrom[i]);
        m_grayFieldFrom[i] = (unsigned char)grayValue;
    }
    
    [self updatePointInfoAfterSetField:YES];
}

- (void)setGrayFieldToRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    m_grayFieldTo[0] = red;
    m_grayFieldTo[1] = green;
    m_grayFieldTo[2] = blue;
    [self updatePointInfoAfterSetField:YES];
}

- (void)setBlackFieldFromRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    m_blackFieldFrom[0] = red;
    m_blackFieldFrom[1] = green;
    m_blackFieldFrom[2] = blue;
    if (red >= m_whiteFieldFrom[0]) {
        m_whiteFieldFrom[0] = MIN(red + 2, 255);
    }
    if (green >= m_whiteFieldFrom[1]) {
        m_whiteFieldFrom[1] = MIN(green + 2, 255);
    }
    if (blue >= m_whiteFieldFrom[2]) {
        m_whiteFieldFrom[2] = MIN(blue + 2, 255);
    }
    [self updatePointInfoAfterSetField:NO];
    
}

- (void)setBlackFieldToRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    m_blackFieldTo[0] = red;
    m_blackFieldTo[1] = green;
    m_blackFieldTo[2] = blue;
    [self updatePointInfoAfterSetField:NO];
}

- (void)updatePointInfoAfterSetField:(BOOL)isEnableGray
{
    m_redEnable = YES;
    m_greenEnable = YES;
    m_blueEnable = YES;
    [m_pointValueArray removeAllObjects];
    [m_pointValueArrayForRed removeAllObjects];
    [m_pointValueArrayForGreen removeAllObjects];
    [m_pointValueArrayForBlue removeAllObjects];
    [m_pointValueArray addObject:[NSValue valueWithPoint:NSMakePoint(0, 0)]];
    [m_pointValueArray addObject:[NSValue valueWithPoint:NSMakePoint(255.0, 255.0)]];
    [m_pointValueArrayForRed addObject:[NSValue valueWithPoint:NSMakePoint((float)m_blackFieldFrom[0], (float)m_blackFieldTo[0])]];
    [m_pointValueArrayForRed addObject:[NSValue valueWithPoint:NSMakePoint((float)m_whiteFieldFrom[0], (float)m_whiteFieldTo[0])]];
    [m_pointValueArrayForGreen addObject:[NSValue valueWithPoint:NSMakePoint((float)m_blackFieldFrom[1], (float)m_blackFieldTo[1])]];
    [m_pointValueArrayForGreen addObject:[NSValue valueWithPoint:NSMakePoint((float)m_whiteFieldFrom[1], (float)m_whiteFieldTo[1])]];
    [m_pointValueArrayForBlue addObject:[NSValue valueWithPoint:NSMakePoint((float)m_blackFieldFrom[2], (float)m_blackFieldTo[2])]];
    [m_pointValueArrayForBlue addObject:[NSValue valueWithPoint:NSMakePoint((float)m_whiteFieldFrom[2], (float)m_whiteFieldTo[2])]];
    if(isEnableGray)
    {
        [m_pointValueArrayForRed insertObject:[NSValue valueWithPoint:NSMakePoint((float)m_grayFieldFrom[0], (float)m_grayFieldTo[0])] atIndex:1];
        [m_pointValueArrayForGreen insertObject:[NSValue valueWithPoint:NSMakePoint((float)m_grayFieldFrom[1], (float)m_grayFieldTo[1])] atIndex:1];
        [m_pointValueArrayForBlue insertObject:[NSValue valueWithPoint:NSMakePoint((float)m_grayFieldFrom[2], (float)m_grayFieldTo[2])] atIndex:1];
    }
}


- (IBAction)blackFieldToButtonClicked:(id)sender
{
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setAction:NULL];
    [colorPanel setShowsAlpha:YES];
    NSColor *color = [NSColor colorWithDeviceRed:m_blackFieldTo[0] / 255.0 green:m_blackFieldTo[1] / 255.0 blue:m_blackFieldTo[1] / 255.0 alpha:1.0];
    [colorPanel setColor:color];
    [colorPanel orderFront:self];
    [colorPanel setTitle:@"拾取目标低光颜色"];
    [colorPanel setContinuous:YES];
    [colorPanel setAction:@selector(changeBlackFieldToColor:)];
    [colorPanel setTarget:self];
}

- (IBAction)grayFieldToButtonClicked:(id)sender
{
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setAction:NULL];
    [colorPanel setShowsAlpha:YES];
    NSColor *color = [NSColor colorWithDeviceRed:m_grayFieldTo[0] / 255.0 green:m_grayFieldTo[1] / 255.0 blue:m_grayFieldTo[1] / 255.0 alpha:1.0];
    [colorPanel setColor:color];
    [colorPanel orderFront:self];
    [colorPanel setTitle:@"拾取目标中间色颜色"];
    [colorPanel setContinuous:YES];
    [colorPanel setAction:@selector(changeGrayFieldToColor:)];
    [colorPanel setTarget:self];
}

- (IBAction)whiteFieldToButtonClicked:(id)sender
{
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setAction:NULL];
    [colorPanel setShowsAlpha:YES];
    NSColor *color = [NSColor colorWithDeviceRed:m_whiteFieldTo[0] / 255.0 green:m_whiteFieldTo[1] / 255.0 blue:m_whiteFieldTo[1] / 255.0 alpha:1.0];
    [colorPanel setColor:color];
    [colorPanel orderFront:self];
    [colorPanel setTitle:@"拾取目标高光颜色"];
    [colorPanel setContinuous:YES];
    [colorPanel setAction:@selector(changeWhiteFieldToColor:)];
    [colorPanel setTarget:self];
}

- (void)changeBlackFieldToColor:(id)sender
{
    NSColor *color = [(NSColorPanel*)sender color];
    color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    unsigned char red = (unsigned char)([color redComponent] * 255.0);
    unsigned char green = (unsigned char)([color greenComponent] * 255.0);
    unsigned char blue = (unsigned char)([color blueComponent] * 255.0);
    [self setBlackFieldToRed:red green:green blue:blue];
    [m_blackFieldToColorView setNeedsDisplay:YES];
    for (int i = 0; i < 4; i++) {
        [self updateInterpolationObjectInfoForIndex:i];
        [self updateCurveViewInfoForIndex:i];
    }
    [m_curveView setNeedsDisplay:YES];
    [self updateOverlayInSelector];
}

- (void)changeGrayFieldToColor:(id)sender
{
    NSColor *color = [(NSColorPanel*)sender color];
    color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    unsigned char red = (unsigned char)([color redComponent] * 255.0);
    unsigned char green = (unsigned char)([color greenComponent] * 255.0);
    unsigned char blue = (unsigned char)([color blueComponent] * 255.0);
    [self setGrayFieldToRed:red green:green blue:blue];
    [m_grayFieldToColorView setNeedsDisplay:YES];
    for (int i = 0; i < 4; i++) {
        [self updateInterpolationObjectInfoForIndex:i];
        [self updateCurveViewInfoForIndex:i];
    }
    [m_curveView setNeedsDisplay:YES];
    [self updateOverlayInSelector];
}

- (void)changeWhiteFieldToColor:(id)sender
{
    NSColor *color = [(NSColorPanel*)sender color];
    color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    unsigned char red = (unsigned char)([color redComponent] * 255.0);
    unsigned char green = (unsigned char)([color greenComponent] * 255.0);
    unsigned char blue = (unsigned char)([color blueComponent] * 255.0);
    [self setWhiteFieldToRed:red green:green blue:blue];
    [m_whiteFieldToColorView setNeedsDisplay:YES];
    for (int i = 0; i < 4; i++) {
        [self updateInterpolationObjectInfoForIndex:i];
        [self updateCurveViewInfoForIndex:i];
    }
    [m_curveView setNeedsDisplay:YES];
    [self updateOverlayInSelector];
}

- (unsigned char*)getViewColorWithTag:(int)tag
{
    switch (tag) {
        case 0:
            return m_blackFieldTo;
            break;
        case 1:
            return m_grayFieldTo;
            break;
        case 2:
            return m_whiteFieldTo;
            break;
            
        default:
            break;
    }
    return m_blackFieldTo;
}

- (void)colorSelectViewClickedWithTag:(int)tag
{
    switch (tag) {
        case 0:
            [self blackFieldToButtonClicked:nil];
            break;
        case 1:
            [self grayFieldToButtonClicked:nil];
            break;
        case 2:
            [self whiteFieldToButtonClicked:nil];
            break;
            
        default:
            break;
    }
}

@end

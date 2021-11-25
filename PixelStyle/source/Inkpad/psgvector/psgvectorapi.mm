//
//  psgvectorapi.cpp
//  psgvector
//
//  Created by wu zhiqiang on 8/10/15.
//  Copyright (c) 2015 EffectMatrix Inc. All rights reserved.
//

#include "psgvectorapi.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDCurveFit.h"
#import "WDColor.h"
#import "WDGradient.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"

void Vector_SetupDefaults()
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"VecDefaults.plist"];
    [defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:defaultPath]];
    
    // Install valid defaults for various colors/gradients if necessary. These can't be encoded in the Defaults.plist.
    if (![defaults objectForKey:WDStrokeColorProperty])
    {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDColor blackColor]];
        [defaults setObject:value forKey:WDStrokeColorProperty];
    }
    
    if (![defaults objectForKey:WDFillProperty])
    {
        //NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDColor whiteColor]];
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDColor greenColor]]; //lcz modify
        [defaults setObject:value forKey:WDFillProperty];
    }
    
    if (![defaults objectForKey:WDFillColorProperty])
    {
        //NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDColor whiteColor]];
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDColor greenColor]]; //lcz modify
        [defaults setObject:value forKey:WDFillColorProperty];
    }
    
    if (![defaults objectForKey:WDFillGradientProperty])
    {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDGradient defaultGradient]];
        [defaults setObject:value forKey:WDFillGradientProperty];
    }
    
    if (![defaults objectForKey:WDStrokeDashPatternProperty])
    {
        NSArray *dashes = @[];
        [defaults setObject:dashes forKey:WDStrokeDashPatternProperty];
    }
    
    if (![defaults objectForKey:WDShadowColorProperty]) {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[WDColor colorWithRed:0 green:0 blue:0 alpha:0.333f]];
        [defaults setObject:value forKey:WDShadowColorProperty];
    }
}

/*
typedef void * WDLAYER_HANDLE;
typedef void * WDPATH_HANDLE;
typedef void * WDTEXT_HANDLE;
typedef void * WDSTYLABLE_HANDLE;

WDLAYER_HANDLE CreateWDLayer()
{
    WDLayer *layer = [WDLayer layer];
    layer.drawing = self;
    
    return layer;
}



WDPATH_HANDLE CreateSmoothPath(CGPoint *pPoints, int nPointCount, float fError, int bClose)
{
    NSMutableArray *arrPoints = [NSMutableArray array];
    
    for(int i=0; i< nPointCount; i++)
    {
#if TARGET_OS_IPHONE
        NSValue *value = [NSValue valueWithCGPoint:pPoints[i]];
#else
        NSValue *value = [NSValue valueWithPoint:pPoints[i]];

#endif
        [arrPoints addObject:value];
    }
    
    BOOL shouldClose = YES;
    
    if(!bClose) shouldClose = NO;
    WDPath *pathSmooth = [WDCurveFit smoothPathForPoints:arrPoints error:fError attemptToClose:shouldClose];
    
    return  pathSmooth;
}

WDPATH_HANDLE CreateRectPath(CGRect rect)
{
    return  [WDPath pathWithRect:rect];
}

WDPATH_HANDLE CreateRoundedRectPath(CGRect rect,  float fRadius)
{
    return  [WDPath pathWithRoundedRect:rect cornerRadius:fRadius];

}

WDPATH_HANDLE CreateOvalInRectPath(CGRect rect)
{
    return  [WDPath pathWithOvalInRect:rect];
}


WDPATH_HANDLE CreateLinePath(CGPoint  pointStart CGPoint pointEnd)
{
    return  [WDPath pathWithStart:pointStart end:pointEnd];
}


WDTEXT_HANDLE CreateTextObjectInRect(CGRect rect, const char *cText, const char *cFontName, float fFontSize, int nAlignment, void *FillStyle,  float fOpacity, void *shadow )
{
    WDText *text = [[WDText alloc] init];
    text.width = CGRectGetWidth(rect);
    
    text.text = [NSString stringWithUTF8String:cText];
    text.fontName = [NSString stringWithUTF8String:cFontName];
    text.fontSize = fFontSize;
    text.transform = CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y);
    text.alignment = (NSTextAlignment)nAlignment;
    // set this after width, so that the gradient will be set up properly
    text.fill = FillStyle;
    text.opacity = fOpacity;
    text.shadow = (WDShadow *)shadow;
    
    if (!text.fill)
    {
        // make sure the text isn't invisible
        text.fill = [WDColor blackColor];
    }
    
   // [drawing_ addObject:text];
   // [self selectObject:text];
    
    return text;
}


void SetStylableFillStype(WDSTYLABLE_HANDLE hStylablElement, void *FillStyle)
{
    
}



void SetStylableFillStype(WDSTYLABLE_HANDLE hStylablElement, void *StrokeStyle)
{
    
}

void SetStylableOpacity(WDSTYLABLE_HANDLE hStylablElement, float fOpacity)
{
    
}

void SetStylableShadow(WDSTYLABLE_HANDLE hStylablElement, void *shadow)
{
    
}

*/




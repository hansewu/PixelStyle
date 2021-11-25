//
//  SVGExporter.m
//  PixelStyle
//
//  Created by wyl on 16/4/1.
//
//

#import "SVGExporter.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSVecLayer.h"

#import "WDSVGHelper.h"
#import "WDXMLElement.h"
#import "WDLayer.h"
#import "WDPath.h"

@implementation SVGExporter

- (BOOL)hasOptions
{
    return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
    return @"SVG document (SVG)";
}

- (NSString *)extension
{
    return @"svg";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    CGFloat nWidth = [(PSContent *)[document contents] width];
    CGFloat nHeight = [(PSContent *)[document contents] height];
    
    NSMutableString     *svg = [NSMutableString string];
    WDSVGHelper         *sharedHelper = [WDSVGHelper sharedSVGHelper];
    
    [sharedHelper beginSVGGeneration];
    
    [svg appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
    [svg appendString:@"<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"\n"];
    [svg appendString:@"  \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"];
    [svg appendString:@"<!-- Created with Inkpad (http://www.taptrix.com/) -->"];
    
    WDXMLElement *svgElement = [WDXMLElement elementWithName:@"svg"];
    [svgElement setAttribute:@"version" value:@"1.1"];
    [svgElement setAttribute:@"xmlns" value:@"http://www.w3.org/2000/svg"];
    [svgElement setAttribute:@"xmlns:xlink" value:@"http://www.w3.org/1999/xlink"];
    [svgElement setAttribute:@"xmlns:inkpad" value:@"http://taptrix.com/inkpad/svg_extensions"];
    [svgElement setAttribute:@"width" value:[NSString stringWithFormat:@"%gpt", nWidth]];
    [svgElement setAttribute:@"height" value:[NSString stringWithFormat:@"%gpt", nHeight]];
    [svgElement setAttribute:@"viewBox" value:[NSString stringWithFormat:@"0,0,%g,%g", nWidth, nHeight]];
    
    [svgElement addChild:[sharedHelper definitions]];
    
    int nLayerCount = [(PSContent *)[document contents] layerCount];
//    for(int nIndex = 0; nIndex < nLayerCount; nIndex++)
    for(int nIndex = nLayerCount - 1; nIndex >= 0; nIndex--)
    {
        PSAbstractLayer *pLayer = [(PSContent *)[document contents] layer:nIndex];
        PA_LAYER_FORMAT layerFormat = pLayer.layerFormat;
        if(layerFormat != PS_TEXT_LAYER && (layerFormat != PS_VECTOR_LAYER)) continue;
//        if(![pLayer visible]) continue;
        PSVecLayer *pVecLayer = (PSVecLayer *)pLayer;
        WDLayer *wdLayer = [pVecLayer getLayer];
        WDXMLElement *layerSVG = [self SVGElement:wdLayer vecLayer:pVecLayer];//[wdLayer SVGElement];
        
        if (layerSVG) {
            [svgElement addChild:layerSVG];
        }
    }
//    for (WDLayer *layer in layers_) {
//        WDXMLElement *layerSVG = [layer SVGElement];
//        
//        if (layerSVG) {
//            [svgElement addChild:layerSVG];
//        }
//    }
    
    [svg appendString:[svgElement XMLValue]];
   
    NSData *result = [svg dataUsingEncoding:NSUTF8StringEncoding];
    
    [sharedHelper endSVGGeneration];

    
    [result writeToFile:path atomically:YES];
    
    return YES;
}

- (WDXMLElement *) SVGElement:(WDLayer *)wdLayer vecLayer:(PSVecLayer *)pVecLayer
{
    if(wdLayer.elements.count == 0) return nil;
    
    WDXMLElement *layer = [WDXMLElement elementWithName:@"g"];
    NSString *uniqueName = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:
                            [@"Layer$" stringByAppendingString:[pVecLayer name]]];
    [layer setAttribute:@"id" value:[uniqueName substringFromIndex:6]];
    [layer setAttribute:@"inkpad:layerName" value:[pVecLayer name]];
    
    if (![pVecLayer visible]) {
        [layer setAttribute:@"visibility" value:@"hidden"];
    }
    
    if ([pVecLayer opacity]/255.0 != 1.0f) {
        [layer setAttribute:@"opacity" floatValue:[pVecLayer opacity]/255.0];
    }
    
    CGAffineTransform layerTransform = [pVecLayer transform];
    for (WDElement *element in wdLayer.elements)
    {
        WDElement *elementCopy = [[element copyWithZone:nil] autorelease];
        [(WDPath *)elementCopy transform:layerTransform];
        [layer addChild:[elementCopy SVGElement]];
    }
    
    return layer;
}


@end

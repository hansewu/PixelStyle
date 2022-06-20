//
//  MyWindow.h
// 
//
//  Created by Calvin on 11/9/16.
//  Copyright © 2016 EffectMatrix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyView.h"
#include "AImageFilter.h"
#include <vector>
#import "FileManager.h"
@class GDataXMLElement;
@class MyTabView;

@interface MyWindow : NSWindow<NSTabViewDelegate>
{

}

-(void)setInputImage:(NSImage*)image;
-(void)start;

-(void)clickBtnShowEffectImage:(NSButton*)sender;
-(void)enableBtn;

-(MyTabView*)GetTabView;
-(NSView*)getLabelView;
-(CIContext*)getContext;
-(NSImage*)getInputImage;
-(MyView*)getShowView;
-(GDataXMLElement*)getGDataCombination;
-(void)setGDataCombination:(GDataXMLElement*)element;
-(GDataXMLElement*)getGDataCombinationTemplate;
-(void)setGDataCombinationTemplate:(GDataXMLElement*)element;
-(int)getFilterIndex;
-(void)setIndexOfFilter:(int)index;
-(CIImage*)getInputCIImage;

-(IMAGE_FILTER_HANDLE)getFilterHandle;
-(void)setFilterHandle:(IMAGE_FILTER_HANDLE)handle;

-(std::vector<IMAGE_FILTER_HANDLE>&)getFilterHandleVector;
-(void)setFilterHandleVector:(std::vector<IMAGE_FILTER_HANDLE>)vector;
-(NSMutableArray*)getIndexArrayForCategory;
@end

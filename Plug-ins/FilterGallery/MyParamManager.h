//
//  MyParamManager.h
//  FilterGallery
//
//  Created by Calvin on 4/1/17.
//  Copyright © 2017 EffectMatrix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "MyTabView.h"
#import "MyView.h"
#import "AImageFilter.h"
#import "FileManager.h"
#include <vector>
#import "MyWindow.h"
@class TemplateManager;

@interface MyParamManager : NSObject
{
    FileManager* m_FileManager;
    MyWindow* m_Window;
    TemplateManager* m_TemplateManager;
    
    NSImage* m_imageForSlider;
    NSImage* m_imageForSliderBar;
    
    NSView* m_viewContainControls;
    NSScrollView* m_paramScrollView;
}
-(id)init;
-(void)setWindow:(MyWindow*)window;
-(void)setFileManager:(FileManager*)manager;
-(void)setTemplateManager:(TemplateManager*)manager;
- (void)clickBtnToRefreshTemplateParam:(NSButton *)sender;

-(void)addContainerView;
-(void)updateParamUI:(int)nIndexOfFilter;
-(void)initParamUIForSingleFilter;
-(NSView*)getContainView;
-(void)setContainView:(id)view;
@end

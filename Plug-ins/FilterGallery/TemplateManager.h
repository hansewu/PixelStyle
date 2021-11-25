//
//  TemplateManager.h
//  FilterGallery
//
//  Created by Calvin on 4/5/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GDataXMLNode.h"
#import "MyView.h"
#import "MyTabView.h"
#import "AImageFilter.h"
#import "MyVerticalScroller.h"
#import "MyHorizontalScroller.h"
#import "TemplateButton.h"
#include <vector>
#import "FileManager.h"
#import "MyWindow.h"
#import "MyShowViewManager.h"
#import "MyParamManager.h"


@interface TemplateManager : NSObject
{
    FileManager* m_FileManager;
    MyParamManager* m_ParamManager;
    MyWindow* m_Window;
    MyShowViewManager* m_ShowViewManager;
    NSScrollView* m_scrollViewForTemplate;
    int m_nIndexOfBtnForTemplate;
    float m_heightCurrentTemplate;
}

-(void)setFileManager:(FileManager*)manager;
-(void)setShowViewManager:(MyShowViewManager*)manager;
-(void)setParamManager:(MyParamManager*)manager;
-(void)setWindow:(MyWindow*)window;

-(void)showFilterTemplate;
-(void)showFirstTemplateEffect;
-(void)clickButtonToAddTemplate:(NSButton*)sender;
-(void)clickBtnToReplaceTemplate:(NSButton*) sender;
-(void)clickBtnToMinusTemplate:(NSButton *)sender;

-(void)setIndexOfTemplate:(int)index;
-(int)getIndexOfTemplate;

-(float)getHeightOfTemplate;
-(void)setHeightOfTemplate:(float)height;
@end

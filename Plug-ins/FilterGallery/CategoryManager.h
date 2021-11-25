//
//  CategoryManager.h
//  FilterGallery
//
//  Created by 沈宸 on 2017/4/11.
//  Copyright © 2017年 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "MyTabView.h"
#include "AImageFilter.h"
#import "GDataXMLNode.h"
#import "FileManager.h"
#import "TemplateManager.h"
#import "MyWindow.h"
#import "MyShowViewManager.h"
#import "MyParamManager.h"

@interface CategoryManager : NSObject<NSTabViewDelegate>
{
    FileManager* m_FileManager;
    TemplateManager* m_TemplateManager;
    MyWindow* m_Window;
    MyShowViewManager* m_ShowViewManager;
    MyParamManager* m_ParamManager;
    
    NSScrollView* m_scrollViewForFilter;
}
-(void)showFirstBtnEffectAndUI;
-(void)initCombinaionFilterTabItem;
-(void)clickBtnToSaveCombination:(NSButton*)sender;
-(void)clickBtnToDeleteCombination:(NSButton*)sender;


-(void)setFileManager:(FileManager*)manager;
-(void)setTemplateManager:(TemplateManager*)manager;
-(void)setWindow:(MyWindow*)window;
-(void)setShowViewManager:(MyShowViewManager*)manager;
-(void)setParamManager:(MyParamManager*)manager;
-(NSArray*)getArrayForCategoryOrder;
@end

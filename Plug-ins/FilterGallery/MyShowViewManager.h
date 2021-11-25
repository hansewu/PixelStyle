//
//  MyShowViewManager.h
//  FilterGallery
//
//  Created by 沈宸 on 2017/4/10.
//  Copyright © 2017年 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyView.h"
#include <vector>
#import "FileManager.h"
#include "AImageFilter.h"
#import "GDataXMLNode.h"
#import "MyWindow.h"
#import "MyParamManager.h"

@interface MyShowViewManager : NSObject
{
    MyWindow* m_Window;
    FileManager* m_FileManager;
    MyParamManager* m_ParamManager;
    NSMutableArray* m_arrayForLayerFiltersSaved;
    int m_numOfFiltesCountCurrent;
}
-(void)setParamManager:(MyParamManager*)manager;
-(void)setWindow:(MyWindow*)window;
-(void)setFileManager:(FileManager*)manager;

-(void)showCombinationFilterEffect:(int)tag;

-(void)showEffect;

-(NSMutableArray*)getSavedFilterArray;
-(int)getCurrentFiltersCount;
-(void)setCurrentFiltersCount:(int)count;
@end

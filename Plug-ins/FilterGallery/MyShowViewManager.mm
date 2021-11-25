//
//  MyShowViewManager.m
//  FilterGallery
//
//  Created by 沈宸 on 2017/4/10.
//  Copyright © 2017年 Calvin. All rights reserved.
//

#import "MyShowViewManager.h"
extern FileManager* m_FileManager;

@implementation MyShowViewManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        m_arrayForLayerFiltersSaved = [[NSMutableArray alloc]init];
    }
    return self;
}

-(int)getCurrentFiltersCount
{
    return m_numOfFiltesCountCurrent;
}
-(void)setCurrentFiltersCount:(int)count
{
    m_numOfFiltesCountCurrent = count;
}

-(NSMutableArray*)getSavedFilterArray
{
    return m_arrayForLayerFiltersSaved;
}

-(void)setFileManager:(FileManager*)manager
{
    m_FileManager = manager;
}

-(void)setParamManager:(MyParamManager*)manager
{
    m_ParamManager = manager;
}

-(void)setWindow:(MyWindow *)window
{
    m_Window = window;
}

-(void)dealloc
{
    if(m_arrayForLayerFiltersSaved)
    {
        [m_arrayForLayerFiltersSaved removeAllObjects];
        [m_arrayForLayerFiltersSaved release];
        m_arrayForLayerFiltersSaved = nil;
    }
    [super dealloc];
}
//showVIew
-(void)showCombinationFilterEffect:(int)tag
{
    //删除未保存的滤镜
    int numOfFilters = (int)m_arrayForLayerFiltersSaved.count;
    if(numOfFilters != m_numOfFiltesCountCurrent)
    {
        for(int i = numOfFilters; i > m_numOfFiltesCountCurrent; i--)
        {
            [m_arrayForLayerFiltersSaved removeObjectAtIndex:i - 1];
        }
    }
    
    int nIndexOfFilterCombination = tag;
    GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
    NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
    GDataXMLElement* combination =  arrayForCombination[nIndexOfFilterCombination];
    NSArray* arrayForFilter = [combination elementsForName:@"filter"];
    for(int i = 0; i < arrayForFilter.count; i++)
    {
        int nIndexOfFilter = [[[[arrayForFilter[i] elementsForName:@"filterIndex"]lastObject] stringValue] intValue];
        IMAGE_FILTER_HANDLE handle = CreateFilterForImage([m_Window getInputCIImage], nIndexOfFilter);
        ([m_Window getFilterHandleVector]).push_back(handle);
        [m_arrayForLayerFiltersSaved addObject:((IMAGE_FILTER*)handle)->filter];
    }
}


//showView
-(void)showEffect
{
    NSUInteger index = [[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem] - 1;
    if([m_Window getFilterHandle])
    {
        DestroyImageFilter([m_Window getFilterHandle]);
        [m_Window setFilterHandle:nil];
    }
    if ([m_Window getFilterHandleVector].size()) {
        long nCount = [m_Window getFilterHandleVector].size();
        for (int i = 0; i < nCount; i++) {
            DestroyImageFilter([m_Window getFilterHandleVector].at(0));
            [m_Window getFilterHandleVector].erase([m_Window getFilterHandleVector].begin());
        }
    }

    [m_Window setFilterHandle:CreateFilterForImageInCategory([m_Window getInputCIImage],((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex])];
    int numOfFilters = (int)m_arrayForLayerFiltersSaved.count;
    if(numOfFilters != m_numOfFiltesCountCurrent)
    {
        for(int i = numOfFilters; i > m_numOfFiltesCountCurrent; i--)
        {
            [m_arrayForLayerFiltersSaved removeObjectAtIndex:i - 1];
        }
    }
    [m_arrayForLayerFiltersSaved addObject:((IMAGE_FILTER*)[m_Window getFilterHandle])->filter];
}

@end

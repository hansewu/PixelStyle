//
//  CategoryManager.m
//  FilterGallery
//
//  Created by 沈宸 on 2017/4/11.
//  Copyright © 2017年 Calvin. All rights reserved.
//

#import "CategoryManager.h"
#import "MyButton.h"
#import "MyHorizontalScroller.h"
#import "MyHorizontalScrollView.h"
#include <vector>
#import "MyWindow.h"

@interface CategoryManager ()
{
    NSArray* m_arrayForCategoryOrder;
}
@end
@implementation CategoryManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        m_arrayForCategoryOrder = [[CategoryOrder componentsSeparatedByString:@" "] retain];
    }
    
    return self;
}

-(NSArray*)getArrayForCategoryOrder
{
    return m_arrayForCategoryOrder;
}

-(void)setShowViewManager:(MyShowViewManager*)manager
{
    m_ShowViewManager = manager;
}

-(void)setFileManager:(FileManager*)manager
{
    m_FileManager = manager;
}

-(void)setTemplateManager:(TemplateManager*)manager
{
    m_TemplateManager = manager;
}

-(void)setParamManager:(MyParamManager*)manager
{
    m_ParamManager = manager;
}

-(void)setWindow:(MyWindow*)window
{
    m_Window = window;
}

//TabView
//当选中的是filterCombination分类时，初始化界面的方法
-(void)initCombinaionFilterTabItem
{
    //创建这个分类中所有的滤镜
    if(m_scrollViewForFilter)
    {
        [m_scrollViewForFilter removeFromSuperview];
        m_scrollViewForFilter = nil;
    }
    GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
    NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
    
    [self configTabScrollView];
    
    int btnWidth = 70 + 13;
    int btnHeight = 85 + 16;
    int nOriginalXForBtn = 5;
    int intervalOfBtn = 15;
    int nNumberOfCombination = (int)arrayForCombination.count;

    NSRect contentRect = [m_Window GetTabView].contentRect;
    NSView* docView = [[NSView alloc] initWithFrame:NSMakeRect(contentRect.origin.x, contentRect.origin.y, nNumberOfCombination * (btnWidth + intervalOfBtn), contentRect.size.height - fHeightOfTabScrollView)];
    [m_scrollViewForFilter setDocumentView:docView];
    [docView release];
    
    NSString* stringForFilterName = nil;
    
    NSString* filePathForImage = [[NSBundle bundleForClass:[self class]] pathForResource:@"combination" ofType:@"jpg"];
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:filePathForImage];
    NSImage* resizedImage = [m_FileManager resizeImage:image toRect:NSMakeRect(0, 0, 300, 300)];
    CIImage* inputImage = [CIImage imageWithCGImage:[resizedImage CGImageForProposedRect:nil context:nil hints:nil]];
    for(int i = 0; i < nNumberOfCombination; i++)
    {
        NSArray* arrayForFilter = [arrayForCombination[i] elementsForName:@"filter"];
        IMAGE_FILTER* handle = nil;
        for(int j = 0; j < arrayForFilter.count; j++)
        {
//            NSString* sInNameOfFilter = [[[arrayForFilter[j] elementsForName:@"filterName"]lastObject] stringValue];
//            int nIndex = GetIndexOfFilter(sInNameOfFilter);
            int nIndex = [[[[arrayForFilter[j] elementsForName:@"filterIndex"]lastObject] stringValue] intValue];
            if(j == 0)
                handle = (IMAGE_FILTER*)CreateFilterForImage(inputImage, nIndex);
            
            else
                handle = (IMAGE_FILTER*)CreateFilterForImage(handle->image, nIndex);
        }
        NSImage* outputImage = [[[NSImage alloc] initWithCGImage:[[m_Window getContext] createCGImage:handle->image fromRect:inputImage.extent] size:NSZeroSize]autorelease];
        stringForFilterName = [NSString stringWithFormat:@"Combine %d", i + 1];
        MyButton* btn = [[MyButton alloc]initWithFrame:NSMakeRect(nOriginalXForBtn, 10, btnWidth, btnHeight)];
        btn.wantsLayer = YES;
        
        [btn setBtnImage:outputImage];
        
        [btn setBtnTitle:stringForFilterName];
        
        btn.action = @selector(chooseFilterCombination:);
        btn.target = self;
        [btn setTag: i];
        
        [m_scrollViewForFilter.documentView addSubview:btn];
        [btn release];
        nOriginalXForBtn += btnWidth + intervalOfBtn;
    }
    if(nNumberOfCombination <= 1)
        ((NSButton*)[[m_Window GetTabView].selectedTabViewItem.view viewWithTag:10000]).enabled = NO;
}

//tabView
-(void)configTabScrollView
{
    NSRect contentRect = [m_Window GetTabView].contentRect;
    int nIndexOfCategory = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    NSView* contentView = [[[NSView alloc] init] autorelease];
    if(nIndexOfCategory)
        m_scrollViewForFilter = [[MyHorizontalScrollView alloc] initWithFrame:NSMakeRect(contentRect.origin.x, contentRect.origin.y, contentRect.size.width, contentRect.size.height - fHeightOfTabScrollView)];
    else
    {
        m_scrollViewForFilter = [[MyHorizontalScrollView alloc] initWithFrame:NSMakeRect(contentRect.origin.x, contentRect.origin.y, contentRect.size.width - 50, contentRect.size.height - fHeightOfTabScrollView)];
        NSButton* btnAdd = [[[NSButton alloc] initWithFrame:NSMakeRect(contentRect.size.width - 50, 85, 40, 40)]autorelease];
        btnAdd.title = @"";
        btnAdd.bezelStyle = NSTexturedSquareBezelStyle;
        [btnAdd.cell setImageScaling:NSImageScaleAxesIndependently
         ];
//        btnAdd.cell.imageScaling = NSImageScaleAxesIndependently;
        btnAdd.bordered = NO;
        btnAdd.target = self;
        btnAdd.action = @selector(clickBtnToSaveCombination:);
        btnAdd.toolTip = @"Save Combination Filter";
        NSString* imagePath = [TBundle pathForResource:@"addCombination" ofType:@"png"];
        btnAdd.image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
        NSButton* btnDelete = [[[NSButton alloc] initWithFrame:NSMakeRect(contentRect.size.width - 50, 25, 40, 40)] autorelease];
        btnDelete.title = @"";
        imagePath = [TBundle pathForResource:@"delete2" ofType:@"png"];
        btnDelete.image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
//        btnDelete.imageScaling = NSImageScaleAxesIndependently;
        [btnDelete.cell setImageScaling:NSImageScaleAxesIndependently
         ];
        btnDelete.bordered = NO;
        btnDelete.target = self;
        btnDelete.action = @selector(clickBtnToDeleteCombination:);
        btnDelete.toolTip = @"Delete Combination Filter";
        btnDelete.bezelStyle = NSTexturedSquareBezelStyle;
        btnDelete.tag = 10000;
        [contentView addSubview:m_scrollViewForFilter];
        [contentView addSubview:btnAdd];
        [contentView addSubview:btnDelete];
    }
    
    MyHorizontalScroller* scroller = [[MyHorizontalScroller alloc] init];
    m_scrollViewForFilter.horizontalScroller = scroller;
    m_scrollViewForFilter.backgroundColor = [NSColor colorWithRed:60.0/255 green:60.0/255 blue:60.0/255 alpha:1.0];
    m_scrollViewForFilter.hasHorizontalScroller = YES;
    [m_Window GetTabView].selectedTabViewItem.view = contentView;
    
    [contentView addSubview:m_scrollViewForFilter];
    
}

-(void)configCombinationBtn:(NSButton*)btn
{
    btn.bezelStyle = NSTexturedSquareBezelStyle;
    btn.bordered = NO;
}

//tabView
-(void)initDocumentViewAtIndex:(int)index
{
    //创建这个分类中所有的滤镜
    if(m_scrollViewForFilter)
    {
        [m_scrollViewForFilter removeFromSuperview];
        m_scrollViewForFilter = nil;
    }
    
    int nFilterCount = GetFiltersCountInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue);
    
    int btnWidth = 70 + 13;
    int btnHeight = 85 + 16;
    int nOriginalXForBtn = 5;
    int intervalOfBtn = 15;
    
    [self configTabScrollView];
    NSRect contentRect = [m_Window GetTabView].contentRect;
    NSView* docView = [[NSView alloc] initWithFrame:NSMakeRect(contentRect.origin.x, contentRect.origin.y, nFilterCount * (btnWidth + intervalOfBtn), contentRect.size.height - fHeightOfTabScrollView)];
    [m_scrollViewForFilter.contentView setDocumentView:docView];
    [docView release];
    
    NSString* filePathForImage = [m_FileManager pathForCategoryImage:index + 1];
    
    for(int i = 0; i < nFilterCount; i++)
    {
        NSString* stringForFilterName = GetFilterNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, i);
        
        MyButton* btn = [[MyButton alloc]initWithFrame:NSMakeRect(nOriginalXForBtn, 10, btnWidth, btnHeight)];
        
        NSImage* image = [[NSImage alloc] initWithContentsOfFile:filePathForImage];
        NSImage* resizedImage = [m_FileManager resizeImage:image toRect:NSMakeRect(0, 0, 300, 300)];
        
        CIImage* ciImage = [CIImage imageWithCGImage:[resizedImage CGImageForProposedRect:nil context:nil hints:nil]];
        IMAGE_FILTER* handle = (IMAGE_FILTER*)CreateFilterForImageInCategory(ciImage, ((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, i);
        
        int nIndexOfCategory = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
        GDataXMLElement* rootElement = [m_FileManager getTemplateArray][((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue];
        AVARIABLE_VALUE paramValue;
        
        NSArray* arrayForSingleFilterTemplate = [rootElement elementsForName:@"filter"];
        
        NSString* stringForFilterInName2 = GetFilterNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue, i);
        
        for(int j = 0; j < arrayForSingleFilterTemplate.count; j++)
        {
            NSString* stringForFilterInName = [[[arrayForSingleFilterTemplate[j] elementsForName:@"filterName"]lastObject]stringValue];
            if([stringForFilterInName isEqualToString:stringForFilterInName2])
            {
                GDataXMLElement* paramElement = (GDataXMLElement*)[[arrayForSingleFilterTemplate[j] elementsForName:@"param"]lastObject];
                if(GetFilterParaCount(handle -> nFilterIndex) > 0)
                {
                    for (int k = 0; k < paramElement.childCount; k++) {
                        NSString* stringForParamOrder = [NSString stringWithFormat:@"param%d", k];
                        GDataXMLElement* paramOrder = (GDataXMLElement*)[[paramElement elementsForName:stringForParamOrder]lastObject];
                        NSString* stringForParamType = [[[paramOrder elementsForName:@"paramType"] lastObject] stringValue];
                        if([stringForParamType isEqualToString:@"AV_FLOAT"])
                        {
                            paramValue.fFloatValue = [[[[paramOrder elementsForName:@"paramCurrent"] lastObject] stringValue]floatValue];
                            ModifyImageFilterParm(handle, k, paramValue);
                            continue;
                        }
                        if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                        {
                            paramValue.fOffsetXY[0] = [[[[paramOrder elementsForName:@"ParamForX"] lastObject] stringValue]floatValue];
                            
                            paramValue.fOffsetXY[1] = [[[[paramOrder elementsForName:@"ParamForY"] lastObject] stringValue]floatValue];
                            
                            ModifyImageFilterParm(handle, k, paramValue);
                            continue;
                        }
                        if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                        {
                            float r,g,b;
                            r = [[[[paramOrder elementsForName:@"paramColorR"] lastObject] stringValue]floatValue];
                            g = [[[[paramOrder elementsForName:@"paramColorG"] lastObject] stringValue]floatValue];
                            b = [[[[paramOrder elementsForName:@"paramColorB"] lastObject] stringValue]floatValue];
                            
                            unsigned int nR,nG,nB;
                            nR = r * 255;
                            nG = g * 255;
                            nB = b * 255;
                            
                            unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + 255;
                            paramValue.nUnsignedValue = nColor;
                            ModifyImageFilterParm(handle, k, paramValue);
                            continue;
                        }
                    }
                }
                break;
            }
        }
        
        CIImage* outputImage = handle -> image;
        
        CGImageRef cgImage = [[m_Window getContext] createCGImage:outputImage   fromRect:ciImage.extent];
        
        NSImage* outputImage2 = [[[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize] autorelease];
        [btn setBtnImage:outputImage2];
        [btn setBtnTitle:stringForFilterName];
        btn.action = @selector(clickBtn:);
        btn.target = self;
        [btn setTag:i];
        [m_scrollViewForFilter.documentView addSubview:btn];
        [btn release];
        nOriginalXForBtn += btnWidth + intervalOfBtn;
    }
}
#define VIEWTAG 1000
//tabView
-(void)chooseFilterCombination:(NSButton*)sender
{
    [m_TemplateManager setHeightOfTemplate:0];
    [m_TemplateManager setIndexOfTemplate:-1];
    [m_Window setIndexOfFilter:(int)sender.tag];
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
    
    NSArray* arrayForBtns = [m_scrollViewForFilter.documentView subviews];
    for (NSButton* btn in arrayForBtns) {
        btn.layer.borderColor = nil;
        btn.layer.borderWidth = 0.0;
    }
    sender.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:1.0].CGColor;
    sender.layer.borderWidth = 3.0;
    
    [m_ParamManager addContainerView];
    
    //点击滤镜显示滤镜默认效果
    [m_ShowViewManager showCombinationFilterEffect:(int)sender.tag];
    
    //设置参数界面
    [m_ParamManager updateParamUI:(int)sender.tag];
    
//    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
//    [m_Window  clickBtnShowEffectImage:effectBtn];
    
    [m_Window getShowView].layer.filters = [m_ShowViewManager getSavedFilterArray];
    
    //加载模板
    [m_TemplateManager showFilterTemplate];
    
    [m_TemplateManager showFirstTemplateEffect];
    
    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
    [m_Window  clickBtnShowEffectImage:effectBtn];
}

//TabView
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [m_TemplateManager setIndexOfTemplate:-1];
    if([m_ParamManager getContainView])
    {
        [[m_ParamManager getContainView] removeFromSuperview];
        [m_ParamManager setContainView:nil];
    }
    NSInteger index = [[tabView tabViewItems] indexOfObject:tabViewItem];
    if(!index)
    {
        [self initCombinaionFilterTabItem];
    }
    else
        [self initDocumentViewAtIndex:(int)index - 1];
    [self showFirstBtnEffectAndUI];
    
#pragma -mark marked;
    //    m_showView.layer.filters = m_arrayForLayerFiltersSaved;
    
//    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
//    [m_Window  clickBtnShowEffectImage:effectBtn];
    [m_Window getShowView].layer.filters = [m_ShowViewManager getSavedFilterArray];
    
    //加载模板
    [m_TemplateManager showFilterTemplate];
    
    //如果此滤镜有模板则显示第一个模板的效果
    [m_TemplateManager showFirstTemplateEffect];
    
    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
    [m_Window clickBtnShowEffectImage:effectBtn];
    
    [m_Window enableBtn];
}

//showView
-(void)showFirstBtnEffectAndUI
{
    int nIndex = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    [m_Window setIndexOfFilter:0];
    NSButton* btn = [m_scrollViewForFilter viewWithTag:[m_Window getFilterIndex]];
    btn.layer.borderColor = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor;
    btn.layer.borderWidth = 2.0;
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
    if(!nIndex)
    {
        [m_ParamManager addContainerView];
        //点击滤镜显示滤镜默认效果
        [m_ShowViewManager showCombinationFilterEffect:[m_Window getFilterIndex]];
        //设置参数界面
        [m_ParamManager updateParamUI:[m_Window getFilterIndex]];
    }else{
        [m_ShowViewManager showEffect];
        [m_ParamManager addContainerView];
        [m_ParamManager initParamUIForSingleFilter];
    }
}

//tabView
-(void)clickBtn:(NSButton*)sender
{
    [m_TemplateManager setHeightOfTemplate:.0];
    [m_TemplateManager setIndexOfTemplate:-1];
    
    NSArray* arrayForBtns = [m_scrollViewForFilter.documentView subviews];
    for (NSButton* btn in arrayForBtns) {
        btn.layer.borderColor = nil;
        btn.layer.borderWidth = 0.0;
    }
    sender.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:1.0].CGColor;
    sender.layer.borderWidth = 3.0;
    
    [m_Window setIndexOfFilter:(int)sender.tag];
    
    [m_ShowViewManager showEffect];
    [m_ParamManager addContainerView];
    [m_ParamManager initParamUIForSingleFilter];
    
    [m_TemplateManager showFilterTemplate];
#pragma -mark marked;
//        m_showView.layer.filters = m_arrayForLayerFiltersSaved;
    [m_Window getShowView].layer.filters = [m_ShowViewManager getSavedFilterArray];
    
    
    [m_TemplateManager showFirstTemplateEffect];
    //显示到效果图
    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
    [m_Window clickBtnShowEffectImage:effectBtn];
}

//tabView
-(void)clickBtnToSaveCombination:(NSButton*)sender
{
    [m_ShowViewManager setCurrentFiltersCount:0];
    GDataXMLDocument* doc = [m_FileManager getFilterCombinationDocument];
    NSString* filePath = [m_FileManager pathForCombinationDocument];
    NSString* filePathForTemplate = [m_FileManager pathForCombinationTemplateDocument];
    GDataXMLDocument* docForTemplate = [m_FileManager getCombinationTemplateDocument];
    
    if([[m_Window getGDataCombination] elementsForName:@"filter"].count)
    {
        [doc.rootElement addChild:[m_Window getGDataCombination]];
        [docForTemplate.rootElement addChild:[m_Window getGDataCombinationTemplate]];
    }
    
    [doc.XMLData writeToFile:filePath atomically:YES];
    [docForTemplate.XMLData writeToFile:filePathForTemplate atomically:YES];
    
    [[m_FileManager getTemplateArray] removeObjectAtIndex:0];
    GDataXMLElement* rootElement = [[docForTemplate.rootElement copy]autorelease];
    [[m_FileManager getTemplateArray] insertObject:rootElement atIndex:0];
    
    if ([m_Window getGDataCombination]) {
        [[m_Window GetTabView] selectTabViewItem:[m_Window GetTabView].tabViewItems[0]];
        [self initCombinaionFilterTabItem];
        [self showFirstBtnEffectAndUI];
        [m_TemplateManager showFilterTemplate];
        [m_TemplateManager showFirstTemplateEffect];
    }
    
    [[m_Window getGDataCombination] release];
    [m_Window setGDataCombination:nil];
    
    [[m_Window getGDataCombinationTemplate] release];
    [m_Window setGDataCombinationTemplate:nil];
}

//tabVIew
-(void)clickBtnToDeleteCombination:(NSButton*)sender
{
    int nIndexOfTab = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    if(nIndexOfTab)
        return;
    
    NSString* filePath = [m_FileManager pathForCombinationDocument];
    GDataXMLDocument* doc = [m_FileManager getFilterCombinationDocument];
    GDataXMLElement* rootElement = doc.rootElement;
    NSArray* arrayForCombination = [rootElement elementsForName:@"filterCombination"];
    NSString* filterCombinationName = [[[arrayForCombination[[m_Window getFilterIndex]] elementsForName:@"filterCombinationName"] lastObject] stringValue];
    [rootElement removeChild:arrayForCombination[[m_Window getFilterIndex]]];
    [doc.XMLData writeToFile:filePath atomically:YES];
    
    filePath = [m_FileManager pathForCombinationTemplateDocument];
    doc = [m_FileManager getCombinationTemplateDocument];
    rootElement = doc.rootElement;
    arrayForCombination = [rootElement elementsForName:@"Combination"];
    for(int i = 0; i < arrayForCombination.count; i++)
    {
        NSString* combinationNameInTemplate = [[[arrayForCombination[i] elementsForName:@"filterCombinationName"]lastObject]stringValue];
        if([combinationNameInTemplate isEqualToString:filterCombinationName])
        {
            [rootElement removeChild:arrayForCombination[i]];
        }
    }

    [doc.XMLData writeToFile:filePath atomically:YES];
    //刷新tabItem1,并且选中第一个组合滤镜的第一个模板的效果
    [self initCombinaionFilterTabItem];
    [self showFirstBtnEffectAndUI];
    
//    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
//    [m_Window  clickBtnShowEffectImage:effectBtn];
    
    [m_Window getShowView].layer.filters = [m_ShowViewManager getSavedFilterArray];
    
    [m_TemplateManager showFilterTemplate];
    [m_TemplateManager showFirstTemplateEffect];
    NSButton* effectBtn = [[m_Window getLabelView] viewWithTag:VIEWTAG + 1];
    [m_Window clickBtnShowEffectImage:effectBtn];
}

-(void)dealloc
{
    if(m_scrollViewForFilter)
    {
        [m_scrollViewForFilter removeFromSuperview];
        m_scrollViewForFilter = nil;
    }
    
    [m_arrayForCategoryOrder release];
    [super dealloc];
}
@end

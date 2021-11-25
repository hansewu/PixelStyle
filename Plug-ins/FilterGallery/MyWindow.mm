 //
//  MyWindow.m
//
//  Created by Calvin on 11/9/16.
//  Copyright © 2016 Calvin. All rights reserved.
//

#import "MyWindow.h"
#import <CoreImage/CoreImage.h>
#import "GDataXMLNode.h"
#import "MyTabView.h"
#import "MyButton.h"
#import "TemplateButton.h"
#import "MyVerticalScroller.h"
#import "TemplateLabelView.h"
#import "LADSlider.h"
#import "MyHorizontalScrollView.h"
#import "MyParamManager.h"
#import "TemplateManager.h"
#import "CategoryManager.h"
#import "MyShowViewManager.h"

@interface MyWindow()
{
    FileManager* m_FileManager;
    TemplateManager* m_TemplateManager;
    CategoryManager* m_CategoryManager;
    MyShowViewManager* m_ShowViewManager;
    MyParamManager* m_ParamManager;
    MyTabView* m_tabViewToShow;
    NSView* m_labelView;
    CIContext* ctx;
    NSImage* m_inputImage;
    MyView* m_showView;
    GDataXMLElement* m_gDataElementForCombination;
    GDataXMLElement* m_gDataTemplateForCombination;
    int m_nIndexOfSelectedFilterInCategory;
    IMAGE_FILTER_HANDLE m_filterHandle;
    std::vector<IMAGE_FILTER_HANDLE> vectorForHandle;
    NSMutableArray* m_arrayForIndexOfCategory;
}
@end


@implementation MyWindow

-(std::vector<IMAGE_FILTER_HANDLE>&)getFilterHandleVector
{
    return vectorForHandle;
}

-(void)setFilterHandleVector:(std::vector<IMAGE_FILTER_HANDLE>)vector
{
    
}

-(IMAGE_FILTER_HANDLE)getFilterHandle
{
    return m_filterHandle;
}

-(void)setFilterHandle:(IMAGE_FILTER_HANDLE)handle
{
    m_filterHandle = handle;
}
-(int)getFilterIndex
{
    return m_nIndexOfSelectedFilterInCategory;
}

-(void)setIndexOfFilter:(int)index
{
    m_nIndexOfSelectedFilterInCategory = index;
}

-(GDataXMLElement*)getGDataCombination
{
    return m_gDataElementForCombination;
}

-(GDataXMLElement*)getGDataCombinationTemplate
{
    return m_gDataTemplateForCombination;
}

-(void)setGDataCombination:(GDataXMLElement*)element
{
    m_gDataElementForCombination = element;
}

-(void)setGDataCombinationTemplate:(GDataXMLElement*)element
{
    m_gDataTemplateForCombination = element;
}
-(MyView*)getShowView
{
    return m_showView;
}

-(NSImage*)getInputImage
{
    return m_inputImage;
}
-(CIContext*)getContext
{
    return ctx;
}

-(NSView*)getLabelView
{
    return m_labelView;
}

-(MyTabView*)GetTabView
{
    return m_tabViewToShow;
}
//window
-(void)start
{
    [self createSplitObject];
    
    //初始化每个分类，在底层的Index
    [self setIndexOfCategory];

    //初始化一个ctx
    ctx = [[CIContext context] retain];
    self.backgroundColor = WindowBackColor;
    [self.contentView setWantsLayer:YES];
    self.contentView.layer.backgroundColor = WindowBackColor.CGColor;
    
    [m_TemplateManager setIndexOfTemplate:-1];
    //创建showView
    [self createShowView];
    
    //记录现有0的layer中的滤镜的数量；
    [m_ShowViewManager setCurrentFiltersCount:(int)[m_ShowViewManager getSavedFilterArray].count];
    
    //更新tabView
    [self initTabView];
    
    //创建文件
    [m_FileManager createXMLFile];
    
    //读取模板文件，创建数组
    [m_FileManager createTemplateArray];
    
    //显示组合滤镜Tab
    [m_CategoryManager initCombinaionFilterTabItem];
    
    [m_TemplateManager showFilterTemplate];
    //显示第一个混合滤镜效果
    [m_CategoryManager showFirstBtnEffectAndUI];
    [m_TemplateManager showFirstTemplateEffect];
    m_showView.layer.filters = [m_ShowViewManager getSavedFilterArray];
    
    [self createLabel];
    [self createTemplateLabel];
    [self createShowLabel];
    
    [self enableBtn];
}

-(void)createSplitObject
{
    m_FileManager = [[FileManager alloc] init];
    [m_FileManager setWindow:self];
    
    m_TemplateManager = [[TemplateManager alloc] init];
    [m_TemplateManager setWindow:self];
    [m_TemplateManager setFileManager:m_FileManager];
    
    m_ParamManager = [[MyParamManager alloc]init];
    [m_ParamManager setFileManager:m_FileManager];
    [m_ParamManager setWindow:self];
    [m_TemplateManager setParamManager:m_ParamManager];
    [m_ParamManager setTemplateManager:m_TemplateManager];
    
    
    m_ShowViewManager = [[MyShowViewManager alloc]init];
    [m_ShowViewManager setWindow:self];
    [m_ShowViewManager setFileManager:m_FileManager];
    [m_ShowViewManager setParamManager:m_ParamManager];
    [m_TemplateManager setShowViewManager:m_ShowViewManager];
    
    m_CategoryManager = [[CategoryManager alloc] init];
    [m_CategoryManager setFileManager:m_FileManager];
    [m_CategoryManager setTemplateManager:m_TemplateManager];
    [m_CategoryManager setWindow:self];
    [m_CategoryManager setShowViewManager:m_ShowViewManager];
    [m_CategoryManager setParamManager:m_ParamManager];
}

//window
-(void)createShowView
{
    NSView* showView = [[[MyView alloc] initWithFrame:NSMakeRect(2, 2, 515, 588)]autorelease];
    CGImageRef cgImage = [m_inputImage CGImageForProposedRect:nil context:nil hints:nil];
    int nWidth = (int)CGImageGetWidth(cgImage);
    int nHeight = (int)CGImageGetHeight(cgImage);
    NSSize size = NSMakeSize(nWidth, nHeight);
    
    float width,height;
    if(size.width > size.height)
    {
        width = showView.frame.size.width;
        height = showView.frame.size.width * (size.height / size.width);
        m_showView = [[[MyView alloc] initWithFrame:NSMakeRect(0, (showView.frame.size.height - height) / 2, width, height)] autorelease];
    }else{
        height = showView.frame.size.height;
        width = showView.frame.size.height * (size.width / size.height);
        m_showView = [[[MyView alloc] initWithFrame:NSMakeRect((showView.frame.size.width - width) / 2, 0, width, height)]autorelease];
    }
    m_showView.layerUsesCoreImageFilters = YES;
    [showView addSubview:m_showView];
    [m_showView setImage:m_inputImage];
    [m_showView loadLayer];
    m_showView.layer.masksToBounds = YES;
    [self.contentView addSubview:showView];
}
//window
-(void)createLabel
{
    NSView* view = [[[NSView alloc] initWithFrame:NSMakeRect(660, 0, 340, 40)]autorelease];
    [view setWantsLayer:YES];
    view.layer.backgroundColor = LabelBackColor.CGColor;
    
    NSButton* btnApply = [[[NSButton alloc] initWithFrame:NSMakeRect(10,5,90,25)]autorelease];
    [btnApply setButtonType:NSMomentaryChangeButton];
    NSString* pathForButtonImage = [TBundle pathForResource:@"button" ofType:@"png"];
    NSString* pathForButtonOnImage = [TBundle pathForResource:@"button_on" ofType:@"png"];
    btnApply.image = [[[NSImage alloc] initWithContentsOfFile:pathForButtonImage] autorelease];
    btnApply.alternateImage = [[[NSImage alloc] initWithContentsOfFile:pathForButtonOnImage] autorelease];
    [btnApply.cell setImageScaling:NSImageScaleAxesIndependently
     ];
//    btnApply.imageScaling = NSImageScaleAxesIndependently;
    btnApply.bordered = NO;
    btnApply.action = @selector(clickBtnToAddCombination:);
    btnApply.tag = VIEWTAGFORAPPLY;
    
    NSTextField* textFieldApply = [[[NSTextField alloc] initWithFrame:NSMakeRect(10, 2.5, 70, 20)]autorelease];
    textFieldApply.stringValue = @"Add Filter";
    textFieldApply.editable = NO;
    textFieldApply.drawsBackground = NO;
    textFieldApply.bordered = NO;
    textFieldApply.alignment = NSCenterTextAlignment;
    textFieldApply.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
    [btnApply addSubview:textFieldApply];

    NSButton* btnConfirm = [[[NSButton alloc] initWithFrame:NSMakeRect(145,5,90,25)]autorelease];

    [btnConfirm setButtonType:NSMomentaryChangeButton];
    btnConfirm.image = [[[NSImage alloc] initWithContentsOfFile:pathForButtonImage] autorelease];
    btnConfirm.alternateImage = [[[NSImage alloc] initWithContentsOfFile:pathForButtonOnImage] autorelease];
//    btnConfirm.imageScaling = NSImageScaleAxesIndependently;
    [btnConfirm.cell setImageScaling:NSImageScaleAxesIndependently
     ];
    btnConfirm.bordered = NO;
    btnConfirm.action = @selector(clickBtnToComfirmEffect:);
    
    NSTextField* textFieldConfirm = [[[NSTextField alloc] initWithFrame:NSMakeRect(10, 2.5, 70, 20)]autorelease];
    textFieldConfirm.stringValue = @"Confirm";
    textFieldConfirm.editable = NO;
    textFieldConfirm.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
    textFieldConfirm.alignment = NSCenterTextAlignment;
    textFieldConfirm.drawsBackground = NO;
    textFieldConfirm.bordered = NO;
    [btnConfirm addSubview:textFieldConfirm];

    NSButton* btnCancel = [[[NSButton alloc] initWithFrame:NSMakeRect(240,5,90,25)]autorelease];
    [btnCancel setButtonType:NSMomentaryChangeButton];
    btnCancel.image = [[[NSImage alloc] initWithContentsOfFile:pathForButtonImage] autorelease];
    btnCancel.alternateImage = [[[NSImage alloc] initWithContentsOfFile:pathForButtonOnImage] autorelease];
//    btnCancel.imageScaling = NSImageScaleAxesIndependently;
    [btnCancel.cell setImageScaling:NSImageScaleAxesIndependently
     ];
    btnCancel.bordered = NO;
    btnCancel.action = @selector(cancelWindow:);
    
    NSTextField* textFieldCancel = [[[NSTextField alloc] initWithFrame:NSMakeRect(10, 2.5, 70, 20)]autorelease];
    textFieldCancel.stringValue = @"Cancel";
    textFieldCancel.editable = NO;
    textFieldCancel.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
    textFieldCancel.drawsBackground = NO;
    textFieldCancel.alignment = NSCenterTextAlignment;
    textFieldCancel.bordered = NO;
    [btnCancel addSubview:textFieldCancel];

    [view addSubview:btnApply];
    [view addSubview:btnConfirm];
    [view addSubview:btnCancel];
    [self.contentView addSubview:view];
}

-(void)setIndexOfCategory
{
    m_arrayForIndexOfCategory = [[NSMutableArray alloc] init];
    for (int i = 0; i < [m_CategoryManager getArrayForCategoryOrder].count; i++) {
        NSString* nameForCategory = [m_CategoryManager getArrayForCategoryOrder][i];
        for(int j = 0; j < GetCategoriesCount(); j++)
        {
            NSString* nameForCategory2 = GetCategoryNameInCategory(j);
            if([nameForCategory isEqualToString:nameForCategory2])
            {
                [m_arrayForIndexOfCategory addObject:@(j)];
                break;
            }
        }
    }
}

-(NSMutableArray*)getIndexArrayForCategory
{
    return m_arrayForIndexOfCategory;
}

//window
-(void)cancelWindow:(NSButton*)sender
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"closeWindow" object:nil];
}

#define VIEWTAG  1000
//window
-(void)createShowLabel
{
    m_labelView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 590, 517, 32)]autorelease];

    [m_labelView setWantsLayer:YES];
    m_labelView.layer.backgroundColor = LabelBackColor.CGColor;
    [self.contentView addSubview:m_labelView];

    NSImageView* imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(400, 0.5f, 10, 30)] autorelease];
    NSString* pathForLineImage = [TBundle pathForResource:@"line" ofType:@"png"];
    imageView.image = [[[NSImage alloc] initWithContentsOfFile:pathForLineImage] autorelease];
    [m_labelView addSubview:imageView];
    
    NSButton* btnOriginal = [[[NSButton alloc] initWithFrame:NSMakeRect(320, 6, 80, 20)]autorelease];
    btnOriginal.tag = VIEWTAG;
    btnOriginal.bezelStyle = NSTexturedSquareBezelStyle;
    btnOriginal.target = self;
    btnOriginal.action = @selector(clickBtnShowOriginalImage:);
    btnOriginal.bordered = NO;
    btnOriginal.title = @"";
    NSTextField* textFieldOriginal = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, btnOriginal.frame.size.width, btnOriginal.frame.size.height)]autorelease];
    textFieldOriginal.font = [NSFont fontWithName:@"Verdana" size:12];
    textFieldOriginal.stringValue = @"Original";
    textFieldOriginal.alignment = NSTextAlignmentRight;
    textFieldOriginal.bordered = NO;
    textFieldOriginal.drawsBackground = NO;
    textFieldOriginal.editable = NO;
    textFieldOriginal.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
    [btnOriginal addSubview:textFieldOriginal];
    [m_labelView addSubview:btnOriginal];
    
    NSButton* btnEffect = [[[NSButton alloc] initWithFrame:NSMakeRect(410, 6, 80, 20)]autorelease];
    btnEffect.tag = VIEWTAG + 1;
    btnEffect.bezelStyle = NSTexturedSquareBezelStyle;
    btnEffect.target =  self;
    btnEffect.action = @selector(clickBtnShowEffectImage:);
    btnEffect.bordered = NO;
    btnEffect.title = @"";
    NSTextField* textFieldEffect = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, btnEffect.frame.size.width, btnEffect.frame.size.height)]autorelease];
    textFieldEffect.stringValue = @"Preview";
    textFieldEffect.font = [NSFont fontWithName:@"Verdana" size:12];
    textFieldEffect.textColor = [NSColor colorWithRed:180.0/255 green:200.0/255 blue:80.0/255.0 alpha:1.0];
    textFieldEffect.alignment = NSTextAlignmentLeft;
    textFieldEffect.bordered = NO;
    textFieldEffect.drawsBackground = NO;
    textFieldEffect.editable = NO;
    [btnEffect addSubview:textFieldEffect];
    [m_labelView addSubview:btnEffect];
}
//window
-(void)clickBtnShowOriginalImage:(NSButton*)sender
{
    m_showView.layer.filters = nil;
    NSTextField* textField = sender.subviews[0];
    textField.textColor = [NSColor colorWithRed:180.0/255 green:200.0/255 blue:80.0/255.0 alpha:1.0];
    NSButton* effectBtn = [m_labelView viewWithTag:VIEWTAG + 1];
    NSTextField* textField2 = [effectBtn subviews][0];
    textField2.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
}
//window
-(void)clickBtnShowEffectImage:(NSButton*)sender
{
    NSLog(@"进入clickBtnShowEffectImage函数");
    m_showView.layer.filters = [m_ShowViewManager getSavedFilterArray];
    NSTextField* textField = sender.subviews[0];
    textField.textColor = [NSColor colorWithRed:180.0/255 green:200.0/255 blue:80.0/255.0 alpha:1.0];
    NSButton* originalBtn = [m_labelView viewWithTag:VIEWTAG];
    NSTextField* textField2 = [originalBtn subviews][0];
    textField2.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
}

//window
-(void)createTemplateLabel
{
    TemplateLabelView* view = [[[TemplateLabelView alloc] initWithFrame:NSMakeRect(520, 420, 480, 25)]autorelease];
    [view setTitle:@"Template"];
    [view setLineStartPoint:NSMakePoint(137, 2)];
    [view setLineEndPoint:NSMakePoint(137, 23)];
    [self.contentView addSubview:view];
    NSButton* btnDeleteTemplate = [[[NSButton alloc] initWithFrame:NSMakeRect(110, 2.5, 20, 20)] autorelease];
    NSString* imagePath = [TBundle pathForResource:@"delete" ofType:@"png"];
    btnDeleteTemplate.image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
    btnDeleteTemplate.bordered = NO;
    btnDeleteTemplate.target = m_TemplateManager;
    btnDeleteTemplate.action = @selector(clickBtnToMinusTemplate:);
    btnDeleteTemplate.bezelStyle = NSShadowlessSquareBezelStyle;
    btnDeleteTemplate.toolTip = @"Delete Template";
    
    NSButton* btnAddTemplate = [[[NSButton alloc] initWithFrame:NSMakeRect(80, 2.5, 20, 20)] autorelease];
    imagePath = [TBundle pathForResource:@"addTemplate" ofType:@"png"];
    btnAddTemplate.image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
    btnAddTemplate.bordered = NO;
    btnAddTemplate.target = m_TemplateManager;
    btnAddTemplate.action = @selector(clickButtonToAddTemplate:);
    btnAddTemplate.bezelStyle = NSShadowlessSquareBezelStyle;
    btnAddTemplate.toolTip = @"Add Template";
    
    NSButton* btnRefresh = [[[NSButton alloc] initWithFrame:NSMakeRect(450, 2.5, 20, 20)] autorelease];
    imagePath = [TBundle pathForResource:@"refresh" ofType:@"png"];
    btnRefresh.image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
    btnRefresh.bordered = NO;
    btnRefresh.target = m_ParamManager;
    btnRefresh.action = @selector(clickBtnToRefreshTemplateParam:);
    btnRefresh.target = m_ParamManager;
    btnRefresh.bezelStyle = NSShadowlessSquareBezelStyle;
    btnRefresh.toolTip = @" Reduction Parameters";
    
    NSButton* btnSave = [[[NSButton alloc] initWithFrame:NSMakeRect(420, 2.5, 20, 20)] autorelease];
    imagePath = [TBundle pathForResource:@"save" ofType:@"png"];
    btnSave.image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
    btnSave.bezelStyle =  NSShadowlessSquareBezelStyle;
    btnSave.bordered = NO;
    btnSave.target = m_TemplateManager;
    btnSave.action = @selector(clickBtnToReplaceTemplate:);
    btnSave.toolTip = @"Replace Template";
    
    [view addSubview:btnDeleteTemplate];
    [view addSubview:btnRefresh];
    [view addSubview:btnSave];
    [view addSubview:btnAddTemplate];
}

//window
-(void)initTabView
{
    m_tabViewToShow = [[MyTabView alloc] initWithFrame:NSMakeRect(520, 445, 480, 175) ItemCount:1 + GetCategoriesCount()];
    m_tabViewToShow.allowsTruncatedLabels = NO;
    NSTabViewItem* item = [[[NSTabViewItem alloc] init]autorelease];
    item.label = @"Combination";
    [m_tabViewToShow addTabViewItem:item];
    for(int i = 0; i < GetCategoriesCount(); i++)
    {
        NSTabViewItem* item = [[[NSTabViewItem alloc]initWithIdentifier:@"i"] autorelease];
//        item.label = GetCategoryNameInCategory(i);
        item.label = [m_CategoryManager getArrayForCategoryOrder][i];
        [m_tabViewToShow addTabViewItem:item];
    }
    [m_tabViewToShow initialSegmentControl];
    m_tabViewToShow.delegate = m_CategoryManager;

    [self.contentView addSubview:m_tabViewToShow];
    [m_tabViewToShow release];
}


//window
-(void)clickBtnToAddCombination:(NSButton*)sender
{
    [m_ShowViewManager setCurrentFiltersCount:(int)[m_ShowViewManager getSavedFilterArray].count];
    m_showView.layer.filters = [m_ShowViewManager getSavedFilterArray];
    int nIndex = (int)[m_tabViewToShow.tabViewItems indexOfObject:m_tabViewToShow.selectedTabViewItem];
    int nIndexForInCategoryOrder = ((NSNumber*)m_arrayForIndexOfCategory[nIndex - 1]).intValue;
    if(!nIndex)
    {
        return;
    }
    //如果是新添加的新建一个Combiantion,如果不是新添加的则在最后一个新添加的基础上继续添加
    if(m_gDataElementForCombination == nil)
    {
        GDataXMLDocument* doc = [m_FileManager getFilterCombinationDocument];
        NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
        GDataXMLElement* lastFilterCombination = [arrayForCombination lastObject];
        int nLastCombinationID = 0;
        if(lastFilterCombination)
        {
            NSString* intString = [[[[lastFilterCombination elementsForName:@"filterCombinationName"]lastObject] stringValue] substringFromIndex:11];
            nLastCombinationID = [intString intValue];
        }
        
        m_gDataElementForCombination = [[GDataXMLNode elementWithName:@"filterCombination"] retain];
        GDataXMLElement* combiantionName = [GDataXMLNode elementWithName:@"filterCombinationName" stringValue:[NSString stringWithFormat:@"combination%d", nLastCombinationID + 1]];
        [m_gDataElementForCombination addChild:combiantionName];
        
        m_gDataTemplateForCombination = [[GDataXMLNode elementWithName:@"Combination"]retain];
        GDataXMLElement* combinaionNameForTemplate = [GDataXMLNode elementWithName:@"filterCombinationName" stringValue:[NSString stringWithFormat:@"combination%d",nLastCombinationID + 1]];
        [m_gDataTemplateForCombination addChild:combinaionNameForTemplate];
    }
    
    GDataXMLElement* filterElement = [GDataXMLNode elementWithName:@"filter"];
    GDataXMLElement* filterElementForTemplate = [GDataXMLNode elementWithName:@"filter"];
    GDataXMLElement* filterName = [GDataXMLNode elementWithName:@"filterName" stringValue:GetFilterNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory)];
    GDataXMLElement* filterIndex = [GDataXMLNode elementWithName:@"filterIndex" stringValue:[NSString stringWithFormat:@"%d",((IMAGE_FILTER*)m_filterHandle) -> nFilterIndex]];
    GDataXMLElement* filterCategory = [GDataXMLNode elementWithName:@"filterCategory" stringValue:GetCategoryNameInCategory(nIndexForInCategoryOrder)];
    [filterElement addChild:filterName];
    [filterElement addChild:filterIndex];
    [filterElement addChild:filterCategory];
    
    int nCountForParam = GetFilterParaCountInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory);
    if(nCountForParam > 0)
    {
        GDataXMLElement* param = [GDataXMLNode elementWithName:@"param"];
        GDataXMLElement* paramForTemplate = [GDataXMLElement elementWithName:@"param"];
        for(int i = 0; i < nCountForParam; i++)
        {
            GDataXMLElement* paramOrder = [GDataXMLNode elementWithName:[NSString stringWithFormat:@"param%d",i]];
            GDataXMLElement* paramOrdreForTemplate = [GDataXMLNode elementWithName:[NSString stringWithFormat:@"param%d",i]];
            
            AENUM_VARIABLE_TYPE paramType = GetFilterParamTypeInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i);
            switch (paramType) {
                case AV_FLOAT:
                {
                    GDataXMLElement* paramTypeElement = [GDataXMLNode elementWithName:@"paramType" stringValue:@"AV_FLOAT"];
                    NSString* sParamName = [NSString stringWithFormat:@"%@ %@", filterName.stringValue,GetFilterParamNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    GDataXMLElement* paramName = [GDataXMLNode elementWithName:@"paramName" stringValue:sParamName];
                    GDataXMLElement* paramInName = [GDataXMLNode elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    GDataXMLElement* paramMin = [GDataXMLNode elementWithName:@"paramMin" stringValue:[NSString stringWithFormat:@"%.6f",GetFilterParamMinInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i).fFloatValue]];
                    GDataXMLElement* paramMax = [GDataXMLNode elementWithName:@"paramMax" stringValue:[NSString stringWithFormat:@"%.6f",GetFilterParamMaxInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i).fFloatValue]];
                    GDataXMLElement* paramDefault = [GDataXMLNode elementWithName:@"paramDefault" stringValue:[NSString stringWithFormat:@"%.6f",GetFilterParamDefaultInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i).fFloatValue]];
                    
                    NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:i * 100];
                    
                    GDataXMLElement* paramCurrent = [GDataXMLNode elementWithName:@"paramCurrent" stringValue:[NSString stringWithFormat:@"%.6f", slider.floatValue]];
                    
                    [paramOrder addChild:paramName];
                    [paramOrder addChild:paramInName];
                    [paramOrder addChild:paramMin];
                    [paramOrder addChild:paramMax];
                    [paramOrder addChild:paramDefault];
                    [paramOrder addChild:paramTypeElement];
                    
                    [paramOrdreForTemplate addChild:paramInName];
                    [paramOrdreForTemplate addChild:paramTypeElement];
                    [paramOrdreForTemplate addChild:paramCurrent];
                    break;
                }
                case AV_DWORDCOLOR:
                {
                    GDataXMLElement* paramTypeElement = [GDataXMLNode elementWithName:@"paramType" stringValue:@"AV_DWORDCOLOR"];
                    NSString* sParamName = [NSString stringWithFormat:@"%@ %@", filterName.stringValue,GetFilterParamNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    GDataXMLElement* paramName = [GDataXMLNode elementWithName:@"paramName" stringValue:sParamName];
                    GDataXMLElement* paramInName = [GDataXMLNode elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    [paramOrder addChild:paramName];
                    [paramOrder addChild:paramInName];
                    [paramOrder addChild:paramTypeElement];
                    
                    NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag: i * 100 ];
                    CGFloat r,g,b;
                    [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                    GDataXMLElement* elementNewColorR = [GDataXMLNode elementWithName:@"paramColorR" stringValue:[NSString stringWithFormat:@"%.2f",r]];
                    GDataXMLElement* elementNewColorG = [GDataXMLNode elementWithName:@"paramColorG" stringValue:[NSString stringWithFormat:@"%.2f",g]];
                    GDataXMLElement* elementNewColorB = [GDataXMLNode elementWithName:@"paramColorB" stringValue:[NSString stringWithFormat:@"%.2f",b]];
                    [paramOrdreForTemplate addChild:paramInName];
                    [paramOrdreForTemplate addChild:paramTypeElement];
                    [paramOrdreForTemplate addChild:elementNewColorR];
                    [paramOrdreForTemplate addChild:elementNewColorG];
                    [paramOrdreForTemplate addChild:elementNewColorB];
                    break;
                }
                case AV_DWORDCOLORRGB:
                {
                    GDataXMLElement* paramTypeElement = [GDataXMLNode elementWithName:@"paramType" stringValue:@"AV_DWORDCOLORRGB"];
                    NSString* sParamName = [NSString stringWithFormat:@"%@ %@", filterName.stringValue,GetFilterParamNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    GDataXMLElement* paramName = [GDataXMLNode elementWithName:@"paramName" stringValue:sParamName];
                    GDataXMLElement* paramInName = [GDataXMLNode elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    [paramOrder addChild:paramName];
                    [paramOrder addChild:paramInName];
                    [paramOrder addChild:paramTypeElement];
                    NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag: i * 100 ];
                    CGFloat r,g,b;
                    [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                    GDataXMLElement* elementNewColorR = [GDataXMLNode elementWithName:@"paramColorR" stringValue:[NSString stringWithFormat:@"%.2f",r]];
                    GDataXMLElement* elementNewColorG = [GDataXMLNode elementWithName:@"paramColorG" stringValue:[NSString stringWithFormat:@"%.2f",g]];
                    GDataXMLElement* elementNewColorB = [GDataXMLNode elementWithName:@"paramColorB" stringValue:[NSString stringWithFormat:@"%.2f",b]];
                    [paramOrdreForTemplate addChild:paramInName];
                    [paramOrdreForTemplate addChild:paramTypeElement];
                    [paramOrdreForTemplate addChild:elementNewColorR];
                    [paramOrdreForTemplate addChild:elementNewColorG];
                    [paramOrdreForTemplate addChild:elementNewColorB];
                    
                    break;
                }
                case AV_CENTEROFFSET:
                {
                    GDataXMLElement* paramTypeElement = [GDataXMLNode elementWithName:@"paramType" stringValue:@"AV_CENTEROFFSET"];
                    NSString* sParamName = [NSString stringWithFormat:@"%@ %@", filterName.stringValue,GetFilterParamNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    GDataXMLElement* paramName = [GDataXMLNode elementWithName:@"paramName" stringValue:sParamName];
                    GDataXMLElement* paramInName = [GDataXMLNode elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexForInCategoryOrder, m_nIndexOfSelectedFilterInCategory, i)];
                    [paramOrder addChild:paramName];
                    [paramOrder addChild:paramInName];
                    [paramOrder addChild:paramTypeElement];
                    
                    NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:i * 100 ];
                    NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:i * 100 + 10];
                    
                    [paramOrdreForTemplate addChild:paramInName];
                    [paramOrdreForTemplate addChild:paramTypeElement];
                    GDataXMLElement* elementForX = [GDataXMLNode elementWithName:@"ParamForX" stringValue:[NSString stringWithFormat:@"%.6f", sliderX.floatValue]];
                    GDataXMLElement* elementForY = [GDataXMLNode elementWithName:@"ParamForY" stringValue:[NSString stringWithFormat:@"%.6f", sliderY.floatValue]];
                    [paramOrdreForTemplate addChild:elementForX];
                    [paramOrdreForTemplate addChild:elementForY];
                    break;
                }
                default:
                    break;
            }
            [param addChild:paramOrder];
            [paramForTemplate addChild:paramOrdreForTemplate];
        }
        [filterElement addChild:param];
        [filterElementForTemplate addChild:paramForTemplate];
    }
    [m_gDataElementForCombination addChild:filterElement];
    [m_gDataTemplateForCombination addChild:filterElementForTemplate];
}

//window
-(void)clickBtnToComfirmEffect:(NSButton*)sender
{
    int nIndexOfCategory = (int)[m_tabViewToShow.tabViewItems indexOfObject:m_tabViewToShow.selectedTabViewItem];
    NSImage* ImageEffect = [self getOutputImage:nIndexOfCategory];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"confirm" object:ImageEffect];
}
//window
-(void)modifyParamValueWithScale:(float)scale width:(float)fWidth height:(float)fHeight
{
    int nIndexOfCategory = (int)[m_tabViewToShow.tabViewItems indexOfObject:m_tabViewToShow.selectedTabViewItem];
    if(!nIndexOfCategory)
    {
        for (int i = 0; i < vectorForHandle.size(); i++)
        {
            int nCount = GetFilterParaCount(((IMAGE_FILTER*)vectorForHandle[i])->nFilterIndex);
            for(int j = 0; j < nCount; j++)
            {
                AUNI_VARIABLE aValue = GetImageFilterParm(vectorForHandle[i], j);
                if(aValue.mod == 1 && aValue.nType == AV_FLOAT)
                {
                    NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:(i * 1000 + j * 100)];
                    AVARIABLE_VALUE inputValue;
                    inputValue.fFloatValue = slider.floatValue;
                    ModifyImageFilterParmWithWidthAndHeight(vectorForHandle[i], j, inputValue, fWidth, fHeight);
                }
                if(aValue.mod == 1 && aValue.nType == AV_CENTEROFFSET)
                {
                    NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100 ];
                    NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100 + 10];
                    AVARIABLE_VALUE inputValue;
                    inputValue.fOffsetXY[0] = sliderX.floatValue;
                    inputValue.fOffsetXY[1] = sliderY.floatValue;
                    ModifyImageFilterParmWithWidthAndHeight(vectorForHandle[i], j, inputValue, fWidth, fHeight);
                }
                if(aValue.mod == 3 && aValue.nType == AV_FLOAT)
                {
                    NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:(i*1000 + j * 100)];
                    AVARIABLE_VALUE inputValue;
                    inputValue.fFloatValue = slider.floatValue * scale;
                    ModifyImageFilterParmWithWidthAndHeight(vectorForHandle[i], j, inputValue, fWidth, fHeight);
                }
            }
        }
    }
    else{
        int nCount = GetFilterParaCount(((IMAGE_FILTER*)m_filterHandle)->nFilterIndex);
        for(int i = 0; i < nCount; i++)
        {
            AUNI_VARIABLE aValue = GetImageFilterParm(m_filterHandle, i);
            if(aValue.mod == 1 && aValue.nType == AV_FLOAT)
            {
                NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:(i*100)];
                AVARIABLE_VALUE inputValue;
                inputValue.fFloatValue = slider.floatValue;
                ModifyImageFilterParmWithWidthAndHeight(m_filterHandle, i, inputValue, fWidth, fHeight);
            }
            if(aValue.mod == 1 && aValue.nType == AV_CENTEROFFSET)
            {
                NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:i * 100];
                NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:i * 100 + 10];
                AVARIABLE_VALUE inputValue;
                inputValue.fOffsetXY[0] = sliderX.floatValue;
                inputValue.fOffsetXY[1] = sliderY.floatValue;
                ModifyImageFilterParmWithWidthAndHeight(m_filterHandle, i, inputValue, fWidth, fHeight);
            }
            if(aValue.mod == 3 && aValue.nType == AV_FLOAT)
            {
                NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:(i*100)];
                AVARIABLE_VALUE inputValue;
                inputValue.fFloatValue = slider.floatValue * scale;
                ModifyImageFilterParmWithWidthAndHeight(m_filterHandle, i, inputValue, fWidth, fHeight);
            }
        }
    }
}


//window
-(NSImage*)getOutputImage:(int)indexOfCategory
{
    CGImageRef cgInputImage = [m_inputImage CGImageForProposedRect:nil context:nil hints:nil];
    float nWidth = (float)CGImageGetWidth(cgInputImage);
    float nHeight = (float)CGImageGetHeight(cgInputImage);
    float scale = nWidth / m_showView.frame.size.width;
    
    [self modifyParamValueWithScale:scale width:nWidth height:nHeight];
    
    CIImage* inputImage = [self getInputCIImage];
    CIImage* outputImage = nil;
    IMAGE_FILTER_HANDLE handle = NULL;
    if(!indexOfCategory)
    {
//        for (int i = 0; i < vectorForHandle.size(); i++) {
//            CIFilter* filter = ((IMAGE_FILTER*)vectorForHandle[i])->filter;
//            if(i == 0)
//                [filter setValue:inputImage forKey:kCIInputImageKey];
//            else
//                [filter setValue:outputImage forKey:kCIInputImageKey];
//            outputImage = [filter valueForKey:kCIOutputImageKey];
//        }
        GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
        NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
        GDataXMLElement* combination =  arrayForCombination[m_nIndexOfSelectedFilterInCategory];
        NSArray* arrayForFilter = [combination elementsForName:@"filter"];
        for(int i = 0; i < arrayForFilter.count; i++)
        {
            int nIndexOfFilter = [[[[arrayForFilter[i] elementsForName:@"filterIndex"]lastObject] stringValue] intValue];
            if(i == 0)
            {
                handle = CreateFilterForImage([self getInputCIImage], nIndexOfFilter);
                [self modifyParamValue:handle filterOrder:i];
                outputImage = GetOutImage(handle);
            }
            else
            {
                DestroyImageFilter(handle);
                handle = CreateFilterForImage(outputImage, nIndexOfFilter);
                [self modifyParamValue:handle filterOrder:i];
                outputImage = GetOutImage(handle);
            }
        }
    }
    else{
        outputImage = GetOutImage(m_filterHandle);
    }
    CGImageRef cgImage = [ctx createCGImage:outputImage fromRect:inputImage.extent];
    if(handle)
    {
        DestroyImageFilter(handle);
        handle = NULL;
    }
    NSImage* nsOutputImage = [[[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize] autorelease];
    return nsOutputImage;
}

-(void)modifyParamValue:(IMAGE_FILTER_HANDLE)handle filterOrder:(int)i
{
    IMAGE_FILTER* h_Handle = (IMAGE_FILTER*)handle;
    
    CGImageRef cgInputImage = [m_inputImage CGImageForProposedRect:nil context:nil hints:nil];
    float fWidth = (float)CGImageGetWidth(cgInputImage);
    float fHeight = (float)CGImageGetHeight(cgInputImage);
    float scale = fWidth / m_showView.frame.size.width;
    
    int nCount = GetFilterParaCount(h_Handle->nFilterIndex);
    for(int j = 0; j < nCount; j++)
    {
        AUNI_VARIABLE aValue = GetImageFilterParm(h_Handle, j);
        switch (aValue.nType) {
            case AV_FLOAT:
            {
                NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:(i * 1000 + j * 100)];
                AVARIABLE_VALUE inputValue;
                inputValue.fFloatValue = slider.floatValue;
                if (aValue.mod == 1) {
                    ModifyImageFilterParmWithWidthAndHeight(h_Handle, j, inputValue, fWidth, fHeight);
                }else if (aValue.mod == 3)
                {
                    inputValue.fFloatValue = slider.floatValue * scale;
                    ModifyImageFilterParmWithWidthAndHeight(vectorForHandle[i], j, inputValue, fWidth, fHeight);
                }
                else
                    ModifyImageFilterParm(handle, j, inputValue);
            }
                break;
            case AV_CENTEROFFSET:
            {
                NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100 ];
                NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100 + 10];
                AVARIABLE_VALUE inputValue;
                inputValue.fOffsetXY[0] = sliderX.floatValue;
                inputValue.fOffsetXY[1] = sliderY.floatValue;
                if (aValue.nValueNormalizationEnable == 0) {
                    ModifyImageFilterParmWithWidthAndHeight(h_Handle, j, inputValue, fWidth, fHeight);
                }else
                    ModifyImageFilterParm(handle, j, inputValue);
            }
                break;
            case AV_DWORDCOLORRGB:
            case AV_DWORDCOLOR:
            {
                NSColorWell* well = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100 ];
                CGFloat r = well.color.redComponent;
                CGFloat g = well.color.greenComponent;
                CGFloat b = well.color.blueComponent;
                CGFloat alpha = well.color.alphaComponent;
                unsigned int nR,nG,nB,nA;
                nR = r * 255;
                nG = g * 255;
                nB = b * 255;
                nA = alpha * 255;
                unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + nA;
                AVARIABLE_VALUE inputValue;
                inputValue.nUnsignedValue = nColor;
                ModifyImageFilterParm(handle, j, inputValue);
            }
                break;
            default:
                break;
        }
    }
}

//window
-(void)setInputImage:(NSImage*)image
{
    m_inputImage = image;
}

//window
-(void)enableBtn
{
    NSButton* applyBtn = [self.contentView viewWithTag:VIEWTAGFORAPPLY];
    
    if(![m_tabViewToShow.tabViewItems indexOfObject:m_tabViewToShow.selectedTabViewItem])
    {
        applyBtn.enabled = NO;
    }else{
        applyBtn.enabled = YES;
    }
}

-(CIImage*)getInputCIImage
{
    NSData* data = [m_inputImage TIFFRepresentation];
    CIImage* inputImage = [CIImage imageWithData:data];
    return inputImage;
}

-(void)dealloc
{
    for (int i = (int)self.contentView.subviews.count - 1; i < 0; i--) {
        NSView* view = [self.contentView.subviews objectAtIndex:i];
        [view removeFromSuperview];
        view = nil;
    }
    
    [m_ParamManager release];
    [m_ShowViewManager release];
    [m_FileManager release];
    [m_CategoryManager release];
    [m_TemplateManager release];
    
    if(m_filterHandle)
    {
        DestroyImageFilter(m_filterHandle);
        m_filterHandle = nil;
    }
    if(m_gDataElementForCombination)
    {
        [m_gDataElementForCombination release];
        m_gDataElementForCombination = nil;
    }
    if(m_gDataTemplateForCombination)
    {
        [m_gDataTemplateForCombination release];
        m_gDataTemplateForCombination = nil;
    }
    if (vectorForHandle.size()) {
        long nCount = vectorForHandle.size();
        for (int i = 0; i < nCount; i++) {
            DestroyImageFilter(vectorForHandle.at(0));
            vectorForHandle.erase(vectorForHandle.begin());
        }
    }

    if(ctx)
    {
        [ctx release];
        ctx = nil;
    }
    
    [super dealloc];
}
@end

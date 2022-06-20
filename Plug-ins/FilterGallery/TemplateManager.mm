//
//  TemplateManager.m
//  FilterGallery
//
//  Created by Calvin on 4/5/17.
//  Copyright © 2017 EffectMatrix. All rights reserved.

#import "TemplateManager.h"
@implementation TemplateManager

-(float)getHeightOfTemplate
{
    return m_heightCurrentTemplate;
}

-(void)setHeightOfTemplate:(float)height
{
    m_heightCurrentTemplate = height;
}

-(void)setIndexOfTemplate:(int)index
{
    m_nIndexOfBtnForTemplate = index;
}

-(int)getIndexOfTemplate
{
    return m_nIndexOfBtnForTemplate;
}

-(void)setShowViewManager:(MyShowViewManager*)manager
{
    m_ShowViewManager = manager;
}

-(void)setParamManager:(MyParamManager*)manager
{
    m_ParamManager = manager;
}

-(void)setFileManager:(FileManager*)manager
{
    m_FileManager = manager;
}

-(void)setWindow:(MyWindow*)window
{
    m_Window = window;
}

//template
-(void)showFirstTemplateEffect
{
    NSLog(@"进入showFirstTemplateEffect函数");
    //    如果此滤镜有至少一个模板那么选择第一个模板的效果
    int nCount = [self getFilterCountAtIndex:[m_Window getFilterIndex]];
    if(nCount > 0)
    {
        [self chooseFilterTemplateAt:0];
    }
    NSLog(@"出showFirstTemplateEffect函数");
}

//template
-(int)getFilterCountAtIndex:(int)index
{
    int nIndexOfCategory = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    GDataXMLElement* rootElement = [m_FileManager getTemplateArray][nIndexOfCategory];
    int numberForTemplate = 0;
    if(!nIndexOfCategory)
    {
        GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
        //rootElement为组合滤镜模板文件的root,rootElement2为组合滤镜文件的root
        GDataXMLElement* rootElement2 = doc.rootElement;
        GDataXMLElement* elementForCombination = [[rootElement2 elementsForName:@"filterCombination"] objectAtIndex:index];
        NSString* nameForCombination = [[[elementForCombination elementsForName:@"filterCombinationName"]lastObject] stringValue];
        NSArray* arrayForCombination = [rootElement elementsForName:@"Combination"];
        for(int i = 0; i < arrayForCombination.count; i++)
        {
            NSString* stringForCombinationName = [[[arrayForCombination[i] elementsForName:@"filterCombinationName"] lastObject] stringValue];
            if([stringForCombinationName isEqualToString:nameForCombination])
                numberForTemplate++;
        }
    }
    else{
        NSArray* arrayForSingleFilterTemplate = [rootElement elementsForName:@"filter"];
        for(int i = 0; i < arrayForSingleFilterTemplate.count; i++)
        {
            NSString* stringForFilterInName = [[[arrayForSingleFilterTemplate[i] elementsForName:@"filterName"]lastObject]stringValue];
            NSString* stringForFilterInName2 = GetFilterNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue, [m_Window getFilterIndex]);
            if([stringForFilterInName isEqualToString:stringForFilterInName2])
                numberForTemplate++;
        }
    }
    return numberForTemplate;
}
//template
-(void)showFilterTemplate
{
    NSLog(@"进入showFilterTemplate函数");
    float fScaleFactor = [NSScreen mainScreen].backingScaleFactor;
    float scale = [m_Window getShowView].bounds.size.height / [m_Window getShowView].bounds.size.width;
    float interval = 15, width = 110;
    NSImage* resizedImage = [m_FileManager resizeImage:[m_Window getInputImage] toRect:NSMakeRect(0, 0, width, width * scale)];
    CIImage* inputImage = [CIImage imageWithCGImage:[resizedImage CGImageForProposedRect:nil context:nil hints:nil]];
    CIImage* generatedImage = NULL;
    if(m_scrollViewForTemplate)
    {
        [m_scrollViewForTemplate removeFromSuperview];
        m_scrollViewForTemplate = nil;
    }
    m_scrollViewForTemplate = [[NSScrollView alloc] initWithFrame:NSMakeRect(520, 0, 135, 420)];
    m_scrollViewForTemplate.backgroundColor = LabelBackColor;
    MyVerticalScroller* scroller = [[MyVerticalScroller alloc] init];
    m_scrollViewForTemplate.verticalScroller = scroller;
    [m_Window.contentView addSubview:m_scrollViewForTemplate];
    NSView* docView = [[[NSView alloc] init]autorelease];
    m_scrollViewForTemplate.documentView = docView;
    m_scrollViewForTemplate.hasVerticalScroller = YES;
    [m_scrollViewForTemplate release];
    
    int nCount = [self getFilterCountAtIndex:[m_Window getFilterIndex]];
    int heightOfDocView = nCount * (width * scale + interval) + 17.5;
    if(heightOfDocView < m_scrollViewForTemplate.contentSize.height)
        docView.frame = NSMakeRect(0, 0, width + 10, m_scrollViewForTemplate.contentSize.height);
    else
        docView.frame = NSMakeRect(0, 0, width + 10, heightOfDocView);
    int originX = 10,originY = docView.frame.size.height - width * scale - 5;
    int nIndexOfCategory = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    GDataXMLElement* rootElement = [m_FileManager getTemplateArray][nIndexOfCategory];
    
    int numberForTemplateOrder = 0;
    AVARIABLE_VALUE paramValue;
    IMAGE_FILTER_HANDLE handle = NULL;
    if(!nIndexOfCategory)
    {
        GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
        //rootElement为组合滤镜模板文件的root,rootElement2为组合滤镜文件的root
        GDataXMLElement* rootElement2 = doc.rootElement;
        GDataXMLElement* elementForCombination = [[rootElement2 elementsForName:@"filterCombination"] objectAtIndex:[m_Window getFilterIndex]];
        NSString* nameForCombination = [[[elementForCombination elementsForName:@"filterCombinationName"]lastObject] stringValue];
        NSArray* arrayForCombination = [rootElement elementsForName:@"Combination"];
        for(int i = 0; i < arrayForCombination.count; i++)
        {
            NSString* stringForCombinationName = [[[arrayForCombination[i] elementsForName:@"filterCombinationName"] lastObject] stringValue];
            if([stringForCombinationName isEqualToString:nameForCombination])
            {
                TemplateButton* btn = [[[TemplateButton alloc] initWithFrame:NSMakeRect(originX, originY, width, width * scale)]autorelease];
                btn.bezelStyle = NSShadowlessSquareBezelStyle;
                btn.tag = numberForTemplateOrder;
                btn.target = self;
                btn.action = @selector(clickBtnForFilterTemplate:);
                [docView addSubview:btn];
                originY -= width  * scale + interval;
                numberForTemplateOrder++;
                
                NSArray* arrayForCombinationCreate = [doc.rootElement elementsForName:@"filterCombination"];
                GDataXMLElement* combination =  arrayForCombinationCreate[[m_Window getFilterIndex]];
                NSArray* arrayForFilters = [combination elementsForName:@"filter"];
                
                for(int j = 0; j < arrayForFilters.count; j++)
                {
                    if(handle)
                        DestroyImageFilter(handle);
                    int nIndexOfFilter = [[[[arrayForFilters[j] elementsForName:@"filterIndex"]lastObject] stringValue] intValue];
                    if(!j)
                    {
                        handle = CreateFilterForImage(inputImage, nIndexOfFilter);
                    }else{
                        handle = CreateFilterForImage(generatedImage, nIndexOfFilter);
                    }
                    NSArray* arrayForFilter = [arrayForCombination[i] elementsForName:@"filter"];
                    
                    NSArray* arrayForParam = [arrayForFilter[j] elementsForName:@"param"];
                    GDataXMLElement* paramElement = [arrayForParam lastObject];
                    if(!paramElement)
                    {
                        generatedImage = GetOutImage(handle);
                        continue;
                    }
                    
                    for(int k = 0; k < (paramElement.childCount ); k++)
                    {
                        NSString* stringForParamOrder = [NSString stringWithFormat:@"param%d",k];
                        NSArray* arrayForParamOrder = [paramElement elementsForName:stringForParamOrder];
                        NSXMLElement* paramOrder = [arrayForParamOrder lastObject];
                        NSString* stringForParamType = [[[paramOrder elementsForName:@"paramType"] lastObject] stringValue];
                        if([stringForParamType isEqualToString:@"AV_FLOAT"])
                        {
                            paramValue.fFloatValue = [[[[paramOrder elementsForName:@"paramCurrent"] lastObject] stringValue] floatValue];
                            AUNI_VARIABLE param = GetImageFilterParm(handle, k);
                            if(param.mod == 3)
                            {
                                paramValue.fFloatValue /= ([m_Window getShowView].bounds.size.width) / btn.frame.size.width;
                                paramValue.fFloatValue *= fScaleFactor;
                            }
//                            只能以原图的大小处理
//                            ModifyImageFilterParm(handle, k, paramValue);
                            ModifyImageFilterParmWithWidthAndHeight(handle, k, paramValue, width * fScaleFactor, width * scale * fScaleFactor);
                        }
                        
                        if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                        {
                            paramValue.fOffsetXY[0] = [[[[paramOrder elementsForName:@"ParamForX"] lastObject] stringValue] floatValue];
                            paramValue.fOffsetXY[1] = [[[[paramOrder elementsForName:@"ParamForY"] lastObject] stringValue] floatValue];
//                            ModifyImageFilterParm(handle, k, paramValue);
                            ModifyImageFilterParmWithWidthAndHeight(handle, k, paramValue, width * fScaleFactor, width * scale * fScaleFactor);
                        }
                        if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                        {
                            float r,g,b;
                            r = [[[[paramOrder elementsForName:@"paramColorR"] lastObject] stringValue] floatValue];
                            g = [[[[paramOrder elementsForName:@"paramColorG"] lastObject] stringValue] floatValue];
                            b = [[[[paramOrder elementsForName:@"paramColorB"] lastObject] stringValue] floatValue];
                            unsigned int nR,nG,nB;
                            nR = r * 255;
                            nG = g * 255;
                            nB = b * 255;
                            unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + 255;
                            paramValue.nUnsignedValue = nColor;
//                            ModifyImageFilterParm(handle, k, paramValue);
                            ModifyImageFilterParmWithWidthAndHeight(handle, k, paramValue, width * fScaleFactor, width * scale * fScaleFactor);
                        }
                    }
                    generatedImage = GetOutImage(handle);
                }
                CGImageRef cgOutputImage = [[m_Window getContext] createCGImage:generatedImage fromRect:inputImage.extent];
                NSImage* outputImage = [[NSImage alloc]initWithCGImage:cgOutputImage size:NSZeroSize];
                [btn setFaceImage:outputImage];
            }
        }
    }else{
        int nIndexOfInCategoryOrder = ((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue;
        NSArray* arrayForSingleFilterTemplate = [rootElement elementsForName:@"filter"];
        for(int i = 0; i < arrayForSingleFilterTemplate.count; i++)
        {
            NSString* stringForFilterInName = [[[arrayForSingleFilterTemplate[i] elementsForName:@"filterName"]lastObject]stringValue];
            NSString* stringForFilterInName2 = GetFilterNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex]);
            if([stringForFilterInName isEqualToString:stringForFilterInName2])
            {
                TemplateButton* btn = [[[TemplateButton alloc] initWithFrame:NSMakeRect(originX, originY, width, width  * scale)]autorelease];
                btn.bezelStyle = NSShadowlessSquareBezelStyle;
                btn.wantsLayer = YES;
                handle = CreateFilterForImageInCategory(inputImage, nIndexOfInCategoryOrder, [m_Window getFilterIndex]);
                GDataXMLElement* paramElement = (GDataXMLElement*)[[arrayForSingleFilterTemplate[i] elementsForName:@"param"]lastObject];
                for (int j = 0; j < paramElement.childCount; j++) {
                    NSString* stringForParamOrder = [NSString stringWithFormat:@"param%d",j];
                    GDataXMLElement* paramOrder = (GDataXMLElement*)[[paramElement elementsForName:stringForParamOrder]lastObject];
                    NSString* stringForParamType = [[[paramOrder elementsForName:@"paramType"] lastObject] stringValue];
                    if([stringForParamType isEqualToString:@"AV_FLOAT"])
                    {
                        paramValue.fFloatValue = [[[[paramOrder elementsForName:@"paramCurrent"] lastObject] stringValue]floatValue];
                        AUNI_VARIABLE param = GetImageFilterParm(handle, j);
                        if(param.mod == 3)
                        {
                            paramValue.fFloatValue /= ([m_Window getShowView].bounds.size.width) / btn.frame.size.width;
                            paramValue.fFloatValue *= fScaleFactor;
                        }
                        ModifyImageFilterParm(handle, j, paramValue);
                        continue;
                    }
                    if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                    {
                        paramValue.fOffsetXY[0] = [[[[paramOrder elementsForName:@"ParamForX"] lastObject] stringValue] floatValue];
                        paramValue.fOffsetXY[1] = [[[[paramOrder elementsForName:@"ParamForY"] lastObject] stringValue] floatValue];
                        ModifyImageFilterParm(handle, j, paramValue);
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
                        ModifyImageFilterParm(handle, j, paramValue);
                        continue;
                    }
                }
                
                btn.tag = numberForTemplateOrder;
                btn.target = self;
                btn.action = @selector(clickBtnForFilterTemplate:);
                

                CIImage* outputImage = GetOutImage(handle);
                CGImageRef outputCGImage = [[m_Window getContext] createCGImage:outputImage fromRect:inputImage.extent];
                NSImage* btnimage = [[[NSImage alloc] initWithCGImage:outputCGImage size:NSZeroSize] autorelease];
                [btn setFaceImage:btnimage];
                [docView addSubview:btn];
                originY -= width * scale + interval;
                numberForTemplateOrder++;
            }
        }
    }
    [m_scrollViewForTemplate.documentView scrollPoint:NSMakePoint(0, m_heightCurrentTemplate)];
    if(handle)
        DestroyImageFilter(handle);
    NSLog(@"出showFilterTemplate函数");
}

-(void)dealloc
{
    if(m_scrollViewForTemplate)
    {
        [m_scrollViewForTemplate removeFromSuperview];
        m_scrollViewForTemplate = nil;
    }
    [super dealloc];
}

//template
-(void)reselectTemplate
{
    TemplateButton* btn = [m_scrollViewForTemplate viewWithTag:m_nIndexOfBtnForTemplate];
    btn.layer.borderColor = [NSColor colorWithWhite:0.5 alpha:1.0].CGColor;
    btn.layer.borderWidth = 3.0;
}
//template
-(void)chooseFilterTemplateAt:(int)index
{
    m_nIndexOfBtnForTemplate = index;
    NSArray* arrayForBtns = [m_scrollViewForTemplate.documentView subviews];
    for (NSButton* btn in arrayForBtns) {
        btn.layer.borderColor = nil;
        btn.layer.borderWidth = 0.0;
    }
    NSButton* selectedBtn = [m_scrollViewForTemplate.documentView viewWithTag:index];
    selectedBtn.layer.borderColor = [NSColor colorWithWhite:0.5 alpha:1.0].CGColor;
    selectedBtn.layer.borderWidth = 3.0;
    
    NSLog(@"选中index = %d的模板",index);
    
    int nIndexOfCategory = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    GDataXMLElement* rootElement = [m_FileManager getTemplateArray][nIndexOfCategory];
    
    int nOrder = 0;
    AVARIABLE_VALUE paramValue;
    if(!nIndexOfCategory)
    {
        NSArray* arrayForCombinationTemplate = [rootElement elementsForName:@"Combination"];
        GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
        //rootElement为组合滤镜模板文件的root,rootElement2为组合滤镜文件的root
        GDataXMLElement* rootElement2 = doc.rootElement;
        GDataXMLElement* elementForCombination = [[rootElement2 elementsForName:@"filterCombination"] objectAtIndex:[m_Window getFilterIndex]];
        NSString* nameForCombination = [[[elementForCombination elementsForName:@"filterCombinationName"]lastObject] stringValue];
        for(int i = 0; i < arrayForCombinationTemplate.count; i++)
        {
            NSString* stringForFilterInName = [[[arrayForCombinationTemplate[i] elementsForName:@"filterCombinationName"] lastObject]stringValue];
            if([stringForFilterInName isEqualToString:nameForCombination])
            {
                if(nOrder == index)
                {
                    NSArray* arrayForFilter = [arrayForCombinationTemplate[i] elementsForName:@"filter"];
                    for(int j = 0; j < arrayForFilter.count; j++)
                    {
                        NSArray* arrayForParam = [arrayForFilter[j] elementsForName:@"param"];
                        GDataXMLElement* paramElement = [arrayForParam lastObject];
                        if(!paramElement)
                            continue;
                        for(int k = 0; k < paramElement.childCount; k++)
                        {
                            NSString* stringForParamOrder = [NSString stringWithFormat:@"param%d",k];
                            NSArray* arrayForParamOrder = [paramElement elementsForName:stringForParamOrder];
                            NSXMLElement* paramOrder = [arrayForParamOrder lastObject];
                            NSString* stringForParamType = [[[paramOrder elementsForName:@"paramType"] lastObject] stringValue];
                            if([stringForParamType isEqualToString:@"AV_FLOAT"])
                            {
                                NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k];
                                slider.floatValue = [[[[paramOrder elementsForName:@"paramCurrent"] lastObject] stringValue] floatValue];
                                paramValue.fFloatValue = slider.floatValue;
                                NSTextField* label = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k + 1];
                                label.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                                ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][j], k, paramValue);
                            }
                            if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                            {
                                NSSlider* sliderForX = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k];
                                NSSlider* sliderForY = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k + 10];
                                NSTextField* labelForX = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k + 1];
                                NSTextField* labelForY = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k + 10 + 1];
                                
                                sliderForX.floatValue = [[[[paramOrder elementsForName:@"ParamForX"] lastObject] stringValue] floatValue];
                                sliderForY.floatValue = [[[[paramOrder elementsForName:@"ParamForY"] lastObject] stringValue] floatValue];
                                labelForX.stringValue = [NSString stringWithFormat:@"%.2f",sliderForX.floatValue];
                                labelForY.stringValue = [NSString stringWithFormat:@"%.2f",sliderForY.floatValue];
                                paramValue.fOffsetXY[0] = sliderForX.floatValue;
                                paramValue.fOffsetXY[1] = sliderForY.floatValue;
                                ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][j], k, paramValue);
                            }
                            if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                            {
                                NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:j * 1000 + 100 * k];
                                float r,g,b;
                                r = [[[[paramOrder elementsForName:@"paramColorR"] lastObject] stringValue] floatValue];
                                g = [[[[paramOrder elementsForName:@"paramColorG"] lastObject] stringValue] floatValue];
                                b = [[[[paramOrder elementsForName:@"paramColorB"] lastObject] stringValue] floatValue];
                                colorWell.color = [NSColor colorWithRed:r green:g blue:b alpha:1];
                                unsigned int nR,nG,nB;
                                nR = r * 255;
                                nG = g * 255;
                                nB = b * 255;
                                unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + 255;
                                paramValue.nUnsignedValue = nColor;
                                ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][j], k, paramValue);
                            }
                            
                        }
                    }
                }
                nOrder++;
            }
        }
    }else{
        NSArray* arrayForSingleFilterTemplate = [rootElement elementsForName:@"filter"];
        for(int i = 0; i < arrayForSingleFilterTemplate.count; i++)
        {
            NSString* stringForFilterInName = [[[arrayForSingleFilterTemplate[i] elementsForName:@"filterName"]lastObject]stringValue];
            NSString* stringForFilterInName2 = GetFilterNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue, [m_Window getFilterIndex]);
            if([stringForFilterInName isEqualToString:stringForFilterInName2])
            {
                if(nOrder == index)
                {
                    NSLog(@"标记");
                    GDataXMLElement* paramElement = (GDataXMLElement*)[[arrayForSingleFilterTemplate[i] elementsForName:@"param"]lastObject];
                    for (int j = 0; j < paramElement.childCount; j++) {
                        NSString* stringForParamOrder = [NSString stringWithFormat:@"param%d",j];
                        GDataXMLElement* paramOrder = (GDataXMLElement*)[[paramElement elementsForName:stringForParamOrder]lastObject];
                        NSString* stringForParamType = [[[paramOrder elementsForName:@"paramType"] lastObject] stringValue];
                        if([stringForParamType isEqualToString:@"AV_FLOAT"])
                        {
                            NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:j * 100];
                            slider.floatValue = [[[[paramOrder elementsForName:@"paramCurrent"] lastObject] stringValue]floatValue];
                            paramValue.fFloatValue = slider.floatValue;
                            NSTextField* label = [[m_ParamManager getContainView] viewWithTag:j * 100 + 1];
                            label.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                            NSLog(@"标记1");
                            ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], j, paramValue);
                            NSLog(@"标记1end");
                            continue;
                        }
                        if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                        {
                            NSSlider* sliderForX = [[m_ParamManager getContainView] viewWithTag:j * 100];
                            NSTextField* labelForX = [[m_ParamManager getContainView] viewWithTag:j * 100 + 1];
                            NSSlider* sliderForY = [[m_ParamManager getContainView] viewWithTag:j * 100 + 10];
                            NSTextField* labelForY = [[m_ParamManager getContainView] viewWithTag:j * 100 + 10 + 1];
                            sliderForX.floatValue = [[[[paramOrder elementsForName:@"ParamForX"] lastObject] stringValue]floatValue];
                            sliderForY.floatValue = [[[[paramOrder elementsForName:@"ParamForY"] lastObject] stringValue]floatValue];
                            labelForX.stringValue = [NSString stringWithFormat:@"%.2f",sliderForX.floatValue];
                            labelForY.stringValue = [NSString stringWithFormat:@"%.2f",sliderForY.floatValue];
                            paramValue.fOffsetXY[0] = sliderForX.floatValue;
                            paramValue.fOffsetXY[1] = sliderForY.floatValue;
                            NSLog(@"标记2");
                            ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], j, paramValue);
                            NSLog(@"标记2end");
                            continue;
                        }
                        if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                        {
                            NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:j * 100];
                            float r,g,b;
                            r = [[[[paramOrder elementsForName:@"paramColorR"] lastObject] stringValue]floatValue];
                            g = [[[[paramOrder elementsForName:@"paramColorG"] lastObject] stringValue]floatValue];
                            b = [[[[paramOrder elementsForName:@"paramColorB"] lastObject] stringValue]floatValue];
                            colorWell.color = [NSColor colorWithRed:r green:g blue:b alpha:1];
                            unsigned int nR,nG,nB;
                            nR = r * 255;
                            nG = g * 255;
                            nB = b * 255;
                            unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + 255;
                            paramValue.nUnsignedValue = nColor;
                            ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], j, paramValue);
                            NSLog(@"标记3end");
                            continue;
                        }
                    }
                }
                nOrder++;
            }
        }
    }
    NSLog(@"选中模板的效果执行结束");
}
//template
-(void)clickBtnForFilterTemplate:(NSButton*)sender
{
    m_nIndexOfBtnForTemplate = (int)sender.tag;
    [self chooseFilterTemplateAt:m_nIndexOfBtnForTemplate];
}

//tempalte
-(void)clickBtnToMinusTemplate:(NSButton *)sender {
    int nIndex = (int)[[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    if(m_nIndexOfBtnForTemplate == -1)
    {
        return;
    }else{
        if(!nIndex)
        {
            [self minusTemplateForCombination];
            m_nIndexOfBtnForTemplate = -1;
            [self addTemplateReshowUIAtIndex:nIndex];
        }else{
            [self minusTemplateForSingleFilter:nIndex];
            m_nIndexOfBtnForTemplate = -1;
            [self addTemplateReshowUIAtIndex:nIndex];
        }
    }
}
//template
-(void)minusTemplateForCombination
{
    int nOrderForCombination = 0;
    int nCountOfFilter = 0;
    NSString* filePath = [m_FileManager pathForCombinationTemplateDocument];
    GDataXMLDocument* doc = [m_FileManager getCombinationTemplateDocument];
    GDataXMLElement* rootElement = [doc rootElement];
    NSArray* arrayForRootElement = [rootElement elementsForName:@"Combination"];
    
    GDataXMLDocument* docForCombination = [m_FileManager getFilterCombinationDocument];
    //rootElement为组合滤镜模板文件的root,rootElement2为组合滤镜文件的root
    GDataXMLElement* rootElement2 = docForCombination.rootElement;
    GDataXMLElement* elementForCombination = [[rootElement2 elementsForName:@"filterCombination"] objectAtIndex:[m_Window getFilterIndex]];
    NSString* nameForCombination = [[[elementForCombination elementsForName:@"filterCombinationName"]lastObject] stringValue];
    
    for(int i = 0; i < arrayForRootElement.count; i++)
    {
        NSString* stringForCombinationName = [[[arrayForRootElement[i] elementsForName:@"filterCombinationName"] lastObject] stringValue];
        
        if([stringForCombinationName isEqualToString:nameForCombination])
        {
            nCountOfFilter++;
        }
    }
    if(nCountOfFilter <= 1)
    {
        //如果只剩下一个模板则跳出函数，不删除
        return;
    }
    
    for(int i = 0; i < arrayForRootElement.count; i++)
    {
        NSArray* arrayForCombinationArgument = [arrayForRootElement[i] elementsForName:@"filterCombinationName"];
        NSString* stringForCombinationName = [[arrayForCombinationArgument lastObject] stringValue];
        
        if([stringForCombinationName isEqualToString:nameForCombination])
        {
            if(nOrderForCombination == m_nIndexOfBtnForTemplate)
            {
                [rootElement removeChild:arrayForRootElement[i]];
                [doc.XMLData writeToFile:filePath atomically:YES];
                return;
            }else{
                nOrderForCombination++;
            }
        }
    }
}
//template
-(void)minusTemplateForSingleFilter:(int)nIndex
{
    int nOrderForFilter = 0;
    //记录所剩的滤镜的数量
    int nCountOfFilter = 0;
    NSString* nameForFilter = GetFilterNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndex - 1]).intValue, [m_Window getFilterIndex]);
    NSString * documentDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filePath = [documentDirectory stringByAppendingPathComponent:[GetCategoryNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndex - 1]).intValue) stringByAppendingPathExtension:@"xml"]];
    NSData* fileData = [NSData dataWithContentsOfFile:filePath];
    GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:fileData options:0 error:nil]autorelease];
    GDataXMLElement* rootElement = [doc rootElement];
    NSArray* arrayForRootElement = [rootElement elementsForName:@"filter"];
    
    for(int i = 0; i < arrayForRootElement.count; i++)
    {
        NSString* stringForFilterName = [[[arrayForRootElement[i] elementsForName:@"filterName"] lastObject] stringValue];
        
        if([stringForFilterName isEqualToString:nameForFilter])
        {
            nCountOfFilter++;
        }
    }
    if(nCountOfFilter <= 1)
    {
        //如果只剩下一个模板则跳出函数，不删除
        return;
    }
    
    for(int i = 0; i < arrayForRootElement.count; i++)
    {
        NSString* stringForFilterName = [[[arrayForRootElement[i] elementsForName:@"filterName"] lastObject] stringValue];
        
        if([stringForFilterName isEqualToString:nameForFilter])
        {
            
            if(nOrderForFilter == m_nIndexOfBtnForTemplate)
            {
                [rootElement removeChild:arrayForRootElement[i]];
                [doc.XMLData writeToFile:filePath atomically:YES];
                return;
            }else{
                ++nOrderForFilter;
            }
        }
    }
}

//template
-(void)clickBtnToReplaceTemplate:(NSButton*) sender
{
    if(m_nIndexOfBtnForTemplate == -1)
    {
        return;
    }else{
        [self clickBtnToSaveTemplate];
        [self reselectTemplate];
    }
}
//template
//添加模板的函数响应
-(void)clickButtonToAddTemplate:(NSButton*)sender
{
    int nIndex = (int)[[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    if(!nIndex)
    {
        [self clickBtnToSaveTemplateForCombination:[m_Window getFilterIndex]];
        [self addTemplateReshowUIAtIndex:nIndex];
    }else{
        [self clickBtnToSaveTemplateForSingleFilter:nIndex];
        [self addTemplateReshowUIAtIndex:nIndex];
    }
    int nCount = [self getFilterCountAtIndex:[m_Window getFilterIndex]];
    m_nIndexOfBtnForTemplate = (nCount > 0 ? nCount - 1 : -1);
    [self reselectTemplate];
}
//template
//替换模板执行的函数
- (void)clickBtnToSaveTemplate {
    int nIndex = (int)[[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    if(!nIndex)
    {
        [self replaceTemplateForCombination];
    }else{
        [self replaceTemplateForSingleFilter:nIndex];
    }
    m_heightCurrentTemplate = m_scrollViewForTemplate.documentVisibleRect.origin.y;
    [self addTemplateReshowUIAtIndex:nIndex];
}
//template
-(void)replaceTemplateForCombination
{
    int nOrderForCombination = 0;
    NSString* filePath = [m_FileManager pathForCombinationTemplateDocument];
    GDataXMLDocument* doc = [m_FileManager getCombinationTemplateDocument];
    GDataXMLElement* rootElement = [doc rootElement];
    NSArray* arrayForRootElement = [rootElement elementsForName:@"Combination"];
    
    GDataXMLDocument* docForCombination = [m_FileManager getFilterCombinationDocument];
    //rootElement为组合滤镜模板文件的root,rootElement2为组合滤镜文件的root
    GDataXMLElement* rootElement2 = docForCombination.rootElement;
    GDataXMLElement* elementForCombination = [[rootElement2 elementsForName:@"filterCombination"] objectAtIndex:[m_Window getFilterIndex]];
    NSString* nameForCombination = [[[elementForCombination elementsForName:@"filterCombinationName"]lastObject] stringValue];
    
    for(int i = 0; i < arrayForRootElement.count; i++)
    {
        NSArray* arrayForCombinationArgument = [arrayForRootElement[i] elementsForName:@"filterCombinationName"];
        NSString* stringForCombinationName = [[arrayForCombinationArgument lastObject] stringValue];
        if([stringForCombinationName isEqualToString:nameForCombination])
        {
            if(nOrderForCombination == m_nIndexOfBtnForTemplate)
            {
                NSArray* arrayForFilter = [arrayForRootElement[i] elementsForName:@"filter"];
                for (int j = 0; j < arrayForFilter.count; j++) {
                    NSArray* arrayForParam = [arrayForFilter[j] elementsForName:@"param"];
                    GDataXMLElement* elementForParamFormat = [arrayForParam lastObject];
                    //没有参数的滤镜，跳出循环
                    if(!elementForParamFormat)
                    {
                        break;
                    }
                    for(int k = 0; k < elementForParamFormat.childCount; k++)
                    {
                        NSString* paramFormat = [NSString stringWithFormat:@"%@%d", @"param",k];
                        NSArray* arrayForParamFormat = [elementForParamFormat elementsForName:paramFormat];
                        GDataXMLElement* elementFormat = [arrayForParamFormat lastObject];
                        NSString* stringForParamType = [[[elementFormat elementsForName:@"paramType"] lastObject] stringValue];
                        if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                        {
                            NSArray* arrayForColorR = [elementFormat elementsForName:@"paramColorR"];
                            GDataXMLElement* elementForColorR = [arrayForColorR lastObject];
                            NSArray* arrayForColorG = [elementFormat elementsForName:@"paramColorG"];
                            GDataXMLElement* elementForColorG = [arrayForColorG lastObject];
                            NSArray* arrayForColorB = [elementFormat elementsForName:@"paramColorB"];
                            GDataXMLElement* elementForColorB = [arrayForColorB lastObject];
                            [elementFormat removeChild:elementForColorR];
                            [elementFormat removeChild:elementForColorG];
                            [elementFormat removeChild:elementForColorB];
                            
                            NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:j * 1000 + k * 100 ];
                            CGFloat r,g,b;
                            [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                            GDataXMLElement* elementNewColorR = [GDataXMLNode elementWithName:@"paramColorR" stringValue:[NSString stringWithFormat:@"%.2f",r]];
                            GDataXMLElement* elementNewColorG = [GDataXMLNode elementWithName:@"paramColorG" stringValue:[NSString stringWithFormat:@"%.2f",g]];
                            GDataXMLElement* elementNewColorB = [GDataXMLNode elementWithName:@"paramColorB" stringValue:[NSString stringWithFormat:@"%.2f",b]];
                            
                            [elementFormat addChild:elementNewColorR];
                            [elementFormat addChild:elementNewColorG];
                            [elementFormat addChild:elementNewColorB];
                        }
                        if([stringForParamType isEqualToString:@"AV_FLOAT"])
                        {
                            NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:j * 1000 + k * 100 ];
                            NSArray* arrayForColorR = [elementFormat elementsForName:@"paramCurrent"];
                            GDataXMLElement* elementForParamCurrent = [arrayForColorR lastObject];
                            [elementFormat removeChild:elementForParamCurrent];
                            GDataXMLElement* elementForNewParamCurrent = [GDataXMLNode elementWithName:@"paramCurrent" stringValue:[NSString stringWithFormat:@"%.6f", slider.floatValue]];
                            [elementFormat addChild:elementForNewParamCurrent];
                        }
                        if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                        {
                            NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:j * 1000 + k * 100 ];
                            NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:j * 1000 + k * 100 + 10];
                            NSArray* arrayForParamX = [elementForParamFormat elementsForName:@"ParamForX"];
                            GDataXMLElement* elementForParamX = [arrayForParamX lastObject];
                            [elementFormat removeChild:elementForParamX];
                            NSArray* arrayForParamY = [elementForParamFormat elementsForName:@"ParamForY"];
                            GDataXMLElement* elementForParamY = [arrayForParamY lastObject];
                            [elementFormat removeChild:elementForParamY];
                            GDataXMLElement* elementForX = [GDataXMLNode elementWithName:@"ParamForX" stringValue:[NSString stringWithFormat:@"%.6f", sliderX.floatValue]];
                            GDataXMLElement* elementForY = [GDataXMLNode elementWithName:@"ParamForY" stringValue:[NSString stringWithFormat:@"%.6f", sliderY.floatValue]];
                            [elementFormat addChild:elementForX];
                            [elementFormat addChild:elementForY];
                        }
                    }
                }
                [doc.XMLData writeToFile:filePath atomically:YES];
            }
            nOrderForCombination++;
        }
    }
}
//template
-(void)replaceTemplateForSingleFilter:(int)nIndex
{
    int nOrderForFilter = 0;
    NSString * documentDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filePath = [documentDirectory stringByAppendingPathComponent:[GetCategoryNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndex - 1]).intValue) stringByAppendingPathExtension:@"xml"]];
    NSData* fileData = [NSData dataWithContentsOfFile:filePath];
    GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:fileData options:0 error:nil]autorelease];
    GDataXMLElement* rootElement = [doc rootElement];
    NSArray* arrayForRootElement = [rootElement elementsForName:@"filter"];
    NSString* nameForFilter = GetFilterNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndex - 1]).intValue, [m_Window getFilterIndex]);
    for(int i = 0; i < arrayForRootElement.count; i++)
    {
        NSString* stringForFilterName = [[[arrayForRootElement[i] elementsForName:@"filterName"] lastObject] stringValue];
        if([stringForFilterName isEqualToString:nameForFilter])
        {
            if(nOrderForFilter == m_nIndexOfBtnForTemplate)
            {
                NSArray* arrayParamElement = [arrayForRootElement[i] elementsForName:@"param"];
                GDataXMLElement* elementForParam = [arrayParamElement lastObject];
                for(int j = 0; j < elementForParam.childCount; j++)
                {
                    NSString* stringForParamOrder = [NSString stringWithFormat:@"%@%d",@"param", j];
                    GDataXMLElement* elementForParamOrder = [[elementForParam elementsForName:stringForParamOrder] lastObject];
                    NSString* stringForParamType = [[[elementForParamOrder elementsForName:@"paramType"]lastObject] stringValue];
                    if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                    {
                        NSArray* arrayForColorR = [elementForParamOrder elementsForName:@"paramColorR"];
                        GDataXMLElement* elementForColorR = [arrayForColorR lastObject];
                        NSArray* arrayForColorG = [elementForParamOrder elementsForName:@"paramColorG"];
                        GDataXMLElement* elementForColorG = [arrayForColorG lastObject];
                        NSArray* arrayForColorB = [elementForParamOrder elementsForName:@"paramColorB"];
                        GDataXMLElement* elementForColorB = [arrayForColorB lastObject];
                        [elementForParamOrder removeChild:elementForColorR];
                        [elementForParamOrder removeChild:elementForColorG];
                        [elementForParamOrder removeChild:elementForColorB];
                        
                        NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag: j * 100 ];
                        CGFloat r,g,b;
                        [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                        GDataXMLElement* elementNewColorR = [GDataXMLNode elementWithName:@"paramColorR" stringValue:[NSString stringWithFormat:@"%.2f",r]];
                        GDataXMLElement* elementNewColorG = [GDataXMLNode elementWithName:@"paramColorG" stringValue:[NSString stringWithFormat:@"%.2f",g]];
                        GDataXMLElement* elementNewColorB = [GDataXMLNode elementWithName:@"paramColorB" stringValue:[NSString stringWithFormat:@"%.2f",b]];
                        
                        [elementForParamOrder addChild:elementNewColorR];
                        [elementForParamOrder addChild:elementNewColorG];
                        [elementForParamOrder addChild:elementNewColorB];
                        
                        continue;
                    }
                    if([stringForParamType isEqualToString:@"AV_FLOAT"])
                    {
                        NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:j * 100 ];
                        NSArray* arrayForParamCurrent = [elementForParamOrder elementsForName:@"paramCurrent"];
                        GDataXMLElement* elementForParamCurrent = [arrayForParamCurrent lastObject];
                        [elementForParamOrder removeChild:elementForParamCurrent];
                        GDataXMLElement* elementForNewParamCurrent = [GDataXMLNode elementWithName:@"paramCurrent" stringValue:[NSString stringWithFormat:@"%.6f", slider.floatValue]];
                        [elementForParamOrder addChild:elementForNewParamCurrent];
                        continue;
                    }
                    if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                    {
                        NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:j * 100 ];
                        NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:j * 100 + 10];
                        NSArray* arrayForParamX = [elementForParamOrder elementsForName:@"ParamForX"];
                        GDataXMLElement* elementForParamX = [arrayForParamX lastObject];
                        [elementForParamOrder removeChild:elementForParamX];
                        NSArray* arrayForParamY = [elementForParamOrder elementsForName:@"ParamForY"];
                        GDataXMLElement* elementForParamY = [arrayForParamY lastObject];
                        [elementForParamOrder removeChild:elementForParamY];
                        GDataXMLElement* elementForX = [GDataXMLNode elementWithName:@"ParamForX" stringValue:[NSString stringWithFormat:@"%.6f", sliderX.floatValue]];
                        GDataXMLElement* elementForY = [GDataXMLNode elementWithName:@"ParamForY" stringValue:[NSString stringWithFormat:@"%.6f", sliderY.floatValue]];
                        [elementForParamOrder addChild:elementForX];
                        [elementForParamOrder addChild:elementForY];
                        continue;
                    }
                }
                [doc.XMLData writeToFile:filePath atomically:YES];
                break;
            }else{
                nOrderForFilter++;
            }
        }
    }
}

//template
-(void)clickBtnToSaveTemplateForCombination:(int)index
{
    NSString* filePath = [m_FileManager pathForCombinationTemplateDocument];
    
    GDataXMLDocument* docForTemplate = [m_FileManager getCombinationTemplateDocument];
    
    GDataXMLDocument* doc = [m_FileManager getFilterCombinationDocument];
    NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
    NSString* stringForCombinationName = [[[arrayForCombination[index] elementsForName:@"filterCombinationName"]lastObject] stringValue];
    
    GDataXMLElement* combinationElement = [GDataXMLElement elementWithName:@"Combination"];
    GDataXMLElement* combinationName = [GDataXMLElement elementWithName:@"filterCombinationName" stringValue:stringForCombinationName];
    [combinationElement addChild:combinationName];
    
    NSArray* arrayForFilters = [arrayForCombination[index] elementsForName:@"filter"];
    for (int i = 0; i < arrayForFilters.count; i++) {
        GDataXMLElement* filterElement = [GDataXMLElement elementWithName:@"filter"];
        NSString* stringForName = [[[arrayForFilters[i] elementsForName:@"filterName"]lastObject] stringValue];
        GDataXMLElement* elementForName = [GDataXMLElement elementWithName:@"filterName" stringValue:stringForName];
        
//        NSString* stringForInName = [[[arrayForFilters[i] elementsForName:@"filterInName"]lastObject] stringValue];
//        GDataXMLElement* elementForInName = [GDataXMLElement elementWithName:@"filterInName" stringValue:stringForInName];
        
        NSString* stringForCategory = [[[arrayForFilters[i] elementsForName:@"filterCategory"]lastObject] stringValue];
        GDataXMLElement* elementForCategory = [GDataXMLElement elementWithName:@"filterCategory" stringValue:stringForCategory];
//        [filterElement addChild:elementForInName];
        [filterElement addChild:elementForName];
        [filterElement addChild:elementForCategory];
        
        NSArray* arrayForParam = [arrayForFilters[i] elementsForName:@"param"];
        GDataXMLElement* param = [arrayForParam lastObject];
        if(param.childCount > 0)
        {
            GDataXMLElement* paramElement = [GDataXMLElement elementWithName:@"param"];
            for (int j = 0; j < param.childCount; j++) {
                GDataXMLElement* paramElementIndex = [GDataXMLElement elementWithName:[NSString stringWithFormat:@"param%d", j]];
                GDataXMLElement* elementForParam = (GDataXMLElement*)[[param elementsForName:[NSString stringWithFormat:@"param%d", j]] lastObject];
                NSString* stringForParamInName = [[[elementForParam elementsForName:@"paramInName"] lastObject]stringValue];
                GDataXMLElement* paramInNameElement = [GDataXMLElement elementWithName:@"paramInName" stringValue:stringForParamInName];
                NSString* stringForParamType =  [[[elementForParam elementsForName:@"paramType"] lastObject]stringValue];
                GDataXMLElement* paramTypeElement = [GDataXMLElement elementWithName:@"paramType" stringValue:stringForParamType];
                [paramElementIndex addChild:paramInNameElement];
                [paramElementIndex addChild:paramTypeElement];
                
                if([stringForParamType isEqualToString:@"AV_FLOAT"])
                {
                    NSSlider* slider = [[m_ParamManager getContainView] viewWithTag: i * 1000 + j * 100];
                    NSString* stringForParamValue = [NSString stringWithFormat:@"%.6f", slider.floatValue];
                    GDataXMLElement* paramCurrent = [GDataXMLElement elementWithName:@"paramCurrent" stringValue:stringForParamValue];
                    [paramElementIndex addChild:paramCurrent];
                }
                if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"])
                {
                    NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100];
                    CGFloat r, g, b;
                    [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                    GDataXMLElement* paramR = [GDataXMLElement elementWithName:@"paramColorR" stringValue:@(r).stringValue];
                    GDataXMLElement* paramG = [GDataXMLElement elementWithName:@"paramColorG" stringValue:@(g).stringValue];
                    GDataXMLElement* paramB = [GDataXMLElement elementWithName:@"paramColorB" stringValue:@(b).stringValue];
                    [paramElementIndex addChild:paramR];
                    [paramElementIndex addChild:paramG];
                    [paramElementIndex addChild:paramB];
                }
                if([stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                {
                    NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100];
                    CGFloat r, g, b;
                    [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                    GDataXMLElement* paramR = [GDataXMLElement elementWithName:@"paramColorR" stringValue:@(r).stringValue];
                    GDataXMLElement* paramG = [GDataXMLElement elementWithName:@"paramColorG" stringValue:@(g).stringValue];
                    GDataXMLElement* paramB = [GDataXMLElement elementWithName:@"paramColorB" stringValue:@(b).stringValue];
                    [paramElementIndex addChild:paramR];
                    [paramElementIndex addChild:paramG];
                    [paramElementIndex addChild:paramB];
                }
                if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                {
                    NSSlider* slider1 = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100];
                    NSSlider* slider2 = [[m_ParamManager getContainView] viewWithTag:i * 1000 + j * 100 + 10];
                    NSString* stringForParamValueX = [NSString stringWithFormat:@"%.6f" ,slider1.floatValue];
                    NSString* stringForParamValueY = [NSString stringWithFormat:@"%.6f", slider2.floatValue];
                    GDataXMLElement* elementX = [GDataXMLElement elementWithName:@"ParamForX" stringValue:stringForParamValueX];
                    GDataXMLElement* elementY = [GDataXMLElement elementWithName:@"ParamForY" stringValue:stringForParamValueY];
                    [paramElementIndex addChild:elementX];
                    [paramElementIndex addChild:elementY];
                }
                [paramElement addChild:paramElementIndex];
            }
            [filterElement addChild:paramElement];
        }
        [combinationElement addChild:filterElement];
    }
    [docForTemplate.rootElement addChild:combinationElement];
    GDataXMLDocument* docToWrite = [[[GDataXMLDocument alloc] initWithRootElement:docForTemplate.rootElement] autorelease];
    [[docToWrite XMLData] writeToFile:filePath atomically:YES];
}
//template
-(void)clickBtnToSaveTemplateForSingleFilter:(int)nIndex
{
    int nIndexOfInCategoryOrder = ((NSNumber*)[m_Window getIndexArrayForCategory][nIndex - 1]).intValue;
    int nCountOfParam = GetFilterParaCountInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex]);
    NSString * documentDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString* stringForCategoryName = GetCategoryNameInCategory(nIndexOfInCategoryOrder);
    NSString* stringForTemplateFileName = [NSString stringWithFormat:@"%@.xml",stringForCategoryName];
    NSString* stringForFilePath = [documentDirectory stringByAppendingPathComponent:stringForTemplateFileName];
    NSData* xmlData = [NSData dataWithContentsOfFile:stringForFilePath];
    GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil] autorelease];
    
    GDataXMLElement* filterElement = [GDataXMLElement elementWithName:@"filter"];
//    GDataXMLElement* filterInName = [GDataXMLElement elementWithName:@"filterInName" stringValue:GetFilterInNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex])];
    GDataXMLElement* filterName = [GDataXMLElement elementWithName:@"filterName" stringValue:GetFilterNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex])];
    GDataXMLElement* filterCategory = [GDataXMLElement elementWithName:@"filterCategory" stringValue:stringForCategoryName];
//    [filterElement addChild:filterInName];
    [filterElement addChild:filterName];
    [filterElement addChild:filterCategory];
    if(nCountOfParam)
    {
        GDataXMLElement* filterParam = [GDataXMLElement elementWithName:@"param"];
        for(int i = 0; i < nCountOfParam; i++)
        {
            NSString* stringForParam = [NSString stringWithFormat:@"param%d",i];
            GDataXMLElement* paramIndex = [GDataXMLElement elementWithName:stringForParam];
            switch (GetFilterParamTypeInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex], i)) {
                case AV_FLOAT:
                {
                    GDataXMLElement* paramInName = [GDataXMLElement elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex], i)];
                    GDataXMLElement* paramType = [GDataXMLElement elementWithName:@"paramType" stringValue:@"AV_FLOAT"];
                    NSSlider* slider = [[m_ParamManager getContainView] viewWithTag:i * 100];
                    GDataXMLElement* paramCurrent = [GDataXMLElement elementWithName:@"paramCurrent" stringValue:[NSString stringWithFormat:@"%.6f", slider.floatValue]];
                    
                    [paramIndex addChild:paramInName];
                    [paramIndex addChild:paramType];
                    [paramIndex addChild:paramCurrent];
                    break;
                }
                    
                case AV_CENTEROFFSET:
                {
                    GDataXMLElement* paramInName = [GDataXMLElement elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex], i)];
                    GDataXMLElement* paramType = [GDataXMLElement elementWithName:@"paramType" stringValue:@"AV_CENTEROFFSET"];
                    
                    NSSlider* sliderX = [[m_ParamManager getContainView] viewWithTag:i * 100];
                    NSSlider* sliderY = [[m_ParamManager getContainView] viewWithTag:i * 100 + 10];
                    GDataXMLElement* paramForX = [GDataXMLElement elementWithName:@"ParamForX" stringValue:[NSString stringWithFormat:@"%.6f", sliderX.floatValue]];
                    GDataXMLElement* paramForY = [GDataXMLElement elementWithName:@"ParamForY" stringValue:[NSString stringWithFormat:@"%.6f", sliderY.floatValue]];
                    [paramIndex addChild:paramInName];
                    [paramIndex addChild:paramType];
                    [paramIndex addChild:paramForX];
                    [paramIndex addChild:paramForY];
                    break;
                }
                    
                case AV_DWORDCOLOR:
                {
                    CGFloat r,g,b;
                    GDataXMLElement* paramInName = [GDataXMLElement elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex], i)];
                    GDataXMLElement* paramType = [GDataXMLElement elementWithName:@"paramType" stringValue:@"AV_DWORDCOLOR"];
                    NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:i * 100];
                    [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                    
                    GDataXMLElement* paramR = [GDataXMLElement elementWithName:@"paramColorR" stringValue:@(r).stringValue];
                    GDataXMLElement* paramG = [GDataXMLElement elementWithName:@"paramColorG" stringValue:@(g).stringValue];
                    GDataXMLElement* paramB = [GDataXMLElement elementWithName:@"paramColorB" stringValue:@(b).stringValue];
                    [paramIndex addChild:paramInName];
                    [paramIndex addChild:paramType];
                    [paramIndex addChild:paramR];
                    [paramIndex addChild:paramG];
                    [paramIndex addChild:paramB];
                    break;
                }
                case AV_DWORDCOLORRGB:
                {
                    CGFloat r,g,b;
                    GDataXMLElement* paramInName = [GDataXMLElement elementWithName:@"paramInName" stringValue:GetFilterParamInNameInCategory(nIndexOfInCategoryOrder, [m_Window getFilterIndex], i)];
                    GDataXMLElement* paramType = [GDataXMLElement elementWithName:@"paramType" stringValue:@"AV_DWORDCOLORRGB"];
                    NSColorWell* colorWell = [[m_ParamManager getContainView] viewWithTag:i * 100];
                    [colorWell.color getRed:&r green:&g blue:&b alpha:nil];
                    
                    GDataXMLElement* paramR = [GDataXMLElement elementWithName:@"paramColorR" stringValue:@(r).stringValue];
                    GDataXMLElement* paramG = [GDataXMLElement elementWithName:@"paramColorG" stringValue:@(g).stringValue];
                    GDataXMLElement* paramB = [GDataXMLElement elementWithName:@"paramColorB" stringValue:@(b).stringValue];
                    [paramIndex addChild:paramInName];
                    [paramIndex addChild:paramType];
                    [paramIndex addChild:paramR];
                    [paramIndex addChild:paramG];
                    [paramIndex addChild:paramB];
                    break;
                }
                default:
                    break;
            }
            [filterParam addChild:paramIndex];
        }
        [filterElement addChild:filterParam];
    }
    [doc.rootElement addChild:filterElement];
    GDataXMLDocument* doc2 = [[[GDataXMLDocument alloc] initWithRootElement:doc.rootElement] autorelease];
    [[doc2 XMLData] writeToFile:stringForFilePath atomically:YES];
}

//template
-(void)addTemplateReshowUIAtIndex:(int)nIndex
{
    if(nIndex)
    {
        NSString * documentDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        NSString* stringForFilePath = [documentDirectory stringByAppendingPathComponent:[GetCategoryNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndex - 1]).intValue) stringByAppendingPathExtension:@"xml"]];
        NSData* xmlData = [NSData dataWithContentsOfFile:stringForFilePath];
        GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil]autorelease];
        [[m_FileManager getTemplateArray] removeObjectAtIndex:nIndex];
        GDataXMLElement* rootElement = [[doc.rootElement copy]autorelease];
        [[m_FileManager getTemplateArray] insertObject:rootElement atIndex:nIndex];
    }else{
        GDataXMLDocument* doc = [m_FileManager getCombinationTemplateDocument];
        [[m_FileManager getTemplateArray] removeObjectAtIndex:nIndex];
        [[m_FileManager getTemplateArray] insertObject:[[doc.rootElement copy]autorelease] atIndex:nIndex];
    }
    [self showFilterTemplate];
}

@end

//
//  MyParamManager.m
//  FilterGallery
//
//  Created by Calvin on 4/1/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import "MyParamManager.h"
#import "GDataXMLNode.h"
#import "AImageFilter.h"
#import "LADSlider.h"
#import "GDataXMLNode.h"
#import "MyVerticalScroller.h"
#import "TemplateManager.h"


@implementation MyParamManager
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString* pathForSliderControlPoint = [TBundle pathForResource:@"sliderControlPoint" ofType:@"png"];
        NSString* pathForSlider = [TBundle pathForResource:@"slider" ofType:@"png"];
        m_imageForSlider = [[NSImage alloc] initWithContentsOfFile:pathForSlider];
        m_imageForSliderBar = [[NSImage alloc] initWithContentsOfFile:pathForSliderControlPoint];
    }
    return self;
}

-(void)setTemplateManager:(TemplateManager*)manager
{
    m_TemplateManager = manager;
}

-(NSView*)getContainView
{
    return m_viewContainControls;
}
-(void)setContainView:(id)view
{
    m_viewContainControls = nil;
}

-(void)setWindow:(MyWindow*)window
{
    m_Window = window;
}

-(void)setFileManager:(FileManager*)manager
{
    m_FileManager = manager;
}

-(void)dealloc
{
    [m_imageForSlider release];
    [m_imageForSliderBar release];
    
    if(m_paramScrollView)
    {
        [m_paramScrollView removeFromSuperview];
        m_paramScrollView = nil;
    }
    
    [super dealloc];
}

//param
//添加界面控件的容器视图；
-(void)addContainerView
{
    if(m_paramScrollView)
    {
        [m_paramScrollView removeFromSuperview];
        m_paramScrollView = nil;
    }
    m_paramScrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(660, 40, 340, 380)]autorelease];
    m_paramScrollView.backgroundColor = LabelBackColor;
    m_paramScrollView.hasVerticalScroller = YES;
    MyVerticalScroller* vScroller = [[[MyVerticalScroller alloc] init] autorelease];
    m_paramScrollView.verticalScroller = vScroller;
    
    m_viewContainControls = [[[NSView alloc]initWithFrame:NSMakeRect(0, 0, 320, 380)]autorelease];
    m_paramScrollView.documentView  = m_viewContainControls;
    [m_Window.contentView addSubview:m_paramScrollView];
}

//param
-(float)calcDocumentViewHeight
{
    int nCountForParam = 0;
    int nIndexOfCategory = (int)[[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    if(!nIndexOfCategory)
    {
        GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
        NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
        NSArray* arrayForFilter = [arrayForCombination[[m_Window getFilterIndex]] elementsForName:@"filter"];
        for(int i = 0; i < arrayForFilter.count; i++)
        {
            NSArray* arrayForParam = [arrayForFilter[i] elementsForName:@"param"];
            GDataXMLElement* param = [arrayForParam lastObject];
            int paramCount = (int)(param.childCount);
            for(int j = 0; j < paramCount; j++)
            {
                NSString* paramOrder = [NSString stringWithFormat:@"param%d",j];
                NSArray* arrayForParamOrder = [param elementsForName:paramOrder];
                GDataXMLElement* elementForParamArgument = [arrayForParamOrder lastObject];
                NSString* stringForParamType = [[[elementForParamArgument elementsForName:@"paramType"]lastObject]stringValue];
                if([stringForParamType isEqualToString:@"AV_FLOAT"])
                {
                    nCountForParam++;
                }else if ([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
                {
                    nCountForParam++;
                }
                else if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
                {
                    nCountForParam += 2;
                }
            }
        }
    }else{
        int nCount = GetFilterParaCountInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue, [m_Window getFilterIndex]);
        for(int i = 0; i < nCount; i++)
        {
            AENUM_VARIABLE_TYPE type = GetFilterParamTypeInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][nIndexOfCategory - 1]).intValue, [m_Window getFilterIndex], i);
            switch (type) {
                case AV_FLOAT:
                    nCountForParam++;
                    break;
                case AV_DWORDCOLORRGB:
                case AV_DWORDCOLOR:
                    nCountForParam++;
                    break;
                case AV_CENTEROFFSET:
                    nCountForParam += 2;
                    break;
                default:
                    break;
            }
        }
    }
    return 50 * nCountForParam;
}

//param
-(void)updateParamUI:(int)nIndexOfFilter
{
    //如果参数过多大于scrollView的高度则重新设置documentView的高度
    float hHeightOfContainView = [self calcDocumentViewHeight] > m_paramScrollView.frame.size.height ? [self calcDocumentViewHeight] : m_paramScrollView.frame.size.height;
    if(hHeightOfContainView > m_paramScrollView.contentSize.height)
        m_viewContainControls.frame = NSMakeRect(0, 0, m_paramScrollView.frame.size.width - 20, hHeightOfContainView);
    [m_paramScrollView.documentView scrollPoint:NSMakePoint(0, ((NSView*)(m_paramScrollView.documentView)).frame.size.height)];
    int nYForParamName = m_viewContainControls.frame.size.height - 60,nTagForControl = 0;
    
    int nCountForParam = 0;
    GDataXMLDocument* doc =[m_FileManager getFilterCombinationDocument];
    NSArray* arrayForCombination = [doc.rootElement elementsForName:@"filterCombination"];
    NSArray* arrayForFilter = [arrayForCombination[nIndexOfFilter] elementsForName:@"filter"];
    for(int i = 0; i < arrayForFilter.count; i++)
    {
        nTagForControl = 0;
        NSArray* arrayForParam = [arrayForFilter[i] elementsForName:@"param"];
        GDataXMLElement* param = [arrayForParam lastObject];
        int paramCount = (int)(param.childCount);
        for(int j = 0; j < paramCount; j++)
        {
            NSString* paramOrder = [NSString stringWithFormat:@"param%d",j];
            NSArray* arrayForParamOrder = [param elementsForName:paramOrder];
            GDataXMLElement* elementForParamArgument = [arrayForParamOrder lastObject];
            NSString* stringForParamType = [[[elementForParamArgument elementsForName:@"paramType"]lastObject]stringValue];
            NSString* stringForParamName = [[[elementForParamArgument elementsForName:@"paramName"]lastObject]stringValue];
            NSString* stringForParamInName = [[[elementForParamArgument elementsForName:@"paramInName"]lastObject]stringValue];
            if([stringForParamType isEqualToString:@"AV_FLOAT"])
            {
                float defaultValue = [[[[elementForParamArgument elementsForName:@"paramDefault"]lastObject]stringValue]floatValue];
                float minValue = [[[[elementForParamArgument elementsForName:@"paramMin"]lastObject]stringValue]floatValue];
                float maxValue = [[[[elementForParamArgument elementsForName:@"paramMax"]lastObject]stringValue]floatValue];
                NSTextField* labelForParamName = [[[NSTextField alloc]initWithFrame:NSMakeRect(nXForParamName, nYForParamName, nWidthForParamName, nHeightForParamName)]autorelease];
                labelForParamName.lineBreakMode = NSLineBreakByWordWrapping;
                labelForParamName.cell.truncatesLastVisibleLine = YES;
                labelForParamName.drawsBackground = NO;
                labelForParamName.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForParamName.bezeled = NO;
                labelForParamName.editable = NO;
                labelForParamName.stringValue = stringForParamName;
                labelForParamName.alignment = NSTextAlignmentRight;
                labelForParamName.tag = -1;
                [m_viewContainControls addSubview:labelForParamName];
                
                LADSlider* slider = [[[LADSlider alloc] initWithKnobImage:m_imageForSliderBar barImage: m_imageForSlider] autorelease];
                slider.frame = NSMakeRect(nXForParamName + 90, nYForParamName + 17.5, 160, 20);
                slider.maxValue = 1;
                slider.minValue = 0;
                slider.floatValue = (defaultValue -  minValue) / (maxValue - minValue);
                slider.action = @selector(updateSliderForCombination:);
                slider.target = self;
                slider.tag = i *1000 + nTagForControl;
                slider.continuous = YES;
                [m_viewContainControls addSubview:slider];
                
                NSTextField* labelForValue = [[[NSTextField alloc]initWithFrame:NSMakeRect(270, nYForParamName + 12, 40, 25)]autorelease];
                labelForValue.drawsBackground = NO;
                labelForValue.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForValue.bezeled = NO;
                labelForValue.editable = NO;
                labelForValue.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                labelForValue.alignment = NSTextAlignmentRight;
                labelForValue.tag = slider.tag + 1;
                [m_viewContainControls addSubview:labelForValue];
                
                nYForParamName -= 50;
                nTagForControl += 100;
                nCountForParam++;
                continue;
            }else if ([stringForParamType isEqualToString:@"AV_DWORDCOLOR"] || [stringForParamType isEqualToString:@"AV_DWORDCOLORRGB"])
            {
                NSTextField* labelForParamName = [[[NSTextField alloc]initWithFrame:NSMakeRect(nXForParamName, nYForParamName, nWidthForParamName, nHeightForParamName)]autorelease];
                labelForParamName.lineBreakMode = NSLineBreakByWordWrapping;
                labelForParamName.cell.truncatesLastVisibleLine = YES;
                labelForParamName.drawsBackground = NO;
                labelForParamName.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForParamName.bezeled = NO;
                labelForParamName.editable = NO;
                labelForParamName.stringValue = stringForParamName;
                labelForParamName.alignment = NSTextAlignmentRight;
                labelForParamName.tag = -1;
                [m_viewContainControls addSubview:labelForParamName];
                
                NSColorWell* colorWell = [[[NSColorWell alloc]initWithFrame:NSMakeRect(150, nYForParamName + 17.5, 50, 25)]autorelease];
                colorWell.action = @selector(clickWellForCombination:);
                colorWell.target = self;
                colorWell.tag = nTagForControl + i * 1000;
                if([stringForParamType isEqualToString:@"AV_DWORDCOLOR"])
                {
                    CIColor* ciColor = [((IMAGE_FILTER*)([m_Window getFilterHandleVector][i])) -> filter valueForKey:stringForParamInName];
                    colorWell.color = [NSColor colorWithCIColor:ciColor];
                }else{
                    CIVector* vector = [((IMAGE_FILTER*)([m_Window getFilterHandleVector][i])) -> filter valueForKey:stringForParamInName];
                    float r, g, b;
                    r = vector.X;
                    g = vector.Y;
                    b = vector.Z;
                    NSColor* color = [NSColor colorWithRed:r green:g blue:b alpha:1];
                    colorWell.color = color;
                }
                [m_viewContainControls addSubview:colorWell];
                
                nYForParamName -= 50;
                nTagForControl += 100;
                nCountForParam++;
                continue;
            }else if([stringForParamType isEqualToString:@"AV_CENTEROFFSET"])
            {
                NSTextField* labelForParamName = [[[NSTextField alloc]initWithFrame:NSMakeRect(nXForParamName, nYForParamName, nWidthForParamName, nHeightForParamName)]autorelease];
                labelForParamName.lineBreakMode = NSLineBreakByWordWrapping;
                labelForParamName.cell.truncatesLastVisibleLine = YES;
                labelForParamName.drawsBackground = NO;
                labelForParamName.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForParamName.bezeled = NO;
                labelForParamName.editable = NO;
                labelForParamName.stringValue = stringForParamName;
                labelForParamName.alignment = NSTextAlignmentRight;
                labelForParamName.tag = -1;
                [m_viewContainControls addSubview:labelForParamName];
                
                LADSlider* slider = [[[LADSlider alloc] initWithKnobImage:m_imageForSliderBar barImage: m_imageForSlider] autorelease];
                slider.frame = NSMakeRect(nXForParamName + 90, nYForParamName + 17.5, 160, 20);
                slider.maxValue = 1;
                slider.minValue = 0;
                slider.floatValue = 0.5;
                slider.action = @selector(updateSliderForCombination:);
                slider.target = self;
                slider.tag = nTagForControl + i * 1000;
                slider.continuous = YES;
                [m_viewContainControls addSubview:slider];
                
                NSTextField* labelForValue = [[[NSTextField alloc]initWithFrame:NSMakeRect(270, nYForParamName + 12, 40, 25)]autorelease];
                labelForValue.editable = NO;
                labelForValue.drawsBackground = NO;
                labelForValue.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForValue.bezeled = NO;
                labelForValue.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                labelForValue.alignment = NSTextAlignmentRight;
                labelForValue.tag = slider.tag + 1;
                [m_viewContainControls addSubview:labelForValue];
                
                nYForParamName -= 50;
                nTagForControl += 10;
                nCountForParam++;
                
                
                LADSlider* slider2 = [[[LADSlider alloc] initWithKnobImage:m_imageForSliderBar barImage: m_imageForSlider] autorelease];
                slider2.frame = NSMakeRect(nXForParamName + 90, nYForParamName + 17.5, 160, 20);
                slider2.maxValue = 1;
                slider2.minValue = 0;
                slider2.floatValue = 0.5;
                slider2.action = @selector(updateSliderForCombination:);
                slider2.target = self;
                slider2.tag = nTagForControl + i * 1000;
                slider2.continuous = YES;
                [m_viewContainControls addSubview:slider2];
                
                NSTextField* labelForValue2 = [[[NSTextField alloc]initWithFrame:NSMakeRect(270, nYForParamName + 12, 40, 25)]autorelease];
                labelForValue2.editable = NO;
                labelForValue2.drawsBackground = NO;
                labelForValue2.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForValue2.bezeled = NO;
                labelForValue2.stringValue = [NSString stringWithFormat:@"%.2f",slider2.floatValue];
                labelForValue2.alignment = NSTextAlignmentRight;
                labelForValue2.tag = slider2.tag + 1;
                [m_viewContainControls addSubview:labelForValue2];
                
                nYForParamName -= 50;
                nTagForControl += 90;
                nCountForParam++;
                continue;
            }
        }
    }
}

//param
-(void)initParamUIForSingleFilter
{
    //如果参数过多大于scrollView的高度则重新设置documentView的高度
    float hHeightOfContainView = [self calcDocumentViewHeight] > m_paramScrollView.frame.size.height ? [self calcDocumentViewHeight] : m_paramScrollView.frame.size.height;
    if(hHeightOfContainView > m_paramScrollView.contentSize.height)
        m_viewContainControls.frame = NSMakeRect(0, 0, m_paramScrollView.frame.size.width - 20, hHeightOfContainView);
    [m_paramScrollView.documentView scrollPoint:NSMakePoint(0, ((NSView*)(m_paramScrollView.documentView)).frame.size.height)];
    int nYForParamName = m_viewContainControls.frame.size.height - 60,nTagForControl = 0;
    
    NSInteger index = (int)[[[m_Window GetTabView] tabViewItems] indexOfObject:[m_Window GetTabView].selectedTabViewItem] - 1;
    
    for(int i = 0; i < GetFilterParaCountInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex]);i++)
    {
        AVARIABLE_VALUE defaultValue = GetFilterParamDefaultInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
        
        AVARIABLE_VALUE maxValue = GetFilterParamMaxInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
        
        AVARIABLE_VALUE minValue = GetFilterParamMinInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
        
        AENUM_VARIABLE_TYPE aType = GetFilterParamTypeInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
        switch (aType) {
            case AV_FLOAT:
            {
                NSTextField* labelForParamName = [[[NSTextField alloc]initWithFrame:NSMakeRect(nXForParamName, nYForParamName, nWidthForParamName, nHeightForParamName)]autorelease];
                labelForParamName.drawsBackground = NO;
                labelForParamName.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForParamName.bezeled = NO;
                labelForParamName.editable = NO;
                labelForParamName.stringValue = GetFilterParamNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
                labelForParamName.alignment = NSTextAlignmentRight;
                labelForParamName.tag = -1;
                [m_viewContainControls addSubview:labelForParamName];
                LADSlider* slider = [[[LADSlider alloc] initWithKnobImage:m_imageForSliderBar barImage: m_imageForSlider] autorelease];
                slider.frame = NSMakeRect(nXForParamName + 90, nYForParamName + 17.5, 160, 20);
                slider.maxValue = 1;
                slider.minValue = 0;
                slider.floatValue = (defaultValue.fFloatValue -  minValue.fFloatValue) / (maxValue.fFloatValue - minValue.fFloatValue);
                slider.action = @selector(updateSlider:);
                slider.target = self;
                slider.tag = nTagForControl;
                slider.continuous = YES;
                [m_viewContainControls addSubview:slider];
                
                NSTextField* labelForValue = [[[NSTextField alloc]initWithFrame:NSMakeRect(270, nYForParamName + 12, 40, 25)]autorelease];
                labelForValue.drawsBackground = NO;
                labelForValue.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForValue.bezeled = NO;
                labelForValue.editable = NO;
                labelForValue.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                labelForValue.alignment = NSTextAlignmentRight;
                labelForValue.tag = slider.tag + 1;
                [m_viewContainControls addSubview:labelForValue];
                
                nYForParamName -= 50;
                nTagForControl += 100;
                break;
            }
            case AV_DWORDCOLORRGB:
            case AV_DWORDCOLOR:
            {
                NSTextField* labelForParamName = [[[NSTextField alloc]initWithFrame:NSMakeRect(nXForParamName, nYForParamName, nWidthForParamName, nHeightForParamName)]autorelease];
                labelForParamName.drawsBackground = NO;
                labelForParamName.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForParamName.bezeled = NO;
                labelForParamName.editable = NO;
                labelForParamName.bordered = NO;
                labelForParamName.stringValue = GetFilterParamNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
                labelForParamName.alignment = NSTextAlignmentRight;
                labelForParamName.tag = -1;
                [m_viewContainControls addSubview:labelForParamName];
                
//                NSString* stringInName = GetFilterParamInNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
                NSColor* color = nil;
                if(aType == AV_DWORDCOLORRGB)
                {
                    CGFloat r = (defaultValue.nUnsignedValue >> 24 & 255) / 255;
                    CGFloat g = (defaultValue.nUnsignedValue >> 16 & 255) / 255;
                    CGFloat b = (defaultValue.nUnsignedValue >> 8 & 255) / 255;
                    CGFloat alpha = (defaultValue.nUnsignedValue & 255) / 255;
                    color = [NSColor colorWithRed:r green:g blue:b alpha:alpha];
//                    CIVector* vector = [((IMAGE_FILTER*)[m_Window getFilterHandle]) -> filter valueForKey:stringInName];
//                    CGFloat r = vector.X;
//                    CGFloat g = vector.Y;
//                    CGFloat b = vector.Z;
//                    CGFloat alpha = vector.W;
//                    NSLog(@"FilterName:%@, R:%.2f,G:%.2f,B:%.2f,Alpha:%.2f",stringInName,r,g,b,alpha);
//                    color = [NSColor colorWithRed:r green:g blue:b alpha:1];
                }else{
//                    CIColor* ciColor = [((IMAGE_FILTER*)[m_Window getFilterHandle]) -> filter valueForKey:stringInName];
//                    color = [NSColor colorWithCIColor:ciColor];
//                    CGFloat r = color.redComponent;
//                    CGFloat g = color.greenComponent;
//                    CGFloat b = color.blueComponent;
//                    CGFloat alpha = color.alphaComponent;
//                    NSLog(@"FilterName:%@, R:%.2f,G:%.2f,B:%.2f,Alpha:%.2f",stringInName,r,g,b,alpha);
                    CGFloat r = (defaultValue.nUnsignedValue >> 24 & 255) / 255;
                    CGFloat g = (defaultValue.nUnsignedValue >> 16 & 255) / 255;
                    CGFloat b = (defaultValue.nUnsignedValue >> 8 & 255) / 255;
                    CGFloat alpha = (defaultValue.nUnsignedValue & 255) / 255;
                    color = [NSColor colorWithRed:r green:g blue:b alpha:alpha];
                }
                
                NSColorWell* colorWell = [[[NSColorWell alloc]initWithFrame:NSMakeRect(150, nYForParamName + 17.5, 50, 25)]autorelease];
                colorWell.action = @selector(clickWell:);
                colorWell.target = self;
                colorWell.tag = nTagForControl;
                colorWell.color = color;
                [m_viewContainControls addSubview:colorWell];
                
                nYForParamName -= 50;
                nTagForControl += 100;
                break;
            }
            case AV_CENTEROFFSET:
            {
                NSTextField* labelForParamName = [[[NSTextField alloc]initWithFrame:NSMakeRect(nXForParamName, nYForParamName, nWidthForParamName, nHeightForParamName)]autorelease];
                labelForParamName.drawsBackground = NO;
                labelForParamName.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForParamName.bezeled = NO;
                labelForParamName.editable = NO;
                labelForParamName.stringValue = GetFilterParamNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], i);
                labelForParamName.alignment = NSTextAlignmentRight;
                labelForParamName.tag = -1;
                [m_viewContainControls addSubview:labelForParamName];
                
                LADSlider* slider = [[[LADSlider alloc] initWithKnobImage:m_imageForSliderBar barImage: m_imageForSlider] autorelease];
                slider.frame = NSMakeRect(nXForParamName + 90, nYForParamName + 17.5, 160, 20);
                slider.maxValue = 1;
                slider.minValue = 0;
                slider.floatValue = defaultValue.fOffsetXY[0] - minValue.fOffsetXY[0] / maxValue.fOffsetXY[0] - minValue.fOffsetXY[0];
                slider.action = @selector(updateSlider:);
                slider.target = self;
                slider.tag = nTagForControl;
                slider.continuous = YES;
                [m_viewContainControls addSubview:slider];
                
                NSTextField* labelForValue = [[[NSTextField alloc]initWithFrame:NSMakeRect(270, nYForParamName + 12, 40, 25)]autorelease];
                
                labelForValue.drawsBackground = NO;
                labelForValue.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForValue.bezeled = NO;
                labelForValue.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                labelForValue.alignment = NSTextAlignmentRight;
                labelForValue.tag = slider.tag + 1;
                labelForValue.editable = NO;
                [m_viewContainControls addSubview:labelForValue];
                
                nYForParamName -= 50;
                nTagForControl += 10;
                
                LADSlider* slider2 = [[[LADSlider alloc] initWithKnobImage:m_imageForSliderBar barImage: m_imageForSlider] autorelease];
                slider2.frame = NSMakeRect(nXForParamName + 90, nYForParamName + 17.5, 160, 20);
                slider2.maxValue = 1;
                slider2.minValue = 0;
                slider2.floatValue = defaultValue.fOffsetXY[1] - minValue.fOffsetXY[1] / maxValue.fOffsetXY[1] - minValue.fOffsetXY[1];
                slider2.action = @selector(updateSlider:);
                slider2.target = self;
                slider2.tag = nTagForControl;
                slider2.continuous = YES;
                [m_viewContainControls addSubview:slider2];

                NSTextField* labelForValue2 = [[[NSTextField alloc]initWithFrame:NSMakeRect(270, nYForParamName + 12, 40, 25)]autorelease];
                labelForValue2.editable = NO;
                labelForValue2.drawsBackground = NO;
                labelForValue2.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
                labelForValue2.bezeled = NO;
                labelForValue2.stringValue = [NSString stringWithFormat:@"%.2f",slider.floatValue];
                labelForValue2.alignment = NSTextAlignmentRight;
                labelForValue2.tag = slider2.tag + 1;
                [m_viewContainControls addSubview:labelForValue2];
                
                nYForParamName -= 50;
                nTagForControl += 90;
                break;
            }
            default:
                break;
        }
    }
}
//param
-(void)clickWellForCombination:(NSColorWell*)sender
{
    int nFilterOrder = (int)sender.tag / 1000;
    int nParamOrder = ((int)sender.tag % 1000) / 100;
    AVARIABLE_VALUE paramValue;
    CGFloat r,g,b,a;
    [sender.color getRed:&r green:&g blue:&b alpha:&a];
    unsigned int nR,nG,nB,nA;
    nR = r * 255;
    nG = g * 255;
    nB = b * 255;
    nA = a * 255;
    unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + nA;
    paramValue.nUnsignedValue = nColor;
    ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][nFilterOrder], nParamOrder, paramValue);
}
//param
-(void)updateSliderForCombination:(NSSlider*)sender
{
    int nFilterOrder = (int)sender.tag / 1000;
    int nParamOrder = ((int)sender.tag %1000) / 100;
    AVARIABLE_VALUE paramValue;
    NSTextField* labelForValue = [m_viewContainControls viewWithTag:sender.tag + 1];
    labelForValue.stringValue = [NSString stringWithFormat:@"%.2f",sender.floatValue];
    
    AENUM_VARIABLE_TYPE paramType = GetFilterParamType(((IMAGE_FILTER*)[m_Window getFilterHandleVector][nFilterOrder]) -> nFilterIndex, nParamOrder);
    if(paramType == AV_FLOAT)
    {
        paramValue.fFloatValue = [sender floatValue];
    }else{
        if(sender.tag%100 == 0)
        {
            paramValue.fOffsetXY[0] = sender.floatValue;
            NSSlider* slider = [m_viewContainControls viewWithTag:sender.tag + 10];
            paramValue.fOffsetXY[1] = slider.floatValue;
        }
        else{
            paramValue.fOffsetXY[1] = sender.floatValue;
            NSSlider* slider = [m_viewContainControls viewWithTag:sender.tag - 10];
            paramValue.fOffsetXY[0] = slider.floatValue;
        }
    }
    ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][nFilterOrder], nParamOrder, paramValue);
}
//param
-(void)updateSlider:(NSSlider*)sender
{
    int nParamSequence = (int)sender.tag/100;
    NSUInteger index = [[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem] - 1;
    AVARIABLE_VALUE paramValue;
    NSTextField* labelForValue = [m_viewContainControls viewWithTag:sender.tag + 1];
    labelForValue.stringValue = [NSString stringWithFormat:@"%.2f",sender.floatValue];
    AENUM_VARIABLE_TYPE paramType = GetFilterParamTypeInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][index]).intValue, [m_Window getFilterIndex], nParamSequence);
    if(paramType == AV_FLOAT)
    {
        paramValue.fFloatValue = [sender floatValue];
    }else{
        if(sender.tag % 100 == 0)
        {
            paramValue.fOffsetXY[0] = sender.floatValue;
            NSSlider* slider = [m_viewContainControls viewWithTag:sender.tag + 10];
            paramValue.fOffsetXY[1] = slider.floatValue;
        }
        else{
            paramValue.fOffsetXY[1] = sender.floatValue;
            NSSlider* slider = [m_viewContainControls viewWithTag:sender.tag - 10];
            paramValue.fOffsetXY[0] = slider.floatValue;
        }
    }
    ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], nParamSequence, paramValue);
}
//param
-(void)clickWell:(NSColorWell*)sender
{
    int nParamSequence = (int)sender.tag/100;
    AVARIABLE_VALUE paramValue;
    CGFloat r,g,b,a;
    [sender.color getRed:&r green:&g blue:&b alpha:&a];
    unsigned int nR,nG,nB,nA;
    nR = r * 255;
    nG = g * 255;
    nB = b * 255;
    nA = a * 255;
    unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + nA;
    paramValue.nUnsignedValue = nColor;
    ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], nParamSequence, paramValue);
}
//param
- (void)clickBtnToRefreshTemplateParam:(NSButton *)sender {
    int nIndex = (int)[[m_Window GetTabView].tabViewItems indexOfObject:[m_Window GetTabView].selectedTabViewItem];
    if([m_TemplateManager getIndexOfTemplate] == -1)
    {
        return;
    }else{
        if(nIndex)
        {
            [self refreshSingleFilterTemplate:nIndex];
        }else{
            [self refreshCombinationTemplate];
        }
    }
}
//param
-(void)refreshSingleFilterTemplate:(int)nIndex
{
    int nOrderForFilter = 0;
    AVARIABLE_VALUE paramValue;
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
            if(nOrderForFilter == [m_TemplateManager getIndexOfTemplate])
            {
                NSArray* arrayForParam = [arrayForRootElement[i] elementsForName:@"param"];
                GDataXMLElement* elementForParam = [arrayForParam lastObject];
                for(int j = 0; j < elementForParam.childCount; j++)
                {
                    NSString* stringForParamOrder = [NSString stringWithFormat:@"%@%d",@"param",j];
                    NSArray* arrayForParamOrder = [elementForParam elementsForName:stringForParamOrder];
                    GDataXMLElement* elementForParamOrder = [arrayForParamOrder lastObject];
                    NSString* stringForType = [[[elementForParamOrder elementsForName:@"paramType"] lastObject] stringValue];
                    if([stringForType isEqualToString:@"AV_FLOAT"])
                    {
                        NSSlider* slider = [m_viewContainControls viewWithTag:j * 100];
                        NSTextField* textField = [m_viewContainControls viewWithTag:j * 100 + 1];
                        float fValue = [[[[elementForParamOrder elementsForName:@"paramCurrent"]lastObject]stringValue] floatValue];
                        slider.floatValue = fValue;
                        paramValue.fFloatValue = fValue;
                        textField.stringValue = [NSString stringWithFormat:@"%.2f",fValue];
                        ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], j, paramValue);
                    }
                    if([stringForType isEqualToString:@"AV_DWORDCOLORRGB"] || [stringForType isEqualToString:@"AV_DWORDCOLOR"])
                    {
                        NSColorWell* colorWell = [m_viewContainControls viewWithTag:j * 100];
                        float r,g,b;
                        r = [[[[elementForParamOrder elementsForName:@"paramColorR"]lastObject]stringValue] floatValue];
                        g = [[[[elementForParamOrder elementsForName:@"paramColorG"]lastObject]stringValue] floatValue];
                        b = [[[[elementForParamOrder elementsForName:@"paramColorB"]lastObject]stringValue] floatValue];
                        colorWell.color = [NSColor colorWithRed:r green:g blue:b alpha:1];
                        unsigned int nR,nG,nB;
                        nR = r * 255;
                        nG = g * 255;
                        nB = b * 255;
                        unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + 255;
                        paramValue.nUnsignedValue = nColor;
                        ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], j, paramValue);
                    }
                    if([stringForType isEqualToString:@"AV_CENTEROFFSET"])
                    {
                        NSSlider* sliderForX = [m_viewContainControls viewWithTag:j * 100];
                        NSTextField* labelForX = [m_viewContainControls viewWithTag:j * 100 + 1];
                        NSSlider* sliderForY = [m_viewContainControls viewWithTag:j * 100 + 10];
                        NSTextField* labelForY = [m_viewContainControls viewWithTag:j * 100 + 10 + 1];
                        sliderForX.floatValue = [[[[elementForParamOrder elementsForName:@"ParamForX"]lastObject]stringValue] floatValue];
                        sliderForY.floatValue = [[[[elementForParamOrder elementsForName:@"ParamForY"]lastObject]stringValue] floatValue];
                        
                        labelForX.stringValue = [NSString stringWithFormat:@"%.2f",sliderForX.floatValue];
                        labelForY.stringValue = [NSString stringWithFormat:@"%.2f",sliderForY.floatValue];
                        paramValue.fOffsetXY[0] = sliderForX.floatValue;
                        paramValue.fOffsetXY[1] = sliderForY.floatValue;
                        ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandle], j, paramValue);
                    }
                }
                return;
            }else{
                ++nOrderForFilter;
            }
        }
    }
}
//param
-(void)refreshCombinationTemplate
{
    int nOrderForCombinationTemplate = 0;
    AVARIABLE_VALUE paramValue;
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
        NSString* stringForFilterName = [[[arrayForRootElement[i] elementsForName:@"filterCombinationName"] lastObject] stringValue];
        if([stringForFilterName isEqualToString:nameForCombination])
        {
            if(nOrderForCombinationTemplate == [m_TemplateManager getIndexOfTemplate])
            {
                NSArray* arrayForFilter = [arrayForRootElement[i] elementsForName:@"filter"];
                for(int j = 0; j < arrayForFilter.count; j++)
                {
                    NSArray* arrayForParam = [arrayForFilter[j] elementsForName:@"param"];
                    if (!arrayForParam) {
                        continue;
                    }
                    GDataXMLElement* elementForParam = [arrayForParam lastObject];
                    for(int k = 0; k < elementForParam.childCount; k++)
                    {
                        NSString* stringForParamOrder = [NSString stringWithFormat:@"%@%d", @"param",k];
                        GDataXMLElement* elementForParamOrder = [[elementForParam elementsForName:stringForParamOrder]lastObject];
                        NSString* paramType = [[[elementForParamOrder elementsForName:@"paramType"]lastObject]stringValue];
                        if([paramType isEqualToString:@"AV_FLOAT"])
                        {
                            NSSlider* slider = [m_viewContainControls viewWithTag:j * 1000 + k * 100];
                            NSTextField* valueTextField = [m_viewContainControls viewWithTag:j * 1000 + k * 100 + 1];
                            float fValue = [[[[elementForParamOrder elementsForName:@"paramCurrent"]lastObject]stringValue]floatValue];
                            slider.floatValue = fValue;
                            valueTextField.stringValue = [NSString stringWithFormat:@"%.2f",fValue];
                            paramValue.fFloatValue = fValue;
                            ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][j], k, paramValue);
                            continue;
                        }
                        if([paramType isEqualToString:@"AV_DWORDCOLORRGB"] || [paramType isEqualToString:@"AV_DWORDCOLOR"])
                        {
                            NSColorWell* colorWell = [m_viewContainControls viewWithTag:j * 1000 + k * 100];
                            float r,g,b;
                            r = [[[[elementForParamOrder elementsForName:@"paramColorR"]lastObject]stringValue] floatValue];
                            g = [[[[elementForParamOrder elementsForName:@"paramColorG"]lastObject]stringValue] floatValue];
                            b = [[[[elementForParamOrder elementsForName:@"paramColorB"]lastObject]stringValue] floatValue];
                            colorWell.color = [NSColor colorWithRed:r green:g blue:b alpha:1];
                            unsigned int nR,nG,nB;
                            nR = r * 255;
                            nG = g * 255;
                            nB = b * 255;
                            unsigned int nColor = (nR << 24) + (nG << 16) + (nB << 8) + 255;
                            paramValue.nUnsignedValue = nColor;
                            ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][j], k, paramValue);
                            continue;
                        }
                        if([paramType isEqualToString:@"AV_CENTEROFFSET"])
                        {
                            NSSlider* sliderForX = [m_viewContainControls viewWithTag:j * 1000 + k * 100];
                            NSTextField* labelForX = [m_viewContainControls viewWithTag:j * 1000 + k * 100 + 1];
                            NSSlider* sliderForY = [m_viewContainControls viewWithTag:j * 1000 + k * 100 + 10];
                            NSTextField* labelForY = [m_viewContainControls viewWithTag:j * 1000 + k * 100 + 10 + 1];
                            sliderForX.floatValue = [[[[elementForParamOrder elementsForName:@"ParamForX"]lastObject]stringValue] floatValue];
                            sliderForY.floatValue = [[[[elementForParamOrder elementsForName:@"ParamForY"]lastObject]stringValue] floatValue];
                            
                            labelForX.stringValue = [NSString stringWithFormat:@"%.2f",sliderForX.floatValue];
                            labelForY.stringValue = [NSString stringWithFormat:@"%.2f",sliderForY.floatValue];
                            paramValue.fOffsetXY[0] = sliderForX.floatValue;
                            paramValue.fOffsetXY[1] = sliderForY.floatValue;
                            ModifyFilterParamInLayer([m_Window getShowView].layer, [m_Window getFilterHandleVector][j], k, paramValue);
                            continue;
                        }
                    }
                }
                return;
            }else{
                ++nOrderForCombinationTemplate;
            }
        }
    }
}
@end

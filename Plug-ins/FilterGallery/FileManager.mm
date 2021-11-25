//
//  FileManager.m
//  FilterGallery
//
//  Created by 沈宸 on 2017/4/11.
//  Copyright © 2017年 Calvin. All rights reserved.
//

#import "FileManager.h"
#import "GDataXMLNode.h"
#import "MyWindow.h"

@interface FileManager ()
{
    NSMutableArray* m_arrayForTemplateArrayOfCategory;
    MyWindow* m_Window;
}

@end

@implementation FileManager
-(void)setWindow:(MyWindow*)window
{
    m_Window = window;
}

-(NSMutableArray*)getTemplateArray
{
    return m_arrayForTemplateArrayOfCategory;
}

-(void)setTemplateArray:(NSMutableArray*)array
{
    m_arrayForTemplateArrayOfCategory = array;
}

-(void)dealloc
{
    if(m_arrayForTemplateArrayOfCategory)
    {
        [m_arrayForTemplateArrayOfCategory release];
        m_arrayForTemplateArrayOfCategory = nil;
    }
    [super dealloc];
}
//File
-(void)createTemplateArray
{
    m_arrayForTemplateArrayOfCategory = [[NSMutableArray alloc] init];
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filePath = [self pathForCombinationTemplateDocument];
    NSData* xmlData = [NSData dataWithContentsOfFile:filePath];
    GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil] autorelease];
    GDataXMLElement* rootElement = [[doc.rootElement copy]autorelease];
    [m_arrayForTemplateArrayOfCategory insertObject:rootElement atIndex:0];
    for (int i = 0; i < GetCategoriesCount(); i++) {
        NSString* templateFilePath = [documentPath stringByAppendingPathComponent:[GetCategoryNameInCategory(((NSNumber*)[m_Window getIndexArrayForCategory][i]).intValue) stringByAppendingPathExtension:@"xml"]];
        NSData* xmlData = [NSData dataWithContentsOfFile:templateFilePath];
        GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil] autorelease];
        GDataXMLElement* rootElement = [[doc.rootElement copy]autorelease];
        [m_arrayForTemplateArrayOfCategory addObject:rootElement];
    }
}
//file
-(NSString*)getFileName:(int)indexOfCategory
{
    NSString* fileName = nil;
    switch (indexOfCategory) {
        case 0:
            fileName = @"filterCombinationTemplate";
            break;
        case 1:
            fileName = @"Adjustment";
            break;
        case 2:
            fileName = @"Color";
            break;
        case 3:
            fileName = @"Blur";
            break;
        case 4:
            fileName = @"Distortion";
            break;
        case 5:
            fileName = @"Pixelate";
            break;
        case 6:
            fileName = @"Stylize";
            break;
        default:
            break;
    }
    return fileName;
}
//file
-(void)createXMLFile
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //拷贝组合滤镜文件
    NSString* filePathForCombination = [TBundle pathForResource:@"filtersCombination" ofType:@"xml"];
    NSString* filePathForCombinationInDocument = [self pathForCombinationDocument];
    if(![fileManager fileExistsAtPath:filePathForCombinationInDocument])
    {
        [fileManager copyItemAtPath:filePathForCombination toPath:filePathForCombinationInDocument error:nil];
    }
    //拷贝模板文件
    for(int i = 0; i < 1 + GetCategoriesCount(); i++)
    {
        NSString* fileBundlePath = [TBundle pathForResource:[self getFileName:i] ofType:@"xml"];
        NSString* destPath = [documentDirectory stringByAppendingPathComponent:[[self getFileName:i] stringByAppendingString:@".xml"]];
        if(![fileManager fileExistsAtPath:destPath])
        {
            [fileManager copyItemAtPath:fileBundlePath toPath:destPath error:nil];
        }
    }
}

//file
-(NSString*)pathForCategoryImage:(int)i
{
    NSString* path = nil;
    switch (i) {
        case 1:
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"adjustment" ofType:@"jpg"];
            break;
        case 2:
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"coloreffect" ofType:@"jpg"];
            break;
        case 3:
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"blur" ofType:@"jpg"];
            break;
        case 4:
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"distortion" ofType:@"jpg"];
            break;
        case 5:
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"pixelate" ofType:@"jpg"];
            break;
        case 6:
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"stylize" ofType:@"jpg"];
            break;
        default:
            break;
    }
    return path;
}

//file
-(NSString*)pathForCombinationDocument
{
    NSString * documentDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filePath = [documentDirectory stringByAppendingPathComponent:@"filtersCombination.xml"];
    return filePath;
}
//file
-(NSString*)pathForCombinationTemplateDocument
{
    NSString * documentDirectory= [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filePath = [documentDirectory stringByAppendingPathComponent:@"filterCombinationTemplate.xml"];
    return filePath;
}
//file
-(GDataXMLDocument*)getFilterCombinationDocument
{
    NSString* filePath = [self pathForCombinationDocument];
    NSData* xmlData = [NSData dataWithContentsOfFile:filePath];
    GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil]autorelease];
    return doc;
}
//file
-(GDataXMLDocument*)getCombinationTemplateDocument
{
    NSString* filePath = [self pathForCombinationTemplateDocument];
    NSData* xmlData = [NSData dataWithContentsOfFile:filePath];
    GDataXMLDocument* doc = [[[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil]autorelease];
    return doc;
}

//file
-(NSImage*)resizeImage:(NSImage*)orignalImage toRect:(NSRect)newRect
{
    NSImage* newImage = [[[NSImage alloc] initWithSize:newRect.size] autorelease];
    [newImage lockFocus];
    [orignalImage drawInRect:newRect];
    [newImage unlockFocus];
    return newImage;
}
@end

//
//  FileManager.h
//  FilterGallery
//
//  Created by 沈宸 on 2017/4/11.
//  Copyright © 2017年 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyTabView.h"
#include "AImageFilter.h"
@class MyWindow;
@class GDataXMLDocument;






@interface FileManager : NSObject
{
}
-(void)createXMLFile;
-(void)createTemplateArray;
-(NSString*)pathForCombinationTemplateDocument;
-(NSString*)pathForCombinationDocument;
-(NSImage*)resizeImage:(NSImage*)orignalImage toRect:(NSRect)newRect;
-(GDataXMLDocument*)getFilterCombinationDocument;
-(GDataXMLDocument*)getCombinationTemplateDocument;
-(NSString*)pathForCategoryImage:(int)i;

-(NSMutableArray*)getTemplateArray;
-(void)setTemplateArray:(NSMutableArray*)array;
-(void)setWindow:(MyWindow*)window;
@end

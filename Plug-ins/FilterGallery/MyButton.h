//
//  MyButton.h
//  CIFilters
//
//  Created by Calvin on 1/11/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyButton : NSButton
{
    NSImage* btnImage;
    NSString* btnTitle;
    NSArray* filterArray;
}
-(void)setBtnImage:(NSImage*)image;
-(void)setBtnTitle:(NSString*)string;
-(void)setBtnFilters:(NSArray*)array;
@end

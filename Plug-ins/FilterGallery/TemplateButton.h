//
//  TemplateButton.h
//  CIFilters
//
//  Created by Calvin on 1/12/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TemplateButton : NSButton
{
    NSImage* m_image;
}

-(void)setFaceImage:(NSImage*)image;

@end

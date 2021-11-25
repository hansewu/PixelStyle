//
//  MyView.h
//
//  Created by Calvin on 11/9/16.
//  Copyright © 2016 Calvin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyView : NSView
{
    NSImage* m_image;
}

-(void)setImage:(NSImage*)image;

-(void)loadLayer;
@end

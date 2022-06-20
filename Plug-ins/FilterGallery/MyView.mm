//
//  MyView.m
// 
//
//  Created by Calvin on 11/9/16.
//  Copyright © 2016 EffectMatrix. All rights reserved.
//

#import "MyView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MyView
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

-(void)loadLayer
{
    CALayer* m_rootLayer = [CALayer layer];
    m_rootLayer.frame = self.bounds;
    m_rootLayer.contents = m_image;
    self.layer = m_rootLayer;
}

-(void)setImage:(NSImage*)image
{
    m_image = image;
}

@end

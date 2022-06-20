//
//  MyImageView.m
//  SeamCarving
//
//  Created by Calvin on 8/29/16.
//  Copyright © 2016 EffectMatrix. All rights reserved.
//

#import "MyImageView.h"

@implementation MyImageView
{
    NSRect m_rectCenterTransparent;
    NSRect m_rectMax;
    NSRect m_rectShowImage;
    
    NSRect m_rectPrevShowImage;
    
    NSImage *m_showImage;
    
    NSPoint m_downPoint;
}

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if(m_rectCenterTransparent.size.width != 0 && (m_rectCenterTransparent.size.height != 0))
    {
        CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
        CGContextSetFillColorWithColor(ctx, [NSColor colorWithRed:0 green:0 blue:0 alpha: 0.2].CGColor);
        CGContextFillRect(ctx, self.bounds);
        
        if(m_showImage)
        {
            CGImageRef cgImage = [m_showImage CGImageForProposedRect:nil context:nil hints:nil];
            CGRect rectTemp = {(int)m_rectShowImage.origin.x,(int)m_rectShowImage.origin.y,(int)m_rectShowImage.size.width,(int)m_rectShowImage.size.height};
            CGContextDrawImage(ctx, rectTemp, cgImage);
        }
        
        CGRect rectTemp2 = {(int)m_rectCenterTransparent.origin.x,(int)m_rectCenterTransparent.origin.y,(int)m_rectCenterTransparent.size.width,(int)m_rectCenterTransparent.size.height};
        CGRect rectTop;
        if(rectTemp2.origin.y + rectTemp2.size.height < self.frame.size.height)
            rectTop = CGRectMake(0, (rectTemp2.origin.y + rectTemp2.size.height), (int)self.frame.size.width, (int)(self.frame.size.height - (rectTemp2.origin.y + rectTemp2.size.height)));
        
//        NSLog(@"%f,%f,%f,%f",rectTop.origin.x,rectTop.origin.y,rectTop.size.width,rectTop.size.height);
        
        
        CGRect rectBottom;
        if(rectTemp2.origin.y > 0)
            rectBottom = CGRectMake(0, 0, (int)self.frame.size.width, (int)(rectTemp2.origin.y));
        rectBottom = CGRectIntegral(rectBottom);
//         NSLog(@"%f,%f,%f,%f",rectBottom.origin.x,rectBottom.origin.y,rectBottom.size.width,rectBottom.size.height);
        CGRect rectLeft;
        if(rectTemp2.origin.x > 0)
            rectLeft = CGRectMake(0,
                    (int)(rectTemp2.origin.y),(int)rectTemp2.origin.x,
                                  (int)(rectTemp2.size.height));
     
//        NSLog(@"%f,%f,%f,%f",rectLeft.origin.x,rectLeft.origin.y,rectLeft.size.width,rectLeft.size.height);
        
        CGRect rectRight;
        if(rectTemp2.origin.x + rectTemp2.size.width < self.frame.size.width)
            rectRight = CGRectMake((int)(rectTemp2.origin.x + rectTemp2.size.width),
                (int)(rectTemp2.origin.y),
                (int)(self.frame.size.width - (rectTemp2.origin.x + rectTemp2.size.width)),
               (int)(rectTemp2.size.height));
//        NSLog(@"%f,%f,%f,%f",rectRight.origin.x,rectRight.origin.y,rectRight.size.width,rectRight.size.height);
        
        
        CGContextSetFillColorWithColor(ctx, [NSColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor);
        CGContextFillRect(ctx, rectTop);
        CGContextFillRect(ctx, rectLeft);
        CGContextFillRect(ctx, rectRight);
        CGContextFillRect(ctx, rectBottom);
    }
}

-(id)init
{
    self = [super init];
    if(self){
        m_rectCenterTransparent = NSZeroRect;
        m_rectMax = NSZeroRect;
        m_rectShowImage = NSZeroRect;
        m_showImage = nil;
    }
    return self;
}

-(void)dealloc
{
    if(m_showImage) {[m_showImage release]; m_showImage = nil;}
    
    [super dealloc];
}

-(void)setMaxRect:(NSRect)maxRect
{
    m_rectMax = maxRect;
}

-(void)setCenterTransparentRect:(NSRect)centerRect
{
    m_rectCenterTransparent = centerRect;
}

-(void)setShowImageRect:(NSRect)showImageRect
{
    m_rectShowImage = showImageRect;
}

-(NSRect)showImageRect
{
    return m_rectShowImage;
}

-(NSRect)centerTransparentRect
{
    return m_rectCenterTransparent;
}

-(void)setImage:(NSImage *)image
{
    if(m_showImage) {[m_showImage release]; m_showImage = nil;}
    
    m_showImage = [image retain];
}

-(void)mouseDown:(NSEvent *)theEvent
{
    m_rectPrevShowImage = m_rectShowImage;
//    m_rectPrevCenterTransparent = m_rectCenterTransparent;
    
    m_downPoint = [theEvent locationInWindow];
    m_downPoint = [self convertPoint:m_downPoint toView:self];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point toView:self];
    float fdeltaX = point.x - m_downPoint.x;
    float fdeltaY = point.y - m_downPoint.y;
    
    
    m_rectShowImage.origin.x = m_rectPrevShowImage.origin.x + fdeltaX;
    m_rectShowImage.origin.y = m_rectPrevShowImage.origin.y + fdeltaY;
    
    [self setNeedsDisplay:YES];
}


@end

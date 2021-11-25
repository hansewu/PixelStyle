//
//  MyButton.m
//  CIFilters
//
//  Created by Calvin on 1/11/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import "MyButton.h"

@implementation MyButton
-(void)setBtnImage:(NSImage*)image
{
    btnImage = [image retain];
}

-(void)setBtnTitle:(NSString *)string
{
    btnTitle = [string retain];
}

-(void)setBtnFilters:(NSArray*)array
{
    filterArray = array;
}

-(id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:nil] autorelease];
        [self addTrackingArea:trackingArea];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSBezierPath* pathToFill = [NSBezierPath bezierPathWithRect:self.bounds];
    [[NSColor colorWithDeviceRed:45.0/255 green:46.0/255 blue:46.0/255 alpha:1]setFill];
    [pathToFill fill];

    NSImageView* imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(2, 2, self.bounds.size.width - 4, self.bounds.size.height * 3 / 4 - 1)];
    imageView.image = btnImage;
    imageView.imageScaling = NSImageScaleAxesIndependently;
    imageView.imageFrameStyle = NSImageFrameNone;
    [self addSubview:imageView];
   
    NSTextField* textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, self.bounds.size.height*3/4 + 3, self.bounds.size.width, self.bounds.size.height / 4)]autorelease];

    textField.stringValue = btnTitle;
    textField.alignment = NSTextAlignmentCenter;
    textField.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
    textField.font = [NSFont systemFontOfSize:14];
    textField.drawsBackground = NO;
    textField.bordered = NO;
    textField.editable = NO;
    [self addSubview:textField];
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1] setStroke];
    path.lineWidth = 4.0;
    [path stroke];
}

-(void)mouseEntered:(NSEvent *)event
{
    self.alphaValue = 0.7;
}

-(void)mouseExited:(NSEvent *)event
{
    self.alphaValue = 1.0;
}

//-(BOOL)isFlipped
//{
//    return YES;
//}

-(void)dealloc
{
    NSArray* trackingAreas = [self trackingAreas];
    for (NSTrackingArea* area in trackingAreas) {
        [self removeTrackingArea:area];
    }
    if(btnTitle)
    {
        [btnTitle release];
        btnTitle =  nil;
    }
    if(btnImage)
    {
        [btnImage release];
        btnImage =  nil;
    }
    [super dealloc];
}
@end

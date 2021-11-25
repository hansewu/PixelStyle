/*
	MyTableRowView.m
	Copyright (c) 2006, Apple Computer, Inc., all rights reserved.
*/
#import "MyTableRowView.h"


@implementation MyTableRowView

-(void)drawRect:(NSRect)dirtyRect
{
    CGImageRef imageRef = [[NSImage imageNamed:@"info-win-backer"] CGImageForProposedRect:nil context:nil hints:nil];
            assert(imageRef);
            
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(context, NSRectToCGRect(dirtyRect), imageRef);
    
    
    
    CGRect rect = NSRectToCGRect(dirtyRect);
    imageRef = [[NSImage imageNamed:@"slim-line"] CGImageForProposedRect:nil context:nil hints:nil];
    assert(imageRef);
    
    if(self.bDrawSperateLine && (self.bounds.size.width == rect.size.width))
        CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height-1, rect.size.width, 1), imageRef);
    
    BOOL bSelected = [self isSelected];
    if(bSelected)
    {
        [[NSColor colorWithDeviceRed:112.0/255 green:123.0/255 blue:146.0/255 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect: dirtyRect] fill];
        
        
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGRect rect = NSRectToCGRect(dirtyRect);
        
        CGImageRef imageRef = [[NSImage imageNamed:@"slim-line"] CGImageForProposedRect:nil context:nil hints:nil];
        assert(imageRef);
       
        if(self.bDrawSperateLine && (self.bounds.size.width == rect.size.width))
            CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height-1, rect.size.width, 1), imageRef);
    }
}

-(void)drawSelectionInRect:(NSRect)dirtyRect
{
    [[NSColor colorWithDeviceRed:112.0/255 green:123.0/255 blue:146.0/255 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRect: dirtyRect] fill];
    
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect rect = NSRectToCGRect(dirtyRect);
    
    CGImageRef imageRef = [[NSImage imageNamed:@"slim-line"] CGImageForProposedRect:nil context:nil hints:nil];
    assert(imageRef);
    
    if(self.bDrawSperateLine)
        CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height-1, rect.size.width, 1), imageRef);
}

//-(void)drawSeparatorInRect:(NSRect)dirtyRect
//{
//    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
//    CGRect rect = NSRectToCGRect(dirtyRect);
//    
//    CGImageRef imageRef = [[NSImage imageNamed:@"slim-line"] CGImageForProposedRect:nil context:nil hints:nil];
//    assert(imageRef);
//    CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height-1, rect.size.width, 1), imageRef);
//}

@end

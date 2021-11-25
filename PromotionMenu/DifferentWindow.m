//
//  DifferentWindow.m
//  ImageMatting
//
//  Created by wyl on 15/2/7.
//  Copyright (c) 2015年 effectmatrix. All rights reserved.
//

//#import <WebKit/WebKit.h>
#import "DifferentWindow.h"

@implementation DifferentWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:style backing:bufferingType defer:flag];
    
    if (self) {
        
        [self initViews];
    }
    
    return self;
}


-(void)initViews
{
    self.delegate = self;
    
    
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 54, self.frame.size.width, self.frame.size.height - 76)] autorelease];
    [imageView setImage:[NSImage imageNamed:@"mat-difference.jpg"]];
    [imageView setImageScaling:NSImageScaleAxesIndependently];
    [self.contentView addSubview:imageView];
    
    NSButton *proButton = [[[NSButton alloc] initWithFrame:NSMakeRect(300, 10, 163, 34)] autorelease];
    [proButton setBordered:NO];
    [proButton setImage:[NSImage imageNamed:@"mat-button2.png"]];
    [proButton setAction:@selector(buyPro:)];
    [proButton setTitle:@"Get Pro Version"];
    [proButton setTarget:self];
    [proButton setImagePosition:NSImageOverlaps];
    [proButton.cell setImageScaling:NSImageScaleAxesIndependently
     ];
    [self.contentView addSubview:proButton];
    
//    NSButton *closeButton = [[[NSButton alloc] initWithFrame:NSMakeRect(self.frame.size.width - 165, 5, 60, 30)] autorelease];
//    [closeButton setBordered:NO];
//    [closeButton setImage:myLibraryImageNamed(@"mat-close.png")];
//    [closeButton setAction:@selector(closeWindow:)];
//    [closeButton setTitle:@"Close"];
//    [closeButton setTarget:self];
//    [closeButton setImagePosition:NSImageOverlaps];
//    [closeButton.cell setImageScaling:NSImageScaleAxesIndependently
//     ];
//    [self.contentView addSubview:closeButton];
    
}


-(void)closeWindow:(id)sender
{
    [self close];
}


-(void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModal];
}


-(void)dealloc
{
    [super dealloc];
}



-(void)buyPro:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/super-photocut-pro-transparent-wedding-gown-cutout/id1192683659?mt=12"]];
}


@end

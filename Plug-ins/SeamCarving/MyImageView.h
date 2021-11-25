//
//  MyImageView.h
//  SeamCarving
//
//  Created by Calvin on 8/29/16.
//  Copyright © 2016 Calvin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyImageView : NSView

-(void)setMaxRect:(NSRect)maxRect;
-(void)setCenterTransparentRect:(NSRect)centerRect;
-(void)setShowImageRect:(NSRect)showImageRect;
-(void)setImage:(NSImage *)image;
-(NSRect)showImageRect;
-(NSRect)centerTransparentRect;

@end

//
//  PSWindow.h
//  PixelStyle
//
//  Created by wyl on 15/12/4.
//
//

#import <Cocoa/Cocoa.h>

@interface PSWindow : NSWindow

@end

@interface NSWindow (NSWindow_AccessoryView)
-(void)addViewToTitleBar:(NSView*)viewToAdd atXPosition:(CGFloat)x;
@end


@interface PSDocmentWindow : PSWindow

@end


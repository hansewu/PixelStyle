

#import "UIKitOS.h"

CGFloat getScreenScale()
{
#if TARGET_OS_IPHONE
    return [UIScreen mainScreen].scale;
#else
    float screen_scale_factor = 1.0;

    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)])
    {
        screen_scale_factor = [[NSScreen mainScreen] backingScaleFactor];
    }
    
    return screen_scale_factor;
#endif
}

#if !TARGET_OS_IPHONE
NSData * UIImagePNGRepresentation(NSImage * image)
{
    // Create a bitmap representation from the current image
    
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    return [bitmapRep representationUsingType:NSPNGFileType properties:nil];
}

NSData * UIImageJPEGRepresentation(NSImage * image, CGFloat compressionQuality)
{
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    NSDictionary *imageProps = nil;
    
    NSNumber *quality = [NSNumber numberWithFloat:compressionQuality];
    imageProps = [NSDictionary dictionaryWithObject:quality forKey:NSImageCompressionFactor];
    
    return [bitmapRep representationUsingType:NSJPEGFileType properties:imageProps];
}


static NSGraphicsContext *s_currentContext;
void UIGraphicsPushContext(CGContextRef context)
{
    NSGraphicsContext *nsGraphicsContext;
    
    nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    
 //   [NSGraphicsContext saveGraphicsState];
    s_currentContext = NSGraphicsContext.currentContext;
    [NSGraphicsContext setCurrentContext:nsGraphicsContext];
}

void UIGraphicsPopContext(void)
{
    [NSGraphicsContext setCurrentContext:s_currentContext];
}

NSString *NSStringFromCGPoint(CGPoint point)
{
    return NSStringFromPoint( point);
}

@implementation NSValue (WDAdditions)

+ (NSValue *) valueWithCGRect:(CGRect)rect
{
    return [self valueWithRect:rect];
}

@end


#endif

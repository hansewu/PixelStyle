//
//  PSLineAttributePicker.h
//

#import <AppKit/AppKit.h>
#import "WDStrokeStyle.h"

@interface PSLineAttributePicker : NSControl {
    int                 selectedIndex_;
    NSButton            *joinButton_[3];
    NSButton            *capButton_[3];
    
    id                  m_controller;
}

@property (nonatomic, assign) CGLineCap cap;
@property (nonatomic, assign) CGLineJoin join;
@property (nonatomic, assign) WDStrokeAttributes mode;

-(void)setController:(id)controller;
+ (NSImage *) joinImageWithSize:(CGSize)size join:(CGLineJoin)join highlight:(BOOL)highlight;
+ (NSImage *) capImageWithSize:(CGSize)size cap:(CGLineCap)cap highlight:(BOOL)highlight;

@end

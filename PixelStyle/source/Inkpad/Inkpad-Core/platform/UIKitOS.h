
//
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AppKit/NSText.h>

#define UIColor         NSColor
#define UIImage         NSImage
#define UIImageView     NSImageView
#define UIFont          NSFont
#define UIPasteboard    NSPasteboard
#define UIView          NSView
#define UIViewController NSViewController
#define UIControl       NSControl
#define UIButton        NSButton
#define UITableView     NSTableView
#define UITableViewDelegate NSTableViewDelegate
#define UITableViewDataSource NSTableViewDataSource
#define UITextFieldDelegate NSTextFieldDelegate
#define UILabel         NSTextField
#define UITextField     NSTextField
#define UISlider        NSSlider
#define UISegmentedControl NSSegmentedControl
#define UICollectionView NSCollectionView
#define UITextViewDelegate NSTextViewDelegate
#define UIDocument      NSDocument
#define UIMotionEffectGroup NSMotionEffectGroup
//#define UICollectionViewController NSCollectionViewController
//#define UISwitch NSSwitch
//#define UITableViewCell NSTableViewCell

typedef NS_ENUM(NSInteger, UIDocumentSaveOperation) {
    UIDocumentSaveForCreating,
    UIDocumentSaveForOverwriting
};
/*
typedef NS_ENUM(NSUInteger, NSOSXTextAlignment) {
    NSTextAlignmentLeft      = 0,    // Visually left aligned
//#if TARGET_OS_IPHONE
//    NSTextAlignmentCenter    = 1,    // Visually centered
//    NSTextAlignmentRight     = 2,    // Visually right aligned
//#else // !TARGET_OS_IPHONE
    NSTextAlignmentRight     = 1,    // Visually right aligned
    NSTextAlignmentCenter    = 2,    // Visually centered
//#endif
    NSTextAlignmentJustified = 3,    // Fully-justified. The last line in a paragraph is natural-aligned.
    NSTextAlignmentNatural   = 4,    // Indicates the default alignment for script
} ;
*/
typedef NS_OPTIONS(NSUInteger, UIRectCorner) {
    UIRectCornerTopLeft     = 1 << 0,
    UIRectCornerTopRight    = 1 << 1,
    UIRectCornerBottomLeft  = 1 << 2,
    UIRectCornerBottomRight = 1 << 3,
    UIRectCornerAllCorners  = ~0UL
};

NSData * UIImagePNGRepresentation(NSImage * image);
NSData * UIImageJPEGRepresentation(NSImage * image, CGFloat compressionQuality);

void UIGraphicsPushContext(CGContextRef context);
void UIGraphicsPopContext(void);

NSString *NSStringFromCGPoint(CGPoint point);

@interface NSValue (WDAdditions)

+ (NSValue *) valueWithCGRect:(CGRect)rect;

@end


#endif

CGFloat getScreenScale();

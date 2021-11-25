//
//  PSVectorProxy.h
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//
#import "Globals.h"

@interface PSVectorProxy : NSObject

// To methods in Shape...
- (IBAction)unitePaths:(id)sender;
- (IBAction)intersectPaths:(id)sender;
- (IBAction)subtractPaths:(id)sender;
- (IBAction)excludePaths:(id)sender;

// To methods in Shape Arrange...
- (IBAction)bringShapeToFront:(id)sender;
- (IBAction)bringShapeForward:(id)sender;
- (IBAction)sendShapeBackward:(id)sender;
- (IBAction)sendShapeToBack:(id)sender;

// To methods in Shape Align...
- (IBAction)alignShape:(id)sender;

- (IBAction)flipShapeHorizontally:(id)sender;
- (IBAction)flipShapeVertically:(id)sender;

// To methods in Shape Paths...
- (IBAction)combinePaths:(id)sender;
- (IBAction)separatePaths:(id)sender;

- (IBAction)deletePaths:(id)sender;


- (BOOL)validateMenuItem:(id)menuItem;

@end

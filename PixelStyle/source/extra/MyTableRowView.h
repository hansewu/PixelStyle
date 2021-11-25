//
//  NSTableView_Extensions.h
//
//  Copyright (c) 2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTableView(MyExtensions)

- (NSArray *)allSelectedItems;
- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend;

@end

@interface MyTableView : NSTableView{
	// The document the outline view is in
	IBOutlet id document;
	
	// Whether or not the view is the first responder
	BOOL isFirst;
}
@end

@interface MyTableRowView : NSTableRowView{
    
    // Whether or not the view is the first responder
    BOOL isFirst;
}

@property BOOL bDrawSperateLine;

@end


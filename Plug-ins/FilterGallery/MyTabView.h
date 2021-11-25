//
//  WILLTabView.h
//  WILLTabView
//
//  Created by Aaron C on 12/6/11.
//  Copyright (c) 2011 WILLINTERACTIVE. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface MyTabView : NSTabView {
    NSSegmentedControl *segmentedControl;
}

-(void)selectTabViewItem:(NSTabViewItem *)tabViewItem;
-(id)initWithFrame:(NSRect)frameRect  ItemCount:(int)count;
-(void)setLabelToSegmentedControl;
-(void)setSetmentControlFrame;
-(void)initialSegmentControl;
@end

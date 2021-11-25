//
//  PSArrowheadCell.h
//
//  Created by Steve Sprang on 10/16/13.
//  Copyright (c) 2013 Taptrix, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

@class WDDrawingController;


@interface PSArrowheadCell : NSView
{

}

@property (nonatomic, strong) NSButton *startArrowButton;
@property (nonatomic, strong) NSButton *endArrowButton;
@property (nonatomic, strong) NSString *arrowhead;
@property (nonatomic, retain) WDDrawingController *drawingController;

@end

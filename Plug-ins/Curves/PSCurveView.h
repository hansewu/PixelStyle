//
//  PSCurveView.h
//  Curves
//
//  Created by lchzh on 23/9/15.
//  Copyright (c) 2015 lchzh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DRAGPOINTVIEWSIZE 10


@interface PSCurveView : NSView
{
    id m_delegate;
    NSMutableArray * m_drawPointValueArray;
    NSMutableArray * m_drawPointValueArrayForRed;
    NSMutableArray * m_drawPointValueArrayForGreen;
    NSMutableArray * m_drawPointValueArrayForBlue;
    
    
    BOOL m_bIsDragging;
    int m_nDragPointIndex;
}

- (void)updateDrawPointArray:(NSArray*)pointsArray ForColorIndex:(int)index;
- (void)setCustumDelegate:(id)delegate;

@end

@interface NSObject (PSCurveViewDelegate)


- (void)insertPoint:(NSPoint)point atIndex:(int)index;
- (void)removePointAtIndex:(int)index;
- (void)replacePoint:(NSPoint)point atIndex:(int)index;
- (int)getSelectedColorIndex;
- (unsigned char*)getGrayHistogramInfo;
- (NSMutableArray *)getDragPointValueArrayForColorIndex:(int)index;
- (BOOL)getCurveEnableForColorIndex:(int)index;


@end

//
//  PSCurveView.m
//  Curves
//
//  Created by lchzh on 23/9/15.
//  Copyright (c) 2015 lchzh. All rights reserved.
//

#import "PSCurveView.h"

@implementation PSCurveView


- (void)awakeFromNib
{
    m_drawPointValueArray = [[NSMutableArray alloc] init];
    m_drawPointValueArrayForRed = [[NSMutableArray alloc] init];
    m_drawPointValueArrayForGreen = [[NSMutableArray alloc] init];
    m_drawPointValueArrayForBlue = [[NSMutableArray alloc] init];
    
}

- (void)resetCurveViewCursor
{
    NSCursor *cursor = [NSCursor crosshairCursor];
    [self addCursorRect:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height) cursor:cursor];
}



- (void)drawRect:(NSRect)dirtyRect {

    [self resetCurveViewCursor];
    [super drawRect:dirtyRect];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    [path moveToPoint:NSMakePoint(64, 0)];
    [path lineToPoint:NSMakePoint(64, 255)];
    [path moveToPoint:NSMakePoint(128, 0)];
    [path lineToPoint:NSMakePoint(128, 255)];
    [path moveToPoint:NSMakePoint(192, 0)];
    [path lineToPoint:NSMakePoint(192, 255)];
    
    [path moveToPoint:NSMakePoint(0, 64)];
    [path lineToPoint:NSMakePoint(255, 64)];
    [path moveToPoint:NSMakePoint(0, 128)];
    [path lineToPoint:NSMakePoint(255, 128)];
    [path moveToPoint:NSMakePoint(0, 192)];
    [path lineToPoint:NSMakePoint(255, 192)];
    
    [[NSColor lightGrayColor] set];
    [path stroke];
    
    int index = [m_delegate getSelectedColorIndex];
    unsigned char *hitogramInfo = [m_delegate getGrayHistogramInfo];
    for (int i = 0; i < 256; i++) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(i, 0)];
        [path lineToPoint:NSMakePoint(i, hitogramInfo[i])];
        switch (index) {
            case 0:
                [[NSColor lightGrayColor] set];
                break;
            case 1:
                [[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.2] set];
                break;
            case 2:
                [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:0.2] set];
                break;
            case 3:
                [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.2] set];
                break;
                
            default:
                break;
        }
        [path stroke];
    }
    switch (index) {
        case 0:
            if ([m_delegate getCurveEnableForColorIndex:1] && [m_drawPointValueArrayForRed count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArrayForRed objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArrayForRed count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArrayForRed objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArrayForRed objectAtIndex:[m_drawPointValueArrayForRed count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor redColor] set];
                [path stroke];
            }
            if ([m_delegate getCurveEnableForColorIndex:2] && [m_drawPointValueArrayForGreen count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArrayForGreen objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArrayForGreen count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArrayForGreen objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArrayForGreen objectAtIndex:[m_drawPointValueArrayForGreen count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor greenColor] set];
                [path stroke];
            }
            if ([m_delegate getCurveEnableForColorIndex:3] && [m_drawPointValueArrayForBlue count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArrayForBlue objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArrayForBlue count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArrayForBlue objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArrayForBlue objectAtIndex:[m_drawPointValueArrayForBlue count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor blueColor] set];
                [path stroke];
            }
            if ([m_drawPointValueArray count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArray objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArray count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArray objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArray objectAtIndex:[m_drawPointValueArray count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor blackColor] set];
                [path stroke];
            }

            break;
            
        case 1:
            if ([m_drawPointValueArrayForRed count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArrayForRed objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArrayForRed count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArrayForRed objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArrayForRed objectAtIndex:[m_drawPointValueArrayForRed count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor redColor] set];
                [path stroke];
            }
            
            break;
        case 2:
            if ([m_drawPointValueArrayForGreen count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArrayForGreen objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArrayForGreen count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArrayForGreen objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArrayForGreen objectAtIndex:[m_drawPointValueArrayForGreen count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor greenColor] set];
                [path stroke];
            }
           
            
            break;
        case 3:
            if ([m_drawPointValueArrayForBlue count] > 0) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                NSPoint begin = [[m_drawPointValueArrayForBlue objectAtIndex:0] pointValue];
                [path moveToPoint:NSMakePoint(0, begin.y)];
                [path lineToPoint:begin];
                for (int i = 1; i < [m_drawPointValueArrayForBlue count]; i++) {
                    NSPoint point2 = [[m_drawPointValueArrayForBlue objectAtIndex:i] pointValue];
                    [path lineToPoint:point2];
                }
                NSPoint end = [[m_drawPointValueArrayForBlue objectAtIndex:[m_drawPointValueArrayForBlue count] - 1] pointValue];
                [path lineToPoint:NSMakePoint(255.0, end.y)];
                [[NSColor blueColor] set];
                [path stroke];
            }
            
            break;
            
        default:
            break;
    }
    
    
    NSMutableArray *dragPointArray = [m_delegate getDragPointValueArrayForColorIndex:index];
    for (int i = 0; i < [dragPointArray count]; i++) {
        NSPoint point2 = [[dragPointArray objectAtIndex:i] pointValue];
        [self drawACircleAtPoint:point2 ofRadius:DRAGPOINTVIEWSIZE/2];
    }
    
}

- (void)drawACircleAtPoint:(NSPoint)point ofRadius:(float)radius
{
    NSRect rect = NSMakeRect(point.x - radius, point.y - radius, radius * 2, radius * 2);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
    int index = [m_delegate getSelectedColorIndex];
    switch (index) {
        case 0:
            [[NSColor blackColor] set];
            break;
        case 1:
            [[NSColor redColor] set];
            break;
        case 2:
            [[NSColor greenColor] set];
            break;
        case 3:
            [[NSColor blueColor] set];
            break;
            
        default:
            break;
    }

    [path stroke];
}



- (void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"mouseDown");
    m_bIsDragging = NO;
    NSPoint dragPoint = [theEvent locationInWindow];
    dragPoint = [self convertPoint:dragPoint fromView:NULL];
    m_nDragPointIndex = [self getDragPointIndexForPoint:dragPoint];
    if (m_nDragPointIndex >= 0) {
        m_bIsDragging = YES;
    }
}


//double PointToSegDist(double x, double y, double x1, double y1, double x2, double y2)
//{
//    double cross = (x2 - x1) * (x - x1) + (y2 - y1) * (y - y1);
//    if (cross <= 0) return sqrt((x - x1) * (x - x1) + (y - y1) * (y - y1));
//    
//    double d2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
//    if (cross >= d2) return sqrt((x - x2) * (x - x2) + (y - y2) * (y - y2));
//    
//    double r = cross / d2;
//    double px = x1 + (x2 - x1) * r;
//    double py = y1 + (y2 - y1) * r;
//    return sqrt((x - px) * (x - px) + (py - y) * (py - y));
//}

- (float)pointToSegmentDistance:(NSPoint)p Point1:(NSPoint)p1 Point2:(NSPoint)p2
{
    float cross = (p2.x - p1.x) * (p.x - p1.x) + (p2.y - p1.y) * (p.y - p1.y);
    if (cross <= 0) return sqrt((p.x - p1.x) * (p.x - p1.x) + (p.y - p1.y) * (p.y - p1.y));
    
    float d2 = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y);
    if (cross >= d2) return sqrt((p.x - p2.x) * (p.x - p2.x) + (p.y - p2.y) * (p.y - p2.y));
    
    float r = cross / d2;
    float px = p1.x + (p2.x - p1.x) * r;
    float py = p1.y + (p2.y - p1.y) * r;
    return sqrt((p.x - px) * (p.x - px) + (py - p.y) * (py - p.y));
}

//省的计算sqrt，节约时间
- (float)pointToSegmentSquareDistance:(NSPoint)p Point1:(NSPoint)p1 Point2:(NSPoint)p2
{
    float cross = (p2.x - p1.x) * (p.x - p1.x) + (p2.y - p1.y) * (p.y - p1.y);
    if (cross <= 0) return (p.x - p1.x) * (p.x - p1.x) + (p.y - p1.y) * (p.y - p1.y);
    
    float d2 = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y);
    if (cross >= d2) return (p.x - p2.x) * (p.x - p2.x) + (p.y - p2.y) * (p.y - p2.y);
    
    float r = cross / d2;
    float px = p1.x + (p2.x - p1.x) * r;
    float py = p1.y + (p2.y - p1.y) * r;
    return (p.x - px) * (p.x - px) + (py - p.y) * (py - p.y);
}

- (BOOL)isPointOnSegment:(NSPoint)p Point1:(NSPoint)p1 Point2:(NSPoint)p2
{
    return [self pointToSegmentSquareDistance:p Point1:p1 Point2:p2] <= 20.0;
}

- (int)getDragPointIndexForPoint:(NSPoint)downPoint
{
    int colorIndex = [m_delegate getSelectedColorIndex];
    NSMutableArray *dragPointArray = [m_delegate getDragPointValueArrayForColorIndex:colorIndex];
    
    NSMutableArray *drawPointArray = m_drawPointValueArray;
    switch (colorIndex) {
        case 0:
            break;
        case 1:
            drawPointArray = m_drawPointValueArrayForRed;
            break;
        case 2:
            drawPointArray = m_drawPointValueArrayForGreen;
            break;
        case 3:
            drawPointArray = m_drawPointValueArrayForBlue;
            break;
            
        default:
            break;
    }
    int index = -1;
    BOOL isInLine = NO;
    for (int i = 0; i < [drawPointArray count] - 1; i++) {
        NSPoint tempPoint1 = [[drawPointArray objectAtIndex:i] pointValue];
        NSPoint tempPoint2 = [[drawPointArray objectAtIndex:i + 1] pointValue];
        if ([self isPointOnSegment:downPoint Point1:tempPoint1 Point2:tempPoint2]) {
            isInLine = YES;
            break;
        }
    }
    
    if (isInLine) {
        for (int i = 0; i < [dragPointArray count]; i++) {
            NSPoint tempPoint = [[dragPointArray objectAtIndex:i] pointValue];
            if (fabs(tempPoint.x - downPoint.x) < 5.0 && fabs(tempPoint.y - downPoint.y) < 5.0) {
                index = i;
                break;
            }else{
                if (tempPoint.x - downPoint.x > 0.0) {
                    index = i;
                    [m_delegate insertPoint:downPoint atIndex:index];
                    break;
                }else{
                    if (i == [dragPointArray count] - 1) {
                        [m_delegate insertPoint:downPoint atIndex:(int)[dragPointArray count]];
                        index = i + 1;
                        break;
                    }
                }
            }
        }
    }
    
    return index;
}

- (void)deletePointAtIndex:(int)index
{
//    if ([dragPointArray count] <= 2) {
//        return;
//    }
//    [dragPointArray removeObjectAtIndex:index];
    [m_delegate removePointAtIndex:index];
    m_bIsDragging = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    //NSLog(@"mouseDragged");
    int colorIndex = [m_delegate getSelectedColorIndex];
    NSMutableArray *dragPointArray = [m_delegate getDragPointValueArrayForColorIndex:colorIndex];
    
    if (m_bIsDragging) {
        NSPoint dragPoint = [theEvent locationInWindow];
        dragPoint = [self convertPoint:dragPoint fromView:NULL];
//        for (NSValue* pointvalue in m_dragPointValueArray) {
//            NSLog(@"%@ ",NSStringFromPoint([pointvalue pointValue]));
//        }
        if (m_nDragPointIndex != 0 && m_nDragPointIndex != [dragPointArray count] - 1) {
            if (dragPoint.x < 0 || dragPoint.x > self.frame.size.width || dragPoint.y < 0 || dragPoint.y > self.frame.size.height) {
                [self deletePointAtIndex:m_nDragPointIndex];
                return;
            }
            if (m_nDragPointIndex - 1 >= 0) {
                NSPoint leftPoint = [[dragPointArray objectAtIndex:m_nDragPointIndex - 1] pointValue];
                if (dragPoint.x <= leftPoint.x) {
                    [self deletePointAtIndex:m_nDragPointIndex];
                    return;
                }
            }
            if (m_nDragPointIndex + 1 < [dragPointArray count]) {
                NSPoint rightPoint = [[dragPointArray objectAtIndex:m_nDragPointIndex + 1] pointValue];
                if (dragPoint.x >= rightPoint.x) {
                    [self deletePointAtIndex:m_nDragPointIndex];
                    return;
                }
            }
        }
        
        if (m_nDragPointIndex == 0) {
            float xedge = [[dragPointArray objectAtIndex:1] pointValue].x - 5;
            dragPoint.x = MIN(MAX(0, dragPoint.x), xedge);
            dragPoint.y = MIN(MAX(0, dragPoint.y), self.frame.size.height);
        }
        if (m_nDragPointIndex == [dragPointArray count] - 1) {
            float xedge = [[dragPointArray objectAtIndex:[dragPointArray count] - 2] pointValue].x + 5;
            dragPoint.x = MIN(MAX(xedge, dragPoint.x), self.frame.size.width);
            dragPoint.y = MIN(MAX(0, dragPoint.y), self.frame.size.height);
        }
        
        for (NSValue* pointvalue in dragPointArray) {
            NSLog(@"%@ ",NSStringFromPoint([pointvalue pointValue]));
        }
        
        [m_delegate replacePoint:dragPoint atIndex:m_nDragPointIndex];
    }
}


- (void)mouseUp:(NSEvent *)theEvent
{
//    NSLog(@"mouseUp");
//    [m_delegate updateOverlayAfterChanged];
}


- (void)updateDrawPointArray:(NSArray*)pointsArray ForColorIndex:(int)index
{
    switch (index) {
        case 0:
            [m_drawPointValueArray removeAllObjects];
            [m_drawPointValueArray addObjectsFromArray:pointsArray];
            break;
        case 1:
            [m_drawPointValueArrayForRed removeAllObjects];
            [m_drawPointValueArrayForRed addObjectsFromArray:pointsArray];
            break;
        case 2:
            [m_drawPointValueArrayForGreen removeAllObjects];
            [m_drawPointValueArrayForGreen addObjectsFromArray:pointsArray];
            break;
        case 3:
            [m_drawPointValueArrayForBlue removeAllObjects];
            [m_drawPointValueArrayForBlue addObjectsFromArray:pointsArray];
            break;
            
        default:
            break;
    }
    
}

- (void)setCustumDelegate:(id)delegate
{
    m_delegate = delegate;
}

@end

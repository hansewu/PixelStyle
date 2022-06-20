//
//  TemplateLabelView.h
//  CIFilters
//
//  Created by Calvin on 1/17/17.
//  Copyright © 2017 EffectMatrix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TemplateLabelView : NSView
{
    NSString* m_title;
    NSPoint m_startpointForLine;
    NSPoint m_endpointForLine;
}

-(void)setTitle:(NSString*)title;
-(void)setLineStartPoint:(NSPoint)point;
-(void)setLineEndPoint:(NSPoint)point;
@end

//
//  InterfaceButton.h
//  CIFilters
//
//  Created by Calvin on 1/17/17.
//  Copyright © 2017 EffectMatrix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InterfaceButton : NSButton
{
    NSString* _label;
}

-(void)setLabel:(NSString*)label;
@end

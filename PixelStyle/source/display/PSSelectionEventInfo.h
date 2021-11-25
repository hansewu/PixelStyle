//
//  PSSelectionEventInfo.h
//  PixelStyle
//
//  Created by lchzh on 5/11/15.
//
//

#import <Foundation/Foundation.h>

#import "Globals.h"

@interface PSSelectionEventInfo : NSObject
{
    int selectionType;
    int selectionMode;
    IntRect selectionRect;
    int selectionFeather;
    int selectionRadius;
    
    IntPoint *selectionPoints;
    int selectionPointsCount;
    
    int selectionFirstActive;
    
    MAKE_OVERLAYER_INFO wandInfo;
}

@property int selectionType;
@property int selectionMode;
@property IntRect selectionRect;
@property IntPoint *selectionPoints;
@property int selectionPointsCount;
@property int selectionFeather;
@property int selectionRadius;
@property int selectionFirstActive;
@property MAKE_OVERLAYER_INFO wandInfo;

@end

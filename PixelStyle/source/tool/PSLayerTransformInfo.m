//
//  PSLayerTransformInfo.m
//  PixelStyle
//
//  Created by lchzh on 29/10/15.
//
//

#import "PSLayerTransformInfo.h"

@implementation PSLayerTransformInfo

@synthesize transformedLayer;
@synthesize transformController;
@synthesize selectedRect;
@synthesize selectedData;
@synthesize stayedData;
@synthesize stayedImageRef;

@synthesize newCGLayerRef;
@synthesize newXOffset;
@synthesize newYOffset;
@synthesize newWidth;
@synthesize newHeight;

- (id)init
{
    self = [super init];
    self.transformedLayer = NULL;
    self.selectedData = NULL;
    self.transformController = NULL;
    self.stayedData = NULL;
    self.stayedImageRef = NULL;
    self.newCGLayerRef = NULL;
        
    
    return self;
}

-(void)dealloc
{   
    [super dealloc];
}

@end

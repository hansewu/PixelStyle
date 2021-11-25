//
//  PSFilterInfoNode.h
//  PixelStyle
//
//  Created by lchzh on 7/3/16.
//
//

#import <Foundation/Foundation.h>

@interface PSFilterInfoNode : NSObject
{
    NSString *_name;
    NSMutableArray *_children;
    BOOL _isCatagory;
}

- (id)initWithName:(NSString *)filtername isCatagory:(BOOL)filterisCatagory;

@property(readonly, retain) NSString *name;
@property(readonly, retain) NSArray *children;
@property(readonly) BOOL isCatagory;

@end

//
//  PSFilterInfoNode.m
//  PixelStyle
//
//  Created by lchzh on 7/3/16.
//
//

#import "PSFilterInfoNode.h"
#import "PSSmartFilter.h"

@implementation PSFilterInfoNode

@synthesize name = _name, isCatagory = _isCatagory;
@dynamic children;

- (id)initWithName:(NSString *)filtername isCatagory:(BOOL)filterisCatagory
{
    self  = [super init];
    _name = [[NSString alloc] initWithString:filtername];
    _isCatagory = filterisCatagory;
    
    return self;
}

- (NSArray *)children
{
    if (!_children) {
        _children = [[NSMutableArray alloc] init];
    }else{
        return _children;
    }
    if ([_name isEqualToString:@"RootNode"]) {
        NSArray *names = [PSSmartFilterRegister getAllFiltersCatagoryName];
        for (int i = 0; i < [names count]; i++) {
            NSString *cname = [names objectAtIndex:i];
            if (![cname isEqualToString:@"SPECIAL"]) {
                PSFilterInfoNode *node = [[PSFilterInfoNode alloc] initWithName:cname isCatagory:YES];
                [_children addObject:node];
                [node release];
            }
        }
    }else if(_isCatagory){
        NSArray *names = [PSSmartFilterRegister getAllFiltersNameForCatagory:_name];
        for (int i = 0; i < [names count]; i++) {
            NSString *cname = [names objectAtIndex:i];
            if (cname) {
                PSFilterInfoNode *node = [[PSFilterInfoNode alloc] initWithName:cname isCatagory:NO];
                [_children addObject:node];
                [node release];
            }
        }
    }else{
        return nil;
    }
    return _children;
}

@end

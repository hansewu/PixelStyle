//
//  PSMemoryManager.h
//  PixelStyle
//
//  Created by lchzh on 20/10/15.
//
//

#import <Foundation/Foundation.h>

#define HISTORY_MAX_SIZE 100

@interface PSMemoryManager : NSObject
{
    NSMutableArray *m_pAllLayerMemoryInfo;
    NSUInteger m_currentSize;
    int m_accessHistory[HISTORY_MAX_SIZE];
    int m_historyCount;
    
}

- (void)addAccessLayerHistory:(int)layerID;
- (void*)applyMemoryForLayer:(int)layerID memoryType:(int)type size:(int)size;
- (void)freeMemoryForLayer:(int)layerID memoryType:(int)type;
- (BOOL)judgeHasMemoryForLayer:(int)layerID memoryType:(int)type;
- (BOOL)setMemoryForLayer:(int)layerID memoryType:(int)type toType:(int)toType;

@end

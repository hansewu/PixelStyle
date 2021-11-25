//
//  PSMemoryManager.m
//  PixelStyle
//
//  Created by lchzh on 20/10/15.
//
//

#import "PSMemoryManager.h"

#define MAX_MALLOC_MEMORY_SIZE  1000000000

@implementation PSMemoryManager

- (id)init
{
    self = [super init];
    m_pAllLayerMemoryInfo = [[NSMutableArray alloc] init];
    m_currentSize = 0;
    for (int i = 0; i < HISTORY_MAX_SIZE; i++) {
        m_accessHistory[i] = -1;
    }
    m_historyCount = 0;
    return self;
}

- (void)dealloc
{
    for (int i = 0; i < [m_pAllLayerMemoryInfo count]; i++) {
        NSMutableDictionary *tempInfo = [m_pAllLayerMemoryInfo objectAtIndex:i];
        void *pointer = [[tempInfo objectForKey:@"POINTERVALUE"] pointerValue];
        if (pointer) {
            free(pointer);
        }
    }
    [m_pAllLayerMemoryInfo removeAllObjects];
    [m_pAllLayerMemoryInfo release];
    
    [super dealloc];

}

- (void)awakeFromNib
{
    m_pAllLayerMemoryInfo = [[NSMutableArray alloc] init];
}

- (void)addAccessLayerHistory:(int)layerID
{
    for (int i = 0; i < m_historyCount; i++) {
        if (m_accessHistory[i] == layerID)
        {
            for (int j = i; j < m_historyCount - 1; j++) {
                m_accessHistory[j] = m_accessHistory[j + 1];
            }
            m_historyCount--;
        }
    }
    m_accessHistory[m_historyCount] = layerID;
    m_historyCount++;
    
    if (m_historyCount == HISTORY_MAX_SIZE) {
        int reduce = 20;
        for (int i = 0; i < m_historyCount - reduce; i++) {
            m_accessHistory[i] = m_accessHistory[i + reduce];
        }
        m_historyCount -= reduce;
    }
}

- (void)checkMemorySpace
{
    for (int i = 0; i < m_historyCount; i++)
    {
        for (int j = 0; j < [m_pAllLayerMemoryInfo count]; j++)
        {
            if (m_currentSize > MAX_MALLOC_MEMORY_SIZE) {
                NSMutableDictionary *tempInfo = [m_pAllLayerMemoryInfo objectAtIndex:j];
                int layerID1 = [[tempInfo objectForKey:@"LAYERIDNUMBER"] intValue];
                if (layerID1 == m_accessHistory[i]) {
                    void *pointer = [[tempInfo objectForKey:@"POINTERVALUE"] pointerValue];
                    int size = [[tempInfo objectForKey:@"SIZENUMBER"] intValue];
                    free(pointer);
                    m_currentSize -= size;
                    [m_pAllLayerMemoryInfo removeObjectAtIndex:j];
                    j--;
                }
            }else{
                return;
            }
            
        }
    }
}

- (void*)applyMemoryForLayer:(int)layerID memoryType:(int)type size:(int)size
{
    for (int i = 0; i < [m_pAllLayerMemoryInfo count]; i++) {
        NSMutableDictionary *tempInfo = [m_pAllLayerMemoryInfo objectAtIndex:i];
        int layerID1 = [[tempInfo objectForKey:@"LAYERIDNUMBER"] intValue];
        int type1 = [[tempInfo objectForKey:@"TYPENUMBER"] intValue];
        if (layerID1 == layerID && type1 == type) {
            void *pointer = [[tempInfo objectForKey:@"POINTERVALUE"] pointerValue];
            return pointer;
        }
    }
    [self checkMemorySpace];
    void *memory = malloc(size);
    m_currentSize += size;
    NSNumber *layerIDNumber = [NSNumber numberWithInt:layerID];
    NSNumber *typeNumber = [NSNumber numberWithInt:type];
    NSNumber *sizeNumber = [NSNumber numberWithInt:size];
    NSValue *pointerValue = [NSValue valueWithPointer:memory];
    NSMutableDictionary *memoryInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:layerIDNumber, @"LAYERIDNUMBER", typeNumber, @"TYPENUMBER",  sizeNumber, @"SIZENUMBER", pointerValue, @"POINTERVALUE", nil];
    [m_pAllLayerMemoryInfo addObject:memoryInfo];
    return memory;
}

- (BOOL)setMemoryForLayer:(int)layerID memoryType:(int)type toType:(int)toType
{
    for (int i = 0; i < [m_pAllLayerMemoryInfo count]; i++) {
        NSMutableDictionary *tempInfo = [m_pAllLayerMemoryInfo objectAtIndex:i];
        int layerID1 = [[tempInfo objectForKey:@"LAYERIDNUMBER"] intValue];
        int type1 = [[tempInfo objectForKey:@"TYPENUMBER"] intValue];
        if (layerID1 == layerID && type1 == type) {
            NSNumber *typeNumber = [NSNumber numberWithInt:toType];
            [tempInfo setObject:typeNumber forKey:@"TYPENUMBER"];
            return YES;
        }
    }
    return NO;    
}

- (void)freeMemoryForLayer:(int)layerID memoryType:(int)type
{
    for (int i = 0; i < [m_pAllLayerMemoryInfo count]; i++) {
        NSMutableDictionary *tempInfo = [m_pAllLayerMemoryInfo objectAtIndex:i];
        int layerID1 = [[tempInfo objectForKey:@"LAYERIDNUMBER"] intValue];
        int type1 = [[tempInfo objectForKey:@"TYPENUMBER"] intValue];
        if (layerID1 == layerID && type1 == type) {
            void *pointer = [[tempInfo objectForKey:@"POINTERVALUE"] pointerValue];
            int size = [[tempInfo objectForKey:@"SIZENUMBER"] intValue];
            free(pointer);
            m_currentSize -= size;
            [m_pAllLayerMemoryInfo removeObjectAtIndex:i];
            return;
        }
    }
}

- (BOOL)judgeHasMemoryForLayer:(int)layerID memoryType:(int)type
{
    for (int i = 0; i < [m_pAllLayerMemoryInfo count]; i++) {
        NSMutableDictionary *tempInfo = [m_pAllLayerMemoryInfo objectAtIndex:i];
        int layerID1 = [[tempInfo objectForKey:@"LAYERIDNUMBER"] intValue];
        int type1 = [[tempInfo objectForKey:@"TYPENUMBER"] intValue];
        if (layerID1 == layerID && type1 == type) {
            return YES;
        }
    }
    return NO;
}

@end

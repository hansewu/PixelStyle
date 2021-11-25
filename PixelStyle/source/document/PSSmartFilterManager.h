//
//  PSSmartFilterManager.h
//  SmartFilterDesign
//
//  Created by lchzh on 1/12/15.
//  Copyright © 2015 effectmatrix. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PSSmartFilter.h"

@class PSSecureImageData;

typedef struct smart_filter_info
{
    int uniqueID; //index 可以弃用
    NSString * filterName;
    COMMON_FILTER_INFO filterInfo;
    BOOL isEnable;
    
}SMART_FILTER_INFO;


typedef struct
{
    int             nWidth;
    int             nHeight;
    int             nSpp;
    unsigned char  *pBuffer;

    PSSecureImageData *dataImage;
    
    CGRect dirtyRect;
    int  precision; //0 low 1 high
    CGSize   sizeScale;
    
    unsigned char  *mask; //暂时为空
    
}INPUT_DATA_INFO;

typedef struct
{
    CGRect            bufferRect; // 渲染时需根据scale进行缩放
    int             nSpp;
    int             bAlphaPremultiplied;
    unsigned char  *pBuffer;
    
    CGSize     sizeScale;
    int state; //0 有效 1 无效（可能中断）
    
}OUTPUT_DATA_INFO;


@class PSDistanceInfoManager;

typedef struct {
    SMART_FILTER_INFO *allFilters;
    int filtersCount;
} UndoRecordForSmartFilter;

typedef struct
{
    CGRect dirtyRect;
    CGRect neededRect;
    CGRect effectedRect;
    unsigned char* outputData;
    
}BLOCK_DATA_INFO;

@interface PSSmartFilterManager : NSObject<NSCoding>
{
    SMART_FILTER_INFO *m_allFilters;
    int m_filtersCount;
    NSRecursiveLock *m_filterSourceLock;

    id m_delegateForManager;
    
    volatile int m_filterState;
    volatile BOOL m_isProcessFull;
    
    
    PSDistanceInfoManager *m_distanceInfoManager;
    
    UndoRecordForSmartFilter *m_undoRecords;
    int m_undoRecordsCount;
    int m_undoRecordsMaxLen;
    UndoRecordForSmartFilter m_oldRecords;
    
    BLOCK_DATA_INFO *m_blockDataInfo;
    int m_blockCount;
    
}


- (id)customCopy;

- (void)setDelegateForManager:(id)delegete;

- (void)addNewSmartFilter:(NSString*)filterName;
- (void)insertNewSmartFilter:(NSString*)filterName atIndex:(int)index;
- (void)removeSmartFilter:(int)index;
- (void)moveSmartFilterFrom:(int)fromIndex to:(int)toIndex;

- (void)flatternFilters;

- (SMART_FILTER_INFO)getSmartFilterAtIndex:(int)index;
- (void)setSmartFilter:(SMART_FILTER_INFO)filterInfo AtIndex:(int)index;
- (int)getSmartFiltersCount;

- (BOOL)isHasEffect;
//获取参数信息，包括参数类型、参数值、最大值、最小值等
- (FILTER_PARAMETER_INFO)getSmartFilterParameterInfo:(int)filterIndex parameterIndex:(int)paraIndex;
- (FILTER_PARAMETER_INFO)getSmartFilterParameterInfo:(int)filterIndex parameterName:(const char *)pParaName;

//获取参数值
- (PARAMETER_VALUE)getSmartFilterParameterForFilter:(int)filterIndex parameterIndex:(int)paraIndex;
- (PARAMETER_VALUE)getSmartFilterParameterForFilter:(int)filterIndex parameterName:(const char *)pParaName;

-(int)getFilterParaIndexWithName:(const char *)pParaName forFilter:(int)filterIndex;
-(void)setSmartFilterParameter:(PARAMETER_VALUE)value filterIndex:(int)filterIndex parameterIndex:(int)paraIndex;
-(void)setSmartFilterParameter:(PARAMETER_VALUE)value filterIndex:(int)filterIndex parameterName:(const char *)pParaName;

- (void)resetSmartFilter:(int)index;

- (BOOL)getFilterIsValidAtIndex:(int)filterIndex;


// 做级联 根据filter输入纹理个数 有的要特殊处理  甚至从gpu出来 再进去
- (OUTPUT_DATA_INFO)getFilteredDataForSrcData:(INPUT_DATA_INFO )inputDataInfo;
- (void)cancleCurrentFullProcess;

//for undo/redo
- (void)filtersEditWillBegin;
- (void)filtersEditDidEnd;
- (void)filtersEditDidCancel;


@end

@interface NSObject (PSSmartFilterManagerDelegate)

- (NSUndoManager*)getUndoManager;
- (void)refreshTotalToRender;
- (void)updateSmartFilterInterface;

@end

//
//  PSLayerEffect.h
//  PixelStyle
//
//  Created by lchzh on 6/9/15.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "GPUImageEffectFilter.h"
#import "Rects.h"
//#import "PSDistanceTransform.h"

#define MAX_DISTANCE_RADIUS 200

@protocol protocolEffectNotify <NSObject>

- (void)displayRenderedInfo:(CGRect)rect;

@end



typedef struct
{
    IntSize offset;
    float fBlur;
    unsigned char color[4];
}LAYER_SHADOW;

typedef struct {
    int effectNum;
    
    BOOL strokeEnable;
    float strokeSize;
    GPUVector3 strokeColor;
    float strokeColorAlpha;
    int strokePosition;
    
    BOOL fillEnable;
    GPUVector3 fillColor;
    float fillColorAlpha;
    
    BOOL outerGlowEnable;
    GPUVector3 outerGlowColor;
    float outerGlowColorAlpha;
    float outerGlowSize;
    
    BOOL innerGlowEnable;
    GPUVector3 innerGlowColor;
    float innerGlowColorAlpha;
    float innerGlowSize;
    
    BOOL shadowEnable;
    LAYER_SHADOW shadow;
    
} UndoRecordForEffect;



//@class PSDistanceTransform;
@class PSSecureImageData;
//@class GPUImageEffectFilter;

@interface PSLayerEffect : NSObject
{
    id m_idDocument;
    id m_idLayer;
    GPUImageEffectFilter *m_effectFilter;
    UndoRecordForEffect *m_undoRecords;
    UndoRecordForEffect m_oldRecords;
    
    id<protocolEffectNotify>  m_idDelegateForEffect;
    volatile BOOL m_isLayerEffectEnable;
   
    //PSDistanceTransform *m_idDistanceTransform;
    
    BOOL m_isNeedUpdateDistance;
        
    int m_undoRecordsCount;
    int m_undoRecordsMaxLen;
    
    int m_nEffectNum;
    
    BOOL m_bIsStrokeEnable;
    float m_strokeSize;
    GPUVector3 m_strokeColor;
    int m_strokePosition; //0out,1middle,2in
    float m_strokeColorAlpha;
    
    BOOL m_bIsFillEnable;
    GPUVector3 m_fillColor;
    float m_fillColorAlpha;
    
    BOOL m_bIsOuterGlowEnable;
    GPUVector3 m_outerGlowColor;
    float m_outerGlowColorAlpha;
    float m_outerGlowSize;
    
    BOOL m_bIsInnerGlowEnable;
    GPUVector3 m_innerGlowColor;
    float m_innerGlowColorAlpha;
    float m_innerGlowSize;
    
    LAYER_SHADOW m_sLayerShadow;
    BOOL m_bLayerShadowEnable;
    
    BOOL m_bHasRefresh;
    
}



- (id)initWithDocument:(id)doc forLayer:(id)ilayer;

- (id)initWithDelegate:(id)delegate;
- (void)setDelegateForEffect:(id)delegate;




- (void)setStrokeEnable:(BOOL)enable;
- (void)setStrokeColorRed:(float)red green:(float)green blue:(float)blue;
- (void)setStrokePositon:(int)nPosition;
- (void)setStrokeColorAlpha:(float)alpha;
- (void)setStrokeSize:(float)size;

- (void)setFillEnable:(BOOL)enable;
- (void)setFillColorRed:(float)red green:(float)green blue:(float)blue;
- (void)setFillColorAlpha:(float)alpha;


- (void)setOuterGlowEnable:(BOOL)enable;
- (void)setOuterGlowColorRed:(float)red green:(float)green blue:(float)blue;
- (void)setOuterGlowColorAlpha:(float)alpha;
- (void)setOuterGlowSize:(float)size;

- (void)setInnerGlowEnable:(BOOL)enable;
- (void)setInnerGlowColorRed:(float)red green:(float)green blue:(float)blue;
- (void)setInnerGlowColorAlpha:(float)alpha;
- (void)setInnerGlowSize:(float)size;

- (void)setShadowEnable:(BOOL)enable;
-(void)setShadow:(LAYER_SHADOW)sShadow;



- (BOOL)strokeIsEnable;
- (GPUVector3)getStrokeColor;
- (int)getStrokePositon;
- (float)getStrokeColorAlpha;
- (float)getStrokeSize;

- (BOOL)fillIsEnable;
- (GPUVector3)getFillColor;
- (float)getFillColorAlpha;


- (BOOL)outerGlowIsEnable;
- (GPUVector3)getOuterGlowColor;
- (float)getOuterGlowColorAlpha;
- (float)getOuterGlowSize;

- (BOOL)innerGlowIsEnable;
- (GPUVector3)getInnerGlowColor;
- (float)getInnerGlowColorAlpha;
- (float)getInnerGlowSize;

- (BOOL)shadowIsEnable;
-(LAYER_SHADOW)getShadow;


- (void)setChannelRedVisible:(BOOL)rvisible GreenVisible:(BOOL)gvisible BlueVisible:(BOOL)bvisible AlphaVisible:(BOOL)avisible;

- (BOOL)getEffectFilterIsEnable;
- (NSRect)getNeededRectForDistanceOfRect:(NSRect)srcRect;
- (NSRect)getNeededRectForEffectOfRect:(NSRect)srcRect;

- (NSRect)getEffectedRectForDistanceOfRect:(NSRect)srcRect;
- (NSRect)getEffectedRectForEffectOfRect:(NSRect)srcRect;

- (void)computeDistanceForImage:(unsigned char*)srcData width:(int)width height:(int)height spp:(int)spp radius:(float)radius distanceDes:(float*)distData;

- (void)computeDistanceFastWithImage:(unsigned char*)srcData srcDistance:(float*)srcDis originx:(int)originx originy:(int)originy width:(int)width height:(int)height srcWidth:(int)srcWidth srcHeight:(int)srcHeight spp:(int)spp radius:(float)radius distanceDes:(float*)distData extendInfo:(int)extendInfo effectState:(int*)effectState;

- (unsigned char*)getEffectResultForImage:(unsigned char*)srcData width:(int)width height:(int)height spp:(int)spp distanceInfo:(float*)distData effectState:(int*)effectState scale:(float)scale;

//message from ui
- (void)refreshEffect;
- (void)effectEventWillBegin;
- (void)cancelEffectEvent;
- (void)okEffectEvent;


//output info
- (BOOL)getLayerEffectEnable;





@end

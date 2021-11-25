//
//  PSSynthesizeImageRender.h
//  PixelStyle
//
//  Created by wyl on 16/1/5.
//
//

#import <Foundation/Foundation.h>

@interface PSSynthesizeImageRender : NSObject
{
    
    CGLayerRef m_cgLayerSynthesizedImage;
    
    NSThread *m_threadRenderImage;
    volatile bool m_bCanSynthesizeImage;
    volatile bool m_bFinishedThread;
    NSRecursiveLock *m_lockCGlayer;
    
    id m_idDocument;
}

-(id)initWithDocument:(id)document;
-(void)beginSynthesizeImageRender;
-(void)stopSynthesizeImageRender;
-(void)waitForStopSynthesizeImageRender;
-(void)resetSynthesizedImageCGlayer;

-(CGLayerRef)getSynthesizedImageCGlayer:(bool *)bWantUnlock;
-(void)unlockSynthesizedImageCGlayer;

-(void)shutdown;

@end

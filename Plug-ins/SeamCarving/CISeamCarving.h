//
//  CISeamCarving.h
//  SeamCarving
//
//  Created by Calvin on 8/17/16.
//  Copyright © 2016 EffectMatrix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@class PSPlugins;
@class MyImageView;

@interface CISeamCarving : NSObject<NSTextFieldDelegate>
{
    //the plugin's manager
    id                          m_idSeaPlugins;
    // show weather to jump out the seamCaving to stop the previous thread
    bool                        m_bStopThread;
    // YES if the application succeeded
    BOOL                        m_bSuccess;
}

-(id)initWithManager:(PSPlugins*)manager;

- (NSString *)name;

- (NSString *)groupName;

-(NSString*) sanity;

-(void)run;

-(void)reapply;

-(BOOL)canReapply;

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem;

@end

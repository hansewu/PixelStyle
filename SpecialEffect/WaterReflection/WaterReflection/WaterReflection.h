//
//  WaterReflection.h
//  WaterReflection
//
//  Created by lchzh on 1/3/16.
//  Copyright © 2016 lchzh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "PSPlugins.h"

#import "PSPreviewView.h"

@interface WaterReflection : NSObject
{
    // The plug-in's manager
    id seaPlugins;
    
    IBOutlet id panel;
    IBOutlet NSView* previewView;
    IBOutlet NSScrollView* preScrollView;
    
    unsigned char* m_desData;
    int m_nWidth;
    int m_nHeight;
    int m_nSpp;
    
}


- (id)initWithManager:(PSPlugins *)manager;
- (int)type;
- (NSString *)name;
- (NSString *)groupName;
- (NSString *)sanity;
- (void)run;
- (void)reapply;
- (BOOL)canReapply;
- (BOOL)validateMenuItem:(id)menuItem;


- (IBAction)apply:(id)sender;
- (IBAction)cancel:(id)sender;


@end

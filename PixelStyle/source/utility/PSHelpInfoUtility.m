//
//  PSHelpInfoUtility.m
//  PixelStyle
//
//  Created by lchzh on 6/1/16.
//
//

#import "PSHelpInfoUtility.h"

#import "PSController.h"
#import "UtilitiesManager.h"

@implementation PSHelpInfoUtility

- (void)awakeFromNib
{
    // Shown By Default
    [[PSController utilitiesManager] setHelpInfoUtility: self for:m_idDocument];
    
}


- (void)updateHelpInfo:(NSString*)info
{
    if (info == nil) {
        info = @"";
    }
    [m_idHelpInfo setStringValue:info];
    
}

@end

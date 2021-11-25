//
//  PSHelpInfoUtility.h
//  PixelStyle
//
//  Created by lchzh on 6/1/16.
//
//

#import <Foundation/Foundation.h>

@interface PSHelpInfoUtility : NSObject
{
    IBOutlet id m_idDocument;
    IBOutlet id m_idHelpInfo;
    
}

- (void)updateHelpInfo:(NSString*)info;

@end

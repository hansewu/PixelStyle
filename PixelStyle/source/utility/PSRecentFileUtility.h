//
//  PSRecentFileUtility.h
//  PixelStyle
//
//  Created by wyl on 16/6/21.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface PSRecentFileUtility : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *m_tableViewRecentFile;
}

-(void)updateRecentFile;

@end

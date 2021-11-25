//
//  ChannelView.h
//  PixelStyle
//
//  Created by wyl on 15/10/20.
//
//

#import <Cocoa/Cocoa.h>

@interface ChannelView : NSView<NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate>
{
    IBOutlet NSTableView *m_tableViewChannels;
    // The document this data source is connected to
    IBOutlet id m_idDocument;
}

-(void)updateUI;

@end

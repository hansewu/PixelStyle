//
//  PSAbout.h
//  PixelStyle
//
//  Created by wyl on 16/3/21.
//
//

#import "Globals.h"

@interface PSAbout : NSObject
{
    IBOutlet NSImageView    *m_imageViewIcon;
    IBOutlet NSTextField    *m_sProductName;
    IBOutlet NSTextField    *m_sProductVersion;
    IBOutlet NSTextField    *m_sRights;
    
    IBOutlet id             m_windowAbout;
    
    IBOutlet NSTextView     *m_textViewAboutInfo;
}

-(IBAction)showAboutWindow:(id)sender;

@end

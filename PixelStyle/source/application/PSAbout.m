//
//  PSAbout.m
//  PixelStyle
//
//  Created by wyl on 16/3/21.
//
//

#import "PSAbout.h"
#import "PSWindow.h"
#import "ConfigureInfo.h"

@implementation PSAbout

-(id)init
{
    self = [super init];
    
    return self;
}

-(void)updateView
{
    [m_imageViewIcon setImage:[NSImage imageNamed:@"AppIcon"]];
    
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    [m_sProductName setStringValue:sProductName];
    
    NSString *sProductVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *sProductVersion2 = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [m_sProductVersion setStringValue:[NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"Version", nil), sProductVersion, sProductVersion2]];
    
    NSString *sRights = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSHumanReadableCopyright"];
    [m_sRights setStringValue:sRights];
    
    NSString *sPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:README_FILE];
    [m_textViewAboutInfo readRTFDFromFile:sPath];
}

-(IBAction)showAboutWindow:(id)sender
{
    [self updateView];
    
    [(PSWindow *)m_windowAbout setLevel:NSFloatingWindowLevel];
    [(PSWindow *)m_windowAbout makeKeyAndOrderFront:self];
}

@end

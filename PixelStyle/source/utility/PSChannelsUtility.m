//
//  PSChannelsUtility.m
//  PixelStyle
//
//  Created by lchzh on 5/9/17.
//
//

#import "PSChannelsUtility.h"
#import "ChannelView.h"

#import "PSController.h"
#import "UtilitiesManager.h"

@implementation PSChannelsUtility


- (void)awakeFromNib
{
    [[PSController utilitiesManager] setChannelsUtility:self for:m_idDocument];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChannelView:) name:@"UPDATECHANNELVIEW" object:nil];
}

- (void)updateChannelView:(NSNotification*) notification
{
    if (notification.object != m_idDocument) {
        return;
    }
    [(ChannelView*)m_viewChannels updateUI];
}


- (void)shutdown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UPDATECHANNELVIEW" object:nil];
}

- (void)activate
{
    if([self visible]){
        [self update];
    }
}

- (void)deactivate
{
    
}

- (IBAction)show:(id)sender
{
//    [[[m_idDocument window] contentView] setVisibility: YES forRegion: kPointInformation];
    
}

- (IBAction)hide:(id)sender
{
//    [[[m_idDocument window] contentView] setVisibility: NO forRegion: kPointInformation];
}

- (IBAction)toggle:(id)sender
{
    if ([self visible]) {
        [self hide:sender];
    }
    else {
        [self show:sender];
    }
}




- (void)update
{
//    [self updateHistogramInfo];
//    [m_idHistogramView setNeedsDisplay:YES];
}

- (BOOL)visible
{
//    return [[[m_idDocument window] contentView] visibilityForRegion: kPointInformation];
    
    return YES;
}



@end

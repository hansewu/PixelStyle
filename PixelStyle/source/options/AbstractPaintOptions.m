#import "AbstractPaintOptions.h"

#import "PSController.h"
#import "UtilitiesManager.h"
#import "BrushUtility.h"
#import "TextureUtility.h"
#import "PSTexture.h"
#import "PSBrush.h"

@implementation AbstractPaintOptions
-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (IBAction)toggleTextures:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

- (IBAction)toggleBrushes:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[(BrushUtility *)[[PSController utilitiesManager] brushUtilityFor:gCurrentDocument] showPanelFrom: p onWindow: w];
}

-(void)update
{
    if([self useTextures])
    {
        NSImage *image = [[[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture] thumbnail];
        [m_imageViewTexture setImage:image];
    }
    else
        [m_imageViewTexture setImage:[NSImage imageNamed:@"texture-no"]];
    
    if(m_imageViewBrush)
        [m_imageViewBrush setImage:[[[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush] thumbnail]];
        
}

@end

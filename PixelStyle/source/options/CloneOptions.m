#import "CloneOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "CloneTool.h"
#import "PSDocument.h"
#import "PSTools.h"

@implementation CloneOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_imageViewBrush setToolTip:NSLocalizedString(@"Display the current brush", nil)];
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Brush Preset” Selector", nil)];
    [m_idMergedCheckbox setToolTip:NSLocalizedString(@"Define the selection mode for the sample point of clone tool", nil)];
    [m_idMakeSourceCheckbox setToolTip:NSLocalizedString(@"Set the source point for the clone stamp tool", nil)];
    
    [(NSButton *)m_idMergedCheckbox setTitle:NSLocalizedString(@"Use sample from all layer", nil)];
    
    [m_idMergedCheckbox setState:[gUserDefaults boolForKey:@"clone merged"]];
}

- (BOOL)mergedSample
{
	return [m_idMergedCheckbox state];
}

- (IBAction)mergedChanged:(id)sender
{
	id cloneTool = [[m_idDocument tools] getTool:kCloneTool];

	[cloneTool unset];
}

- (IBAction)makeSourceChanged:(id)sender
{
    if([m_idMakeSourceCheckbox state])
        m_enumModifier = kAltModifier;
    else
        m_enumModifier = kNoModifier;
}

- (void)updateModifiers:(unsigned int)modifiers
{
    [super updateModifiers:modifiers];
    int modifier = [super modifier];
    
    switch (modifier) {
        case kAltModifier:
        {
            [m_idMakeSourceCheckbox setState:YES];
            [self makeSourceChanged:m_idMakeSourceCheckbox];
        }
            break;
        case kNoModifier:
        {
            [m_idMakeSourceCheckbox setState:NO];
            [self makeSourceChanged:m_idMakeSourceCheckbox];
        }
            break;
        default:
            break;
    }
}

- (void)update
{
    [super update];
    
	id cloneTool = [[m_idDocument tools] getTool:kCloneTool];
	IntPoint sourcePoint;
	
	if ([cloneTool sourceSet]) {
		sourcePoint = [cloneTool sourcePoint:YES];
		if ([cloneTool sourceName] != NULL)
			[m_idSourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source set", @"Source: (%d, %d) from \"%@\""), sourcePoint.x, sourcePoint.y, [cloneTool sourceName]]];
		else
			[m_idSourceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"source set document", @"Source: (%d, %d) from whole document"), sourcePoint.x, sourcePoint.y]];
	}
	else {
		[m_idSourceLabel setStringValue:LOCALSTR(@"source unset", @"Source: Unset")];
	}
}

- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setObject:[self mergedSample] ? @"YES" : @"NO" forKey:@"clone merged"];
}

@end

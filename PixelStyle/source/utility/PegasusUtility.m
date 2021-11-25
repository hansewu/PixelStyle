#import "PegasusUtility.h"
#import "PSLayer.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "LayerSettings.h"
#import "PSHelpers.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "UtilitiesManager.h"
#import "PSProxy.h"
#import "PSWindowContent.h"
#import "ToolboxUtility.h"
#import "PSTools.h"

@implementation PegasusUtility

- (id)init
{
	return self;
}

- (void)awakeFromNib
{
    [m_idNewButton setToolTip:NSLocalizedString(@"Create a New Layer", nil)];
    [m_idDuplicateButton setToolTip:NSLocalizedString(@"Duplicate the Selected Layer", nil)];
    [m_idDeleteButton setToolTip:NSLocalizedString(@"Delete the Selected Layer", nil)];
    
    // Enable the utility
    m_bEnabled = YES;
    
    [[PSController utilitiesManager] setPegasusUtility: self for:m_idDocument];
}

- (void)dealloc
{
	//if ([m_idLayersView documentView]) [[m_idLayersView documentView] autorelease];
	[super dealloc];
}

- (void)activate
{
	// Get the LayersView and LayerSettings to activate
	[(LayerSettings *)m_idLayerSettings activate];
	[self update:kPegasusUpdateAll];
}

- (void)deactivate
{
	// Get the LayersView and LayerSettings to deactivate
	[m_idLayerSettings deactivate];
	[self update:kPegasusUpdateAll];
}

- (void)update:(int)updateCode
{
	id layer = [[m_idDocument contents] activeLayer];
	
	switch (updateCode) {
		case kPegasusUpdateAll:
			if (m_idDocument && layer && m_bEnabled) {
				// Enable the layer buttons
				[m_idNewButton setEnabled:YES];
				[m_idDuplicateButton setEnabled:YES];
				[m_idUpButton setEnabled:YES];
				[m_idDownButton setEnabled:YES];
				[m_idDeleteButton setEnabled:YES];
			}
			else {
				// Disable the layer buttons
				[m_idNewButton setEnabled:NO];
				[m_idDuplicateButton setEnabled:NO];
				[m_idUpButton setEnabled:NO];
				[m_idDownButton setEnabled:NO];
				[m_idDeleteButton setEnabled:NO];
			}
		break;
	}
	[m_idDataSource update];
    [m_idLayerSettings changeLayerSettingsAfterUpdateActiveLayer];
}

- (id)layerSettings
{
	return m_idLayerSettings;
}

- (IBAction)show:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility: YES forRegion: kSidebar];
}

- (IBAction)hide:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility: NO forRegion: kSidebar];
}

- (void)setEnabled:(BOOL)value
{
	m_bEnabled = value;
	[self update:kPegasusUpdateAll];
}

- (IBAction)toggleLayers:(id)sender
{
	if ([self visible])
		[self hide:sender];
	else
		[self show:sender];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	id layer = [[m_idDocument contents] activeLayer];
	
	// Switch to the appropriate code block given menu item
	switch ([menuItem tag]) {
		case 1002:
			if (![layer hasAlpha])
				return NO;
		break;
	}
	
	return YES;
}

- (BOOL)visible
{
	return [[[m_idDocument window] contentView] visibilityForRegion: kSidebar];
}

- (IBAction)addLayer:(id)sender
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if(curToolIndex == kShapeTool || (curToolIndex == kVectorPenTool))
        [(PSContent*)[m_idDocument contents] addVectorLayer:kActiveLayer];
	else
        [(PSContent*)[m_idDocument contents] addLayer:kActiveLayer];
}

- (IBAction)duplicateLayer:(id)sender
{
	id selection = [m_idDocument selection];
	
	if (![selection floating]) {
		[(PSContent *)[m_idDocument contents] duplicateLayer:kActiveLayer];
	}
}

- (IBAction)deleteLayer:(id)sender
{
    @autoreleasepool
    {
        if ([[m_idDocument contents] layerCount] > 1){
//            [(PSContent *)[m_idDocument contents] deleteLayer];
            [(PSContent *)[m_idDocument contents] deleteLayer:kActiveLayer];
        }else{
            NSBeep();
        }
    }
}

@end

#import "EffectOptions.h"
#import "PSController.h"
#import "PSPlugins.h"
#import "PSTools.h"
#import "PluginClass.h"
#import "InfoPanel.h"


@implementation EffectOptions
- (void)awakeFromNib
{
    [super awakeFromNib];
    
	int effectIndex;
	m_idParentWin = nil;
	NSArray *pointPlugins = [[PSController seaPlugins] pointPlugins];
	if ([pointPlugins count]) {
		if ([gUserDefaults objectForKey:@"effectIndex"]) effectIndex = [gUserDefaults integerForKey:@"effectIndex"];
		else effectIndex = 0;
		if (effectIndex < 0 || effectIndex >= [pointPlugins count]) effectIndex = 0;

		[m_idEffectTable noteNumberOfRowsChanged];
		[m_idEffectTable selectRowIndexes:[NSIndexSet indexSetWithIndex:effectIndex] byExtendingSelection:NO];
		[m_idEffectTable scrollRowToVisible:effectIndex];
		[m_idEffectTableInstruction setStringValue:[[pointPlugins objectAtIndex:effectIndex] instruction]];
		[m_idClickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [[pointPlugins objectAtIndex:effectIndex] points]]];
		[(InfoPanel *)m_idPanel setPanelStyle:kVerticalPanelStyle];
    }	
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	return [[[PSController seaPlugins] pointPluginsNames] objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[[PSController seaPlugins] pointPluginsNames] count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSArray *pointPlugins = [[PSController seaPlugins] pointPlugins];
	[m_idEffectTableInstruction setStringValue:[[pointPlugins objectAtIndex:[(NSTableView *)m_idEffectTable selectedRow]] instruction]];
	[[[gCurrentDocument tools] getTool:kEffectTool] reset];
}

- (int)selectedRow
{
	return [(NSTableView *)m_idEffectTable selectedRow];
}

- (IBAction)updateClickCount:(id)sender
{
	[m_idClickCountLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"click count", @"Clicks remaining: %d"), [[[[PSController seaPlugins] pointPlugins] objectAtIndex:[(NSTableView *)m_idEffectTable selectedRow]] points] - [[[gCurrentDocument tools] getTool:kEffectTool] clickCount]]];
}

- (IBAction)showEffects:(id)sender
{
	NSWindow *w = [gCurrentDocument window];
	NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
	[m_idPanel orderFrontToGoal:p onWindow: w];
	m_idParentWin = w;
	
	[NSApp runModalForWindow:m_idPanel];
}

- (IBAction)closeEffects:(id)sender
{

	[NSApp stopModal];
	if (m_idParentWin){
		[m_idParentWin removeChildWindow:m_idPanel];
		m_idParentWin = NULL;
	}
	[m_idPanel orderOut:self];	
}

@end

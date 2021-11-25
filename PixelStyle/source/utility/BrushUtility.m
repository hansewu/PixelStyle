#import "BrushUtility.h"
#import "BrushView.h"
#import "PSBrush.h"
#import "UtilitiesManager.h"
#import "PSController.h"
#import "InfoPanel.h"

#ifdef TODO
#warning Make brushes lazy, that is if they are not in the active group they are not memory
#endif

@implementation BrushUtility

- (id)init
{
    self = [super init];
    
	// Load the brushes
	[self loadBrushes:NO];
	
	// Determine the currently active brush group
	if ([gUserDefaults objectForKey:@"active brush group"] == NULL)
		m_nActiveGroupIndex = 0;
	else
		m_nActiveGroupIndex = [gUserDefaults integerForKey:@"active brush group"];
	if (m_nActiveGroupIndex < 0 || m_nActiveGroupIndex >= [m_arrGroups count])
		m_nActiveGroupIndex = 0;
		
	// Determine the currently active brush 	
	if ([gUserDefaults objectForKey:@"active brush"] == NULL)
		m_nActiveBrushIndex = 12;
	else
		m_nActiveBrushIndex = [gUserDefaults integerForKey:@"active brush"];
	if (m_nActiveBrushIndex < 0 || m_nActiveBrushIndex >= [[m_arrGroups objectAtIndex:m_nActiveGroupIndex] count])
		m_nActiveBrushIndex = 0;
	
	return self;
}

- (void)awakeFromNib
{
	int yoff, i;

	[super awakeFromNib];
	
    [m_labelSpacing setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Spacing", nil)]];
    [m_idSpacingLabel setToolTip:NSLocalizedString(@"Space between brush plots", nil)];
    [m_idBrushGroupPopUp setToolTip:NSLocalizedString(@"Brush group", nil)];
    
	// Configure the view
	[m_idView setHasVerticalScroller:YES];
	[m_idView setBorderType:NSGrooveBorder];
	[m_idView setDocumentView:[[BrushView alloc] initWithMaster:self]];
	[m_idView setBackgroundColor:[NSColor lightGrayColor]];
	if ([[m_idView documentView] bounds].size.height > 3 * kBrushPreviewSize) {
		yoff = MIN((m_nActiveBrushIndex / kBrushesPerRow) * kBrushPreviewSize, ([[self brushes] count] / kBrushesPerRow - 2) * kBrushPreviewSize);
		[[m_idView contentView] scrollToPoint:NSMakePoint(0, yoff)];
	}
	[m_idView reflectScrolledClipView:[m_idView contentView]];
	[m_idView setLineScroll:kBrushPreviewSize];
	
	// Configure the pop-up menu
	[m_idBrushGroupPopUp removeAllItems];
    
	[m_idBrushGroupPopUp addItemWithTitle:NSLocalizedString([m_arrGroupNames objectAtIndex:0], nil)];
	[[m_idBrushGroupPopUp itemAtIndex:0] setTag:0];
	if (m_nCustomGroups != 0) {
		[[m_idBrushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
		for (i = 1; i < m_nCustomGroups + 1; i++) {
			[m_idBrushGroupPopUp addItemWithTitle:NSLocalizedString([m_arrGroupNames objectAtIndex:i],nil)];
			[[m_idBrushGroupPopUp itemAtIndex:[[m_idBrushGroupPopUp menu] numberOfItems] - 1] setTag:i];
		}
	}
	[[m_idBrushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = m_nCustomGroups + 1; i < [m_arrGroupNames count]; i++) {
		[m_idBrushGroupPopUp addItemWithTitle:NSLocalizedString([m_arrGroupNames objectAtIndex:i],nil)];
		[[m_idBrushGroupPopUp itemAtIndex:[[m_idBrushGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[m_idBrushGroupPopUp selectItemAtIndex:[m_idBrushGroupPopUp indexOfItemWithTag:m_nActiveGroupIndex]];
	
	// Inform the brush that it is active
	[self setActiveBrushIndex:m_nActiveBrushIndex];
	
	// Set the window's properties
	[(InfoPanel *)m_winWindow setPanelStyle:kVerticalPanelStyle];
	
	[[PSController utilitiesManager] setBrushUtility: self for:m_idDocument];
}

- (void)dealloc
{
	int i;
	
	// Release any existing brushes
	if (m_dicBrushes) {
		for (i = 0; i < [m_dicBrushes count]; i++)
			[[[m_dicBrushes allValues] objectAtIndex:i] autorelease];
		[m_dicBrushes autorelease];
	}
	if (m_arrGroups) [m_arrGroups autorelease];
	if (m_arrGroupNames) [m_arrGroupNames autorelease];
	if ([m_idView documentView]) [[m_idView documentView] autorelease];
	[super dealloc];
}

- (void)shutdown
{
	[gUserDefaults setInteger:m_nActiveBrushIndex forKey:@"active brush"];
	[gUserDefaults setInteger:m_nActiveGroupIndex forKey:@"active brush group"];
}

- (void)activate:(id)sender
{
	m_idDocument = sender;
}

- (void)deactivate
{
	m_idDocument = NULL;
}

- (void)update
{
	m_nActiveGroupIndex = [[m_idBrushGroupPopUp selectedItem] tag];
	if (m_nActiveGroupIndex >= [m_arrGroups count])
		m_nActiveGroupIndex = 0;
	if (m_nActiveBrushIndex >= [[m_arrGroups objectAtIndex:m_nActiveGroupIndex] count])
		m_nActiveBrushIndex = 0;
	[self setActiveBrushIndex:m_nActiveBrushIndex];
	[[m_idView documentView] update];
	[m_idView setNeedsDisplay:YES];
}

// Apologies for the bad code in the next method

- (void)loadBrushes:(BOOL)update
{
	NSArray *files;
	NSString *tempPathA, *tempPathB;
	NSArray *newValues, *newKeys, *tempBrushArray, *tempArray;
	BOOL isDirectory;
	id tempBrush;
	int i, j;
	
	// Release any existing brushes
	if (m_dicBrushes) {
		for (i = 0; i < [m_dicBrushes count]; i++)
			[[[m_dicBrushes allValues] objectAtIndex:i] autorelease];
		[m_dicBrushes autorelease];
	}
	if (m_arrGroups) [m_arrGroups autorelease];
	if (m_arrGroupNames) [m_arrGroupNames autorelease];
	
	// Create a dictionary of all brushes
	m_dicBrushes = [NSDictionary dictionary];
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/brushes"]];
	for (i = 0; i < [files count]; i++) {
		tempPathA = [[[gMainBundle resourcePath] stringByAppendingString:@"/brushes/"] stringByAppendingString:[files objectAtIndex:i]];
        //NSLog(@"tempPathA %@",tempPathA);
		if ([[tempPathA pathExtension] isEqualToString:@"gbr"]) {
			tempBrush = [[PSBrush alloc] initWithContentsOfFile:tempPathA];
			if (tempBrush) {
				newKeys = [[m_dicBrushes allKeys] arrayByAddingObject:tempPathA];
				newValues = [[m_dicBrushes allValues] arrayByAddingObject:tempBrush];
				m_dicBrushes = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
			}
		}
	}
	[m_dicBrushes retain];
	
	// Create the all group
	tempBrushArray = [[m_dicBrushes allValues] sortedArrayUsingSelector:@selector(compare:)];
	m_arrGroups = [NSArray arrayWithObject:tempBrushArray];
	m_arrGroupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
	
	// Create the custom groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/brushes"]];
	for (i = 0; i < [files count]; i++) {
		tempPathA = [[gMainBundle resourcePath] stringByAppendingString:@"/brushes/"];
		tempPathB = [tempPathA stringByAppendingString:[files objectAtIndex:i]];
		if ([[tempPathB pathExtension] isEqualToString:@"txt"]) {
			tempArray = [NSArray arrayWithContentsOfFile:tempPathB];
			if (tempArray) {
				tempBrushArray = [NSArray array];
				for (j = 0; j < [tempArray count]; j++) {
					tempBrush = [m_dicBrushes objectForKey:[tempPathA stringByAppendingString:[tempArray objectAtIndex:j]]];
					if (tempBrush) {
						tempBrushArray = [tempBrushArray arrayByAddingObject:tempBrush];
					}
				}
				if ([tempBrushArray count] > 0) {
					m_arrGroups = [m_arrGroups arrayByAddingObject:tempBrushArray];
					m_arrGroupNames = [m_arrGroupNames arrayByAddingObject:[[tempPathB lastPathComponent] stringByDeletingPathExtension]];
				}
			}	
		}
	}
	m_nCustomGroups = [m_arrGroups count] - 1;
	
	// Create the other groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/brushes"]];
	for (i = 0; i < [files count]; i++) {
		tempPathA = [[[gMainBundle resourcePath] stringByAppendingString:@"/brushes/"] stringByAppendingString:[files objectAtIndex:i]];
		[gFileManager fileExistsAtPath:tempPathA isDirectory:&isDirectory];
		if (isDirectory) {
			tempPathA = [tempPathA stringByAppendingString:@"/"];
			tempArray = [gFileManager subpathsAtPath:tempPathA];
			tempBrushArray = [NSArray array];
			for (j = 0; j < [tempArray count]; j++) {
				tempBrush = [m_dicBrushes objectForKey:[tempPathA stringByAppendingString:[tempArray objectAtIndex:j]]];
				if (tempBrush) {
					tempBrushArray = [tempBrushArray arrayByAddingObject:tempBrush];
				}
			}
			if ([tempBrushArray count] > 0) {
				tempBrushArray = [tempBrushArray sortedArrayUsingSelector:@selector(compare:)];
				m_arrGroups = [m_arrGroups arrayByAddingObject:tempBrushArray];
				m_arrGroupNames = [m_arrGroupNames arrayByAddingObject:[tempPathA lastPathComponent]];
			}
		}
	}
	
	// Retain the groups and groupNames
	[m_arrGroups retain];
	[m_arrGroupNames retain];
	
	// Update utility if requested
	if (update) [self update];
}

- (IBAction)changeSpacing:(id)sender
{
//	[m_idSpacingLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"spacing", @"Spacing: %d%%"), [self spacing]]];
    [m_idSpacingLabel setIntValue: [self spacing]];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (int)spacing
{
	return ([m_idSpacingSlider intValue] / 5 * 5 == 0) ? 1 : [m_idSpacingSlider intValue] / 5 * 5;
}

- (id)activeBrush
{
	return [[m_arrGroups objectAtIndex:m_nActiveGroupIndex] objectAtIndex:m_nActiveBrushIndex];
}

- (int)activeBrushIndex
{
	return m_nActiveBrushIndex;
}

- (void)setActiveBrushIndex:(int)index
{
	id oldBrush = [[m_arrGroups objectAtIndex:m_nActiveGroupIndex] objectAtIndex:m_nActiveBrushIndex];
	id newBrush = [[m_arrGroups objectAtIndex:m_nActiveGroupIndex] objectAtIndex:index];
	
	[oldBrush deactivate];
	m_nActiveBrushIndex = index;
	[m_idBrushNameLabel setStringValue:[newBrush name]];
	[m_idSpacingSlider setIntValue:[newBrush spacing]];
    [m_idSpacingLabel setIntValue: [self spacing]];
	[newBrush activate];
    
    [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] update];
}

- (NSArray *)brushes
{
	return [m_arrGroups objectAtIndex:m_nActiveGroupIndex];
}

- (NSArray *)allBrushes
{
    return [m_arrGroups objectAtIndex:0];
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    int nValue = [textField intValue];
    
    if(nValue < [(NSSlider *)m_idSpacingSlider minValue]) nValue = [(NSSlider *)m_idSpacingSlider minValue];
    else if (nValue > [(NSSlider *)m_idSpacingSlider maxValue]) nValue = [(NSSlider *)m_idSpacingSlider maxValue];
    
    [m_idSpacingLabel setIntValue:nValue];
    [m_idSpacingSlider setIntValue:nValue];
    
    
    return YES;
}

@end

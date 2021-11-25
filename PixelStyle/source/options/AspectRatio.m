#import "AspectRatio.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "Units.h"

#define customItemIndex 3

@implementation AspectRatio

- (void)awakeWithMaster:(id)imaster andString:(id)iprefString
{
    [m_idRatioPopup setToolTip:NSLocalizedString(@"Set the drawing shape of marquee tool", nil)];
    [m_idRatioLabel setStringValue:[NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Aspect ratio", nil)]];
    
    NSMenuItem *menuItem = [(NSPopUpButton *)m_idRatioPopup itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Normal", nil)];
    menuItem = [(NSPopUpButton *)m_idRatioPopup itemAtIndex:5];
    [menuItem setTitle:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"Custom", nil)]];
    [(NSButton *)m_idSet setTitle:NSLocalizedString(@"Set", nil)];
    
	int ratioIndex;
	id customItem;
	
	m_idMaster = imaster;
	m_idPrefString = iprefString;

//	[m_idRatioCheckbox setState:NSOffState];
//	[m_idRatioPopup setEnabled:[m_idRatioCheckbox state]];
//    [m_idRatioPopup setStringValue:<#(NSString * _Nullable)#>];
	
	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio index", m_idPrefString]] == NULL) {
		[m_idRatioPopup selectItemAtIndex:0];
	}
	else {
		ratioIndex = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio index", m_idPrefString]];
		if (ratioIndex < 0 || ratioIndex > customItemIndex) ratioIndex = 1;
		[m_idRatioPopup selectItemAtIndex:ratioIndex];
	}

	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio horiz", m_idPrefString]] == NULL) {
		m_fRatioX = 2.0;
	}
	else {
		m_fRatioX = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio horiz", m_idPrefString]];
	}
	
	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio vert", m_idPrefString]] == NULL) {
		m_fRatioY = 1.0;
	}
	else {
		m_fRatioY = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio vert", m_idPrefString]];
	}
	
	if ([gUserDefaults objectForKey:[NSString stringWithFormat:@"%@ ratio type", m_idPrefString]] == NULL) {
		m_nAspectType = kRatioAspectType;
	}
	else {
		m_nAspectType = [gUserDefaults integerForKey:[NSString stringWithFormat:@"%@ ratio type", m_idPrefString]];
	}
	
	customItem = [m_idRatioPopup itemAtIndex:customItemIndex];
	switch (m_nAspectType) {
		case kRatioAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g to %g", m_fRatioX, m_fRatioY]];
		break;
		case kExactPixelAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%d by %d px", (int)m_fRatioX, (int)m_fRatioY]];
		break;
		case kExactInchAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g in", m_fRatioX, m_fRatioY]];
		break;
		case kExactMillimeterAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g mm", m_fRatioX, m_fRatioY]];
		break;
	}

	m_fForgotX = 472;
	m_fForgotY = 364;
}

- (IBAction)setCustomItem:(id)sender
{
	[m_idXRatioValue setStringValue:[NSString stringWithFormat:@"%g", m_fRatioX]];
	[m_idYRatioValue setStringValue:[NSString stringWithFormat:@"%g", m_fRatioY]];
	switch (m_nAspectType) {
		case kRatioAspectType:
			[m_idToLabel setStringValue:@"to"];
			[m_idAspectTypePopup selectItemAtIndex:0];
		break;
		case kExactPixelAspectType:
			[m_idToLabel setStringValue:@"by"];
			[m_idAspectTypePopup selectItemAtIndex:1];
		break;
		case kExactInchAspectType:
			[m_idToLabel setStringValue:@"by"];
			[m_idAspectTypePopup selectItemAtIndex:2];
		break;
		case kExactMillimeterAspectType:
			[m_idToLabel setStringValue:@"by"];
			[m_idAspectTypePopup selectItemAtIndex:3];
		break;
	}
	
	[m_idPanel center];
	[m_idPanel makeFirstResponder:m_idXRatioValue];
	[NSApp beginSheet:m_idPanel modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)applyCustomItem:(id)sender
{
	id customItem;
	
	if (m_nAspectType == kExactPixelAspectType) {
		m_fRatioX = [m_idXRatioValue intValue];
		m_fRatioY = [m_idYRatioValue intValue];
	}
	else {
		m_fRatioX = [m_idXRatioValue floatValue];
		m_fRatioY = [m_idYRatioValue floatValue];
	}
	customItem = [m_idRatioPopup itemAtIndex:customItemIndex];
	switch (m_nAspectType) {
		case kRatioAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g to %g", m_fRatioX, m_fRatioY]];
		break;
		case kExactPixelAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%d by %d px", (int)m_fRatioX, (int)m_fRatioY]];
		break;
		case kExactInchAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g in", m_fRatioX, m_fRatioY]];
		break;
		case kExactMillimeterAspectType:
			[customItem setTitle:[NSString stringWithFormat:@"%g by %g mm", m_fRatioX, m_fRatioY]];
		break;
	}
	[NSApp stopModal];
	[NSApp endSheet:m_idPanel];
	[m_idPanel orderOut:self];
	[m_idRatioPopup selectItemAtIndex:customItemIndex];
}

- (IBAction)changeCustomAspectType:(id)sender
{
	float xres = [[gCurrentDocument contents] xres], yres = [[gCurrentDocument contents] yres];
	int oldType;
	
	oldType = m_nAspectType;
	m_nAspectType = [m_idAspectTypePopup indexOfSelectedItem] - 1;
	if (oldType != kRatioAspectType) {
		m_fForgotX = PixelsFromFloat([m_idXRatioValue floatValue], oldType, xres);
		m_fForgotY = PixelsFromFloat([m_idYRatioValue floatValue], oldType, yres);
	}
	switch (m_nAspectType) {
		case kRatioAspectType:
			m_fRatioX = 2;
			m_fRatioY = 1;
			[m_idXRatioValue setStringValue:[NSString stringWithFormat:@"%d", (int)m_fRatioX]];
			[m_idYRatioValue setStringValue:[NSString stringWithFormat:@"%d", (int)m_fRatioY]];
			[m_idToLabel setStringValue:@"to"];
			[m_idAspectTypePopup setTitle:@"ratio"];
		break;
		case kExactPixelAspectType:
			[m_idXRatioValue setStringValue:StringFromPixels(m_fForgotX, m_nAspectType, xres)];
			[m_idYRatioValue setStringValue:StringFromPixels(m_fForgotY, m_nAspectType, yres)];
			m_fRatioX = [m_idXRatioValue floatValue];
			m_fRatioY = [m_idYRatioValue floatValue];
			[m_idToLabel setStringValue:@"by"];
			[m_idAspectTypePopup setTitle:@"px"];
		break;
		case kExactInchAspectType:
			[m_idXRatioValue setStringValue:StringFromPixels(m_fForgotX, m_nAspectType, xres)];
			[m_idYRatioValue setStringValue:StringFromPixels(m_fForgotY, m_nAspectType, yres)];
			m_fRatioX = [m_idXRatioValue floatValue];
			m_fRatioY = [m_idYRatioValue floatValue];
			[m_idToLabel setStringValue:@"by"];
			[m_idAspectTypePopup setTitle:@"in"];
		break;
		case kExactMillimeterAspectType:
			[m_idXRatioValue setStringValue:StringFromPixels(m_fForgotX, m_nAspectType, xres)];
			[m_idYRatioValue setStringValue:StringFromPixels(m_fForgotY, m_nAspectType, yres)];
			m_fRatioX = [m_idXRatioValue floatValue];
			m_fRatioY = [m_idYRatioValue floatValue];
			[m_idToLabel setStringValue:@"by"];
			[m_idAspectTypePopup setTitle:@"mm"];
		break;
	}
}

- (NSSize)ratio
{
	NSSize result;
	
	switch ([m_idRatioPopup indexOfSelectedItem]) {
		case 1:
			result = NSMakeSize(1.0, 1.0);
		break;
		case 2:
			result = NSMakeSize(4.0 / 3.0, 3.0 / 4.0);
		break;
		case 3:
			if (m_nAspectType == kRatioAspectType)
				result = NSMakeSize(m_fRatioX / m_fRatioY, m_fRatioY / m_fRatioX);
			else if (m_nAspectType == kExactPixelAspectType)
				result = NSMakeSize((int)m_fRatioX, (int)m_fRatioY);
			else
				result = NSMakeSize(m_fRatioX, m_fRatioY);
		break;
		default:
			result = NSMakeSize(1.0, 1.0);
		break;
	}

	if (result.width <= 0.0) result.width = 1.0;
	if (result.height <= 0.0) result.height = 1.0;
	
	return result;
}

- (int)aspectType
{
	int result;
	
    if ([m_idRatioPopup indexOfSelectedItem] == 0)
        result = kNoAspectType;
    else if ([m_idRatioPopup indexOfSelectedItem] < customItemIndex)
        result = kRatioAspectType;
    else
        result = m_nAspectType;
    
//	if ([m_idRatioCheckbox state]) {
//		if ([m_idRatioPopup indexOfSelectedItem] < customItemIndex)
//			result = kRatioAspectType;
//		else
//			result = m_nAspectType;
//	}
//	else {
//		result = kNoAspectType;
//	}
	
	return result;
}

- (IBAction)update:(id)sender;
{
//	[m_idRatioPopup setEnabled:[m_idRatioCheckbox state]];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[m_idRatioPopup indexOfSelectedItem] forKey:[NSString stringWithFormat:@"%@ ratio index", m_idPrefString]];
	[gUserDefaults setFloat:m_fRatioX forKey:[NSString stringWithFormat:@"%@ ratio horiz", m_idPrefString]];
	[gUserDefaults setFloat:m_fRatioY forKey:[NSString stringWithFormat:@"%@ ratio vert", m_idPrefString]];
	[gUserDefaults setInteger:m_nAspectType forKey:[NSString stringWithFormat:@"%@ ratio type", m_idPrefString]];
}

@end

#import "TextureUtility.h"
#import "TextureView.h"
#import "PSTexture.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSPrefs.h"
#import "PSProxy.h"
#import "InfoPanel.h"
#import "TextTool.h"
#import "PSDocument.h"
#import "PSTools.h"

#ifdef TODO
#warning Make textures lazy, that is if they are not in the active group they are not memory
#endif

@implementation TextureUtility

- (id)init
{
    self = [super init];
	// Load the textures
	[self loadTextures:NO];
	
	// Determine the currently active texture group
	if ([gUserDefaults objectForKey:@"active texture group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [gUserDefaults integerForKey:@"active texture group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		
	// Determine the currently active texture 	
	if ([gUserDefaults objectForKey:@"active texture"] == NULL)
		activeTextureIndex = 0;
	else
		activeTextureIndex = [gUserDefaults integerForKey:@"active texture"];
	if (activeTextureIndex < 0 || activeTextureIndex >= [[groups objectAtIndex:activeGroupIndex] count])
		activeTextureIndex = 0;
		
	// Set the opacity
	[m_idOpacitySlider setIntValue:100];
//	[m_idOpacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [m_idOpacitySlider intValue]]];
    [m_idOpacityLabel setIntValue: [m_idOpacitySlider intValue]];
	opacity = 255;
	
	return self;
}

- (void)awakeFromNib
{
	int yoff, i;
	
	[super awakeFromNib];

	// Configure the view
    [m_labelOpacity setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [m_idOpacitySlider setToolTip:NSLocalizedString(@"Texture opacity", nil)];
    [m_idTextureGroupPopUp setToolTip:NSLocalizedString(@"Texture group", nil)];
    
	[m_idView setHasVerticalScroller:YES];
	[m_idView setBorderType:NSGrooveBorder];
	[m_idView setDocumentView:[[TextureView alloc] initWithMaster:self]];
	[m_idView setBackgroundColor:[NSColor lightGrayColor]];
	if ([[m_idView documentView] bounds].size.height > 3 * kTexturePreviewSize) {
		yoff = MIN((activeTextureIndex / kTexturesPerRow) * kTexturePreviewSize, ([[self textures] count] / kTexturesPerRow - 2) * kTexturePreviewSize);
		[[m_idView contentView] scrollToPoint:NSMakePoint(0, yoff)];
	}
	[m_idView reflectScrolledClipView:[m_idView contentView]];
	[m_idView setLineScroll:kTexturePreviewSize];
	
	// Configure the pop-up menu
	[m_idTextureGroupPopUp removeAllItems];
	[m_idTextureGroupPopUp addItemWithTitle:NSLocalizedString([groupNames objectAtIndex:0],nil)];
	[[m_idTextureGroupPopUp itemAtIndex:0] setTag:0];
	[[m_idTextureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[m_idTextureGroupPopUp addItemWithTitle:NSLocalizedString([groupNames objectAtIndex:i],nil)];
		[[m_idTextureGroupPopUp itemAtIndex:[[m_idTextureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[m_idTextureGroupPopUp selectItemAtIndex:[m_idTextureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Inform the texture that it is active
	[self setActiveTextureIndex:-1];

	[[PSController utilitiesManager] setTextureUtility: self for:m_idDocument];
}

- (void)dealloc
{
	int i;
	
	// Release any existing textures
	if (m_dicTextures) {
		for (i = 0; i < [m_dicTextures count]; i++)
			[[[m_dicTextures allValues] objectAtIndex:i] autorelease];
		[m_dicTextures autorelease];
	}
	if (groups) [groups autorelease];
	if (groupNames) [groupNames autorelease];
	if ([m_idView documentView]) [[m_idView documentView] autorelease];
	[super dealloc];
}

- (void)activate:(id)sender
{
	m_idDocument = sender;
}

- (void)deactivate
{
	m_idDocument = NULL;
}

- (void)shutdown
{
	[gUserDefaults setInteger:activeTextureIndex forKey:@"active texture"];
	[gUserDefaults setInteger:activeGroupIndex forKey:@"active texture group"];

}

- (void)update
{
	activeGroupIndex = [[m_idTextureGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
	if (activeTextureIndex >= [[groups objectAtIndex:activeGroupIndex] count])
		activeTextureIndex = 0;
	[self setActiveTextureIndex:activeTextureIndex];
	[[m_idView documentView] update];
	[m_idView setNeedsDisplay:YES];
}

- (void)loadTextures:(BOOL)update
{
	NSArray *files, *subfiles, *newValues, *newKeys, *array;
	NSString *path;
	BOOL isDirectory;
	id texture;
	int i, j;
	
	// Release any existing textures
	if (m_dicTextures) {
		for (i = 0; i < [m_dicTextures count]; i++)
			[[[m_dicTextures allValues] objectAtIndex:i] autorelease];
		[m_dicTextures autorelease];
	}
	if (groups) [groups autorelease];
	if (groupNames) [groupNames autorelease];
	
	// Create a dictionary of all textures
	m_dicTextures = [NSDictionary dictionary];
    
    NSString *applcationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *customTextureDir = [NSString stringWithFormat:@"%@/%@", applcationSupport, bundleIdentifier];
    NSArray *textureDirs = [NSArray arrayWithObjects:[gMainBundle resourcePath], customTextureDir, nil];
    for (int index = 0; index < [textureDirs count]; index++) {
        NSString *rootPath = [textureDirs objectAtIndex:index];
        files = [gFileManager subpathsAtPath:[rootPath stringByAppendingString:@"/textures"]];
        for (i = 0; i < [files count]; i++) {
            path = [[rootPath stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
            texture = [[PSTexture alloc] initWithContentsOfFile:path];
            if (texture) {
                newKeys = [[m_dicTextures allKeys] arrayByAddingObject:path];
                newValues = [[m_dicTextures allValues] arrayByAddingObject:texture];
                m_dicTextures = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
            }
        }
        [m_dicTextures retain];
    }
	
//    files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/textures"]];
//	for (i = 0; i < [files count]; i++) {
//		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
//		texture = [[PSTexture alloc] initWithContentsOfFile:path];
//		if (texture) {
//			newKeys = [[m_dicTextures allKeys] arrayByAddingObject:path];
//			newValues = [[m_dicTextures allValues] arrayByAddingObject:texture];
//			m_dicTextures = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
//		}
//	}
//	[m_dicTextures retain];
//    
//    
//    files = [gFileManager subpathsAtPath:[customTextureDir stringByAppendingString:@"/textures"]];
//    for (i = 0; i < [files count]; i++) {
//        path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
//        texture = [[PSTexture alloc] initWithContentsOfFile:path];
//        if (texture) {
//            newKeys = [[m_dicTextures allKeys] arrayByAddingObject:path];
//            newValues = [[m_dicTextures allValues] arrayByAddingObject:texture];
//            m_dicTextures = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
//        }
//    }
//    [m_dicTextures retain];
    
    
	
	// Create the all group
	array = [[m_dicTextures allValues] sortedArrayUsingSelector:@selector(compare:)];
	groups = [NSArray arrayWithObject:array];
	groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
	
	// Create the other groups
	
    
    for (int index = 0; index < [textureDirs count]; index++) {
        NSString *rootPath = [textureDirs objectAtIndex:index];
        files = [gFileManager subpathsAtPath:[rootPath stringByAppendingString:@"/textures"]];
        [files sortedArrayUsingSelector:@selector(compare:)];
        for (i = 0; i < [files count]; i++) {
            path = [[rootPath stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
            [gFileManager fileExistsAtPath:path isDirectory:&isDirectory];
            if (isDirectory) {
                path = [path stringByAppendingString:@"/"];
                subfiles = [gFileManager subpathsAtPath:path];
                array = [NSArray array];
                BOOL hasGroup = NO;
                int groupIndex = -1;
                for (int i = 0; i < [groupNames count]; i++) {
                    if ([[path lastPathComponent] isEqualToString:[groupNames objectAtIndex:i]]) {
                        hasGroup = YES;
                        array = [groups objectAtIndex:i];
                        groupIndex = i;
                        break;
                    }
                }
                for (j = 0; j < [subfiles count]; j++) {
                    texture = [m_dicTextures objectForKey:[path stringByAppendingString:[subfiles objectAtIndex:j]]];
                    if (texture) {
                        array = [array arrayByAddingObject:texture];
                    }
                }
                if ([array count] > 0) {
                    array = [array sortedArrayUsingSelector:@selector(compare:)];
                    if (!hasGroup) {
                        groups = [groups arrayByAddingObject:array];
                        groupNames = [groupNames arrayByAddingObject:[path lastPathComponent]];
                    }else{
                        NSArray* groupsTemp = [NSArray array];
//                        NSArray* groupNamesTemp = [NSArray array];
                        for (int i = 0; i < [groups count]; i++) {
                            if (i == groupIndex) {
                                groupsTemp = [groupsTemp arrayByAddingObject:array];
                            }else{
                                groupsTemp = [groupsTemp arrayByAddingObject:[groups objectAtIndex:i]];
                            }
                        }
                        groups = groupsTemp;
                    }
                    
                }
            }
        }
    }
    
//	for (i = 0; i < [files count]; i++) {
//		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
//		[gFileManager fileExistsAtPath:path isDirectory:&isDirectory];
//		if (isDirectory) {
//			path = [path stringByAppendingString:@"/"];
//			subfiles = [gFileManager subpathsAtPath:path];
//			array = [NSArray array];
//			for (j = 0; j < [subfiles count]; j++) {
//				texture = [m_dicTextures objectForKey:[path stringByAppendingString:[subfiles objectAtIndex:j]]];
//				if (texture) {
//					array = [array arrayByAddingObject:texture];
//				}
//			}
//			if ([array count] > 0) {
//				array = [array sortedArrayUsingSelector:@selector(compare:)];
//				groups = [groups arrayByAddingObject:array];
//				groupNames = [groupNames arrayByAddingObject:[path lastPathComponent]];
//			}
//		}
//	}
//    
//    for (i = 0; i < [files count]; i++) {
//        path = [[customTextureDir stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
//        [gFileManager fileExistsAtPath:path isDirectory:&isDirectory];
//        if (isDirectory) {
//            path = [path stringByAppendingString:@"/"];
//            subfiles = [gFileManager subpathsAtPath:path];
//            array = [NSArray array];
//            BOOL hasGroup = NO;
//            for (int i = 0; i < [groupNames count]; i++) {
//                if ([[path lastPathComponent] isEqualToString:[groupNames objectAtIndex:i]]) {
//                    hasGroup = YES;
//                    array = [groups objectAtIndex:i];
//                    break;
//                }
//            }
//            for (j = 0; j < [subfiles count]; j++) {
//                texture = [m_dicTextures objectForKey:[path stringByAppendingString:[subfiles objectAtIndex:j]]];
//                if (texture) {
//                    array = [array arrayByAddingObject:texture];
//                }
//            }
//            if ([array count] > 0) {
//                array = [array sortedArrayUsingSelector:@selector(compare:)];
//                if (!hasGroup) {
//                    groups = [groups arrayByAddingObject:array];
//                    groupNames = [groupNames arrayByAddingObject:[path lastPathComponent]];
//                }
//                
//            }
//        }
//    }
	
	// Retain the groups and groupNames
	[groups retain];
	[groupNames retain];
	
	// Update utility if requested
	if (update) [self update];
}

- (void)addTextureFromPath:(NSString *)path
{
	NSArray *files, *subfiles, *newValues, *newKeys, *oldValues, *oldKeys, *array;
	NSString *tpath;
	BOOL isDirectory;
	id texture;
	int i, j;
	
	// Release any existing textures
	if (groups) [groups autorelease];
	if (groupNames) [groupNames autorelease];
	
	// Update dictionary of all textures
	[m_dicTextures autorelease];
	if ([m_dicTextures objectForKey:path]) {
		newKeys = [NSArray array];
		newValues = [NSArray array];
		oldKeys = [m_dicTextures allKeys];
		oldValues = [m_dicTextures allValues];
		for (i = 0; i < [oldKeys count]; i++) {
			if (![path isEqualToString:[oldKeys objectAtIndex:i]]) {
				newKeys = [newKeys arrayByAddingObject:[oldKeys objectAtIndex:i]];
				newValues = [newValues arrayByAddingObject:[oldValues objectAtIndex:i]];
			}
		}
	}
	else {
		newKeys = [m_dicTextures allKeys];
		newValues = [m_dicTextures allValues];
	}
	texture = [[PSTexture alloc] initWithContentsOfFile:path];
	if (texture) {
		newKeys = [newKeys arrayByAddingObject:path];
		newValues = [newValues arrayByAddingObject:texture];
		m_dicTextures = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
	}
	[m_dicTextures retain];
	
    //modify by lcz , add another texture path
	// Create the all group
	array = [[m_dicTextures allValues] sortedArrayUsingSelector:@selector(compare:)];
	groups = [NSArray arrayWithObject:array];
	groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
	
	// Create the other groups
    NSString *applcationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *customTextureDir = [NSString stringWithFormat:@"%@/%@", applcationSupport, bundleIdentifier];
    NSArray *textureDirs = [NSArray arrayWithObjects:[gMainBundle resourcePath], customTextureDir, nil];
    
    for (int index = 0; index < [textureDirs count]; index++) {
        NSString *rootPath = [textureDirs objectAtIndex:index];
        files = [gFileManager subpathsAtPath:[rootPath stringByAppendingString:@"/textures"]];
        [files sortedArrayUsingSelector:@selector(compare:)];
        for (i = 0; i < [files count]; i++) {
            path = [[rootPath stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
            [gFileManager fileExistsAtPath:path isDirectory:&isDirectory];
            if (isDirectory) {
                path = [path stringByAppendingString:@"/"];
                subfiles = [gFileManager subpathsAtPath:path];
                array = [NSArray array];
                BOOL hasGroup = NO;
                int groupIndex = -1;
                for (int i = 0; i < [groupNames count]; i++) {
                    if ([[path lastPathComponent] isEqualToString:[groupNames objectAtIndex:i]]) {
                        hasGroup = YES;
                        array = [groups objectAtIndex:i];
                        groupIndex = i;
                        break;
                    }
                }
                for (j = 0; j < [subfiles count]; j++) {
                    texture = [m_dicTextures objectForKey:[path stringByAppendingString:[subfiles objectAtIndex:j]]];
                    if (texture) {
                        array = [array arrayByAddingObject:texture];
                    }
                }
                if ([array count] > 0) {
                    array = [array sortedArrayUsingSelector:@selector(compare:)];
                    if (!hasGroup) {
                        groups = [groups arrayByAddingObject:array];
                        groupNames = [groupNames arrayByAddingObject:[path lastPathComponent]];
                    }else{
                        NSArray* groupsTemp = [NSArray array];
                        //                        NSArray* groupNamesTemp = [NSArray array];
                        for (int i = 0; i < [groups count]; i++) {
                            if (i == groupIndex) {
                                groupsTemp = [groupsTemp arrayByAddingObject:array];
                            }else{
                                groupsTemp = [groupsTemp arrayByAddingObject:[groups objectAtIndex:i]];
                            }
                        }
                        groups = groupsTemp;
                    }
                    
                }
            }
        }
    }
    
//	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/textures"]];
//	[files sortedArrayUsingSelector:@selector(compare:)];
//	for (i = 0; i < [files count]; i++) {
//		tpath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:[files objectAtIndex:i]];
//		[gFileManager fileExistsAtPath:tpath isDirectory:&isDirectory];
//		if (isDirectory) {
//			tpath = [tpath stringByAppendingString:@"/"];
//			subfiles = [gFileManager subpathsAtPath:tpath];
//			array = [NSArray array];
//			for (j = 0; j < [subfiles count]; j++) {
//				texture = [m_dicTextures objectForKey:[tpath stringByAppendingString:[subfiles objectAtIndex:j]]];
//				if (texture) {
//					array = [array arrayByAddingObject:texture];
//				}
//			}
//			if ([array count] > 0) {
//				array = [array sortedArrayUsingSelector:@selector(compare:)];
//				groups = [groups arrayByAddingObject:array];
//				groupNames = [groupNames arrayByAddingObject:[tpath lastPathComponent]];
//			}
//		}
//	}
	
	// Retain the groups and groupNames
	[groups retain];
	[groupNames retain];
	
	// Configure the pop-up menu
	[m_idTextureGroupPopUp removeAllItems];
	[m_idTextureGroupPopUp addItemWithTitle:NSLocalizedString([groupNames objectAtIndex:0],nil)];
	[[m_idTextureGroupPopUp itemAtIndex:0] setTag:0];
	[[m_idTextureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[m_idTextureGroupPopUp addItemWithTitle:NSLocalizedString([groupNames objectAtIndex:i],nil)];
		[[m_idTextureGroupPopUp itemAtIndex:[[m_idTextureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[m_idTextureGroupPopUp selectItemAtIndex:[m_idTextureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Update utility
	[self setActiveTextureIndex:-1];
	[[m_idView documentView] update];
	[m_idView setNeedsDisplay:YES];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (IBAction)changeOpacity:(id)sender
{
//	[m_idOpacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [m_idOpacitySlider intValue]]];
    [m_idOpacityLabel setIntValue: [m_idOpacitySlider intValue]];
	opacity = [m_idOpacitySlider intValue] * 2.55;
}

- (int)opacity
{
	return opacity;
}

- (id)activeTexture
{
	return [[groups objectAtIndex:activeGroupIndex] objectAtIndex:activeTextureIndex];
}

- (int)activeTextureIndex
{
	if ([[PSController m_idPSPrefs] useTextures])
		return activeTextureIndex;
	else
		return -1;
}

- (void)setActiveTextureIndex:(int)index
{
	id oldTexture;
	id newTexture;
	
	if (index == -1) {
		[[PSController m_idPSPrefs] setUseTextures:NO];
		[m_idTextureNameLabel setStringValue:@""];
		[m_idOpacitySlider setEnabled:NO];
		[m_idView setNeedsDisplay:YES];
	}
	else {
		oldTexture = [[groups objectAtIndex:activeGroupIndex] objectAtIndex:activeTextureIndex];
		newTexture = [[groups objectAtIndex:activeGroupIndex] objectAtIndex:index];
		[oldTexture deactivate];
		activeTextureIndex = index;
		[[PSController m_idPSPrefs] setUseTextures:YES];
		[m_idTextureNameLabel setStringValue:[newTexture name]];
		[m_idOpacitySlider setEnabled:YES];
		[newTexture activate];
		
    }
    
    [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:NO];
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] preview:NULL];
    [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] update];
}

- (NSArray *)textures
{
	return [groups objectAtIndex:activeGroupIndex];
}

- (NSArray *)groupNames
{
	return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    int nValue = [textField intValue];
    
    if(nValue < [(NSSlider *)m_idOpacitySlider minValue]) nValue = [(NSSlider *)m_idOpacitySlider minValue];
    else if (nValue > [(NSSlider *)m_idOpacitySlider maxValue]) nValue = [(NSSlider *)m_idOpacitySlider maxValue];
    
    [m_idOpacityLabel setIntValue:nValue];
    [m_idOpacitySlider setIntValue:nValue];
    
    
    return YES;
}

@end

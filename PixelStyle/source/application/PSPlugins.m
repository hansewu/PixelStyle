#import "PSPlugins.h"
#import "PluginClass.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "PSController.h"
#import "PSTools.h"
#import "EffectTool.h"
#import "ToolboxUtility.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"

extern BOOL useAltiVec;

@implementation PSPlugins

int plugin_sort(id obj1, id obj2, void *context)
{
	int result;
	
	result = [[obj1 groupName] caseInsensitiveCompare:[obj2 groupName]];
	if (result == NSOrderedSame) {
		result = [[obj1 name] caseInsensitiveCompare:[obj2 name]];
	}
	
	return result;
}

BOOL checkRun(NSString *path, NSString *file)
{
	NSDictionary *infoDict;
	BOOL canRun;
	id value;
	
	// Get dictionary
	canRun = YES;
	infoDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/Contents/Info.plist", path, file]];
	
	// Check special
	value = [infoDict objectForKey:@"SpecialPlugin"];
	if (value != NULL) {
		if ([value isEqualToString:@"YES"] || [value isEqualToString:@"yes"] || [value isEqualToString:@"1"]) {
			canRun = NO;
		}
	}
	
	// Check PPC
#ifndef __ppc__
	value = [infoDict objectForKey:@"PPCOnly"];
	if (value != NULL) {
		if ([value isEqualToString:@"YES"] || [value isEqualToString:@"yes"] || [value isEqualToString:@"1"]) {
			canRun = NO;
		}
	}
#endif
	
	// Check Intel
#ifndef __i386__
	value = [infoDict objectForKey:@"IntelOnly"];
	if (value != NULL) {
		if ([value isEqualToString:@"YES"] || [value isEqualToString:@"yes"] || [value isEqualToString:@"1"]) {
			canRun = NO;
		}
	}
#endif
	
	// Check AltiVec or SSE
#ifdef __ppc__
	value = [infoDict objectForKey:@"AltiVecOrSSERequired"];
	if (value != NULL) {
		if ([value isEqualToString:@"YES"] || [value isEqualToString:@"yes"] || [value isEqualToString:@"1"]) {
			if (useAltiVec == NO) canRun = NO;
		}
	}
#endif
	
	// Check system version
	value = [infoDict objectForKey:@"MinSystemVersion"];
	if (value != NULL) {
		switch ((int)floor(NSAppKitVersionNumber)) {
			case NSAppKitVersionNumber10_3:
				canRun = canRun && [value floatValue] <= 10.3;
			break;
			case NSAppKitVersionNumber10_4:
				canRun = canRun && [value floatValue] <= 10.4;
			break;
		}
	}
	
	return canRun;
}

- (id)init
{
	NSString *pluginsPath, *pre_files_name, *files_name;
	NSArray *pre_files;
	NSMutableArray *files;
	NSBundle *bundle;
	id plugin;
	int i, j, found_id;
	BOOL success, found, can_run;
	NSRange range, next_range;
	
	// Set the last effect to nothing
	m_nLastEffect = -1;
	
	// Add standard plug-ins
	m_arrPlugins = [NSArray array];
	pluginsPath = [gMainBundle builtInPlugInsPath];
	//pre_files = [gFileManager directoryContentsAtPath:pluginsPath];
    pre_files = [gFileManager contentsOfDirectoryAtPath:pluginsPath error:NULL];
	files = [NSMutableArray arrayWithCapacity:[pre_files count]];
	for (i = 0; i < [pre_files count]; i++) {
		pre_files_name = [pre_files objectAtIndex:i];
		if ([pre_files_name hasSuffix:@".bundle"] && ![pre_files_name hasSuffix:@"+.bundle"]) {
			can_run = checkRun(pluginsPath, pre_files_name);
			if (can_run) [files addObject:pre_files_name];
		}
	}
	
	// Add plus plug-ins
	for (i = 0; i < [pre_files count]; i++) {
		pre_files_name = [pre_files objectAtIndex:i];
		if ([pre_files_name hasSuffix:@"+.bundle"]) {
			found = NO;
			range.location = 0;
			range.length = [pre_files_name length] - (sizeof("+.bundle") - 1);
			found_id = -1;
			for (j = 0; j < [files count] && !found; j++) {
				files_name = [files objectAtIndex:j];
				next_range.location = 0;
				next_range.length = [files_name length] - (sizeof(".bundle") - 1);
				if ([[files_name substringWithRange:next_range] isEqualToString:[pre_files_name substringWithRange:range]]) {
					found = YES;
					found_id = j;
				}
			}
			can_run = checkRun(pluginsPath, pre_files_name);
			if (can_run) {
				if (found) [files replaceObjectAtIndex:found_id withObject:pre_files_name];
				else [files addObject:pre_files_name];
			}
		}
	}
	
	// Check added plug-ins
	m_nCiAffineTransformIndex = -1;
	for (i = 0; i < [files count]; i++) {		
		bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", pluginsPath, [files objectAtIndex:i]]];
        
        //transform remove
        if ([[files objectAtIndex:i] isEqualToString:@"AffineTransform+.bundle"] || [[files objectAtIndex:i] isEqualToString:@"PerspectiveTransform+.bundle"]) {
            continue;
        }
		if (bundle && [bundle principalClass]) {
			success = NO;
			plugin = [[bundle principalClass] alloc];
			if (plugin) {
				if ([plugin respondsToSelector:@selector(initWithManager:)]) {
					[plugin initWithManager:self];
					if ([plugin respondsToSelector:@selector(sanity)] && [[plugin sanity] isEqualToString:@"PixelStyle Approved (Bobo)"]) {
						m_arrPlugins = [m_arrPlugins arrayByAddingObject:plugin];
						success = YES;
					}		
				}
				if (!success) {
					[plugin autorelease];
				}
			}
		}
	}
	
	// Sort and retain plug-ins
	m_arrPlugins = [m_arrPlugins sortedArrayUsingFunction:plugin_sort context:NULL];
	[m_arrPlugins retain];

	// Determine affine transform plug-in
	for (i = 0; i < [m_arrPlugins count]; i++) {
		plugin = [m_arrPlugins objectAtIndex:i];
		if ([plugin respondsToSelector:@selector(runAffineTransform:withImage:spp:width:height:opaque:newWidth:newHeight:)]) {
			if (m_nCiAffineTransformIndex == -1) {
				m_nCiAffineTransformIndex = i;
			}
			else {
				NSLog(@"Multiple plug-ins are affine transform capable (using first): %@ %@", [files objectAtIndex:m_nCiAffineTransformIndex], [files objectAtIndex:i]);
			}
		}
	}
	
	return self;
}

- (void)awakeFromNib
{
	id menuItem, submenuItem;
	NSMenu *submenu;
	id plugin;
	int i;
	
	// Set up
	m_arrPointPlugins = [NSArray array];
	m_arrPointPluginsNames = [NSArray array];
	   
    NSMutableArray *muArrColorPluginGroup = [[[NSMutableArray alloc] init] autorelease];
	// Configure all plug-ins
	for (i = 0; i < [m_arrPlugins count] && i < 7500; i++) {
		plugin = [m_arrPlugins objectAtIndex:i];
        
		// If the plug-in is a basic plug-in add it to the effects menu
        if([(PluginClass *)plugin type] == kAdjustColorPlugin)
        {
            // Add or find group submenu
            submenuItem = [m_idImageMenu itemWithTitle:NSLocalizedString(@"Adjustment", nil)];
            if (submenuItem == NULL) {
                submenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Adjustment", nil) action:NULL keyEquivalent:@""];
                [m_idImageMenu insertItem:submenuItem atIndex:0];
                submenu = [[NSMenu alloc] initWithTitle:NSLocalizedString([submenuItem title], nil)];
                [submenuItem setSubmenu:submenu];
                [submenu autorelease];
                [submenuItem autorelease];
                
                NSMenuItem *spaceItem = [NSMenuItem separatorItem];
                [m_idImageMenu insertItem:spaceItem atIndex:1];
            }
            else {
                submenu = [submenuItem submenu];
            }
            
            // Add plug-in to group
            menuItem = [m_idImageMenu itemWithTitle:NSLocalizedString([plugin name], nil)];
            if (menuItem == NULL)
            {
                int nGroupID = -1;
                int nInsertIndex = 0;
                for(int nIndex = 0; nIndex < muArrColorPluginGroup.count; nIndex++)
                {
                    NSMutableDictionary *dicPuginGroupInfo = [muArrColorPluginGroup objectAtIndex:nIndex];
                    
                    NSString *nGroupName = [dicPuginGroupInfo objectForKey:@"groupName"];
                    if([[plugin groupName] isEqualToString:nGroupName])
                    {
                        nGroupID = nIndex;
                        
                        break;
                    }
                    
                }
                
                if(nGroupID == -1)
                {
                    NSMenuItem *spaceItem = [NSMenuItem separatorItem];
                    [submenu addItem:spaceItem];
                    
                    NSMutableDictionary *dicPuginGroupInfo = [[[NSMutableDictionary alloc] init] autorelease];
                    [dicPuginGroupInfo setObject:[plugin groupName] forKey:@"groupName"];
                    [muArrColorPluginGroup addObject:dicPuginGroupInfo];
                    
                    nGroupID = muArrColorPluginGroup.count -1;
                }
                
                for(int nIndex = 0; nIndex < nGroupID; nIndex++)
                {
                    NSMutableDictionary *dicPuginGroupInfo = [muArrColorPluginGroup objectAtIndex:nIndex];
                    nInsertIndex += [[dicPuginGroupInfo objectForKey:@"pluginCount"] intValue];
                }
                nInsertIndex += nGroupID;
                
                
                menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString([plugin name], nil) action:@selector(run:) keyEquivalent:@""];
                [menuItem setTarget:self];
                [submenu insertItem:menuItem atIndex:nInsertIndex];
//                [submenu addItem:menuItem];
                [menuItem setTag:i + 10000];
                [menuItem autorelease];
                
                NSMutableDictionary *dicPuginGroupInfo = [muArrColorPluginGroup objectAtIndex:nGroupID];
                int nPluginCountInGroup = [[dicPuginGroupInfo objectForKey:@"pluginCount"] intValue] + 1;
                [dicPuginGroupInfo setObject:[NSNumber numberWithInt:nPluginCountInGroup] forKey:@"pluginCount"];
            }
            
        }
        else if([(PluginClass *)plugin type] <= -1) {}
		else if (YES) { //[(PluginClass *)plugin type] == kBasicPlugin
			
			// Add or find group submenu
			submenuItem = [m_idEffectMenu itemWithTitle:NSLocalizedString([plugin groupName], nil)];
			if (submenuItem == NULL) {
				submenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString([plugin groupName], nil) action:NULL keyEquivalent:@""];
				[m_idEffectMenu insertItem:submenuItem atIndex:[m_idEffectMenu numberOfItems] - 2];
				submenu = [[NSMenu alloc] initWithTitle:NSLocalizedString([submenuItem title], nil)];
				[submenuItem setSubmenu:submenu];
				[submenu autorelease];
				[submenuItem autorelease];
			}
			else {
				submenu = [submenuItem submenu];
			}
			
			// Add plug-in to group
			menuItem = [submenu itemWithTitle:NSLocalizedString([plugin name], nil)];
			if (menuItem == NULL) {
				menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString([plugin name], nil) action:@selector(run:) keyEquivalent:@""];
				[menuItem setTarget:self];
				[submenu addItem:menuItem];
				[menuItem setTag:i + 10000];
				[menuItem autorelease];
			}
            //NSLog(@"[plugin name] %@",[plugin name]);
			
		}
		else if ([(PluginClass *)plugin type] == kPointPlugin) {
			m_arrPointPluginsNames = [m_arrPointPluginsNames arrayByAddingObject:[NSString stringWithFormat:@"%@ / %@", [plugin groupName], [plugin name]]];
			m_arrPointPlugins = [m_arrPointPlugins arrayByAddingObject:plugin];
		}
		
	}
	
	// Finish off
	[m_arrPointPluginsNames retain];
	[m_arrPointPlugins retain];
	
	// Correct effect tool
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] setEffectEnabled:([m_arrPointPluginsNames count] != 0)];

	// Register to recieve the terminate message when PixelStyle quits
	[m_idController registerForTermination:self];
    
    m_currentDocument = gCurrentDocument;
}

- (void)dealloc
{
	int i;
	
	if (m_arrPointPlugins) [m_arrPointPlugins autorelease];
	if (m_arrPlugins) {
		for (i = 0; i < [m_arrPlugins count]; i++) {
			[[m_arrPlugins objectAtIndex:i] autorelease];
		}
		[m_arrPlugins autorelease];
	}
	[super dealloc];
}

- (void)terminate
{
	[gUserDefaults setInteger:[[[[PSController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions: kEffectTool] selectedRow] forKey:@"effectIndex"];
}

- (id)affinePlugin
{
	if (m_nCiAffineTransformIndex >= 0)
		return [m_arrPlugins objectAtIndex:m_nCiAffineTransformIndex];
	else
		return NULL;
}

//From the Apple documentation on NSDocumentController currentDocument it says:
//
//    This method returns nil if it is called when its application is not active. This can occur during processing of a drag-and-drop operation, for example, in an implementation of readSelectionFromPasteboard:. In such a case, send the following message instead from an NSView subclass associated with the document:
//
//    [[[self window] windowController] document];
- (id)data
{
    id document = gCurrentDocument;
    
    if (document)
        m_currentDocument = document;
    
    return [m_currentDocument pluginData];
	//return [gCurrentDocument pluginData];
}

- (IBAction)run:(id)sender
{
    m_currentDocument = gCurrentDocument;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PLUGINSHOULDRUN" object:nil];
	[(PluginClass *)[m_arrPlugins objectAtIndex:[sender tag] - 10000] run];
	m_nLastEffect = [sender tag] - 10000;
    
}

- (IBAction)reapplyEffect:(id)sender
{
	[[m_arrPlugins objectAtIndex:m_nLastEffect] reapply];
}

- (void)cancelReapply
{
	m_nLastEffect = -1;
}

- (BOOL)hasLastEffect
{
	return m_nLastEffect != -1 && [[m_arrPlugins objectAtIndex:m_nLastEffect] canReapply];
}

- (NSArray *)pointPluginsNames
{
	return m_arrPointPluginsNames;
}

- (NSArray *)pointPlugins
{
	return m_arrPointPlugins;
}

- (id)activePointEffect
{
	return [m_arrPointPlugins objectAtIndex:[[[[PSController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions: kEffectTool] selectedRow] ];
}

- (BOOL)validateMenuItem:(id)menuItem
{
    BOOL bValidate = YES;
	id document = gCurrentDocument;
	
	// Never when there is no document
	if (document == NULL)
		return NO;
    
    m_currentDocument = document;
	
	// End the line drawing
	[[document helpers] endLineDrawing];
	
	// Never when the document is locked
	if ([document locked])
		return NO;
	
	// Never if we are told not to
    // crashed often here wzq
	if ([menuItem tag] >= 10000 && [menuItem tag] < 17500) {
        if(!gCurrentDocument)
            return NO;
		if (![[m_arrPlugins objectAtIndex:[menuItem tag] - 10000] validateMenuItem:menuItem])
			return NO;
        
        
	}
    //根据当前工具确定
    bValidate = [[[gCurrentDocument tools] currentTool] validateMenuItem:menuItem];
    
    if(bValidate)
        //根据选中层确定菜单是否可用
        bValidate = [[gCurrentDocument contents] validateMenuItem:menuItem];
    
    return bValidate;
}

- (void)changeNewToolTo:(int)tool isReset:(BOOL)isReset
{
    if (isReset) {
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] setColorCanChange:YES];
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] changeToolTo:m_pluginPreTool];
        
    }else{
        m_pluginPreTool = [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] tool];
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] changeToolTo:tool];
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:gCurrentDocument] setColorCanChange:NO];
    }
}

@end

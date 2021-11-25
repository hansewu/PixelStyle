#import "TextureExporter.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"

enum {
	kExistingCategoryButton,
	kNewCategoryButton
};

@implementation TextureExporter

- (void)awakeFromNib
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)exportAsTexture:(id)sender
{
	[NSApp beginSheet:m_idSheet modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	NSArray *groupNames = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] groupNames];
	NSString *path;

	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
	[m_idSheet orderOut:self];
    
    
    //modify by lcz
    NSString *applcationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *customTextureDir = [NSString stringWithFormat:@"%@/%@", applcationSupport, bundleIdentifier];

	
	// Determine the path
	if ([m_idExistingCategoryRadio state] == NSOnState) {
		path = [[customTextureDir stringByAppendingString:@"/textures/"] stringByAppendingString:[groupNames objectAtIndex:[m_idCategoryTable selectedRow]]];
	}
	else {
//		path = [[[gMainBundle resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:[m_idCategoryTextbox stringValue]];
        path = [[customTextureDir stringByAppendingString:@"/textures/"] stringByAppendingString:[m_idCategoryTextbox stringValue]];
	}
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
        
    }else{
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (!success) {
            NSLog(@"create %@ fail", path);
        }
    }
	path = [path stringByAppendingFormat:@"/%@.png", [m_idNameTextbox stringValue]];
    
    NSLog(@"%@",path);
	
    [m_idDocument writeToURL:[NSURL fileURLWithPath:path] ofType:@"Portable Network Graphics Image (PNG)" error:nil];
	
	// Refresh textures
	[[[PSController utilitiesManager] textureUtilityFor:m_idDocument] addTextureFromPath:path];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
	[m_idSheet orderOut:self];
}

- (IBAction)existingCategoryClick:(id)sender
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)newCategoryClick:(id)sender
{
	[self selectButton:kNewCategoryButton];
}

- (void)selectButton:(int)button
{
	switch (button) {
		case kExistingCategoryButton:
			[m_idExistingCategoryRadio setState:NSOnState];
			[m_idNewCategoryRadio setState:NSOffState];
			[m_idCategoryTable setEnabled:YES];
			[m_idCategoryTextbox setEnabled:NO];
		break;
		case kNewCategoryButton:
			[m_idExistingCategoryRadio setState:NSOffState];
			[m_idNewCategoryRadio setState:NSOnState];
			[m_idCategoryTable setEnabled:NO];
			[m_idCategoryTextbox setEnabled:YES];
		break;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	NSArray *groupNames = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] groupNames];

	return [groupNames objectAtIndex:row];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray *groupNames = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] groupNames];

	return [groupNames count];
}

@end

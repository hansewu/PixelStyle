#import "PSHelp.h"
#import "EmailController.h"
#import "ConfigureInfo.h"

@implementation PSHelp

-(void)dealloc
{
    if(m_pEmailController) {[m_pEmailController release]; m_pEmailController = nil;}
    
    [super dealloc];
}

- (IBAction)goEmail:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:cedarsx@gmail.com?subject=PixelStyle%20Comment"]];
}

- (IBAction)goSourceForge:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sourceforge.net/projects/photoart/"]];
}

- (IBAction)goWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://photoart.sourceforge.net/"]];
}

- (IBAction)goSurvey:(id)sender
{
	NSString *url = [NSString stringWithFormat:@"http://photoart.sourceforge.net/survey.php?version=%@" , [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction)openBugs:(id)sender
{
//	NSString *url = [NSString stringWithFormat:@"http://photoart.sourceforge.net/quick.php?version=%@" , [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL_PRODUCT]];//URL_FORUM]];
}

- (IBAction)openHelp:(id)sender
{
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.effectmatrix.com/mac-appstore/photo-editor-mac-tutorials.htm"]];
//	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"PixelStyle Guide" ofType:@"pdf"]];
}


- (IBAction)openEffectsHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"PixelStyle Effects Guide" ofType:@"pdf"]];
}

- (IBAction)openEmail:(id)sender
{
//    EmailController *pEmailController = [[[EmailController alloc] init] autorelease];
    if(!m_pEmailController)
        m_pEmailController = [[EmailController alloc] init];
    NSWindow *w = [gCurrentDocument window];
    [m_pEmailController showEMailWindowWithModel:w];
}

- (void)URL:(NSURL *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes {}
- (void)URLResourceDidCancelLoading:(NSURL *)sender {}
- (void)URL:(NSURL *)sender resourceDidFailLoadingWithReason:(NSString *)reason {}

- (void)URLResourceDidFinishLoading:(NSURL *)sender
{
	NSURL *download_url;
	NSDictionary *dict;
	int newest_version;
	int installed_version = (int)[[[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"] intValue];
	
	dict = [NSDictionary dictionaryWithContentsOfURL:sender];
	if (dict) {
		newest_version = [[dict objectForKey:@"current version"] intValue];
		if (newest_version > installed_version) {
			download_url = [NSURL URLWithString:[dict objectForKey:@"url"]];
			if (NSRunAlertPanel(LOCALSTR(@"download available title", @"Update available"), LOCALSTR(@"download available body", @"An updated version of PixelStyle is now availble for download."), LOCALSTR(@"download now", @"Download now"), LOCALSTR(@"download later", @"Download later"), NULL) == NSAlertDefaultReturn) {
				[[NSWorkspace sharedWorkspace] openURL:download_url];
			}
		}
		else {
			if (m_bAdviseFailure)
				NSRunAlertPanel(LOCALSTR(@"up-to-date title", @"PixelStyle up-to-date"), LOCALSTR(@"up-to-date body", @"PixelStyle is up-to-date."), LOCALSTR(@"ok", @"OK"), NULL, NULL);				
		}
	}
	else {
		if (m_bAdviseFailure)
			NSRunAlertPanel(LOCALSTR(@"download error title", @"Download error"), LOCALSTR(@"download error body", @"The file required to check if PixelStyle cannot be downloaded from the Internet. Please check your Internet connection and try again."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
	}	
}

- (IBAction)checkForUpdate:(id)sender
{
	NSURL *check_url;
	
	check_url = [NSURL URLWithString:URL_PRODUCT];
	m_bAdviseFailure = (sender != NULL);
	//[check_url loadResourceDataNotifyingClient:self usingCache:YES];
    [[NSWorkspace sharedWorkspace] openURL:check_url];
}

- (void)displayInstantHelp:(int)stringID
{
	NSArray *instantHelpArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Instant" ofType:@"plist"]];
	
	if (stringID >= 0 && stringID < [instantHelpArray count]) {
		[m_idInstantHelpLabel setStringValue:[instantHelpArray objectAtIndex:stringID]];
		[m_idInstantHelpWindow orderFront:self];
	}
}

- (void)updateInstantHelp:(int)stringID
{
	NSArray *instantHelpArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Instant" ofType:@"plist"]];
	
	if (stringID >= 0 && stringID < [instantHelpArray count] && [m_idInstantHelpWindow isVisible]) {
		[m_idInstantHelpLabel setStringValue:[instantHelpArray objectAtIndex:stringID]];
	}
}



#pragma mark - Menu promotion
-(IBAction)onSuperPhotoCutPro:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/super-photocut-pro-transparent-wedding-gown-cutout/id1192683659?mt=12"]];
}

-(IBAction)onSuperVectorizerPro:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/super-vectorizer-2-vector-trace-tool/id1152204742?mt=12"]];
}

-(IBAction)onSuperEraserPro:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/super-eraser-pro-scale-photo-and-erase-unwanted/id1192683670?mt=12"]];
}

-(IBAction)onPhotoSizeOptimizer:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id771501095"]];
}

-(IBAction)onAfterFocus:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/after-focus-photo-background-blur-bokeh-effects/id1016794110?mt=12"]];
}

-(IBAction)onSuperDenosing:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id1016781856"]];
}


@end

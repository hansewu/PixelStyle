#import "Globals.h"

/*!
	@class		PSHelp
	@abstract	Displays help on various matters for PixelStyle users.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSHelp : NSObject {
	
	// The bugs and suggestions window
    IBOutlet id m_idBugsWindow;
	
	// The instant help window 
	IBOutlet id m_idInstantHelpWindow;
	
	// The label for displaying the instant help text
	IBOutlet id m_idInstantHelpLabel;
    
    id          m_pEmailController;
	// Should the user be advised if the download fails?
	BOOL m_bAdviseFailure;
	
}

/*!
	@method		goEmail:
	@discussion	Opens the default e-mail client with a message addressed to me
				for feedback.
	@param		sender
				Ignored.
*/
- (IBAction)goEmail:(id)sender;

/*!
	@method		goSourceForge:
	@discussion	Opens the default web browser with PixelStyle's SourceForge page
				to allow users to submit feedback.
	@param		sender
				Ignored.
*/
- (IBAction)goSourceForge:(id)sender;

/*!
	@method		goWebsite:
	@discussion	Opens the default web browser with PixelStyle's web page to allow
				users to see latest developments with the program.
	@param		sender
				Ignored.
*/
- (IBAction)goWebsite:(id)sender;

/*!
	@method		goSurvey:
	@discussion	Opens the default web browser with PixelStyle's survey to allow
				users to offer feedback on the program.
	@param		sender
				Ignored.
*/
- (IBAction)goSurvey:(id)sender;

/*!
	@method		openBugs:
	@discussion	Opens the bug report and suggestions window.
	@param		sender
				Ignored.
*/
- (IBAction)openBugs:(id)sender;

/*!
	@method		openHelp:
	@discussion	Opens the PixelStyle help manual.
	@param		sender
				Ignored.
*/
- (IBAction)openHelp:(id)sender;


/*!
	@method		openEffectsHelp:
	@discussion	Opens the PixelStyle effects guide.
	@param		sender
				Ignored.
*/
- (IBAction)openEffectsHelp:(id)sender;

/*!
	@method		checkForUpdate:
	@discussion	Checks for an update to PixelStyle.
	@param		sender
				NULL if dialog box feedback should be supressed.
*/
- (IBAction)checkForUpdate:(id)sender;

/*!
	@method		updateInstantHelp:
	@discussion Updates the instant help window with the given string if and
				only if it is visible.
	@param		stringID
				The index of the string in the Instant.plist to be displayed.
*/
- (void)updateInstantHelp:(int)stringID;


//menu promotion
#pragma mark - Menu
-(IBAction)onSuperPhotoCutPro:(id)sender;
-(IBAction)onSuperVectorizerPro:(id)sender;
-(IBAction)onSuperEraserPro:(id)sender;
-(IBAction)onPhotoSizeOptimizer:(id)sender;
-(IBAction)onAfterFocus:(id)sender;
-(IBAction)onSuperDenosing:(id)sender;

@end

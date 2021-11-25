#import "Globals.h"

/*!
	@class		BannerView
	@abstract	A view for an informative Banner
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BannerView : NSView {
	// Reference to the document this banner is in
	IBOutlet id m_idDocument;
	
	// The text to display
	NSString *m_strBannerText;
	
	// The importance of the banner (this defines the color)
	int m_nBannerImportance;
	
	// The default button for the banner
	IBOutlet id m_idDefaultButton;
	
	// The alternate button (optional)
	IBOutlet id m_idAlternateButton;
}

/*!
	@method		setBannerText:defaultButtonText:alternateButtonText:andImportance
	@discussion	Sets the text that is displayed in the background on the buttons
	@param		text
				The text on the background of the banner.
	@param		dText
				The text on the default button. NULL if you want no button.
	@param		aText
				The text on the alternate button. NULL if no button. This button 
				only appears if there is a default button as well.
	@param		importance
				The importance sets the color of the background.
*/
- (void)setBannerText:(NSString *)text defaultButtonText:(NSString *)dText alternateButtonText:(NSString *)aText andImportance:(int)importance;

@end

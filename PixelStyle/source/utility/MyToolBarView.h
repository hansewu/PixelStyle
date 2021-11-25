#import "Globals.h"



@interface MyToolBarView : NSView
{
	// Reference to the document this banner is in
	IBOutlet id m_idDocument;
	
	// The text to display
	NSString *m_strBannerText;
	
	// The importance of the banner (this defines the color)
//	int bannerImportance;
	
	// The default button for the banner
	IBOutlet id m_idDefaultButton;
	
	// The alternate button (optional)
	IBOutlet id m_idAlternateButton;
    
    IBOutlet id m_idColorSelectView;
    
    NSButton *m_btnOldSelected;
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
- (void)enableButton:(id)btSender;
- (void)setBannerText:(NSString *)text defaultButtonText:(NSString *)dText alternateButtonText:(NSString *)aText andImportance:(int)importance;

@end

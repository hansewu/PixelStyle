#import "Globals.h"
#import "AbstractOptions.h"

/*!
	@class		ZoomOptions
	@abstract	Handles the options pane for the zoom tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/


@interface ZoomOptions : AbstractOptions <NSComboBoxDelegate, NSComboBoxDataSource> {

	// A label specifying the current zoom
    IBOutlet id m_idZoomLabel;
	
    IBOutlet NSButton *m_btnZoomOut;
    IBOutlet NSButton *m_btnZoomIn;
    
    IBOutlet id m_comboxZoom;
    IBOutlet id m_btnComboxRight;
    
    BOOL m_bZoomOut;
}

/*!
	@method		update
	@discussion	Updates the options panel.
*/
- (void)update;

-(BOOL)IsZoomOut;
-(IBAction)onBtnZoomOut:(id)sender;
-(IBAction)onBtnZoomIn:(id)sender;

- (IBAction)changeZoomValue:(id)sender;

@end

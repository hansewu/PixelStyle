#import "Globals.h"

/*!
	@class		TextureExporter
	@abstract	Exports a PixelStyle document as a texture.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface TextureExporter : NSObject {

	// The document associated with this object
    IBOutlet id m_idDocument;

	// The exporting panel
	IBOutlet id m_idSheet;

	IBOutlet id m_idCategoryTable;
	
	IBOutlet id m_idCategoryTextbox;
	
	IBOutlet id m_idExistingCategoryRadio;
	
	IBOutlet id m_idNewCategoryRadio;
	
	IBOutlet id m_idNameTextbox;

}

/*!
	@method		awakeFromNib
	@discussion	Configures the exporting panel's interface.
*/
- (void)awakeFromNib;

/*!
	@method		exportAsTexture:
	@discussion	Displays the exporting panel.
	@param		sender
				Ignored.
*/
- (IBAction)exportAsTexture:(id)sender;

/*!
	@method		apply:
	@discussion	Executes the export.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Cancels the export.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

- (IBAction)existingCategoryClick:(id)sender;

- (IBAction)newCategoryClick:(id)sender;

/*
*/
- (void)selectButton:(int)button;

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row;

- (int)numberOfRowsInTableView:(NSTableView *)tableView;

@end

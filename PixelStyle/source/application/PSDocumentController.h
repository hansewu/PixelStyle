#import "Globals.h"

/*!
	@class		PSDocumentController
	@abstract	Subclasses the NSDocumentController class.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2006 Mark Pazolli
*/

@interface PSDocumentController : NSDocumentController {

	// An outlet to the preferences manager of the application
	IBOutlet id m_idPSPrefs;
	
	// A panel through which a new image can be configured
	IBOutlet id m_idNewPanel; 
	
	// The various text boxes from the New Image Settings panel
	IBOutlet id m_idWidthInput, m_idHeightInput;
	
	// The various buttons for changing m_nUnits
	IBOutlet id m_idWidthUnits, m_idHeightUnits;
	
	// The resolution menu from the New Image Settings panel
	IBOutlet id m_idResMenu;
	
	// The mode menu from the New Image Settings panel
	IBOutlet id m_idModeMenu;
	
	// The m_nUnits menu for the New Image Settings panel
	IBOutlet id m_idWidthUnitsMenu, m_idHeightUnitMenu;
	
	// The templates menu from the New Image Settings panel
	IBOutlet id m_idTemplatesMenu;	
	
	// The transparency checkbox for the New Image settings panel
	IBOutlet id m_idBackgroundCheckbox;
	
	// The dropdown for the recent documents.
	IBOutlet id m_idRecentMenu;
    IBOutlet id m_idCreatButton;
	
	// The m_nUnits for the New Image Settings panel
	int m_nUnits;
	
	// The variables stored for retrieval by the new document 
	int m_nType, m_nWidth, m_nHeight, m_nResolution;
	
	// The variables stored for retrieval by the new document
	BOOL m_bOpaque;
	
	// If YES prevents new documents being recorded as recently opened
	BOOL m_bStopNotingRecentDocuments;
	
	// A long list of the possible things we can write
	NSMutableDictionary *m_mdEditableTypes;
	
	// A long list of the possible things we can read
	NSMutableDictionary *m_mdViewableTypes;
    
    NSMutableArray *m_importerPluginsSupportTypes;
	
    IBOutlet id m_idRecentFile;
    
    IBOutlet NSTextField *m_textFieldWidth, *m_textFieldHeight;
    IBOutlet NSTextField *m_textFieldPreset, *m_textFieldResolution;
    IBOutlet NSButton      *m_btnOpen;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		newDocument:
	@discussion	Presents the New Image Settings panel needed to create a new document.
	@param		sender
				Ignored.
*/
- (IBAction)newDocument:(id)sender;

/*!
	@method		openDocument:
	@discussion Called to open a new document (hides the New Image Settings panel).
	@param		sender
				Ignored.
*/
- (IBAction)openDocument:(id)sender;

/*!
	@method		openNonCurrentDocument:
	@discussion Called to open a file that was created from an existing one.
	@param		path
				The path of the file.
	@result		Returns an instance of the freshly opened document.
*/
- (id)openNonCurrentFile:(NSString *)path;

/*!
	@method		openRecent:
	@discussion The action from the open recent popup menu.
	@param		path
				The path of the file.
	@result		Returns an instance of the freshly opened document.
*/
- (IBAction)openRecent:(id)sender;


/*!
	@method		noteNewRecentDocument:
	@discussion	Adds new documents to the "Open Recent" sub-menu.
	@param		aDocument
				The document to add.
*/
- (void)noteNewRecentDocument:(NSDocument *)aDocument;

/*!
	@method		createDocument:
	@discussion	Actually creates a new document based on values in the
				New Image Settings panel.
	@param		sender
				Ignored.
*/
- (IBAction)createDocument:(id)sender;

/*!
	@method		changeToTemplate:
	@discussion	Called to change to a template when a menu item is selected from
				the templates menu.
	@param		sender
				Ignored.
*/
- (IBAction)changeToTemplate:(id)sender;

/*!
	@method		changeUnits:
	@discussion	Called to change the m_nUnits in the New Image Settings panel.
	@param		sender
				Ignored.
*/
- (IBAction)changeUnits:(id)sender;

/*!
	@method		addDocument:
	@discussion	Adds a document to the list of open documents.
	@param		document
				The document to add.
*/
- (void)addDocument:(NSDocument *)document;

/*!
	@method		removeDocument:
	@discussion	Removes a document from the list of open documents.
	@param		document
				The document to remove.
*/
- (void)removeDocument:(NSDocument *)document;

/*!
	@method		type
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)type;

/*!
	@method		width
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)width;

/*!
	@method		height
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)height;

/*!
	@method		resolution
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)resolution;

/*!
	@method		opaque
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)opaque;

/*!
	@method		m_nUnits
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)units;

/*!
	@method		editableTypes
	@discussion	The file types this document controller can open and save to.
	@result		A dict of file extensions, UTI's, and document type strings.
*/
- (NSMutableDictionary*)editableTypes;

/*!
	@method		viewableTypes
	@discussion	The file types this document controller can open.
	@result		A dict of file extensions, UTI's, and document type strings.
*/
- (NSMutableDictionary*)viewableTypes;

/*!
	@method		readableTypes
	@discussion	All of the kinds of type strings we can read in.
	@result		Flat list of all of the types.
*/
- (NSArray*)readableTypes;

/*!
	@method		type:isContainedInDocType:
	@discussion	For determining if a type string is actually of a certain doc type
	@param		type
				The type string we're geting (a file extension, UTI, doc type)
	@param		key
				The known doc type we want to see if we're part of
	@result		Whether or not type is actually of type key.
*/
- (BOOL)type:(NSString *)type isContainedInDocType:(NSString*) key;

- (NSMutableArray*)importerPluginSupportedTypes;


@end

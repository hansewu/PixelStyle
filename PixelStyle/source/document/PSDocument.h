#import "Globals.h"

/*!
	@class		PSDocument
	@abstract	Represents a single PixelStyle document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSDocument : NSDocument<NSWindowDelegate> {

	// The contents of the document (a subclass of PSContent)
	id m_idContents;
	
	// The whiteboard that represents this document
	id m_idWhiteboard;
	
	// The selection manager for this document
	id m_idSelection;
	
	// The m_idOperations manager for this document
	IBOutlet id m_idOperations;
	
	// The tools for this document
	IBOutlet id m_idTools;
	
	// An outlet to the helpers of this document
	IBOutlet id m_idHelpers;
	
	// An outlet to the warnings utility for this document
	IBOutlet id m_idWarnings;
	IBOutlet id m_idTips;
	// The plug-in data used by this document
	IBOutlet id m_idPluginData;
	
	// An outlet to the view associated with this document
	IBOutlet id m_idView;
	
	// An outlet to the window associated with this document
	IBOutlet id m_idDocWindow;//m_windowDoc
    
    IBOutlet id m_idShadowView;//m_windowDoc
	
	// The exporters
	IBOutlet id m_idPSExporter, m_idBmpExport, m_idGifExporter, m_idJpegExporter, m_idJp2Exporter, m_idPngExporter, m_idTiffExporter, m_idXcfExporter, m_idPdfExport, m_idSvgExporter;
	
	// The special texture exporter
	IBOutlet id m_idTextureExporter;
	
	// An array of all possible exporters
	id m_idExporters;
    NSMutableArray* m_exporterPluginsSupportTypes;
	
	// The view to attach to the save panel
	IBOutlet id m_idAccessoryView;
	
	// A pop-up menu of all possible exporters
	IBOutlet id m_idExportersPopUp;
	
	// The button showing the options for the exporter
	IBOutlet id m_idOptionsButton;
	
	// A summary of the export options
	IBOutlet id m_idOptionsSummary;
	
	// The Layer Data Source
	IBOutlet id m_idDataSource;
    
    //memory manager
    //IBOutlet id m_idMemoryManager;
	
	// The unique ID for layer
	int m_nUniqueLayerID;
	
	// The unique ID for floating layer
	int m_nUniqueFloatingLayerID;
	
	// The unique ID for this document (sometimes used)
	int m_nUniqueDocID;
	
	// The document's measure style
	int m_nMeasureStyle;
	
	// Is the document m_bLocked?
	BOOL m_bLocked;
	
	// Is the document initing from the pasteboard or plug-in?
	int m_nSpecialStart;
	
	// File types with Cocoa can be difficult
	BOOL m_bRestoreOldType;
	NSString *m_strOldType;
	
	// Is the file the current version?
	BOOL m_bCurrent;
    
    BOOL m_bWantCloseWindow;
    int m_saveActionType; //0 save, 1 save as, 2 export
    
    NSTimeInterval m_timeAwake;
    NSTimer *m_timerSaveTemp;
    volatile BOOL m_refreshTempDocFile;
    int m_nLastSaveIndex;
    NSLock *m_lockSaveTemp;
    	
}

// CREATION METHODS

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		initWithPasteboard
	@discussion	Initializes an instance of this class with a single pasteboard
				layer.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithPasteboard;

/*!
	@method		initWithContentsOfFile:ofType:
	@discussion	Initializes an instance of this class with the given image file.
	@param		path
				The path of the file with which to initalize this class.
	@param		type
				The type of file with which this class is being initialized.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithContentsOfFile:(NSString *)path ofType:(NSString *)type;

/*!
	@method		initWithData:type:width:height:
	@discussion	Initializes an instance of this class with the given data.
	@param		data
				The data with which this class is being initialized.
	@param		type
				The type with which this class is being initialized.
	@param		width
				The width of the data with which this class is being initialized.
	@param		height
				The height of the data with which this class is being initialized.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithData:(unsigned char *)data type:(int)type width:(int)width height:(int)height;

/*!
	@method		awakeFromNib
	@discussion	Prepares document for use.
*/
- (void)awakeFromNib;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

- (void)revertData; //add by lcz

/*!
	@method		saveDocument:
	@discussion Called to save a document (makes current).
	@param		sender
				Ignored.
*/
- (IBAction)saveDocument:(id)sender;

/*!
	@method		saveDocumentAs:
	@discussion Called to save a document as (makes current).
	@param		sender
				Ignored.
*/
- (IBAction)saveDocumentAs:(id)sender;

// GATEWAY METHODS

/*!
	@method		contents
	@discussion	Returns the contents of the document.
	@result		Returns an instance of PSContent.
*/
- (id)contents;

/*!
	@method		whiteboard
	@discussion	Returns the whiteboard of the document.
	@result		Returns an instance of PSWhiteboard.
*/
- (id)whiteboard;

/*!
	@method		selection
	@discussion	Returns the selection manager of the document.
	@result		Returns an instance of PSSelection.
*/
- (id)selection;

/*!
	@method		operations
	@discussion	Returns the operation manager of the document.
	@result		Returns an instance of PSSelection.
*/
- (id)operations;

/*!
	@method		tools
	@discussion	Returns the tools manager of the document.
	@result		Returns an instance of PSTools.
*/
- (id)tools;

/*!
	@method		helpers
	@discussion	Returns an object containing various helper methods for the
				document.
	@result		Returns an instance of PSHelpers.
*/
- (id)helpers;

/*!
	@method		memoryManager
	@discussion	Returns an  memoryManager for the
 document.
	@result		Returns an instance of PSMemoryManager.
 */
//- (id)memoryManager;

/*!
	@method		warnings
	@discussion	Returns an object contaning the warning related methods.
	@result		Returns an instance of WarningsUtility.
*/
- (id)warnings;
- (id)tips;
/*!
	@method		pluginData
	@discussion	Returns the object shared between PixelStyle and most plug-ins.
	@result		Returns an instance of PluginData.
*/
- (id)pluginData;

/*!
	@method		docView
	@discussion	Returns the document view of the document.
	@result		Returns an instance of PSView.
*/
- (id)docView;

- (id)shadowView;

/*!
	@method		window
	@discussion	Returns the window of the document.
	@result		Returns an instance of NSWindow.
*/
- (id)window;

/*!
	@method		updateWindowColor
	@discussion	Updates the color of the window background
*/
- (void)updateWindowColor;

/*!
	@method		textureExporter
	@discussion	Returns the texture exporter.
	@result		Returns an instance of TextureExporter.
*/
- (id)textureExporter;

// DOCUMENT METHODS

/*!
	@method		readFromFile:ofType:
	@discussion	Reads a given file from disk.
	@param		path
				The path of the file to be read.
	@param		type
				The type of the file to be read.
	@result		Returns YES if the file is successfully read, NO otherwise.
*/
- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)type;

/*!
	@method		writeToFile:ofType:
	@discussion	Writes the document's data to disk.
	@param		path
				The path of the file that the data should be written to.
	@param		type
				The type of the file that the data that should be written to.
	@result		Returns YES if the file is successfully written, NO otherwise.
*/
- (BOOL)writeToFile:(NSString *)filename ofType:(NSString *)ignore;

/*!
	@method		printShowingPrintPanel:
	@discussion	Prints the document, showing the print panel if requested.
	@param		showPanels
				YES if the method should show the associated print panels, NO
				otherwise.
*/
- (void)printShowingPrintPanel:(BOOL)showPanels;

/*!
	@method		prepareSavePanel:
	@discussion	Customizes the save panel, adding a pop-up menu through which
				the user can select a particular exporter.
	@param		savePanel
				The save panel to be adjusted.
	@result		Returns YES if the adjustment was successful, NO otherwise.
*/
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;

/*!
	@method		showExporterOptions:
	@discussion	Displays the options for the currently selected exporter.
	@param		sender
				Ignored.
*/
- (IBAction)showExporterOptions:(id)sender;

/*!
	@method		exporterChange:
	@discussion	Changes the active exporter for the document based upon the
				selection of the exportersPopUp.
	@param		sender
				Ignored.
*/
- (IBAction)exporterChanged:(id)sender;

// DOCUMENT EVENT METHODS

/*!
	@method 	close
	@discussion	Called to close the document.
*/
- (void)close;

/*!
	@method		windowDidBecomeMain:
	@discussion	Called when a sheet is shown.
	@param		notification
				Ignored.
*/
- (void)windowWillBeginSheet:(NSNotification *)notification;

/*!
	@method		windowDidEndSheet:
	@discussion	Called after a sheet is closed.
	@param		notification
				Ignored.
*/
- (void)windowDidEndSheet:(NSNotification *)notification;

/*!
	@method		windowDidBecomeMain:
	@discussion	Called when the document is activated.
	@param		notification
				Ignored.
*/
- (void)windowDidBecomeMain:(NSNotification *)notification;

/*!
	@method		windowDidResignMain:
	@discussion	Called when the document loses focus.
	@param		notification
				Ignored.
*/
- (void)windowDidResignMain:(NSNotification *)notification;

/*!
	@method		windowDidResignKey:
	@discussion	Called when the document loses key focus.
	@param		notification
				Ignored.
*/
- (void)windowDidResignKey:(NSNotification *)aNotification;

/*!
	@method		windowWillUseStandardFrame:defaultFrame:
	@discussion	Called when the document wants to zoom.
	@param		sender
				The window zooming
	@param		defaultFrame
				Ignored
	@result		Returns the new frame of the window
*/
- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame;

/*!
	@method		standardFrame
	@discussion	For calculating the preferred size of the window.
	@result		Returns the rect of the new frame.
*/
- (NSRect) standardFrame;

// EXTRA METHODS

/*!
	@method		current
	@discussion	Returns a boolean indicating whether the document is current.
				Documents are not current, if they were created using the "Compare
				to Last Saved" menu item and have not been resaved since.
	@result		Returns YES if the document is original, NO otherwise.
*/
- (BOOL)current;

/*!
	@method		setCurrent
	@discussion	Sets the current boolean to the specified value. Remember non-current
				documents will be deleted upon closing!
*/
- (void)setCurrent:(BOOL)value;

/*!
	@method		uniqueLayerID
	@discussion	Returns a unique ID for a given layer and then increments the
				uniqueLayerID instance variable so the next layer will recieve a
				unique ID. To ensure sequential numbering this method should
				only be called once by the intializer of PSLayer and its result
				stored.
	@result		Returns an integer representing a new layer may assign to
				itself.
*/
- (int)uniqueLayerID;

/*!
	@method		uniqueFloatingLayerID
	@discussion	Returns a unique ID for a given floating layer and then
				increments the uniqueFloatingLayerID instance variable so the
				next floating layer will recieve a unique ID. To ensure
				sequential numbering this method should only be called once by
				the intializer of SeaFloatingLayer and its result stored.
	@result		Returns an integer representing a new layer may assign to
				itself.
*/
- (int)uniqueFloatingLayerID;

/*!
	@method		uniqueDocID
	@discussion	Returns the unique ID of the document.
	@result		Returns an integer representing a unique ID for the document.
*/
- (int)uniqueDocID;

/*!
	@method		windowNibName
	@discussion	Returns the name of the NIB file associated with this document's
				window for use by NSDocumentController.
	@result		Returns an NSString representing the name of the NIB file.
*/
- (NSString *)windowNibName;

// MENU RELATED

/*!
	@method		customUndo:
	@param		sender
				Ignored.
	@discussion	Undoes the last change.
*/
- (IBAction)customUndo:(id)sender;

/*!
	@method		customRedo:
	@param		sender
				Ignored.
	@discussion	Redoes the last change.
*/
- (IBAction)customRedo:(id)sender;

/*!
	@method		changeMeasuringStyle:
	@discussion	Changes the measuring style of the document.
	@param		aStyle
				An integer representing the measuring style (see
				Units.h).
*/
- (void)changeMeasuringStyle:(int)aStyle;

/*!
	@method		measureStyle
	@discussion	Returns the measuring style.
	@result		Returns an integer representing the measuring style (see
				Units.h).
*/
- (int)measureStyle;

/*!
	@method		locked
	@discussion	Returns whether or not the document is locked. The document can
				be locked as a consequence of a call to lock or as a consequence
				of a sheet being open in the documents window.
	@result		Returns YES if the document is locked, NO otherwise.
*/
- (BOOL)locked;

/*!
	@method		lock
	@discussion	Locks the document (regardless of how many calls were previously
				made to unlock). When the document is locked the user is
				prevented from making certain changes to the document (i.e.
				undoing things, removing layers, etc.). Locking is an internal
				temporary state and as such should be used when drawing or
				changing the margins of the document not to prevent users from
				changing a read-only file.
*/
- (void)lock;

/*!
	@method		unlock
	@discussion	Unlocks the document (regardless of how many calls were
				previously made to lock). When the document is locked the user
				is prevented from making certain changes to the document (i.e.
				undoing things, removing layers, etc.). Locking is an internal
				temporary state and as such should be used when drawing or
				changing the margins of the document not to prevent users from
				changing a read-only file.
*/
- (void)unlock;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

/*!
	@method		runModalSavePanelForSaveOperation:delegate:didSaveSelector:contextInfo:
	@discussion	Runs the save panel for the given save operation.
	@param		saveOperation
				The save operation.
	@param		delegate
				The save panel's delegate.
	@param		didSaveSelector
				The callback selector once the save panel is complete.
	@param		contextInfo
				The pointer to pass to the callback method.
*/
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo;

/*!
	@method		document:didSave:contextInfo:
	@param		doc
				The document being saved.
	@param		didSave
				Whether the document was saved.
	@param		contextInfo
				A pointer to pass to the callback method.
*/
- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;

/*!
	@method		fileTypeFromLastRunSavePanel
	@discussion	Must be overridden to make sure the saving of files works
				correctly.
	@result		Returns exactly the same as the "fileType" method would.
*/
- (NSString *)fileTypeFromLastRunSavePanel;

/*!
    @method     scrollView
	@result		Returns the document main view as a scroll view
*/

- (NSScrollView *)scrollView;

/*!
	@method		dataSource
	@result		Returns the data source used by the layers view
*/
- (id) dataSource;

- (BOOL)canResponseForView:(id)view;

- (void)refreshTempDocumentFile;

@end

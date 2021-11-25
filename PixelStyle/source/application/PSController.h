#import "Globals.h"

/*!
	@class		PSController
	@abstract	Handles a number of special duties relating to the application's
				operation.
	@discussion	The PSController is the sole delegate of NSApp and also
				contains a number of class methods that allow users to access
				various objects that are created by the MainMenu NIB file.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSController : NSObject <NSApplicationDelegate>{
	
	// An outlet to the utilities manager of the application
	IBOutlet id m_idUtilitiesManager;
	
	// An outlet to the plug-ins manager of the application
	IBOutlet id m_idPSPlugins;
	
	// An outlet to the preferences manager of the application
	IBOutlet id m_idPSPrefs;
	
	// An outlet to the proxy object of the application
	IBOutlet id m_idPSProxy;
	
    // An outlet to the vector proxy object of the application
    IBOutlet id m_idPSVectorProxy;
	// An outlet to the help manager of the application
	IBOutlet id m_idPSHelp;

	// An outlet to the warning manager of the application
	IBOutlet id m_idPSWarning;
	
	// The window containing the GNU General Public License
	IBOutlet id m_idLicenseWindow;
	
	// An array of objects wishing to recieve the terminate message
	NSArray *m_arrTerminationObjects;
    
    id          m_pEmailController;
    
    //NSMenu
    IBOutlet NSMenuItem     *m_menuItemAbout;
    IBOutlet NSMenuItem     *m_menuItemHide;
    IBOutlet NSMenuItem     *m_menuItemQuit;
    IBOutlet NSMenuItem     *m_menuItemHelp;
    IBOutlet NSMenuItem     *m_menuItemForum;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		applicationDidFinishLaunching:
	@discussion	Called when the application finishes launching.
	@param		notification
				Ignored.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

/*!
	@method		utilitiesManager
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of UtilitiesManager.
*/
+ (id)utilitiesManager;

/*!
	@method		seaPlugins
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of PSPlugins.
*/
+ (id)seaPlugins;

/*!
	@method		m_idPSPrefs
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of PSPrefs.
*/
+ (id)m_idPSPrefs;

/*!
	@method		seaProxy
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of PSProxy.
*/
+ (id)seaProxy;

+ (id)psVectorProxy;

/*!
	@method		seaHelp
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of PSHelp.
*/
+ (id)seaHelp;

/*!
	@method		seaWarning
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of PSWarning.
*/
+ (id)seaWarning;

/*!
	@method		revert:
	@discussion	Implements a custom revert method that closes the current
				document and reopens it.
	@param 		sender
				Ignored.
*/
- (IBAction)revert:(id)sender;

/*!
	@method		editLastSaved:
	@discussion	Copies the current document file on disk and opens it.
	@param		sender
				Ignored.
*/
- (IBAction)editLastSaved:(id)sender;

/*!
	@method		colorSyncChanged:
	@discussion	Notifies all documents when the ColorSync preferences change.
	@param		notification
				Ignored.
*/
- (void)colorSyncChanged:(NSNotification *)notification;

/*!
	@method		showLicense:
	@discussion	Shows the license for PixelStyle.
	@param		sender
				Ignored.
*/
- (IBAction)showLicense:(id)sender;

/*!
	@method		newDocumentFromPasteboard:
	@discussion	Adds a new document with the contents of the pasteboard.
	@param		sender
				Ignored.
*/
- (IBAction)newDocumentFromPasteboard:(id)sender;

/*!
	@method		registerForTermination:
	@discussion	Registers any given object so that it recieves a terminate
				message before the application quits.
	@param		object
				The object that wishes to recieve a termination message (the
				object is not retained).
*/
- (void)registerForTermination:(id)object;

/*!
	@method		applicationWillTerminate:
	@discussion	Notifies all registered objects of PixelStyle's termination and
				also synchronizes preferences.
	@param		notification
				Ignored.
*/
- (void)applicationWillTerminate:(NSNotification *)notification;

/*!
	@method		applicationShouldOpenUntitledFile:
	@discussion	Returns whether a new document should be created when the
				application starts.
	@param		app
				Ignored.
	@result		Returns YES if a new document should be created when the
				application starts, NO otherwise.
*/
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app;

/*!
	@method		applicationOpenUntitledFile:
	@discussion	Opens a new untitled file for the application.
	@param		app
				Ignored.
	@result		Returns YES if a new document should be created when the
				application starts, NO otherwise.
*/
- (BOOL)applicationOpenUntitledFile:(NSApplication *)app;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

@end

#import "Globals.h"

/*!
	@class		ToolboxUtility
	@abstract	Allows the user to select a range of tools for image
				manipulation.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@class MyToolBarView;
@interface ToolboxUtility : NSObject<NSToolbarDelegate> {

	// The document which is the focus of this utility
	IBOutlet id m_idDocument;

	// The proxy object
	IBOutlet id m_PSProxy;
	
	// The current foreground and background colour
	id m_idForeground, m_idBackground;
	
	// The colorSelectView associated with this utility
	IBOutlet id m_idColorSelectView;
	
	// The toolbox
	IBOutlet id m_idToolbox;
	
	// The options utility object
	IBOutlet id m_idOptionsUtility;
	
    IBOutlet MyToolBarView *m_tbvMyToolBar;
    
	// The tag of the currently selected tool
	int m_nTool;
	
	// The old tool
	int m_nOldTool;

	// The toolbar
	id m_idToolbar;
	
	IBOutlet id m_idSelectionMenu;
	IBOutlet id m_idDrawMenu;
	IBOutlet id m_idEffectMenu;
	IBOutlet id m_idTransformMenu;
	IBOutlet id m_idColorsMenu;
	
	// A timer that delays colour changes
	id m_idDelayTimer;
    
    BOOL m_colorCanChange; //add by lcz
    
    NSArray *m_arrToolBtnTip;
    NSArray *m_arrToolBtnShotKey;
    
    int m_arrayLastTools[10];
    unichar m_nLastToolType;
    
    NSMutableArray *m_arrTools;
    NSMutableArray *m_arrGroupsTools;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		foreground
	@discussion	Returns the foreground colour.
	@result		Returns a NSColor representing the foreground colour.
*/
- (NSColor *)foreground;

/*!
	@method		background
	@discussion	Returns the background colour.
	@result		Returns a NSColor representing the background colour.
*/
- (NSColor *)background;

/*!
	@method		setForeground:
	@discussion	Sets the foreground colour to that given.
	@param		color
				The new foreground colour, the instance of NSColor is retained
				by PSContent (and freed when there is no longer any use for
				it).
*/
- (void)setForeground:(NSColor *)color;

/*!
	@method		setBackground:
	@discussion	Sets the background colour to that given.
	@param		color
				The new background colour, the instance of NSColor is retained
				by PSContent (and freed when there is no longer any use for
				it).
*/
- (void)setBackground:(NSColor *)color;

/*!
	@method		colorView
	@discussion	Returns the color view for actions
	@result		A ColorSelectView pointer.
*/

- (id)colorView;

/*!
	@method		acceptsFirstMouse:
	@discussion	Returns whether or not the window accepts the first mouse click
				upon it.
	@param		event
				Ignored.
	@result		Returns YES indicating that the window does accept the first
				mouse click upon it.
*/
- (BOOL)acceptsFirstMouse:(NSEvent *)event;

/*!
	@method		activate
	@discussion	Activates this utility with its document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates this utility.
*/
- (void)deactivate;

/*!
	@method		update:
	@discussion	Updates the utility for the current document.
	@param		full
				YES if the update is to also include setting the cursor, NO
				otherwise.
*/
- (void)update:(BOOL)full;

/*!
	@method		tool
	@discussion	Returns the currently selected tool.
	@result		Returns the tool type (see PSTools) representing the currently
				selected tool.
*/
- (int)tool;

/*!
	@method		selectToolUsingTag:
	@discussion	Called by menu item to change the tool.
	@param		sender
				An object with a tag that modulo-100 specifies the tool to be
				selected.
*/
- (IBAction)selectToolUsingTag:(id)sender;

/*!
	@method		selectToolFromSender:
	@discussion	Called when the segmented controls get clicked.
	@param		sender
				The segemented control to select the tool.
*/
- (IBAction)selectToolFromSender:(id)sender;

/*!
	@method		changeToolTo:
	@discussion	Preforms checks to make sure changing the tool is valid, and if any updates are needed.
	@param		newTool
				The index of the new tool.
*/
- (void)changeToolTo:(int)newTool;

- (void)setColorCanChange:(BOOL)canChange; //add by lcz

/*!
	@method		floatTool
	@discussion	Selects the position tool.
*/
- (void)floatTool;

/*!
	@method		anchorTool
	@discussion	Selects the last tool to call floatTool
*/
- (void)anchorTool;

/*
	@method		setEffectEnabled:
	@discussion	Sets whether the effect tool is enabled or not.
	@param		enable
				YES to enable the tool, NO otherwise.
*/
- (void)setEffectEnabled:(BOOL)enable;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled and choses the correct menu item title for it if
				appropriate).
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

- (unichar)lastCombinedToolType;
- (int)lastCombinedTool:(unichar)type;

-(NSArray *)allShowTools;
-(unichar)getToolShotKey:(int)nToolIndex;

- (void)switchToolWithToolIndex:(NSInteger)nCurrentShowToolIndex;

@end

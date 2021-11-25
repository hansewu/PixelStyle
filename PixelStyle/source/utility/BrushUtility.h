#import "Globals.h"
#import "AbstractPanelUtility.h"

/*!
	@class		BrushUtility
	@abstract	Loads and manages all brushes for the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface BrushUtility : AbstractPanelUtility <NSTextFieldDelegate>{

	// The brush grouping pop-up
	IBOutlet id m_idBrushGroupPopUp;

	// The label that presents the user with the brushes name
	IBOutlet id m_idBrushNameLabel;
	
	// The label and slider that present spacing to the user
    IBOutlet id m_idSpacingLabel;
    IBOutlet id m_idSpacingSlider;
	
	// The view that displays the brushes
    IBOutlet id m_idView;
		
	// The document which is the focus of this utility
	IBOutlet id m_idDocument;
    
    IBOutlet NSTextField *m_labelSpacing;
	
	// An dictionary of all brushes known to PixelStyle
	NSDictionary *m_dicBrushes;
	
	// An array of all groups (an array of an array SeaBrush's) and group names (an array of NSString's)
	NSArray *m_arrGroups;
	NSArray *m_arrGroupNames;
	
	// The index of the currently active group
	int m_nActiveGroupIndex;
	
	// The index of the currently active brush
	int m_nActiveBrushIndex;
	
	// The number of custom groups
	int m_nCustomGroups;
	
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
	@method		shutdown
	@discussion	Saves currently selected brush upon shutdown.
*/
- (void)shutdown;

/*!
	@method		loadBrushes:
	@discussion	Frees (if necessary) and then reloads all the brushes from
				PixelStyle's brushes directory.
	@param		update
				YES if the brush utility should be updated after reloading all
				the brushes (typical case), NO otherwise.
*/
- (void)loadBrushes:(BOOL)update;

/*!
	@method		changeSpacing:
	@discussion	Called when the brush spacing is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeSpacing:(id)sender;

/*!
	@method		changeGroup:
	@discussion	Called when the brush group is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeGroup:(id)sender;

/*!
	@method		spacing
	@discussion	Returns the spacing associated with the current brush.
	@result		Returns an integer indicating the spacing associated with the
				current brush.
*/
- (int)spacing;

/*!
	@method		activeBrush
	@discussion	Returns the currently active brush.
	@result		Returns an instance of PSBrush representing the currently
				active brush.
*/
- (id)activeBrush;

/*!
	@method		activeBrushIndex
	@discussion	Returns the index of the currently active brush.
	@result		Returns an integer representing the index of the currently
				active brush.
*/
- (int)activeBrushIndex;

/*!
	@method		setActiveBrushIndex:
	@discussion	Sets the active brush to that specified by the given index.
	@param		index
				The index of the brush to activate.
*/
- (void)setActiveBrushIndex:(int)index;

/*!
	@method		brushes
	@discussion	Returns all the brushes in the currently active group.
	@result		Returns an array with all the brushes in the currently active
				group. 
*/
- (NSArray *)brushes;

- (NSArray *)allBrushes;

@end

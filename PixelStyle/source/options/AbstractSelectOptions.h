#import "Globals.h"
#import "AbstractScaleOptions.h"

/*		
	@class		AbstractSelectOptions
	@abstract	Acts as a base class for the options panes of the selection tools.
	@discussion	This class is responsible for keeping track of the mode of the selection,
				since all selection tools share the same modes.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface AbstractSelectOptions : AbstractScaleOptions<NSTextFieldDelegate> {
	// The Selection mode
	int m_nMode , m_nLastMode;
    
    // Show the feather for the rectangle
    IBOutlet NSTextField *m_texFieldFeather;
    IBOutlet NSTextField *m_labelFeather;
}

/*!
	@method		selectionMode
	@discussion	Returns the mode to be used for the selection.
	@result		Returns an integer indicating the mode (see PSSelection).
*/
- (int)selectionMode;

/*!
	@method		setModeFromModifier:
	@discussion	Sets the mode, based on a modifier from the keyboard or the popup menu.
	@param		modifier
				The modifier of the new mode to be set, from the k...Modifier enum.
*/
- (void)setModeFromModifier:(unsigned int)modifier;


/*!
	@method		feather
	@discussion	Returns feather to be used with the rectangle.
	@result		Returns an integer indicating the feather to be used with
 the rectangle.
 */
- (int)feather;

@end

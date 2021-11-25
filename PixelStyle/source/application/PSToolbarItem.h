#import "Globals.h"

/*!
	@class		PSToolbarItem
	@abstract	A class to create simple view-based toolbar items.
	@discussion	Used PSImageToolbarItem for image-based toolbar items.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> N/A
*/

@interface PSToolbarItem : NSToolbarItem {	
}

/*!
	@method		validate
	@discussion	With view-based toolbar items a custom validation function must be defined, or else
				the item will not be enabled. This provides a simple function that is always
				enabled.
*/
- (void) validate;

@end

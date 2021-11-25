#import "Globals.h"
#import "AbstractSelectOptions.h"

/*!
	@class		LassoOptions
	@abstract	Handles the options pane for the lasso tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface LassoOptions : AbstractSelectOptions {
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
 */
- (void)awakeFromNib;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
 */
- (void)shutdown;

@end

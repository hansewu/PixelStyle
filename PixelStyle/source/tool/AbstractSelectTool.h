/*!
 @class		AbstractSelectTool
 @abstract	Acts as a base class for all tools that use selection.
 @discussion	This tool has some additional functionality to handle masks and such.
 <br><br>
 <b>License:</b> GNU General Public License<br>
 <b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "AbstractScaleTool.h"

@interface AbstractSelectTool : AbstractScaleTool {
    
    BOOL m_bOldActive;
    
    NSCursor *m_curDefault;
    NSCursor *m_curAdd;
    NSCursor *m_curSubtract;
    NSCursor *m_curMultipy;
    NSCursor *m_curSubtractProduct;
}

/*!
	@method		cancelSelection
	@discussion	Stops making the selection
*/
- (void)cancelSelection;

@end

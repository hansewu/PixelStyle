/*!
	@class		PSPlugins
	@abstract	A skeleton version of the PSPlugins class.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import "PluginData.h"

@interface PSPlugins : NSObject {

}

/*!
	@method		data
	@discussion	Returns the PluginData object shared between PhotoArt and the plug-in.
    @//discussion 返回PluginData对象 shared between PhotoArt and the plug-in
	@result		Returns the PluginData object shared between PhotoArt and the plug-in.
*/
- (PluginData *)data;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
    @discussion 决定一个给定的菜单项是否是激活状态。
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

@end

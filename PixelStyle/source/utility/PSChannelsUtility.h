//
//  PSChannelsUtility.h
//  PixelStyle
//
//  Created by lchzh on 5/9/17.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface PSChannelsUtility : NSObject
{
    IBOutlet NSView *m_viewChannels;
    // The document this data source is connected to
    IBOutlet id m_idDocument;
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
	@method		shutdown
	@discussion	Saves current transparency colour upon shutdown.
 */
- (void)shutdown;

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
	@method		show:
	@discussion	Shows the utility's window.
	@param		sender
 Ignored.
 */
- (IBAction)show:(id)sender;

/*!
	@method		hide:
	@discussion	Hides the utility's window.
	@param		sender
 Ignored.
 */
- (IBAction)hide:(id)sender;

/*!
	@method		toggle:
	@discussion	Toggles the visibility of the utility's window.
	@param		sender
 Ignored.
 */
- (IBAction)toggle:(id)sender;

/*!
	@method		update
	@discussion	Updates the utility to reflect the current cursor position and
 associated data.
 */
- (void)update;

/*!
	@method		visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
 */
- (BOOL)visible;

@end

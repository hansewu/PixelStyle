//
//  PSHistogramUtility.h
//  PixelStyle
//
//  Created by lchzh on 4/11/15.
//
//

#import <Foundation/Foundation.h>

enum{
    Histogram_Channel_COLOR,
    Histogram_Channel_LUMINANCE,
    Histogram_Channel_RED,
    Histogram_Channel_GREEN,
    Histogram_Channel_BLUE,
};


@interface PSHistogramUtility : NSObject
{
    IBOutlet id m_idDocument;
    IBOutlet id m_idHistogramView;
    
    IBOutlet id m_idChooseChannel;
    
    
    int m_channelType;
    unsigned char m_grayHistogramInfo[256];
    unsigned char m_rgbHistogramInfo[256*3];
    int m_sourceType;
    
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

- (IBAction)changeChannel:(id)sender;
-(void)setChannel:(int)nChannelType;


@end

#import "Globals.h"

/*!
	@class		PSOperations
	@abstract	Acts as a gateway to the various operations of PixelStyle.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PSOperations : NSObject {

	// Outlets to the instances of the same name
	IBOutlet id m_idPSAlignment;
    IBOutlet id m_idPSMargins;
    IBOutlet id m_idPSResolution;
    IBOutlet id m_idPSScale;
	IBOutlet id m_idPSDocRotation;
	IBOutlet id m_idPSRotation;
	IBOutlet id m_idPSFlip;

}

/*!
	@method		seaAlignment
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the PSAlignment class.
*/
- (id)seaAlignment;

/*!
	@method		m_idPSMargins
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the PSMargins class.
*/
- (id)seaMargins;

/*!
	@method		seaResoulution
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaResoulution class.
*/
- (id)seaResolution;

/*!
	@method		m_idPSScale
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the PSScale class.
*/
- (id)seaScale;

/*!
	@method		m_idPSDocRotation
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the PSDocRotation class.
*/
- (id)seaDocRotation;

/*!
	@method		m_idPSRotation
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the PSRotation class.
*/
- (id)seaRotation;

/*!
	@method		m_idPSFlip
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the PSFlip class.
*/
- (id)seaFlip;

@end

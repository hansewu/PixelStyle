#import "Globals.h"
#import "AbstractExporter.h"

/*!
	@defined	kMaxCompression
	@discussion	Specifies the maximum compression value for a JPEG image.
*/
#define kMaxCompression 30

/*!
	@class		JP2Exporter
	@abstract	Exports to the JPEG 2000 file format using Cocoa.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface JP2Exporter : AbstractExporter {

	// The compression factor to be used with the web target (between 0 and 30)
	int m_nWebCompression;

	// The compression factor to be used with the print target (between 0 and 30)
	int m_nPrintCompression;
	
	// YES if targeting the web, NO if targeting print
	BOOL m_bTargetWeb;

	// The panel allowing compression options to be set
	IBOutlet id m_idPanel;
	
	// The compressed preview
	IBOutlet id m_idCompressImageView;
	
	// The uncompressed preview
	IBOutlet id m_idRealImageView;
	
	// The label specifying the compression level
	IBOutlet id m_idCompressLabel;
	
	// The slider allowing compression to be adjusted
	IBOutlet id m_idCompressSlider;
	
	// The radio buttons specifying the target
	IBOutlet id m_idTargetRadios;
	
	// The sample data we are previewing
	unsigned char *m_pSampleData;
	
	// The NSImageBitmapRep used by the uncompressed preview
	id m_idRealImageRep;

}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		compressionChanged:
	@discussion	Called when the user adjusts the compression slider.
	@param		sender
				Ignored.
*/
- (IBAction)compressionChanged:(id)sender;

/*!
	@method		targetChanged:
	@discussion	Called when the user adjusts the media target.
	@param		sender
				Ignored.
*/
- (IBAction)targetChanged:(id)sender;

/*!
	@method		endPanel:
	@discussion	Called to close the options dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end

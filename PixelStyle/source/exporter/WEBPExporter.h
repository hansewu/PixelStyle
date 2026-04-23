#import "Globals.h"
#import "AbstractExporter.h"

/*!
 @class      WEBPExporter
 @abstract   Exports to the WebP file format using libwebp.
 @discussion N/A
             <br><br>
             <b>License:</b> GNU General Public License<br>
             <b>Copyright:</b> Copyright (c) 2023 PixelStyle Project
 */

@interface WEBPExporter : AbstractExporter {
    // The quality factor to be used for WebP encoding (between 0.0 and 1.0, default 0.8)
    float m_fQuality;
    
    // Original quality when options panel is shown (for cancel)
    float m_fOriginalQuality;
    
    // The panel allowing quality options to be set
    IBOutlet id m_idPanel;
    
    // The compressed preview
    IBOutlet id m_idCompressImageView;
    
    // The uncompressed preview
    IBOutlet id m_idRealImageView;
    
    // The label specifying the quality level
    IBOutlet id m_idQualityLabel;
    
    // The slider allowing quality to be adjusted
    IBOutlet id m_idQualitySlider;
    
    // The sample data we are previewing
    unsigned char *m_pSampleData;
    
    // The NSImageBitmapRep used by the uncompressed preview
    id m_idRealImageRep;
}

/*!
 @method     init
 @discussion Initializes an instance of this class.
 @result     Returns instance upon success (or NULL otherwise).
 */
- (id)init;

/*!
 @method     dealloc
 @discussion Frees memory occupied by an instance of this class.
 */
- (void)dealloc;

/*!
 @method     qualityChanged:
 @discussion Called when the user adjusts the quality slider.
 @param      sender
             Ignored.
 */
- (IBAction)qualityChanged:(id)sender;

/*!
 @method     endPanel:
 @discussion Called to close the options dialog.
 @param      sender
             Ignored.
 */
- (IBAction)endPanel:(id)sender;

/*!
 @method     reviseQuality
 @discussion Updates the quality label and returns the current quality value.
 @result     Returns the current quality as a float between 0.0 and 1.0.
 */
- (float)reviseQuality;

@end

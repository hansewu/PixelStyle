#import "Globals.h"
#import "AbstractPaintOptions.h"
#import "PSFontPanel.h"
#import "MyCustomComboBox.h"
#import "MyCustomPanel.h"
/*!
	@class		TextOptions
	@abstract	Handles the options pane for the text tool.
	@discussion	N/A
 <br><br>
 <b>License:</b> GNU General Public License<br>
 <b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
 */
//enum {
//    PSShapeRectangle = 0,
//    PSShapeOval,
//    PSShapeStar,
//    PSShapePolygon,
//    PSShapeLine,
//    PSShapeSpiral
//};

@class PSFontPanel;

@interface VectorOptions : AbstractPaintOptions<FontFamilyNotifyProtocol, MyCustomComboBoxDelegate,MyCustomPanelDelegate>
{
    
    IBOutlet id m_idButtonFontType;
    IBOutlet id  m_btSelectFontFamily;
    IBOutlet id  m_comboFontSize;

    IBOutlet id  m_btColorFill;
    
    IBOutlet id  m_btBold;
    IBOutlet id  m_btItalics;
    IBOutlet id  m_btUnderline;
    IBOutlet id  m_btStrikethrough;
    
//    IBOutlet id  m_sliderSpacing;

    IBOutlet id  m_btCustomTransform;
    IBOutlet id  m_sliderTransformValue;
    
    IBOutlet id m_myCustomBoxSpacing;
    
    IBOutlet id m_btnShowCustomTransformPanel;
    IBOutlet id m_idCustomTransformPanel;
    
    
    PSFontPanel *m_fontPanel;
    NSString *m_strFontFamily;
    
    NSColor *m_colorFontFill;
    
    int m_nShapeMode;
    
    // polygon support
    int                 m_nPolygonNumPoints;
    
    // rect support
    float               m_fRectCornerRadius;
    
    // star support
    int                 m_nStarNumPoints;
    float               m_fStarInnerRadiusRatio;
    float               m_fStarLastRadius;
    
    // spiral support
    int                 m_nSpiralDecay;
}


- (void)awakeFromNib;

- (void)setShapeMode:(int)nShapeMode;
- (int)shapeMode;

- (void)setPolygonNumPoints:(int)nPolygonNumPoints;
- (int)polygonNumPoints;

- (void)setRectCornerRadius:(float)fRectCornerRadius;
- (float)rectCornerRadius;

- (void)setStarNumPoints:(int)nStarNumPoints;
- (int)starNumPoints;

- (void)setStarInnerRadiusRatio:(float)fStarInnerRadiusRatio;
- (float)starInnerRadiusRatio;

- (void)setStarLastRadius:(float)fStarLastRadius;
- (float)starLastRadius;

- (void)setSpiralDecay:(int)nSpiralDecay;
- (int)spiralDecay;
/*!
	@method		alignment
	@discussion	Returns the alignment to be used with the text tool.
	@result		Returns an NSTextAlignment representing an alignment type.
 */
- (NSTextAlignment)alignment;

/*!
	@method		useSubpixel
	@discussion	Returns whether subpxiel rendering should be used.
	@result		Returns YES if subpixel rendering should be used, NO otherwise.
 */
- (BOOL)useSubpixel;

/*!
	@method		outline
	@discussion	Returns the number of points the outline should be.
	@result		Returns an integer indicating the number of points the outline should be
 or zero if outline is disabled.
 */
- (int)outline;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
 should use the foreground colour.
 */
- (BOOL)useTextures;

/*!
	@method		allowFringe
	@discussion	Returns whether a fringe is allowed, the fringe is determined using
 the background layers and will look out of place if the background
 changes. On the other hand, the fringe will look better if the
 background does not change.
	@result		Returns YES if the fringe should be allowed, NO otherwise.
 */
- (BOOL)allowFringe;

/*!
	@method		update
	@discusison	Updates the options and tool after a change.
	@param		sender
 Ignored.
 */
- (IBAction)update:(id)seder;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
 */
- (void)shutdown;

@end

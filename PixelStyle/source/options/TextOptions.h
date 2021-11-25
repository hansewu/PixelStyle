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
@class PSFontPanel;

@interface TextOptions : AbstractPaintOptions<FontFamilyNotifyProtocol, MyCustomComboBoxDelegate,MyCustomPanelDelegate, NSTextFieldDelegate>
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
    IBOutlet id  m_textFieldTransformValue;
    
    IBOutlet id m_myCustomBoxSpacing;
    
    IBOutlet id m_btnShowCustomTransformPanel;
    IBOutlet id m_idCustomTransformPanel;
    
    IBOutlet id m_labelType;
    IBOutlet id m_labelBending;

    
    PSFontPanel *m_fontPanel;
    NSString *m_strFontFamily;
    
    NSColor *m_colorFontFill;
}


- (void)awakeFromNib;

- (IBAction)showFonts:(id)sender;

- (IBAction)changeFontType:(id)sender;

- (IBAction)changeFontSize:(id)sender;

- (IBAction)changeFontColor:(id)sender;

- (IBAction)changeFontBold:(id)sender;
- (IBAction)changeFontItalics:(id)sender;
- (IBAction)changeFontUnderline:(id)sender;
- (IBAction)changeFontStrikethrough:(id)sender;

- (IBAction)changeCharacterSpacing:(id)sender;


- (IBAction)showCustomTransformPanel:(id)sender;
- (IBAction)changeCustomTransformType:(id)sender;
- (IBAction)changeCustomTransformValue:(id)sender;

- (void)updtaeUIForFont:(NSString *)strFontName;
- (void)updateUIForFontSize:(CGFloat)fSize;
- (void)updateUIForCustomTransformType:(int)type;
- (void)updateUIForCustomTransformValue:(CGFloat)fValue;

- (void)updtaeUIForFontColor:(NSColor *)color;

- (void)updtaeUIForFontBold:(int)nWidth;
- (void)updtaeUIForFontItalics:(int)nItalicsValue;
- (void)updtaeUIForFontUnderline:(int)nUnderlineValue;
- (void)updtaeUIForFontStrikethrough:(int)nStrikethroughValue;

- (IBAction)updtaeUIForFontCharacterSpacing:(int)nSpaceValue;
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

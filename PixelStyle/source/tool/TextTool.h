#import "Globals.h"
#import "AbstractTool.h"
#import "PSTextInputView.h"
/*!
	@class		VectorTool
	@abstract	The text tool's role is much the same as in any paint program.
	@discussion	N/A
 
 */
typedef struct
{
    BOOL        bMouseDownInArea;
    BOOL        bMovingText;
    CGPoint    pointMouseDown;
    CGPoint     pointOldStart;
    NSTimeInterval      timeMouseDown;
    IntPoint oldOffsets;
}MOUSE_DOWN_INFO;

@interface TextTool : AbstractTool {
    
    // The preview panel
    IBOutlet id m_idPanel;
    
    // The move panel
    IBOutlet id m_idMovePanel;
    
    // The preview text box
    IBOutlet id m_idTextbox;
    
    // The font manager associated with the text tool
    id m_idFontManager;
    
    // The point where the mouse was released
    IntPoint m_sWhere;
    
    // The rect containing the preview
    IntRect m_sPreviewRect;
    
    // Is the tool running?
    BOOL m_bRunning;
    
    PSTextInputView *m_textInputView;
    
    NSTimer     *m_timerTextCursor;
    
    MOUSE_DOWN_INFO m_MouseDownInfo;
    
    NSTimeInterval m_timeIntervalPast;
    
}

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
 */
- (void)dealloc;

//- (void)setFontName:(NSString *)fontName;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		iwhere
 Where in the document the mouse up event occurred (in terms of
 the document's pixels).
	@param		event
 The mouse up event.
 */
- (void)mouseUpAt:(IntPoint)iwhere withEvent:(NSEvent *)event;

/*!
	@method		apply:
	@discussion	Called to close the text specification dialog and apply the
 changes.
	@param		sender
 Ignored.
 */
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Called to close the text specification dialog and not apply the
 changes.
	@param		sender
 Ignored.
 */
- (IBAction)cancel:(id)sender;

/*!
	@method		preview:
	@discussion	Called to preview the text.
	@param		sender
 Ignored.
 */
- (IBAction)preview:(id)sender;

/*!
	@method		showFonts:
	@discussion	Shows the fonts panel to select the font to be used for the
 text.
	@param		sender
 Ignored.
 */
- (IBAction)showFonts:(id)sender;

/*!
	@method		move:
	@discussion	Shows the move panel to allow moving.
	@param		sender
 Ignored.
 */
- (IBAction)move:(id)sender;

/*!
	@method		doneMove:
	@discussion	Ends the move panel and applies the text.
	@param		sender
 Ignored.
 */
- (IBAction)doneMove:(id)sender;

/*!
	@method		cancelMove:
	@discussion	Ends the move panel and returns to the text specification panel.
	@param		sender
 Ignored.
 */
- (IBAction)cancelMove:(id)sender;

/*!
	@method		setNudge:
	@discussion	Nudges the text in the given direction.
	@param		nudge
 An IntPoint specifying the amount to nudge by in each direction.
 */
- (void)setNudge:(IntPoint)nudge;

/*!
	@method		centerHorizontally
	@discussion	Centres the text horizontally.
 */
- (void)centerHorizontally;

/*!
	@method		centerVertically
	@discussion	Centres the text vertically.
 */
- (void)centerVertically;

- (void)layerAttributesChanged:(int)nLayerType;


//- (void)setNSTextInputContext:(NSTextInputContext *)inputContext1;

-(void)fontFramilySelected:(NSString *)strFamilyName fontName:(NSString *)strFontName;
- (void)insertText:(id)aString;
- (void)changeFontSize:(CGFloat)fontSize;
- (void)changeCustomTransformType:(int)type;
- (void)changeCustomTransformValue:(CGFloat)fValue;

- (void)changeFontColor:(NSColor *)color;

- (void)changeFontBold:(int)nWidth;
- (void)changeFontItalics:(int)nItalicsValue;
- (void)changeFontUnderline:(int)nUnderlineValue;
- (void)changeFontStrikethrough:(int)nStrikethroughValue;
- (void)changeCharacterSpacing:(int)nCharacterSpacing;


- (void)shutDown;


@end
